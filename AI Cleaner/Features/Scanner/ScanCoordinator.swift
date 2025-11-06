//
//  ScanCoordinator.swift
//  AI Cleaner
//
//  Coordinator for scanning and analyzing photos
//

import Foundation
import Photos
import CoreData

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

    enum ScanState {
        case idle
        case scanning
        case completed
        case cancelled
        case error(Error)
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

        for i in 0..<totalPhotos {
            let asset = imageAssets.object(at: i)

            // Check cache first
            if let cached = fetchCachedAnalysis(for: asset) {
                assetsWithVectors.append(cached)
            } else {
                // Analyze image
                let analyzed = try await analyzeImage(asset: asset)
                assetsWithVectors.append(analyzed)

                // Cache result
                cacheAnalysis(analyzed)
            }

            updateProgress(
                step: "Analyzing photos...",
                current: i + 1,
                total: totalPhotos
            )

            // Yield periodically
            if i % 10 == 0 {
                try Task.checkCancellation()
                await Task.yield()
            }
        }

        try Task.checkCancellation()

        // Step 3: Find similar groups
        updateProgress(step: "Finding duplicates...", current: 0, total: 100)
        let similarGroups = await similarityService.findSimilarGroups(
            assets: assetsWithVectors,
            configuration: .default
        )

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

        // Extract feature vector
        let featurePrint = try await visionService.extractFeaturePrint(from: image)
        let vector = FeatureVector(from: featurePrint)

        // Detect blur
        let (blurScore, _) = try await blurDetector.detectBlur(in: image)

        // Detect darkness
        let brightnessResult = try await darknessDetector.analyzeBrightness(in: image)

        // Detect screenshot
        let screenshotResult = await screenshotDetector.detectScreenshot(asset: asset)

        // Get file size
        let fileSize = await photoService.getAssetSize(for: asset)

        let metadata = SimilarityService.AssetMetadata(
            blurScore: blurScore,
            brightnessScore: brightnessResult.brightnessScore,
            isScreenshot: screenshotResult.isScreenshot,
            fileSize: fileSize
        )

        return SimilarityService.AssetWithVector(
            asset: asset,
            vector: vector,
            metadata: metadata
        )
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

        let vector = FeatureVector(data: vectorData, elementCount: 128)

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
