//
//  PhotoOptimizer.swift
//  AI Cleaner
//
//  Service for optimizing photos (4K → 1080p compression)
//

import Foundation
import Photos
import UIKit
import CoreImage
import CoreData

final class PhotoOptimizer {
    static let shared = PhotoOptimizer()

    private init() {}

    // MARK: - Configuration

    struct Configuration {
        /// Target maximum resolution (width or height)
        var targetResolution: CGFloat = 1920 // 1080p

        /// Minimum resolution to consider for optimization
        var minResolutionForOptimization: CGFloat = 2560 // ~4K

        /// JPEG compression quality (0.0 - 1.0)
        var compressionQuality: CGFloat = 0.70

        /// Only optimize photos taken in last N days (nil = all photos)
        var recentDaysOnly: Int? = 30

        nonisolated(unsafe) static let `default` = Configuration()

        /// 1080p preset - Aggressive compression for real space savings
        nonisolated(unsafe) static let preset1080p = Configuration(
            targetResolution: 1920,
            minResolutationForOptimization: 2560,
            compressionQuality: 0.70  // Lower quality = smaller file
        )

        /// High quality preset - Balanced compression
        nonisolated(unsafe) static let presetHighQuality = Configuration(
            targetResolution: 1920,
            minResolutionForOptimization: 2560,
            compressionQuality: 0.80  // Still lower than before
        )
    }

    // MARK: - Optimization Info

    struct OptimizablePhoto {
        let asset: PHAsset
        let currentSize: Int64
        let estimatedOptimizedSize: Int64
        let currentResolution: CGSize
        let targetResolution: CGSize

        var potentialSavings: Int64 {
            currentSize - estimatedOptimizedSize
        }

        var savingsPercentage: Double {
            guard currentSize > 0 else { return 0 }
            return Double(potentialSavings) / Double(currentSize) * 100
        }
    }

    struct OptimizationResult {
        let originalAsset: PHAsset
        let newAsset: PHAsset?
        let originalSize: Int64
        let newSize: Int64
        let success: Bool
        let error: Error?

        var savedBytes: Int64 {
            success ? originalSize - newSize : 0
        }
    }

    // MARK: - Find Optimizable Photos

    func findOptimizablePhotos(
        assets: [PHAsset],
        configuration: Configuration = .default,
        progressHandler: ((Int, Int) -> Void)? = nil
    ) async -> [OptimizablePhoto] {
        var optimizablePhotos: [OptimizablePhoto] = []

        for (index, asset) in assets.enumerated() {
            guard asset.mediaType == .image else { continue }

            let width = CGFloat(asset.pixelWidth)
            let height = CGFloat(asset.pixelHeight)
            let maxDimension = max(width, height)

            // Skip if resolution is below threshold
            guard maxDimension >= configuration.minResolutionForOptimization else {
                continue
            }

            // Check date if needed
            if let recentDays = configuration.recentDaysOnly,
               let creationDate = asset.creationDate {
                let daysAgo = Date().timeIntervalSince(creationDate) / (24 * 3600)
                guard daysAgo <= Double(recentDays) else { continue }
            }

            // Get current file size
            let currentSize = await PhotoLibraryService.shared.getAssetSize(for: asset)
            guard currentSize > 0 else { continue }

            // Calculate target resolution
            let scale = configuration.targetResolution / maxDimension
            let targetWidth = width * scale
            let targetHeight = height * scale

            // Estimate optimized size (rough approximation)
            let pixelReduction = scale * scale
            let compressionFactor = configuration.compressionQuality
            let estimatedSize = Int64(Double(currentSize) * pixelReduction * compressionFactor)

            // Only include if we can save at least 10%
            if currentSize - estimatedSize > currentSize / 10 {
                optimizablePhotos.append(OptimizablePhoto(
                    asset: asset,
                    currentSize: currentSize,
                    estimatedOptimizedSize: estimatedSize,
                    currentResolution: CGSize(width: width, height: height),
                    targetResolution: CGSize(width: targetWidth, height: targetHeight)
                ))
            }

            progressHandler?(index + 1, assets.count)

            if index % 20 == 0 {
                await Task.yield()
            }
        }

        return optimizablePhotos.sorted { $0.potentialSavings > $1.potentialSavings }
    }

