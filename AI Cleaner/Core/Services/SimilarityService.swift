//
//  SimilarityService.swift
//  AI Cleaner
//
//  Service for detecting similar/duplicate images using clustering
//

import Foundation
import Photos

final class SimilarityService {
    static let shared = SimilarityService()

    private init() {}

    // MARK: - Configuration

    struct Configuration {
        var similarityThreshold: Float = 0.15 // Lower = more similar
        var minGroupSize: Int = 2
        var useCosineSimilarity: Bool = true

        nonisolated(unsafe) static let `default` = Configuration()
        nonisolated(unsafe) static let strict = Configuration(similarityThreshold: 0.10, minGroupSize: 2)
        nonisolated(unsafe) static let relaxed = Configuration(similarityThreshold: 0.25, minGroupSize: 2)
    }

    // MARK: - Data Types

    struct AssetWithVector {
        let asset: PHAsset
        let vector: FeatureVector
        let metadata: AssetMetadata
    }

    struct AssetMetadata {
        let blurScore: Float
        let brightnessScore: Float
        let isScreenshot: Bool
        let fileSize: Int64
    }

    struct SimilarityGroup {
        let id: UUID
        let assets: [PHAsset]
        let vectors: [FeatureVector]
        let averageSimilarity: Float
        let metadata: [AssetMetadata]

        var bestQualityAssetIndex: Int {
            // Find the asset with the best quality (highest blur score, brightness, etc.)
            var bestIndex = 0
            var bestScore: Float = -Float.infinity

            for (index, meta) in metadata.enumerated() {
                // Quality score: higher blur score is better, moderate brightness is better
                let qualityScore = meta.blurScore * 2.0 - abs(meta.brightnessScore - 0.5)
                if qualityScore > bestScore {
                    bestScore = qualityScore
                    bestIndex = index
                }
            }

            return bestIndex
        }

        var suggestedDeletions: [Int] {
            let bestIndex = bestQualityAssetIndex
            return assets.indices.filter { $0 != bestIndex }
        }
    }

    // MARK: - Clustering

    func findSimilarGroups(
        assets: [AssetWithVector],
        configuration: Configuration = .default
    ) async -> [SimilarityGroup] {
        guard !assets.isEmpty else { return [] }

        // Build similarity graph using Union-Find (Disjoint Set)
        var parent = Array(0..<assets.count)
        var rank = [Int](repeating: 0, count: assets.count)

        func find(_ x: Int) -> Int {
            if parent[x] != x {
                parent[x] = find(parent[x]) // Path compression
            }
            return parent[x]
        }

        func union(_ x: Int, _ y: Int) {
            let rootX = find(x)
            let rootY = find(y)

            if rootX != rootY {
                // Union by rank
                if rank[rootX] < rank[rootY] {
                    parent[rootX] = rootY
                } else if rank[rootX] > rank[rootY] {
                    parent[rootY] = rootX
                } else {
                    parent[rootY] = rootX
                    rank[rootX] += 1
                }
            }
        }

        // Compare all pairs and union similar ones
        let count = assets.count
        print("🔍 Similarity Analysis (threshold: \(configuration.similarityThreshold)):")
        var matchCount = 0

        for i in 0..<count {
            for j in (i + 1)..<count {
                let distance = configuration.useCosineSimilarity
                    ? FeatureVector.cosineDistance(assets[i].vector, assets[j].vector)
                    : FeatureVector.distance(assets[i].vector, assets[j].vector)

                let isSimilar = distance < configuration.similarityThreshold
                if isSimilar {
                    union(i, j)
                    matchCount += 1
                }

                // Log first few comparisons for debugging
                if count <= 10 && (isSimilar || j - i == 1) {
                    _ = assets[i].asset.localIdentifier.prefix(8)
                    _ = assets[j].asset.localIdentifier.prefix(8)
                    let symbol = isSimilar ? "✅" : "❌"
                    print("   \(symbol) [\(i)] vs [\(j)]: distance = \(String(format: "%.4f", distance))")
                }
            }

            // Yield periodically to avoid blocking
            if i % 50 == 0 {
                await Task.yield()
            }
        }

        print("   Total similar pairs found: \(matchCount)")

        // Group assets by their root parent
        var groups: [Int: [Int]] = [:]
        for i in 0..<count {
            let root = find(i)
            groups[root, default: []].append(i)
        }

        // Convert to SimilarityGroup objects
        var similarityGroups: [SimilarityGroup] = []

        for (_, indices) in groups {
            guard indices.count >= configuration.minGroupSize else { continue }

            let groupAssets = indices.map { assets[$0].asset }
            let groupVectors = indices.map { assets[$0].vector }
            let groupMetadata = indices.map { assets[$0].metadata }

            // Calculate average similarity within group
            var totalSimilarity: Float = 0
            var pairCount = 0

            for i in 0..<indices.count {
                for j in (i + 1)..<indices.count {
                    let distance = configuration.useCosineSimilarity
                        ? FeatureVector.cosineDistance(groupVectors[i], groupVectors[j])
                        : FeatureVector.distance(groupVectors[i], groupVectors[j])
                    totalSimilarity += distance
                    pairCount += 1
                }
            }

            let avgSimilarity = pairCount > 0 ? totalSimilarity / Float(pairCount) : 0

            let group = SimilarityGroup(
                id: UUID(),
                assets: groupAssets,
                vectors: groupVectors,
                averageSimilarity: avgSimilarity,
                metadata: groupMetadata
            )

            similarityGroups.append(group)
        }

        // Sort groups by size (largest first)
        return similarityGroups.sorted { $0.assets.count > $1.assets.count }
    }

