//
//  VisionSceneAnalyzer.swift
//  AI Cleaner
//
//  Service for analyzing photos using Apple Vision framework
//

import Foundation
import Vision
internal import Photos
import UIKit
import CoreData

final class VisionSceneAnalyzer {
    static let shared = VisionSceneAnalyzer()

    private init() {}

    // MARK: - Turkish-English Translation Dictionary

    /// Translation dictionary for common search terms (Turkish → English)
    private let turkishToEnglish: [String: [String]] = [
        // Animals / Hayvanlar
        "kedi": ["cat"],
        "köpek": ["dog"],
        "hayvan": ["animal", "pet"],
        "kuş": ["bird"],
        "at": ["horse"],

        // Food / Yiyecek
        "yemek": ["food", "meal", "dish"],
        "içecek": ["drink", "beverage"],
        "kahve": ["coffee"],
        "çay": ["tea"],
        "kahvaltı": ["breakfast"],
        "akşam yemeği": ["dinner"],
        "öğle yemeği": ["lunch"],
        "pizza": ["pizza"],
        "burger": ["burger", "hamburger"],
        "tatlı": ["dessert", "sweet"],
        "meyve": ["fruit"],
        "sebze": ["vegetable"],

        // Places / Yerler
        "ev": ["home", "house", "indoor"],
        "dışarı": ["outdoor", "outside"],
        "plaj": ["beach", "coast"],
        "deniz": ["sea", "ocean", "water"],
        "dağ": ["mountain"],
        "orman": ["forest", "woods"],
        "park": ["park", "garden"],
        "bina": ["building", "architecture"],
        "sokak": ["street", "road"],
        "şehir": ["city", "urban"],
        "köy": ["village", "rural"],

        // Activities / Aktiviteler
        "spor": ["sport", "fitness", "gym", "exercise"],
        "koşu": ["running", "jogging"],
        "yüzme": ["swimming", "pool"],
        "bisiklet": ["bicycle", "bike", "cycling"],
        "futbol": ["football", "soccer"],
        "basketbol": ["basketball"],
        "dans": ["dance", "dancing"],
        "yoga": ["yoga"],
        "fitness": ["gym", "fitness", "workout"],
        "jimnastik": ["gym", "gymnastics", "fitness"],

        // Vehicles / Araçlar
        "araba": ["car", "automobile", "vehicle"],
        "otobüs": ["bus"],
        "tren": ["train"],
        "uçak": ["airplane", "aircraft"],
        "motosiklet": ["motorcycle"],
        "gemi": ["ship", "boat"],
        "tekne": ["boat"],

        // Nature / Doğa
        "doğa": ["nature", "natural"],
        "ağaç": ["tree"],
        "çiçek": ["flower"],
        "bitki": ["plant"],
        "güneş": ["sun", "sunny"],
        "yağmur": ["rain", "rainy"],
        "kar": ["snow", "snowy"],
        "gökyüzü": ["sky"],
        "bulut": ["cloud"],
        "göl": ["lake"],
        "nehir": ["river"],

        // People / İnsanlar
        "insan": ["person", "people", "human"],
        "kadın": ["woman", "female"],
        "erkek": ["man", "male"],
        "çocuk": ["child", "kid"],
        "bebek": ["baby"],
        "aile": ["family"],
        "arkadaş": ["friend"],
        "grup": ["group", "crowd"],
        "kalabalık": ["crowd"],

        // Events / Etkinlikler
        "düğün": ["wedding"],
        "parti": ["party"],
        "konser": ["concert"],
        "festival": ["festival"],
        "toplantı": ["meeting"],
        "doğum günü": ["birthday"],

        // Technology / Teknoloji
        "ekran görüntüsü": ["screenshot"],
        "belge": ["document", "paper"],
        "kimlik": ["id", "identity"],
        "fatura": ["invoice", "bill"],
        "makbuz": ["receipt"],

        // Other / Diğer
        "gece": ["night"],
        "gündüz": ["day", "daytime"],
        "sabah": ["morning"],
        "akşam": ["evening", "sunset"],
        "karanlık": ["dark", "darkness"],
        "aydınlık": ["bright", "light"],
        "rengarenk": ["colorful"],
        "siyah beyaz": ["black white", "monochrome"],
        "eski": ["old", "vintage"],
        "yeni": ["new"],
        "büyük": ["large", "big"],
        "küçük": ["small"],
        "yakın": ["close", "closeup"],
        "uzak": ["distant", "far"],
        "portre": ["portrait"],
        "manzara": ["landscape", "scenery"],
        "selfie": ["selfie"],
        "panorama": ["panorama"],
    ]