    // MARK: - Optimize Photo

    func optimizePhoto(
        asset: PHAsset,
        configuration: Configuration = .default,
        deleteOriginal: Bool = false,
        clearCache: Bool = true
    ) async throws -> OptimizationResult {
        let startTime = Date()

        // Load full resolution image
        let originalImage = try await PhotoLibraryService.shared.loadFullResolutionImage(for: asset)
        let originalSize = await PhotoLibraryService.shared.getAssetSize(for: asset)

        // Calculate target size
        let originalDimension = max(originalImage.size.width, originalImage.size.height)
        let scale = configuration.targetResolution / originalDimension

        guard scale < 1.0 else {
            // No need to optimize - already smaller than target
            throw PhotoOptimizerError.alreadyOptimized
        }

        let targetSize = CGSize(
            width: floor(originalImage.size.width * scale),
            height: floor(originalImage.size.height * scale)
        )

        // Resize image with better quality
        guard let resizedImage = resizeImageHighQuality(originalImage, to: targetSize) else {
            throw PhotoOptimizerError.resizeFailed
        }

        // Compress to JPEG
        guard let jpegData = resizedImage.jpegData(compressionQuality: configuration.compressionQuality) else {
            throw PhotoOptimizerError.compressionFailed
        }

        let optimizedSize = Int64(jpegData.count)

        // Sanity check: If optimized is larger, throw error
        if optimizedSize >= originalSize {
            print("⚠️ Optimization failed: new size (\(optimizedSize/1024)KB) >= original (\(originalSize/1024)KB)")
            throw PhotoOptimizerError.noSavings
        }

        // Save to photo library
        var newAssetId: String?
        var saveError: Error?

        do {
            try await PHPhotoLibrary.shared().performChanges {
                let creationRequest = PHAssetCreationRequest.forAsset()
                creationRequest.addResource(with: .photo, data: jpegData, options: nil)

                // Copy metadata from original
                if let originalCreationDate = asset.creationDate {
                    creationRequest.creationDate = originalCreationDate
                }
                if let location = asset.location {
                    creationRequest.location = location
                }

                newAssetId = creationRequest.placeholderForCreatedAsset?.localIdentifier
            }
        } catch {
            saveError = error
        }

        // Retrieve the new asset
        var newAsset: PHAsset?
        if let assetId = newAssetId {
            newAsset = PhotoLibraryService.shared.fetchAsset(withLocalIdentifier: assetId)
        }

        let newSize = newAsset != nil ? await PhotoLibraryService.shared.getAssetSize(for: newAsset!) : optimizedSize

        // Delete original if requested and save succeeded
        if deleteOriginal, newAsset != nil, saveError == nil {
            do {
                try await PhotoLibraryService.shared.delete(assets: [asset])
                print("🗑️ Deleted original photo: \(asset.localIdentifier)")

                // Clear cache for deleted asset if requested
                if clearCache {
                    await clearCacheForAsset(asset.localIdentifier)
                }
            } catch {
                // Log but don't fail the operation
                print("⚠️ Failed to delete original asset: \(error)")
            }
        }

        let duration = Date().timeIntervalSince(startTime)
        let savedBytes = originalSize - newSize
        print("✅ Optimized photo in \(String(format: "%.2f", duration))s: \(originalSize/1024)KB → \(newSize/1024)KB (saved \(savedBytes/1024)KB)")

        return OptimizationResult(
            originalAsset: asset,
            newAsset: newAsset,
            originalSize: originalSize,
            newSize: newSize,
            success: newAsset != nil && saveError == nil,
            error: saveError
        )
    }

    // MARK: - Batch Optimization

