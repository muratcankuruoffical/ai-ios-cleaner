//
//  VisionSceneAnalyzer.swift
//  AI Cleaner
//
//  Service for analyzing photos using Apple Vision framework
//

import Foundation
import Vision
import Photos
import UIKit
import CoreData

final class VisionSceneAnalyzer {
    static let shared = VisionSceneAnalyzer()

    private init() {}

    // MARK: - Analysis

    /// Analyze a single photo and extract scene tags
    func analyzePhoto(_ asset: PHAsset) async throws -> [SceneLabel] {
        // Get image from asset
        guard let image = await fetchImage(for: asset) else {
            throw AnalysisError.failedToFetchImage
        }

        // Convert to CGImage
        guard let cgImage = image.cgImage else {
            throw AnalysisError.invalidImage
        }

        // Perform scene classification
        let labels = try await performSceneClassification(on: cgImage)

        print("🔍 [VisionAnalyzer] Analyzed asset \(asset.localIdentifier)")
        print("   Found \(labels.count) scene labels")

        return labels
    }

    /// Analyze multiple photos in batch
    func analyzePhotos(_ assets: [PHAsset], progressHandler: ((Int, Int) -> Void)? = nil) async throws -> [String: [SceneLabel]] {
        var results: [String: [SceneLabel]] = [:]

        for (index, asset) in assets.enumerated() {
            do {
                let labels = try await analyzePhoto(asset)
                results[asset.localIdentifier] = labels

                // Report progress
                await MainActor.run {
                    progressHandler?(index + 1, assets.count)
                }
            } catch {
                print("⚠️ [VisionAnalyzer] Failed to analyze asset \(asset.localIdentifier): \(error.localizedDescription)")
            }
        }

        return results
    }

    /// Cache scene tags to CoreData
    func cacheTags(assetId: String, labels: [SceneLabel], context: NSManagedObjectContext) {
        for label in labels {
            SceneTag.createOrUpdate(
                context: context,
                assetId: assetId,
                label: label.identifier,
                confidence: label.confidence
            )
        }
    }

    // MARK: - Private Methods

    private func performSceneClassification(on cgImage: CGImage) async throws -> [SceneLabel] {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNClassifyImageRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNClassificationObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                // Filter observations with confidence > 0.3 and take top 10
                let labels = observations
                    .filter { $0.confidence > 0.3 }
                    .prefix(10)
                    .map { observation in
                        SceneLabel(
                            identifier: observation.identifier,
                            confidence: observation.confidence
                        )
                    }

                continuation.resume(returning: Array(labels))
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    private func fetchImage(for asset: PHAsset) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isSynchronous = false
            options.isNetworkAccessAllowed = true

            PHImageManager.default().requestImage(
                for: asset,
                targetSize: CGSize(width: 512, height: 512), // Smaller size for faster analysis
                contentMode: .aspectFit,
                options: options
            ) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }

    // MARK: - Search

    /// Search for assets matching a query
    func searchAssets(
        query: String,
        minConfidence: Float = 0.4,
        context: NSManagedObjectContext
    ) -> [String] {
        // Split query into keywords
        let keywords = query.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }

        guard !keywords.isEmpty else { return [] }

        var matchingAssetIds = Set<String>()

        // Search for each keyword
        for keyword in keywords {
            let assetIds = SceneTag.searchAssets(
                byLabel: keyword,
                minConfidence: minConfidence,
                context: context
            )
            matchingAssetIds.formUnion(assetIds)
        }

        return Array(matchingAssetIds)
    }

    // MARK: - Models

    struct SceneLabel {
        let identifier: String
        let confidence: Float

        var displayName: String {
            // Convert identifier to readable format
            // e.g., "gym" -> "Gym", "food_drink" -> "Food & Drink"
            identifier
                .replacingOccurrences(of: "_", with: " ")
                .capitalized
        }
    }

    enum AnalysisError: LocalizedError {
        case failedToFetchImage
        case invalidImage
        case analysisTimedOut

        var errorDescription: String? {
            switch self {
            case .failedToFetchImage:
                return "Failed to fetch image from photo library"
            case .invalidImage:
                return "Image format is not valid"
            case .analysisTimedOut:
                return "Analysis took too long"
            }
        }
    }
}
