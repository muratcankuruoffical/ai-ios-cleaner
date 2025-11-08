//
//  AIPhotoSearchViewModel.swift
//  AI Cleaner
//
//  ViewModel for AI Photo Search
//

import Foundation
import Photos
import CoreData
import Combine

@MainActor
class AIPhotoSearchViewModel: ObservableObject {
    @Published var searchResults: [PHAsset] = []
    @Published var isSearching = false
    @Published var hasSearched = false
    @Published var isIndexing = false
    @Published var indexingProgress = 0
    @Published var totalPhotos = 0

    private let analyzer = VisionSceneAnalyzer.shared
    private let context = CoreDataStack.shared.viewContext
    private var hasIndexed = false

    // MARK: - Initialization

    func initializeIfNeeded() {
        // Check if we need to index photos
        let indexedCount = getIndexedPhotoCount()
        let totalCount = getTotalPhotoCount()

        print("📊 [AIPhotoSearch] Indexed: \(indexedCount), Total: \(totalCount)")

        // If less than 50% indexed or no photos indexed, start indexing
        if indexedCount == 0 || (indexedCount < totalCount / 2) {
            Task {
                await startIndexing()
            }
        } else {
            hasIndexed = true
        }
    }

    // MARK: - Search

    func search(query: String) {
        guard !query.isEmpty else {
            clearResults()
            return
        }

        isSearching = true
        hasSearched = true

        Task {
            // Perform search
            let assetIds = analyzer.searchAssets(
                query: query,
                minConfidence: 0.4,
                context: context
            )

            print("🔍 [AIPhotoSearch] Query: '\(query)' -> Found \(assetIds.count) matches")

            // Fetch PHAssets
            let assets = await fetchAssets(withLocalIdentifiers: assetIds)

            searchResults = assets
            isSearching = false
        }
    }

    func clearResults() {
        searchResults = []
        hasSearched = false
    }

    // MARK: - Indexing

    private func startIndexing() async {
        guard !isIndexing else { return }

        print("🏗️ [AIPhotoSearch] Starting photo indexing...")

        isIndexing = true
        indexingProgress = 0

        // Fetch all photos
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let allPhotos = PHAsset.fetchAssets(with: .image, options: fetchOptions)

        totalPhotos = allPhotos.count

        // Get already indexed asset IDs
        let indexedAssetIds = getIndexedAssetIds()

        print("📊 [AIPhotoSearch] Total photos: \(totalPhotos), Already indexed: \(indexedAssetIds.count)")

        // Convert to array and filter out already indexed photos
        var photosToIndex: [PHAsset] = []
        allPhotos.enumerateObjects { asset, _, _ in
            if !indexedAssetIds.contains(asset.localIdentifier) {
                photosToIndex.append(asset)
            }
        }

        print("📊 [AIPhotoSearch] Photos to index: \(photosToIndex.count)")

        // Process in batches of 20
        let batchSize = 20
        let batches = stride(from: 0, to: photosToIndex.count, by: batchSize).map {
            Array(photosToIndex[$0..<min($0 + batchSize, photosToIndex.count)])
        }

        for batch in batches {
            await processBatch(batch)
        }

        isIndexing = false
        hasIndexed = true

        print("✅ [AIPhotoSearch] Indexing completed!")
    }

    private func processBatch(_ assets: [PHAsset]) async {
        for asset in assets {
            do {
                // Analyze photo
                let labels = try await analyzer.analyzePhoto(asset)

                // Cache tags
                analyzer.cacheTags(
                    assetId: asset.localIdentifier,
                    labels: labels,
                    context: context
                )

                // Save to CoreData
                CoreDataStack.shared.save()

                // Update progress
                indexingProgress += 1

            } catch {
                print("⚠️ [AIPhotoSearch] Failed to analyze \(asset.localIdentifier): \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Helpers

    private func fetchAssets(withLocalIdentifiers identifiers: [String]) async -> [PHAsset] {
        return await withCheckedContinuation { continuation in
            let fetchResult = PHAsset.fetchAssets(
                withLocalIdentifiers: identifiers,
                options: nil
            )

            var assets: [PHAsset] = []
            fetchResult.enumerateObjects { asset, _, _ in
                assets.append(asset)
            }

            continuation.resume(returning: assets)
        }
    }

    private func getTotalPhotoCount() -> Int {
        let fetchOptions = PHFetchOptions()
        let allPhotos = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        return allPhotos.count
    }

    private func getIndexedPhotoCount() -> Int {
        let fetchRequest: NSFetchRequest<SceneTag> = SceneTag.fetchRequest()

        do {
            let count = try context.count(for: fetchRequest)
            // Divide by average tags per photo (~5)
            return count / 5
        } catch {
            return 0
        }
    }

    private func getIndexedAssetIds() -> Set<String> {
        let fetchRequest: NSFetchRequest<SceneTag> = SceneTag.fetchRequest()
        fetchRequest.propertiesToFetch = ["assetId"]
        fetchRequest.returnsDistinctResults = true

        do {
            let tags = try context.fetch(fetchRequest)
            return Set(tags.compactMap { $0.assetId })
        } catch {
            return []
        }
    }
}