    // MARK: - Analysis

    /// Analyze a single photo and extract scene tags
    func analyzePhoto(_ asset: PHAsset) async throws -> [SceneLabel] {
        print("🔍 [VisionAnalyzer] Starting analysis for asset: \(asset.localIdentifier)")

        // Get image from asset
        guard let image = await fetchImage(for: asset) else {
            print("❌ [VisionAnalyzer] Failed to fetch image for asset: \(asset.localIdentifier)")
            throw AnalysisError.failedToFetchImage
        }

        print("✅ [VisionAnalyzer] Image fetched - Size: \(image.size)")

        // Convert to CGImage
        guard let cgImage = image.cgImage else {
            print("❌ [VisionAnalyzer] Failed to convert to CGImage")
            throw AnalysisError.invalidImage
        }

        // Perform scene classification
        let labels = try await performSceneClassification(on: cgImage)

        print("🔍 [VisionAnalyzer] Analyzed asset \(asset.localIdentifier)")
        print("   Found \(labels.count) scene labels:")
        for label in labels.prefix(5) {
            print("   - \(label.identifier): \(String(format: "%.2f", label.confidence))")
        }

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
            var isResumed = false

            let request = VNClassifyImageRequest { request, error in
                guard !isResumed else { return }
                isResumed = true

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
                // Only resume if the completion handler hasn't been called yet
                if !isResumed {
                    isResumed = true
                    continuation.resume(throwing: error)
                }
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

    /// Search for assets matching a query (supports Turkish and English)
    func searchAssets(
        query: String,
        minConfidence: Float = 0.4,
        context: NSManagedObjectContext
    ) -> [String] {
        print("🔍 [VisionAnalyzer] Searching for: '\(query)' (min confidence: \(minConfidence))")

        // Split query into keywords
        let originalKeywords = query.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }

        print("🔍 [VisionAnalyzer] Original keywords: \(originalKeywords)")

        guard !originalKeywords.isEmpty else {
            print("⚠️ [VisionAnalyzer] No keywords found")
            return []
        }

        // Expand keywords with translations (Turkish → English)
        var expandedKeywords: [String] = []

        for keyword in originalKeywords {
            // Add original keyword
            expandedKeywords.append(keyword)

            // Check if it's a Turkish word and add English translations
            if let translations = turkishToEnglish[keyword] {
                expandedKeywords.append(contentsOf: translations)
                print("🌍 [VisionAnalyzer] Turkish '\(keyword)' → English: \(translations)")
            }

            // Also check for partial matches in Turkish dictionary
            for (turkishWord, englishWords) in turkishToEnglish {
                if turkishWord.contains(keyword) || keyword.contains(turkishWord) {
                    expandedKeywords.append(contentsOf: englishWords)
                    print("🌍 [VisionAnalyzer] Partial match '\(keyword)' with '\(turkishWord)' → \(englishWords)")
                }
            }
        }

        // Remove duplicates
        let uniqueKeywords = Array(Set(expandedKeywords))
        print("🔍 [VisionAnalyzer] Expanded keywords: \(uniqueKeywords)")

        var matchingAssetIds = Set<String>()

        // Search for each keyword (original + translations)
        for keyword in uniqueKeywords {
            let assetIds = SceneTag.searchAssets(
                byLabel: keyword,
                minConfidence: minConfidence,
                context: context
            )
            if !assetIds.isEmpty {
                print("🔍 [VisionAnalyzer] Keyword '\(keyword)': \(assetIds.count) matches")
                matchingAssetIds.formUnion(assetIds)
            }
        }

        print("✅ [VisionAnalyzer] Total matches: \(matchingAssetIds.count)")

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
