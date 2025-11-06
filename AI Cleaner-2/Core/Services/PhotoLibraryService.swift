//
//  PhotoLibraryService.swift
//  AI Cleaner
//
//  Service for accessing and managing photo library
//

import Foundation
import Photos
import UIKit

final class PhotoLibraryService {
    static let shared = PhotoLibraryService()

    private let imageManager = PHCachingImageManager()

    private init() {
        imageManager.allowsCachingHighQualityImages = false
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        return status == .authorized || status == .limited
    }

    var authorizationStatus: PHAuthorizationStatus {
        PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    var isAuthorized: Bool {
        let status = authorizationStatus
        return status == .authorized || status == .limited
    }

    // MARK: - Fetching Assets

    func fetchAllImages() -> PHFetchResult<PHAsset> {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        return PHAsset.fetchAssets(with: options)
    }

    func fetchAllVideos() -> PHFetchResult<PHAsset> {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue)
        return PHAsset.fetchAssets(with: options)
    }

    func fetchAsset(withLocalIdentifier identifier: String) -> PHAsset? {
        let result = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
        return result.firstObject
    }

    // MARK: - Image Loading

    func loadImage(
        for asset: PHAsset,
        targetSize: CGSize,
        contentMode: PHImageContentMode = .aspectFit
    ) async throws -> UIImage {
        try await withCheckedThrowingContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            options.isSynchronous = false

            imageManager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: contentMode,
                options: options
            ) { image, info in
                if let error = info?[PHImageErrorKey] as? Error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let image = image else {
                    continuation.resume(throwing: PhotoLibraryError.imageLoadFailed)
                    return
                }

                continuation.resume(returning: image)
            }
        }
    }

    func loadFullResolutionImage(for asset: PHAsset) async throws -> UIImage {
        let targetSize = CGSize(
            width: asset.pixelWidth,
            height: asset.pixelHeight
        )
        return try await loadImage(for: asset, targetSize: targetSize)
    }

    func loadThumbnail(for asset: PHAsset) async throws -> UIImage {
        let thumbnailSize = CGSize(width: 300, height: 300)
        return try await loadImage(for: asset, targetSize: thumbnailSize)
    }

    // Analysis size for Vision framework (512x512 is good balance)
    func loadAnalysisImage(for asset: PHAsset) async throws -> UIImage {
        let analysisSize = CGSize(width: 512, height: 512)
        return try await loadImage(for: asset, targetSize: analysisSize)
    }

    // MARK: - Asset Information

    func getAssetSize(for asset: PHAsset) async -> Int64 {
        guard let resource = PHAssetResource.assetResources(for: asset).first else {
            return 0
        }

        return await withCheckedContinuation { continuation in
            var size: Int64 = 0

            if let unsignedSize = resource.value(forKey: "fileSize") as? CLong {
                size = Int64(unsignedSize)
            }

            continuation.resume(returning: size)
        }
    }

    // MARK: - Deletion

    func delete(assets: [PHAsset]) async throws {
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets(assets as NSArray)
        }
    }

    func deleteAssets(withIdentifiers identifiers: [String]) async throws {
        let assets = identifiers.compactMap { fetchAsset(withLocalIdentifier: $0) }
        try await delete(assets: assets)
    }

    // MARK: - Batch Processing

    func processBatch<T>(
        fetchResult: PHFetchResult<PHAsset>,
        batchSize: Int = 50,
        processor: @escaping (PHAsset) async throws -> T
    ) async throws -> [T] {
        var results: [T] = []
        let count = fetchResult.count

        for i in 0..<count {
            let asset = fetchResult.object(at: i)
            let result = try await processor(asset)
            results.append(result)

            // Yield after each batch to avoid blocking
            if i % batchSize == 0 {
                await Task.yield()
            }
        }

        return results
    }
}

// MARK: - Errors

enum PhotoLibraryError: Error, LocalizedError {
    case unauthorized
    case imageLoadFailed
    case deleteFailed

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Photo library access is not authorized"
        case .imageLoadFailed:
            return "Failed to load image from photo library"
        case .deleteFailed:
            return "Failed to delete assets"
        }
    }
}
