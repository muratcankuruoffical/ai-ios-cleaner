//
//  AIPhotoSearchViewModel.swift
//  AI Cleaner
//
//  ViewModel for AI Photo Search
//

import Foundation
internal import Photos
import CoreData
internal import Combine

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

    var indexingProgressPercentage: Double {
        guard totalPhotos > 0 else { return 0 }
        return Double(indexingProgress) / Double(totalPhotos)
    }

    // MARK: - Initialization

    func initializeIfNeeded() {
        #if targetEnvironment(simulator)
        print("📱 [AIPhotoSearch] Running on simulator - Using mock indexing for UI testing")
        Task {
            totalPhotos = getTotalPhotoCount()

            // Simulate indexing process on simulator (for UI testing only)
            if totalPhotos > 0 {
                await simulateIndexing()
            } else {
                hasIndexed = true
            }
        }
        #else
        Task {
            // Check if we need to index photos
            let indexedCount = getIndexedPhotoCount()
            let totalCount = getTotalPhotoCount()

            totalPhotos = totalCount

            print("📊 [AIPhotoSearch] Indexed: \(indexedCount), Total: \(totalCount)")

            // If less than 50% indexed or no photos indexed, start indexing
            if indexedCount == 0 || (indexedCount < totalCount / 2) {
                print("🏗️ [AIPhotoSearch] Starting automatic indexing...")
                await startIndexing()
            } else {
                print("✅ [AIPhotoSearch] Photos already indexed")
                hasIndexed = true
                indexingProgress = totalCount
            }
        }
        #endif
    }

    // MARK: - Simulator Mock Indexing

    #if targetEnvironment(simulator)
    private func simulateIndexing() async {
        print("🎭 [AIPhotoSearch] Starting mock indexing simulation...")
        isIndexing = true
        indexingProgress = 0

        // Simulate indexing with progress updates
        let batchSize = max(1, totalPhotos / 20) // 20 updates

        for _ in 0..<20 {
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms delay
            indexingProgress = min(indexingProgress + batchSize, totalPhotos)

            if indexingProgress >= totalPhotos {
                break
            }
        }

        // Ensure we reach 100%
        indexingProgress = totalPhotos
        isIndexing = false
        hasIndexed = true

        print("✅ [AIPhotoSearch] Mock indexing completed!")
    }
    #endif

    // MARK: - Search

    func search(query: String) {
        guard !query.isEmpty else {
            clearResults()
            return
        }

        isSearching = true
        hasSearched = true

        Task {
            var assets: [PHAsset] = []

            #if targetEnvironment(simulator)
            // Use simple search on simulator (Vision Framework doesn't work)
            print("📱 [AIPhotoSearch] Using simple search (simulator)")
            assets = await SimplePhotoSearchService.shared.searchPhotos(query: query)
            #else
            // Use Vision Framework on real device
            print("🔍 [AIPhotoSearch] Using Vision Framework (device)")
            let assetIds = analyzer.searchAssets(
                query: query,
                minConfidence: 0.4,
                context: context
            )

            print("🔍 [AIPhotoSearch] Query: '\(query)' -> Found \(assetIds.count) matches")

            // Fetch PHAssets
            assets = await fetchAssets(withLocalIdentifiers: assetIds)
            #endif

            searchResults = assets
            isSearching = false
        }
    }

    func clearResults() {
        searchResults = []
        hasSearched = false
    }

    func forceReindex() {
        Task {
            print("🔄 [AIPhotoSearch] Force re-indexing all photos...")
            await startIndexing(force: true)
        }
    }

    // MARK: - Indexing

    private func startIndexing(force: Bool = false) async {
        guard !isIndexing else { return }

        print("🏗️ [AIPhotoSearch] Starting photo indexing (force: \(force))...")

        isIndexing = true
        indexingProgress = 0

        // Fetch all photos
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let allPhotos = PHAsset.fetchAssets(with: .image, options: fetchOptions)

        totalPhotos = allPhotos.count

        var photosToIndex: [PHAsset] = []

        if force {
            // Re-index all photos
            allPhotos.enumerateObjects { asset, _, _ in
                photosToIndex.append(asset)
            }
            print("📊 [AIPhotoSearch] Force re-indexing all \(totalPhotos) photos")
        } else {
            // Get already indexed asset IDs
            let indexedAssetIds = getIndexedAssetIds()
            print("📊 [AIPhotoSearch] Total photos: \(totalPhotos), Already indexed: \(indexedAssetIds.count)")

            // Convert to array and filter out already indexed photos
            allPhotos.enumerateObjects { asset, _, _ in
                if !indexedAssetIds.contains(asset.localIdentifier) {
                    photosToIndex.append(asset)
                }
            }
        }

        print("📊 [AIPhotoSearch] Photos to index: \(photosToIndex.count)")

        guard !photosToIndex.isEmpty else {
            print("✅ [AIPhotoSearch] No photos to index")
            isIndexing = false
            hasIndexed = true
            indexingProgress = totalPhotos
            return
        }

        // Process in batches of 10 (reduced for stability)
        let batchSize = 10
        let batches = stride(from: 0, to: photosToIndex.count, by: batchSize).map {
            Array(photosToIndex[$0..<min($0 + batchSize, photosToIndex.count)])
        }

        print("📊 [AIPhotoSearch] Processing \(batches.count) batches of \(batchSize)")

        for (index, batch) in batches.enumerated() {
            print("📦 [AIPhotoSearch] Processing batch \(index + 1)/\(batches.count)")
            await processBatch(batch)
        }

        isIndexing = false
        hasIndexed = true

        print("✅ [AIPhotoSearch] Indexing completed! Total indexed: \(indexingProgress)")
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
