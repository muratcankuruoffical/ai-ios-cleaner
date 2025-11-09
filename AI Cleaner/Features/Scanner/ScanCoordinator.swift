//
//  ScanCoordinator.swift
//  AI Cleaner
//
//  Coordinator for scanning and analyzing photos
//

import Foundation
internal import Photos
import CoreData
import UIKit
internal import Combine
internal import EventKit

@MainActor
class ScanCoordinator: ObservableObject {
    // MARK: - Published Properties

    @Published var scanState: ScanState = .idle
    @Published var progress: ScanProgress = ScanProgress()
    @Published var scanResults: ScanResults?
    @Published var deletedAssetIds: Set<String> = [] // Track deleted photos for real-time updates
    @Published var deletedEventIds: Set<String> = [] // Track deleted calendar events
    @Published var deletedContactIds: Set<String> = [] // Track deleted contacts

    // MARK: - Services

    private let photoService = PhotoLibraryService.shared
    private let visionService = VisionService.shared
    private let similarityService = SimilarityService.shared
    private let blurDetector = BlurDetector.shared
    private let darknessDetector = DarknessDetector.shared
    private let screenshotDetector = ScreenshotDetector.shared
    private let videoAnalyzer = VideoAnalyzer.shared
    private let photoOptimizer = PhotoOptimizer.shared
    private let documentDetector = DocumentDetector.shared
    private let contactsCleaner = ContactsCleaner.shared
    private let calendarCleaner = CalendarCleaner.shared
    private let stateManager = ScanStateManager.shared

    // MARK: - State

    private var scanTask: Task<Void, Never>?
    private var sessionId: UUID?
    private var lastProgressUpdate: Date = .distantPast
    private let progressThrottleInterval: TimeInterval = 0.5 // 500ms throttling (reduced from 100ms to prevent UI lag)

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
        var startTime: Date?

        mutating func updateTimeRemaining() {
            guard let startTime = startTime, totalItems > 0, currentItemIndex > 0 else {
                timeRemaining = nil
                return
            }

            let elapsed = Date().timeIntervalSince(startTime)
            let rate = Double(currentItemIndex) / elapsed
            let remaining = Double(totalItems - currentItemIndex) / rate
            timeRemaining = remaining
        }
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
        let similarVideoGroups: [VideoAnalyzer.SimilarVideoGroup]
        let optimizablePhotos: [PhotoOptimizer.OptimizablePhoto]
        let documents: [DocumentDetector.DocumentDetectionResult]
        let contactsResults: ContactsCleaner.ContactsScanResults?
        let calendarResults: CalendarCleaner.CalendarScanResults?

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

        // Total issues found across all categories
        var totalIssuesFound: Int {
            var total = 0

            // Photos issues
            total += statistics.totalDuplicates // All photos in similarity groups
            total += blurryPhotos.count
            total += darkPhotos.count
            total += screenshots.count
            total += optimizablePhotos.count
            total += documents.count

            // Videos issues
            total += largeVideos.count
            total += similarVideoGroups.reduce(0) { $0 + $1.videos.count }

            // Other issues
            if let contactsResults = contactsResults {
                total += contactsResults.totalDuplicates
            }
            if let calendarResults = calendarResults {
                total += calendarResults.totalCleanableEvents
                total += calendarResults.totalCleanableReminders
            }

            return total
        }

        // Total items with issues (photos + videos)
        var totalItemsWithIssues: Int {
            totalPhotos + totalVideos
        }