    func optimizePhotos(
        photos: [OptimizablePhoto],
        configuration: Configuration = .default,
        deleteOriginals: Bool = false,
        progressHandler: ((Int, Int, OptimizationResult) -> Void)? = nil
    ) async -> [OptimizationResult] {
        var results: [OptimizationResult] = []
        var deletedAssetIds: [String] = []

        for (index, photo) in photos.enumerated() {
            do {
                let result = try await optimizePhoto(
                    asset: photo.asset,
                    configuration: configuration,
                    deleteOriginal: deleteOriginals,
                    clearCache: false  // We'll do batch cleanup at the end
                )
                results.append(result)

                // Track deleted assets for batch cache cleanup
                if deleteOriginals && result.success {
                    deletedAssetIds.append(photo.asset.localIdentifier)
                }

                progressHandler?(index + 1, photos.count, result)
            } catch {
                let result = OptimizationResult(
                    originalAsset: photo.asset,
                    newAsset: nil,
                    originalSize: photo.currentSize,
                    newSize: photo.currentSize,
                    success: false,
                    error: error
                )
                results.append(result)
                progressHandler?(index + 1, photos.count, result)
            }

            // Yield periodically
            if index % 5 == 0 {
                await Task.yield()
            }
        }

        // Batch clear cache for all deleted assets
        if !deletedAssetIds.isEmpty {
            await clearCacheForAssets(deletedAssetIds)
        }

        return results
    }

    // MARK: - Utilities

    private func resizeImage(_ image: UIImage, to targetSize: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    private func resizeImageHighQuality(_ image: UIImage, to targetSize: CGSize) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)

        guard let context = CGContext(
            data: nil,
            width: Int(targetSize.width),
            height: Int(targetSize.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            return nil
        }

        // Use high quality interpolation
        context.interpolationQuality = .high

        // Draw the image
        context.draw(cgImage, in: CGRect(origin: .zero, size: targetSize))

        guard let resizedCGImage = context.makeImage() else {
            return nil
        }

        return UIImage(cgImage: resizedCGImage, scale: 1.0, orientation: image.imageOrientation)
    }

    func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    func calculateTotalSavings(photos: [OptimizablePhoto]) -> Int64 {
        photos.reduce(0) { $0 + $1.potentialSavings }
    }

    // MARK: - Cache Management

    private func clearCacheForAsset(_ assetIdentifier: String) async {
        let context = CoreDataStack.shared.newBackgroundContext()

        await context.perform {
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "AssetFingerprint")
            fetchRequest.predicate = NSPredicate(format: "assetLocalId == %@", assetIdentifier)

            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            deleteRequest.resultType = .resultTypeCount

            do {
                let result = try context.execute(deleteRequest) as? NSBatchDeleteResult
                if let count = result?.result as? Int {
                    print("🧹 Cleared cache for deleted asset: \(assetIdentifier) (\(count) records)")
                }
            } catch {
                print("⚠️ Failed to clear cache for asset: \(error)")
            }
        }
    }

    /// Clear cache for multiple assets (batch operation)
    func clearCacheForAssets(_ assetIdentifiers: [String]) async {
        guard !assetIdentifiers.isEmpty else { return }

        let context = CoreDataStack.shared.newBackgroundContext()

        await context.perform {
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "AssetFingerprint")
            fetchRequest.predicate = NSPredicate(format: "assetLocalId IN %@", assetIdentifiers)

            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            deleteRequest.resultType = .resultTypeCount

            do {
                let result = try context.execute(deleteRequest) as? NSBatchDeleteResult
                if let count = result?.result as? Int {
                    print("🧹 Cleared cache for \(assetIdentifiers.count) deleted assets (\(count) records)")
                }
            } catch {
                print("⚠️ Failed to clear cache for assets: \(error)")
            }
        }
    }
}

// MARK: - Errors

enum PhotoOptimizerError: Error, LocalizedError {
    case alreadyOptimized
    case resizeFailed
    case compressionFailed
    case saveFailed
    case noSavings

    var errorDescription: String? {
        switch self {
        case .alreadyOptimized:
            return "Photo is already optimized"
        case .resizeFailed:
            return "Failed to resize image"
        case .compressionFailed:
            return "Failed to compress image"
        case .saveFailed:
            return "Failed to save optimized image"
        case .noSavings:
            return "Optimized photo is not smaller than original"
        }
    }
}