    // MARK: - Exact Duplicates (Fast Path)

    func findExactDuplicates(assets: [AssetWithVector]) async -> [SimilarityGroup] {
        var hashGroups: [String: [Int]] = [:]

        for (index, asset) in assets.enumerated() {
            // Use a simple hash of the first N bytes of the vector
            let hashData = asset.vector.data.prefix(32)
            let hash = hashData.map { String(format: "%02x", $0) }.joined()
            hashGroups[hash, default: []].append(index)

            if index % 100 == 0 {
                await Task.yield()
            }
        }

        var groups: [SimilarityGroup] = []

        for (_, indices) in hashGroups where indices.count >= 2 {
            let groupAssets = indices.map { assets[$0].asset }
            let groupVectors = indices.map { assets[$0].vector }
            let groupMetadata = indices.map { assets[$0].metadata }

            let group = SimilarityGroup(
                id: UUID(),
                assets: groupAssets,
                vectors: groupVectors,
                averageSimilarity: 0,
                metadata: groupMetadata
            )

            groups.append(group)
        }

        return groups.sorted { $0.assets.count > $1.assets.count }
    }

    // MARK: - Incremental Processing

    func findNewSimilarities(
        newAsset: AssetWithVector,
        existingAssets: [AssetWithVector],
        threshold: Float = 0.15
    ) async -> [AssetWithVector] {
        var similar: [AssetWithVector] = []

        for (index, existing) in existingAssets.enumerated() {
            let distance = FeatureVector.cosineDistance(newAsset.vector, existing.vector)

            if distance < threshold {
                similar.append(existing)
            }

            if index % 50 == 0 {
                await Task.yield()
            }
        }

        return similar
    }

    // MARK: - Statistics

    func calculatePotentialSavings(groups: [SimilarityGroup]) -> Int64 {
        var totalBytes: Int64 = 0

        for group in groups {
            let deletionIndices = group.suggestedDeletions
            for index in deletionIndices {
                totalBytes += group.metadata[index].fileSize
            }
        }

        return totalBytes
    }

    func calculateStatistics(groups: [SimilarityGroup]) -> CleanupStatistics {
        let totalGroups = groups.count
        let totalDuplicates = groups.reduce(0) { $0 + ($1.assets.count - 1) }
        let potentialSavings = calculatePotentialSavings(groups: groups)

        let largestGroup = groups.max { $0.assets.count < $1.assets.count }

        return CleanupStatistics(
            totalGroups: totalGroups,
            totalDuplicates: totalDuplicates,
            potentialSavingsBytes: potentialSavings,
            largestGroupSize: largestGroup?.assets.count ?? 0
        )
    }
}

// MARK: - Statistics Model

struct CleanupStatistics {
    let totalGroups: Int
    let totalDuplicates: Int
    let potentialSavingsBytes: Int64
    let largestGroupSize: Int

    var potentialSavingsMB: Double {
        Double(potentialSavingsBytes) / (1024 * 1024)
    }

    var potentialSavingsGB: Double {
        Double(potentialSavingsBytes) / (1024 * 1024 * 1024)
    }

    var formattedSavings: String {
        if potentialSavingsGB >= 1.0 {
            return String(format: "%.2f GB", potentialSavingsGB)
        } else {
            return String(format: "%.0f MB", potentialSavingsMB)
        }
    }
}