        // Formatted description for issues
        var issuesDescription: String {
            let photoCount = statistics.totalDuplicates + blurryPhotos.count + darkPhotos.count + screenshots.count + optimizablePhotos.count + documents.count
            let videoCount = largeVideos.count + similarVideoGroups.reduce(0) { $0 + $1.videos.count }
            let contactsCount = contactsResults?.totalDuplicates ?? 0
            let calendarCount = (calendarResults?.totalCleanableEvents ?? 0) + (calendarResults?.totalCleanableReminders ?? 0)

            var parts: [String] = []
            if photoCount > 0 { parts.append("\(photoCount) Photos") }
            if videoCount > 0 { parts.append("\(videoCount) Videos") }
            if contactsCount > 0 { parts.append("\(contactsCount) Contacts") }
            if calendarCount > 0 { parts.append("\(calendarCount) Calendar") }

            if parts.isEmpty {
                return "No issues found"
            } else {
                return parts.joined(separator: " • ")
            }
        }
    }

    // MARK: - Start Scan

    func startScan() {
        guard scanState == .idle || scanState == .completed || scanState == .cancelled else {
            print("⚠️ [ScanCoordinator] Scan already in progress")
            return
        }

        sessionId = UUID()
        scanState = .scanning
        scanResults = nil
        resetDeletedAssets() // Clear deleted assets tracking for new scan

        // Persist scan state
        stateManager.startScan(sessionId: sessionId!)

        let startTime = Date()
        AnalyticsManager.shared.logScanStarted(photoCount: 0)

        scanTask = Task {
            do {
                let results = try await performScan()
                let duration = Date().timeIntervalSince(startTime)

                await MainActor.run {
                    scanResults = results
                    scanState = .completed
                    stateManager.completeScan()

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
                    stateManager.cancelScan()
                }
            } catch {
                await MainActor.run {
                    scanState = .error(error)
                    stateManager.cancelScan()
                    AnalyticsManager.shared.logError(error, context: "scan")
                }
            }
        }
    }

    // MARK: - Restore Scan

    /// Restore scan progress if a scan was running when app was closed
    func restoreScanIfNeeded() {
        guard stateManager.isScanning else { return }

        print("🔄 [ScanCoordinator] Restoring previous scan session...")

        // Restore progress state
        if let sessionId = stateManager.sessionId {
            self.sessionId = sessionId
            self.scanState = .scanning
            self.progress.currentStep = stateManager.currentStep
            self.progress.currentItemIndex = stateManager.currentIndex
            self.progress.totalItems = stateManager.totalItems
            self.progress.percentage = stateManager.percentage

            print("🔄 [ScanCoordinator] Restored scan at \(Int(stateManager.percentage * 100))%")
        }
    }

    // MARK: - Cancel Scan

    func cancelScan() {
        scanTask?.cancel()
        scanState = .cancelled
    }

    /// Mark assets as deleted to update UI counts in real-time
    func markAssetsAsDeleted(_ assets: [PHAsset]) {
        print("🗑️ [ScanCoordinator] Marking \(assets.count) assets as deleted")
        let ids = Set(assets.map { $0.localIdentifier })
        deletedAssetIds.formUnion(ids)
        print("🗑️ [ScanCoordinator] Total deleted assets: \(deletedAssetIds.count)")
    }

    /// Reset deleted assets tracking (e.g., when starting new scan)
    func resetDeletedAssets() {
        print("🔄 [ScanCoordinator] Resetting deleted assets tracking")
        deletedAssetIds.removeAll()
        deletedEventIds.removeAll()
        deletedContactIds.removeAll()
    }

    /// Mark calendar events as deleted to update UI counts in real-time
    func markEventsAsDeleted(_ eventIds: [String]) {
        print("🗑️ [ScanCoordinator] Marking \(eventIds.count) events as deleted")
        deletedEventIds.formUnion(eventIds)
        print("🗑️ [ScanCoordinator] Total deleted events: \(deletedEventIds.count)")
    }

    /// Mark contacts as deleted to update UI counts in real-time
    func markContactsAsDeleted(_ contactIds: [String]) {
        print("🗑️ [ScanCoordinator] Marking \(contactIds.count) contacts as deleted")
        deletedContactIds.formUnion(contactIds)
        print("🗑️ [ScanCoordinator] Total deleted contacts: \(deletedContactIds.count)")
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

        // Step 2: Process images with BATCH PROCESSING for better performance
        updateProgress(step: "Analyzing photos...", current: 0, total: totalPhotos)

        var assetsWithVectors: [SimilarityService.AssetWithVector] = []
        var failedCount = 0
        var failedAssets: [(PHAsset, Error)] = []

        // Process in smaller batches to prevent assetsd connection issues
        // CRITICAL: Smaller batches prevent memory pressure that causes assetsd crashes
        let batchSize = 25 // Reduced from 50 to prevent "Connection to assetsd was interrupted"
        let batches = stride(from: 0, to: totalPhotos, by: batchSize).map { start -> Range<Int> in
            let end = min(start + batchSize, totalPhotos)
            return start..<end
        }

        print("📦 [ScanCoordinator] Processing \(totalPhotos) photos in \(batches.count) batches of ~\(batchSize)")

        for (batchIndex, batchRange) in batches.enumerated() {
            try Task.checkCancellation()

            // Process batch with limited concurrency to reduce memory pressure
            // Using smaller concurrent group prevents assetsd from being overwhelmed
            await withTaskGroup(of: Result<SimilarityService.AssetWithVector?, Error>.self) { group in
                var batchResults: [Result<SimilarityService.AssetWithVector?, Error>] = []

                // Process in micro-batches for better memory management
                for i in batchRange {
                    let asset = imageAssets.object(at: i)

                    group.addTask {
                        // Check cache first (fast path)
                        if let cached = await self.fetchCachedAnalysis(for: asset) {
                            return .success(cached)
                        }

                        // Analyze image (slow path)
                        do {
                            let analyzed = try await self.analyzeImage(asset: asset)
                            // Cache in background
                            await self.cacheAnalysis(analyzed)
                            return .success(analyzed)
                        } catch {
                            return .failure(error)
                        }
                    }
                }

                // Collect batch results
                for await result in group {
                    batchResults.append(result)

                    switch result {
                    case .success(let analyzed):
                        if let analyzed = analyzed {
                            assetsWithVectors.append(analyzed)
                        }
                    case .failure(let error):
                        failedCount += 1
                        AnalyticsManager.shared.logNonFatalError(
                            message: "Failed to analyze image in batch",
                            context: ["error": error.localizedDescription]
                        )
                    }
                }
            }

            // Update progress after each batch
            let processedCount = min((batchIndex + 1) * batchSize, totalPhotos)
            updateProgress(
                step: "Analyzing photos... (\(failedCount) failed)",
                current: processedCount,
                total: totalPhotos
            )

            // Aggressive yielding to prevent memory buildup and assetsd issues
            await Task.yield()

            // Give assetsd time to recover every 10 batches
            if batchIndex % 10 == 0 && batchIndex > 0 {
                try? await Task.sleep(nanoseconds: 100_000_000) // 100ms pause
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

        // Log individual asset analysis results
        print("\n📸 ASSET ANALYSIS DETAILS:")
        for (index, assetVector) in assetsWithVectors.prefix(10).enumerated() {
            let meta = assetVector.metadata
            print("   [\(index)] Blur: \(String(format: "%6.1f", meta.blurScore)) | Bright: \(String(format: "%.2f", meta.brightnessScore)) | SS: \(meta.isScreenshot ? "YES" : "NO ") | Size: \(meta.fileSize/1024)KB")
        }

        try Task.checkCancellation()

        // Step 3: Find similar groups with STRICTER threshold for perceptual hash
        print("\n📊 STEP 3/9: Finding duplicates...")
        updateProgress(step: "Finding duplicates... (Step 3/9)", current: 0, total: 1)

        // Use much stricter threshold for perceptual hash (8x8 = simple comparison)
        let strictConfig = SimilarityService.Configuration(
            similarityThreshold: 0.05,  // Very strict! 0.25 was grouping everything
            minGroupSize: 2,
            useCosineSimilarity: true
        )

        let similarGroups = await similarityService.findSimilarGroups(
            assets: assetsWithVectors,
            configuration: strictConfig,
            progressHandler: { [self] current, total in
                self.updateProgress(step: "Finding duplicates... (Step 3/9)", current: current, total: total)
            }
        )

        // DEBUG: Log similarity results
        print("   Similar groups found: \(similarGroups.count)")
        if !similarGroups.isEmpty {
            print("   Largest group size: \(similarGroups.first!.assets.count)")
        }

        try Task.checkCancellation()

        // Step 4: Filter by quality
        print("\n📊 STEP 4/9: Detecting quality issues...")
        updateProgress(step: "Detecting quality... (Step 4/9)", current: 50, total: 100)

        // DEBUG: Log blur score distribution
        print("\n🔍 BLUR SCORE DISTRIBUTION:")
        let sortedByBlur = assetsWithVectors.sorted { $0.metadata.blurScore < $1.metadata.blurScore }
        print("   Lowest blur score: \(sortedByBlur.first?.metadata.blurScore ?? 0)")
        print("   Highest blur score: \(sortedByBlur.last?.metadata.blurScore ?? 0)")
        print("   Median: \(sortedByBlur[sortedByBlur.count/2].metadata.blurScore)")

        // REVERSED LOGIC: Higher score = more blur (unexpected but observed in data!)
        // User's data shows: blur photos have scores 9000+, sharp photos ~300-7000
        let blurryPhotos = assetsWithVectors
            .filter { $0.metadata.blurScore > 5000.0 }  // REVERSED! High = blur
            .map { ($0.asset, $0.metadata.blurScore) }
            .sorted { $0.1 > $1.1 }  // Sort descending (highest blur first)

        let darkPhotos = assetsWithVectors
            .filter { $0.metadata.brightnessScore < 0.3 }
            .map { ($0.asset, $0.metadata.brightnessScore) }
            .sorted { $0.1 < $1.1 }

        let screenshots = assetsWithVectors
            .filter { $0.metadata.isScreenshot }
            .map { $0.asset }

        try Task.checkCancellation()

        // Step 5: Analyze videos
        print("\n📊 STEP 5/9: Analyzing videos...")
        updateProgress(step: "Analyzing videos... (Step 5/9)", current: 0, total: totalVideos)

        var videoAssetArray: [PHAsset] = []
        for i in 0..<totalVideos {
            videoAssetArray.append(videoAssets.object(at: i))
        }

        let largeVideos = await videoAnalyzer.findLargeVideos(
            assets: videoAssetArray,
            thresholdMB: 200,
            progressHandler: { [self] current, total in
                self.updateProgress(step: "Finding large videos...", current: current, total: total)
            }
        )

        try Task.checkCancellation()

        // Step 5b: Find similar videos
        print("\n📊 STEP 6/9: Finding similar videos...")
        updateProgress(step: "Similar videos... (Step 6/9)", current: 0, total: totalVideos)

        let similarVideoGroups = await videoAnalyzer.findSimilarVideos(
            assets: videoAssetArray,
            durationThreshold: 2.0,
            progressHandler: { [self] current, total in
                self.updateProgress(step: "Finding similar videos...", current: current, total: total)
            }
        )

        try Task.checkCancellation()

        // Step 5c: Find optimizable photos (4K → 1080p)
        print("\n📊 STEP 7/9: Finding optimizable photos...")
        updateProgress(step: "Optimizable photos... (Step 7/9)", current: 0, total: totalPhotos)

        let imageAssetArray = assetsWithVectors.map { $0.asset }
        let optimizablePhotos = await photoOptimizer.findOptimizablePhotos(
            assets: imageAssetArray,
            configuration: .preset1080p,
            progressHandler: { [self] current, total in
                self.updateProgress(step: "Finding optimizable photos...", current: current, total: total)
            }
        )

        // DEBUG: Log optimization opportunities
        print("\n💾 OPTIMIZATION OPPORTUNITIES:")
        print("   Found \(optimizablePhotos.count) photos that can be optimized")
        if let firstPhoto = optimizablePhotos.first {
            print("   Best saving: \(photoOptimizer.formatFileSize(firstPhoto.potentialSavings))")
        }

        try Task.checkCancellation()

        // Step 5d: Detect documents (ID cards, invoices, etc.)
        print("\n📊 STEP 8/9: Detecting documents...")
        updateProgress(step: "Detecting documents... (Step 8/9)", current: 0, total: totalPhotos)

        let documents = await documentDetector.detectDocuments(
            in: imageAssetArray,
            progressHandler: { [self] current, total in
                self.updateProgress(step: "Detecting documents...", current: current, total: total)
            }
        )

        // DEBUG: Log document detection results
        print("\n📄 DOCUMENT DETECTION:")
        print("   Found \(documents.count) documents")
        let sensitiveCount = documentDetector.countSensitiveDocuments(documents)
        print("   Sensitive documents: \(sensitiveCount)")
        if let firstDoc = documents.first {
            print("   Top match: \(firstDoc.documentType.rawValue) (confidence: \(String(format: "%.2f", firstDoc.confidence)))")
        }

        try Task.checkCancellation()

        // Step 5e: Scan contacts (optional - only if authorized)
        var contactsResults: ContactsCleaner.ContactsScanResults? = nil
        if contactsCleaner.checkAuthorizationStatus() == .authorized {
            updateProgress(step: "Scanning contacts...", current: 0, total: 100)

            contactsResults = await contactsCleaner.scanContacts { [self] current, total in
                self.updateProgress(step: "Scanning contacts...", current: current, total: total)
            }

            print("\n📇 CONTACTS SCAN:")
            print("   Duplicate groups: \(contactsResults?.duplicateGroups.count ?? 0)")
            print("   Total duplicates: \(contactsResults?.totalDuplicates ?? 0)")
        } else {
            print("\n📇 CONTACTS: Skipped (not authorized)")
        }

        try Task.checkCancellation()

        // Step 5f: Scan calendar (optional - only if authorized)
        var calendarResults: CalendarCleaner.CalendarScanResults? = nil
        if calendarCleaner.checkAuthorizationStatus(for: .event) == .authorized {
            updateProgress(step: "Scanning calendar...", current: 0, total: 100)

            calendarResults = await calendarCleaner.scanCalendar { [self] current, total in
                self.updateProgress(step: "Scanning calendar...", current: current, total: total)
            }

            print("\n📅 CALENDAR SCAN:")
            print("   Past events: \(calendarResults?.pastEvents.count ?? 0)")
            print("   Duplicate groups: \(calendarResults?.duplicateGroups.count ?? 0)")
            print("   Completed reminders: \(calendarResults?.completedReminders.count ?? 0)")
        } else {
            print("\n📅 CALENDAR: Skipped (not authorized)")
        }

        try Task.checkCancellation()

        // Step 6: Calculate statistics
        print("\n📊 STEP 9/9: Finalizing results...")
        updateProgress(step: "Finalizing... (Step 9/9)", current: 99, total: 100)

        let statistics = similarityService.calculateStatistics(groups: similarGroups)

        // Calculate total potential savings
        var totalSavings = statistics.potentialSavingsBytes
        print("\n💾 POTENTIAL SAVINGS CALCULATION:")
        print("   📸 Duplicate Photos: \(formatBytes(statistics.potentialSavingsBytes))")

        // Add large video savings
        var largeVideoSavings: Int64 = 0
        for video in largeVideos {
            largeVideoSavings += video.fileSize
        }
        totalSavings += largeVideoSavings
        print("   🎬 Large Videos: \(formatBytes(largeVideoSavings)) (\(largeVideos.count) videos)")

        // Add similar video savings (keep smallest, delete duplicates)
        var similarVideoSavings: Int64 = 0
        for group in similarVideoGroups {
            // Sort by size and calculate savings (all except the smallest)
            let sortedVideos = group.videos.sorted { $0.fileSize < $1.fileSize }
            let savingsFromGroup = sortedVideos.dropFirst().reduce(Int64(0)) { $0 + $1.fileSize }
            similarVideoSavings += savingsFromGroup
        }
        totalSavings += similarVideoSavings
        print("   🎥 Similar Videos: \(formatBytes(similarVideoSavings)) (\(similarVideoGroups.count) groups)")

        // Add optimization savings
        let optimizationSavings = photoOptimizer.calculateTotalSavings(photos: optimizablePhotos)
        totalSavings += optimizationSavings
        print("   📉 Optimizable Photos: \(formatBytes(optimizationSavings)) (\(optimizablePhotos.count) photos)")

        // Add contacts savings
        var contactsSavings: Int64 = 0
        if let contactsResults = contactsResults {
            for group in contactsResults.duplicateGroups {
                contactsSavings += contactsCleaner.estimateTotalSize(group.duplicates)
            }
            totalSavings += contactsSavings
            print("   📇 Duplicate Contacts: \(formatBytes(contactsSavings)) (\(contactsResults.totalDuplicates) contacts)")
        }

        // Add calendar savings
        var calendarSavings: Int64 = 0
        if let calendarResults = calendarResults {
            calendarSavings += calendarCleaner.estimateTotalEventSize(calendarResults.pastEvents)
            calendarSavings += calendarCleaner.estimateTotalEventSize(calendarResults.declinedEvents)
            calendarSavings += calendarCleaner.estimateTotalReminderSize(calendarResults.completedReminders)
            totalSavings += calendarSavings
            print("   📅 Calendar Items: \(formatBytes(calendarSavings)) (\(calendarResults.totalCleanableEvents + calendarResults.totalCleanableReminders) items)")
        }

        print("   ✨ TOTAL POTENTIAL SAVINGS: \(formatBytes(totalSavings))")

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
            similarVideoGroups: similarVideoGroups,
            optimizablePhotos: optimizablePhotos,
            documents: documents,
            contactsResults: contactsResults,
            calendarResults: calendarResults,
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

    private func fetchCachedAnalysis(for asset: PHAsset) async -> SimilarityService.AssetWithVector? {
        await Task.detached(priority: .userInitiated) {
            let context = await CoreDataStack.shared.newBackgroundContext()

            return await context.perform {
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
        }.value
    }

    private func cacheAnalysis(_ result: SimilarityService.AssetWithVector) async {
        await Task.detached(priority: .background) {
            let context = await CoreDataStack.shared.newBackgroundContext()

            await context.perform {
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
        }.value
    }

    // MARK: - Progress Updates

    private func updateProgress(step: String, current: Int, total: Int) {
        // Throttle progress updates to avoid UI lag
        let now = Date()
        let shouldUpdate = now.timeIntervalSince(lastProgressUpdate) >= progressThrottleInterval

        if shouldUpdate || current == 0 || current == total {
            lastProgressUpdate = now

            // Set start time on first progress update for this step
            if progress.currentStep != step || current == 0 {
                progress.startTime = now
            }

            progress.currentStep = step
            progress.currentItemIndex = current
            progress.totalItems = total
            progress.percentage = total > 0 ? Double(current) / Double(total) : 0
            progress.updateTimeRemaining()

            // Persist to state manager (with its own throttling)
            stateManager.updateProgress(step: step, current: current, total: total)
        }
    }

    // MARK: - Helper Methods

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        return formatter.string(fromByteCount: bytes)
    }

    // MARK: - Session Management

    private func saveScanSession(results: ScanResults, duration: TimeInterval) {
        print("💾 [ScanCoordinator] Saving scan session - photos: \(results.totalPhotos)")
        let context = CoreDataStack.shared.newBackgroundContext()

        context.perform {
            // Save scan session
            let session = ScanSession(context: context)
            session.id = results.sessionId
            session.startedAt = Date().addingTimeInterval(-duration)
            session.finishedAt = Date()
            session.processedCount = Int32(results.totalPhotos)
            session.deletedCount = 0
            session.freedBytes = 0
            print("💾 [ScanCoordinator] ScanSession created")

            // Create activity log for scan completion
            ActivityLog.createScanActivity(
                context: context,
                photoCount: results.totalPhotos,
                timestamp: Date()
            )

            print("💾 [ScanCoordinator] Saving context...")
            CoreDataStack.shared.save(context: context)
            print("💾 [ScanCoordinator] Context saved successfully")
        }
    }
}
