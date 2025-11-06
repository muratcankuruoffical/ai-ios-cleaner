//
//  ScanCoordinator.swift
//  AI Cleaner
//
//  Coordinator for scanning and analyzing photos
//

import Foundation
import Photos
import CoreData
import UIKit
internal import Combine

@MainActor
class ScanCoordinator: ObservableObject {
    // MARK: - Published Properties

    @Published var scanState: ScanState = .idle
    @Published var progress: ScanProgress = ScanProgress()
    @Published var scanResults: ScanResults?

    // MARK: - Services

    private let photoService = PhotoLibraryService.shared
    private let visionService = VisionService.shared
    private let similarityService = SimilarityService.shared
    private let blurDetector = BlurDetector.shared
    private let darknessDetector = DarknessDetector.shared
    private let screenshotDetector = ScreenshotDetector.shared
    private let videoAnalyzer = VideoAnalyzer.shared

    // MARK: - State

    private var scanTask: Task<Void, Never>?
    private var sessionId: UUID?

    // MARK: - Scan State

    enum ScanState: Equatable {
        case idle
        case scanning
        case completed
        case cancelled
        case error(Error)

        static func == (lhs: ScanState, rhs: ScanState) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle): return true
            case (.scanning, .scanning): return true
            case (.completed, .completed): return true
            case (.cancelled, .cancelled): return true
            case (.error(let lhsError), .error(let rhsError)):
                return lhsError.localizedDescription == rhsError.localizedDescription
            default: return false
            }
        }
    }

    // MARK: - Scan Progress

    struct ScanProgress {
        var currentStep: String = ""
        var currentItemIndex: Int = 0
        var totalItems: Int = 0
        var percentage: Double = 0.0
        var timeRemaining: TimeInterval?
    }

    // MARK: - Scan Results

    struct ScanResults {
        let sessionId: UUID
        let scanDuration: TimeInterval
        let totalPhotos: Int
        let totalVideos: Int

        // Analysis results
        let similarGroups: [SimilarityService.SimilarityGroup]
        let blurryPhotos: [(asset: PHAsset, score: Float)]
        let darkPhotos: [(asset: PHAsset, score: Float)]
        let screenshots: [PHAsset]
        let largeVideos: [VideoAnalyzer.VideoInfo]

        // Statistics
        let potentialSavingsBytes: Int64
        let statistics: CleanupStatistics

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

    // MARK: - Start Scan

    func startScan() {
        guard scanState == .idle || scanState == .completed || scanState == .cancelled else {
            return
        }

        sessionId = UUID()
        scanState = .scanning
        scanResults = nil

        let startTime = Date()
        AnalyticsManager.shared.logScanStarted(photoCount: 0)

        scanTask = Task {
            do {
                let results = try await performScan()
                let duration = Date().timeIntervalSince(startTime)

                await MainActor.run {
                    scanResults = results
                    scanState = .completed

                    AnalyticsManager.shared.logScanCompleted(
                        photoCount: results.totalPhotos,
                        duration: duration,
                        duplicatesFound: results.similarGroups.count,
                        blurryFound: results.blurryPhotos.count,
                        screenshotsFound: results.screenshots.count
                    )

                    // Save scan session
                    saveScanSession(results: results, duration: duration)
                }
            } catch is CancellationError {
                await MainActor.run {
                    scanState = .cancelled
                }
            } catch {
                await MainActor.run {
                    scanState = .error(error)
                    AnalyticsManager.shared.logError(error, context: "scan")
                }
            }
        }
    }

    // MARK: - Cancel Scan

    func cancelScan() {
        scanTask?.cancel()
        scanState = .cancelled
    }

    // MARK: - Main Scan Logic

    private func performScan() async throws -> ScanResults {
        let startTime = Date()

        // Step 1: Fetch all assets
        updateProgress(step: "Fetching photos...", current: 0, total: 100)
        let imageAssets = photoService.fetchAllImages()
        let videoAssets = photoService.fetchAllVideos()

        let totalPhotos = imageAssets.count
        let totalVideos = videoAssets.count

        try Task.checkCancellation()

        // Step 2: Process images
        updateProgress(step: "Analyzing photos...", current: 0, total: totalPhotos)

        var assetsWithVectors: [SimilarityService.AssetWithVector] = []
        var failedCount = 0
        var failedAssets: [(PHAsset, Error)] = []

        for i in 0..<totalPhotos {
            let asset = imageAssets.object(at: i)

            // Check cache first
            if let cached = fetchCachedAnalysis(for: asset) {
                assetsWithVectors.append(cached)
            } else {
                // Analyze image with error recovery
                do {
                    let analyzed = try await analyzeImage(asset: asset)
                    assetsWithVectors.append(analyzed)

                    // Cache result
                    cacheAnalysis(analyzed)
                } catch {
                    // Log error but continue with next image
                    failedCount += 1
                    failedAssets.append((asset, error))
                    AnalyticsManager.shared.logNonFatalError(
                        message: "Failed to analyze image",
                        context: [
                            "asset_id": asset.localIdentifier,
                            "error": error.localizedDescription,
                            "index": i
                        ]
                    )

                    // Continue processing other images
                }
            }

            updateProgress(
                step: "Analyzing photos... (\(failedCount) failed)",
                current: i + 1,
                total: totalPhotos
            )

            // Yield periodically
            if i % 10 == 0 {
                try Task.checkCancellation()
                await Task.yield()
            }
        }

        // Log summary of failures
        if failedCount > 0 {
            AnalyticsManager.shared.logEvent("scan_partial_failure", parameters: [
                "failed_count": failedCount,
                "total_count": totalPhotos,
                "success_rate": Double(totalPhotos - failedCount) / Double(totalPhotos)
            ])
        }

        // DEBUG: Log analysis results
        print("📊 SCAN DEBUG:")
        print("   Total photos: \(totalPhotos)")
        print("   Successfully analyzed: \(assetsWithVectors.count)")
        print("   Failed: \(failedCount)")
        if !failedAssets.isEmpty {
            print("   First failure: \(failedAssets.first!.1.localizedDescription)")
        }

        try Task.checkCancellation()

        // Step 3: Find similar groups
        updateProgress(step: "Finding duplicates...", current: 0, total: 100)
        let similarGroups = await similarityService.findSimilarGroups(
            assets: assetsWithVectors,
            configuration: .relaxed  // Use relaxed threshold for better detection
        )

        // DEBUG: Log similarity results
        print("   Similar groups found: \(similarGroups.count)")
        if !similarGroups.isEmpty {
            print("   Largest group size: \(similarGroups.first!.assets.count)")
        }

        try Task.checkCancellation()

        // Step 4: Filter by quality
        updateProgress(step: "Detecting quality issues...", current: 0, total: 100)

        let blurryPhotos = assetsWithVectors
            .filter { $0.metadata.blurScore < 100.0 }
            .map { ($0.asset, $0.metadata.blurScore) }
            .sorted { $0.1 < $1.1 }

        let darkPhotos = assetsWithVectors
            .filter { $0.metadata.brightnessScore < 0.3 }
            .map { ($0.asset, $0.metadata.brightnessScore) }
            .sorted { $0.1 < $1.1 }

        let screenshots = assetsWithVectors
            .filter { $0.metadata.isScreenshot }
            .map { $0.asset }

        try Task.checkCancellation()

        // Step 5: Analyze videos
        updateProgress(step: "Analyzing videos...", current: 0, total: totalVideos)

        var videoAssetArray: [PHAsset] = []
        for i in 0..<totalVideos {
            videoAssetArray.append(videoAssets.object(at: i))
        }

        let largeVideos = await videoAnalyzer.findLargeVideos(
            assets: videoAssetArray,
            thresholdMB: 200
        )

        try Task.checkCancellation()

        // Step 6: Calculate statistics
        updateProgress(step: "Calculating savings...", current: 99, total: 100)

        let statistics = similarityService.calculateStatistics(groups: similarGroups)

        // Calculate total potential savings
        var totalSavings = statistics.potentialSavingsBytes

        // Add video savings
        for video in largeVideos {
            totalSavings += video.fileSize
        }

        let duration = Date().timeIntervalSince(startTime)

        return ScanResults(
            sessionId: sessionId!,
            scanDuration: duration,
            totalPhotos: totalPhotos,
            totalVideos: totalVideos,
            similarGroups: similarGroups,
            blurryPhotos: blurryPhotos,
            darkPhotos: darkPhotos,
            screenshots: screenshots,
            largeVideos: largeVideos,
            potentialSavingsBytes: totalSavings,
            statistics: statistics
        )
    }

    // MARK: - Image Analysis

    private func analyzeImage(asset: PHAsset) async throws -> SimilarityService.AssetWithVector {
        // Load image for analysis
        let image = try await photoService.loadAnalysisImage(for: asset)

        // Extract feature vector with fallback
        let vector: FeatureVector
        var usingFallback = false
        do {
            let featurePrint = try await visionService.extractFeaturePrint(from: image)
            vector = FeatureVector(from: featurePrint)
        } catch {
            // FALLBACK: Use simple perceptual hash when Vision fails
            print("⚠️ Vision failed for asset \(asset.localIdentifier), using fallback hash")
            vector = try generateFallbackHash(from: image)
            usingFallback = true
        }

        // Detect blur (with fallback)
        let blurScore: Float
        do {
            let (score, _) = try await blurDetector.detectBlur(in: image)
            blurScore = score
        } catch let error {
            print("⚠️ Blur detection failed: \(error.localizedDescription)")
            blurScore = 100.0 // Assume acceptable quality if detection fails
        }

        // Detect darkness (with fallback)
        let brightnessScore: Float
        do {
            let brightnessResult = try await darknessDetector.analyzeBrightness(in: image)
            brightnessScore = brightnessResult.brightnessScore
        } catch let error {
            print("⚠️ Brightness detection failed: \(error.localizedDescription)")
            brightnessScore = 0.5 // Assume medium brightness if detection fails
        }

        // Detect screenshot
        let screenshotResult = await screenshotDetector.detectScreenshot(asset: asset)

        // Get file size
        let fileSize = await photoService.getAssetSize(for: asset)

        let metadata = SimilarityService.AssetMetadata(
            blurScore: blurScore,
            brightnessScore: brightnessScore,
            isScreenshot: screenshotResult.isScreenshot,
            fileSize: fileSize
        )

        // DEBUG: Log analysis results for this asset
        print("   📷 Asset \(asset.localIdentifier.prefix(8)):")
        print("      Blur: \(String(format: "%.1f", blurScore)) | Brightness: \(String(format: "%.2f", brightnessScore)) | Screenshot: \(screenshotResult.isScreenshot) | Size: \(fileSize/1024)KB")
        print("      Using fallback hash: \(usingFallback)")

        return SimilarityService.AssetWithVector(
            asset: asset,
            vector: vector,
            metadata: metadata
        )
    }

    // MARK: - Fallback Hash Generation

    private func generateFallbackHash(from image: UIImage) throws -> FeatureVector {
        // Generate a simple perceptual hash as fallback when Vision fails
        // This is less accurate but works without Neural Engine

        guard let cgImage = image.cgImage else {
            throw VisionError.invalidImage
        }

        // Resize to 8x8 for perceptual hash
        let size = CGSize(width: 8, height: 8)
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)

        guard let context = CGContext(
            data: nil,
            width: 8,
            height: 8,
            bitsPerComponent: 8,
            bytesPerRow: 8,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            throw VisionError.featureExtractionFailed
        }

        context.interpolationQuality = .high
        context.draw(cgImage, in: CGRect(origin: .zero, size: size))

        guard let data = context.data else {
            throw VisionError.featureExtractionFailed
        }

        // Extract 64 bytes (8x8 grayscale pixels)
        let bytes = data.assumingMemoryBound(to: UInt8.self)
        var hashData = Data(count: 64)
        for i in 0..<64 {
            hashData[i] = bytes[i]
        }

        // Convert to float array for compatibility
        let floatArray = hashData.map { Float($0) / 255.0 }
        let vectorData = FeatureVector.fromFloatArray(floatArray)

        return FeatureVector(data: vectorData, elementCount: 64)
    }

    // MARK: - Caching

    private func fetchCachedAnalysis(for asset: PHAsset) -> SimilarityService.AssetWithVector? {
        let context = CoreDataStack.shared.viewContext
        let fetchRequest: NSFetchRequest<AssetFingerprint> = AssetFingerprint.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "assetLocalId == %@", asset.localIdentifier)
        fetchRequest.fetchLimit = 1

        guard let cached = try? context.fetch(fetchRequest).first,
              let vectorData = cached.vectorData else {
            return nil
        }

        // Use actual stored elementCount, not hardcoded value
        let elementCount = Int(cached.vectorElementCount)
        guard elementCount > 0 else {
            // Invalid cache entry, return nil to force re-analysis
            return nil
        }

        let vector = FeatureVector(data: vectorData, elementCount: elementCount)

        let metadata = SimilarityService.AssetMetadata(
            blurScore: cached.blurScore,
            brightnessScore: cached.brightnessScore,
            isScreenshot: cached.isScreenshot,
            fileSize: 0
        )

        return SimilarityService.AssetWithVector(
            asset: asset,
            vector: vector,
            metadata: metadata
        )
    }

    private func cacheAnalysis(_ result: SimilarityService.AssetWithVector) {
        let context = CoreDataStack.shared.newBackgroundContext()

        context.perform {
            let fingerprint = AssetFingerprint(context: context)
            fingerprint.id = UUID()
            fingerprint.assetLocalId = result.asset.localIdentifier
            fingerprint.vectorData = result.vector.data
            fingerprint.vectorElementCount = Int32(result.vector.elementCount) // Store actual count!
            fingerprint.blurScore = result.metadata.blurScore
            fingerprint.brightnessScore = result.metadata.brightnessScore
            fingerprint.isScreenshot = result.metadata.isScreenshot
            fingerprint.updatedAt = Date()

            CoreDataStack.shared.save(context: context)
        }
    }

    // MARK: - Progress Updates

    private func updateProgress(step: String, current: Int, total: Int) {
        progress.currentStep = step
        progress.currentItemIndex = current
        progress.totalItems = total
        progress.percentage = total > 0 ? Double(current) / Double(total) : 0
    }

    // MARK: - Session Management

    private func saveScanSession(results: ScanResults, duration: TimeInterval) {
        let context = CoreDataStack.shared.newBackgroundContext()

        context.perform {
            let session = ScanSession(context: context)
            session.id = results.sessionId
            session.startedAt = Date().addingTimeInterval(-duration)
            session.finishedAt = Date()
            session.processedCount = Int32(results.totalPhotos)
            session.deletedCount = 0
            session.freedBytes = 0

            CoreDataStack.shared.save(context: context)
        }
    }
}
