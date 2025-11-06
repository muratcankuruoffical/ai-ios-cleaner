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
        var compressionQuality: CGFloat = 0.85

        /// Only optimize photos taken in last N days (nil = all photos)
        var recentDaysOnly: Int? = 30

        static let `default` = Configuration()

        /// 1080p preset
        static let preset1080p = Configuration(
            targetResolution: 1920,
            minResolutionForOptimization: 2560,
            compressionQuality: 0.85
        )

        /// High quality preset (less compression)
        static let presetHighQuality = Configuration(
            targetResolution: 1920,
            minResolutionForOptimization: 2560,
            compressionQuality: 0.90
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
        deleteOriginal: Bool = false
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
            width: originalImage.size.width * scale,
            height: originalImage.size.height * scale
        )

        // Resize image
        guard let resizedImage = resizeImage(originalImage, to: targetSize) else {
            throw PhotoOptimizerError.resizeFailed
        }

        // Compress to JPEG
        guard let jpegData = resizedImage.jpegData(compressionQuality: configuration.compressionQuality) else {
            throw PhotoOptimizerError.compressionFailed
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

        let newSize = newAsset != nil ? await PhotoLibraryService.shared.getAssetSize(for: newAsset!) : 0

        // Delete original if requested and save succeeded
        if deleteOriginal, newAsset != nil, saveError == nil {
            do {
                try await PhotoLibraryService.shared.delete(assets: [asset])
            } catch {
                // Log but don't fail the operation
                print("⚠️ Failed to delete original asset: \(error)")
            }
        }

        let duration = Date().timeIntervalSince(startTime)
        print("✅ Optimized photo in \(String(format: "%.2f", duration))s: \(originalSize/1024)KB → \(newSize/1024)KB")

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

        for (index, photo) in photos.enumerated() {
            do {
                let result = try await optimizePhoto(
                    asset: photo.asset,
                    configuration: configuration,
                    deleteOriginal: deleteOriginals
                )
                results.append(result)
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

        return results
    }

    // MARK: - Utilities

    private func resizeImage(_ image: UIImage, to targetSize: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    func calculateTotalSavings(photos: [OptimizablePhoto]) -> Int64 {
        photos.reduce(0) { $0 + $1.potentialSavings }
    }
}

// MARK: - Errors

enum PhotoOptimizerError: Error, LocalizedError {
    case alreadyOptimized
    case resizeFailed
    case compressionFailed
    case saveFailed

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
        }
    }
}
