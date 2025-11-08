//
//  SmartAlbumsView.swift
//  AI Cleaner
//
//  Smart albums for organizing detected categories
//

import SwiftUI
import Photos

struct SmartAlbumsView: View {
    let scanResults: ScanCoordinator.ScanResults
    @EnvironmentObject var scanCoordinator: ScanCoordinator
    @State private var selectedAlbum: AlbumType?

    // Filter deleted assets from results
    private var filteredSimilarGroups: [SimilarityService.SimilarityGroup] {
        scanResults.similarGroups.compactMap { group -> SimilarityService.SimilarityGroup? in
            let remainingIndices = group.assets.enumerated().compactMap { index, asset in
                scanCoordinator.deletedAssetIds.contains(asset.localIdentifier) ? nil : index
            }
            guard remainingIndices.count > 1 else { return nil } // Need at least 2 photos for similarity

            let remainingAssets = remainingIndices.map { group.assets[$0] }
            let remainingVectors = remainingIndices.map { group.vectors[$0] }
            let remainingMetadata = remainingIndices.map { group.metadata[$0] }

            return SimilarityService.SimilarityGroup(
                id: group.id,
                assets: remainingAssets,
                vectors: remainingVectors,
                averageSimilarity: group.averageSimilarity,
                metadata: remainingMetadata
            )
        }
    }

    private var filteredBlurryPhotos: [(asset: PHAsset, score: Float)] {
        scanResults.blurryPhotos.filter { !scanCoordinator.deletedAssetIds.contains($0.asset.localIdentifier) }
    }

    private var filteredDarkPhotos: [(asset: PHAsset, score: Float)] {
        scanResults.darkPhotos.filter { !scanCoordinator.deletedAssetIds.contains($0.asset.localIdentifier) }
    }

    private var filteredScreenshots: [PHAsset] {
        scanResults.screenshots.filter { !scanCoordinator.deletedAssetIds.contains($0.localIdentifier) }
    }

    private var filteredLargeVideos: [VideoAnalyzer.VideoInfo] {
        scanResults.largeVideos.filter { !scanCoordinator.deletedAssetIds.contains($0.asset.localIdentifier) }
    }

    private var filteredSimilarVideoGroups: [VideoAnalyzer.SimilarVideoGroup] {
        scanResults.similarVideoGroups.compactMap { group -> VideoAnalyzer.SimilarVideoGroup? in
            let remaining = group.videos.filter { !scanCoordinator.deletedAssetIds.contains($0.asset.localIdentifier) }
            guard remaining.count > 1 else { return nil }
            return VideoAnalyzer.SimilarVideoGroup(videos: remaining, similarityReason: group.similarityReason)
        }
    }

    private var filteredOptimizablePhotos: [PhotoOptimizer.OptimizablePhoto] {
        scanResults.optimizablePhotos.filter { !scanCoordinator.deletedAssetIds.contains($0.asset.localIdentifier) }
    }

    private var filteredDocuments: [DocumentDetector.DocumentDetectionResult] {
        scanResults.documents.filter { !scanCoordinator.deletedAssetIds.contains($0.asset.localIdentifier) }
    }

    private var totalDuplicatesCount: Int {
        filteredSimilarGroups.reduce(0) { $0 + $1.assets.count }
    }

    var body: some View {
        List {
            Section("Categories") {
                if !filteredSimilarGroups.isEmpty {
                    AlbumRow(
                        type: .duplicates,
                        count: totalDuplicatesCount,
                        icon: "square.on.square",
                        color: .blue
                    )
                    .onTapGesture {
                        selectedAlbum = .duplicates
                    }
                }

                if !filteredBlurryPhotos.isEmpty {
                    AlbumRow(
                        type: .blurry,
                        count: filteredBlurryPhotos.count,
                        icon: "eye.slash",
                        color: .orange
                    )
                    .onTapGesture {
                        selectedAlbum = .blurry
                    }
                }

                if !filteredDarkPhotos.isEmpty {
                    AlbumRow(
                        type: .dark,
                        count: filteredDarkPhotos.count,
                        icon: "moon",
                        color: .purple
                    )
                    .onTapGesture {
                        selectedAlbum = .dark
                    }
                }

                if !filteredScreenshots.isEmpty {
                    AlbumRow(
                        type: .screenshots,
                        count: filteredScreenshots.count,
                        icon: "camera.viewfinder",
                        color: .green
                    )
                    .onTapGesture {
                        selectedAlbum = .screenshots
                    }
                }

                if !filteredLargeVideos.isEmpty {
                    AlbumRow(
                        type: .largeVideos,
                        count: filteredLargeVideos.count,
                        icon: "video.fill",
                        color: .red
                    )
                    .onTapGesture {
                        selectedAlbum = .largeVideos
                    }
                }

                if !filteredSimilarVideoGroups.isEmpty {
                    AlbumRow(
                        type: .similarVideos,
                        count: filteredSimilarVideoGroups.reduce(0) { $0 + $1.videos.count },
                        icon: "video.badge.plus",
                        color: .pink
                    )
                    .onTapGesture {
                        selectedAlbum = .similarVideos
                    }
                }

                if !filteredOptimizablePhotos.isEmpty {
                    AlbumRow(
                        type: .optimizable,
                        count: filteredOptimizablePhotos.count,
                        icon: "arrow.down.circle",
                        color: .cyan
                    )
                    .onTapGesture {
                        selectedAlbum = .optimizable
                    }
                }

                if !filteredDocuments.isEmpty {
                    AlbumRow(
                        type: .documents,
                        count: filteredDocuments.count,
                        icon: "doc.text",
                        color: .indigo
                    )
                    .onTapGesture {
                        selectedAlbum = .documents
                    }
                }

                if let contactsResults = scanResults.contactsResults,
                   contactsResults.totalDuplicates > 0 {
                    AlbumRow(
                        type: .contacts,
                        count: contactsResults.totalDuplicates,
                        icon: "person.2.fill",
                        color: .brown
                    )
                    .onTapGesture {
                        selectedAlbum = .contacts
                    }
                }

                if let calendarResults = scanResults.calendarResults,
                   calendarResults.totalCleanableEvents > 0 {
                    AlbumRow(
                        type: .calendar,
                        count: calendarResults.totalCleanableEvents,
                        icon: "calendar.badge.clock",
                        color: .teal
                    )
                    .onTapGesture {
                        selectedAlbum = .calendar
                    }
                }
            }
        }
        .navigationTitle("Smart Albums")
        .sheet(item: $selectedAlbum) { albumType in
            NavigationView {
                albumDetailView(for: albumType)
            }
        }
    }

    @ViewBuilder
    private func albumDetailView(for type: AlbumType) -> some View {
        switch type {
        case .duplicates:
            DuplicatesAlbumView(groups: filteredSimilarGroups)
                .environmentObject(scanCoordinator)
        case .blurry:
            SimplePhotoListView(
                photos: filteredBlurryPhotos.map { $0.asset },
                title: "Blurry Photos"
            )
            .environmentObject(scanCoordinator)
        case .dark:
            SimplePhotoListView(
                photos: filteredDarkPhotos.map { $0.asset },
                title: "Dark Photos"
            )
            .environmentObject(scanCoordinator)
        case .screenshots:
            SimplePhotoListView(
                photos: filteredScreenshots,
                title: "Screenshots"
            )
            .environmentObject(scanCoordinator)
        case .largeVideos:
            LargeVideosListView(videos: filteredLargeVideos)
                .environmentObject(scanCoordinator)
        case .similarVideos:
            SimilarVideosListView(groups: filteredSimilarVideoGroups)
                .environmentObject(scanCoordinator)
        case .optimizable:
            PhotoOptimizationView(photos: filteredOptimizablePhotos)
                .environmentObject(scanCoordinator)
        case .documents:
            DocumentsListView(documents: filteredDocuments)
        case .contacts:
            if let contactsResults = scanResults.contactsResults {
                ContactsCleanupView(results: contactsResults)
            } else {
                Text("No contacts data available")
            }
        case .calendar:
            if let calendarResults = scanResults.calendarResults {
                CalendarCleanupView(results: calendarResults)
            } else {
                Text("No calendar data available")
            }
        }
    }
}

// MARK: - Album Types

enum AlbumType: Identifiable {
    case duplicates
    case blurry
    case dark
    case screenshots
    case largeVideos
    case similarVideos
    case optimizable
    case documents
    case contacts
    case calendar

    var id: String {
        switch self {
        case .duplicates: return "duplicates"
        case .blurry: return "blurry"
        case .dark: return "dark"
        case .screenshots: return "screenshots"
        case .largeVideos: return "largeVideos"
        case .similarVideos: return "similarVideos"
        case .optimizable: return "optimizable"
        case .documents: return "documents"
        case .contacts: return "contacts"
        case .calendar: return "calendar"
        }
    }

    var displayName: String {
        switch self {
        case .duplicates: return "Similar Photos"
        case .blurry: return "Blurry Photos"
        case .dark: return "Dark Photos"
        case .screenshots: return "Screenshots"
        case .largeVideos: return "Large Videos"
        case .similarVideos: return "Similar Videos"
        case .optimizable: return "Optimizable Photos"
        case .documents: return "Documents & IDs"
        case .contacts: return "Duplicate Contacts"
        case .calendar: return "Old Events"
        }
    }
}

// MARK: - Album Row

struct AlbumRow: View {
    let type: AlbumType
    let count: Int
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(type.displayName)
                    .font(.headline)
                Text("\(count) items")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Duplicates Album View

struct DuplicatesAlbumView: View {
    let groups: [SimilarityService.SimilarityGroup]
    @EnvironmentObject var scanCoordinator: ScanCoordinator
    @State private var selectedGroup: SimilarityService.SimilarityGroup?

    var body: some View {
        List(groups, id: \.id) { group in
            GroupRow(group: group)
                .onTapGesture {
                    selectedGroup = group
                }
        }
        .navigationTitle("Similar Photos")
        .sheet(item: $selectedGroup) { group in
            NavigationView {
                SwipeDeckView(assets: group.assets, category: "Duplicates")
                    .environmentObject(scanCoordinator)
            }
        }
    }
}

struct GroupRow: View {
    let group: SimilarityService.SimilarityGroup

    var body: some View {
        HStack(spacing: 12) {
            Text("\(group.assets.count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.blue)
                .frame(width: 50)

            VStack(alignment: .leading, spacing: 4) {
                Text("Similar Group")
                    .font(.headline)
                Text("\(group.assets.count) photos")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Simple Photo List View

struct SimplePhotoListView: View {
    let photos: [PHAsset]
    let title: String
    @State private var showingReviewDeck = false
    @EnvironmentObject var scanCoordinator: ScanCoordinator

    var body: some View {
        VStack {
            Button(action: {
                showingReviewDeck = true
            }) {
                HStack {
                    Image(systemName: "hand.thumbsup.fill")
                    Text("Review All")
                }
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [Color(hex: "#0088FF"), Color(hex: "#0066DD")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding()

            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 100))
                ], spacing: 2) {
                    ForEach(photos, id: \.localIdentifier) { asset in
                        PhotoThumbnailView(asset: asset)
                    }
                }
            }
        }
        .navigationTitle(title)
        .sheet(isPresented: $showingReviewDeck) {
            NavigationView {
                SwipeDeckView(assets: photos, category: title)
                    .environmentObject(scanCoordinator)
            }
        }
    }
}

struct PhotoThumbnailView: View {
    let asset: PHAsset
    @State private var image: UIImage?
    @State private var isLoading = true

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if isLoading {
                // Skeleton loading state with shimmer
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))

                    ProgressView()
                        .tint(.gray)
                }
            } else {
                // Failed to load
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))

                    Image(systemName: "photo")
                        .foregroundColor(.gray)
                }
            }
        }
        .frame(width: 100, height: 100)
        .clipped()
        .task {
            await loadThumbnail()
        }
    }

    private func loadThumbnail() async {
        do {
            let thumbnail = try await PhotoLibraryService.shared.loadThumbnail(for: asset)
            await MainActor.run {
                image = thumbnail
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

// MARK: - Large Videos List View

struct LargeVideosListView: View {
    let videos: [VideoAnalyzer.VideoInfo]
    @EnvironmentObject var scanCoordinator: ScanCoordinator
    @State private var deletedVideoIds: Set<String> = []
    @State private var showingDeleteAlert = false
    @State private var videoToDelete: VideoAnalyzer.VideoInfo?

    var availableVideos: [VideoAnalyzer.VideoInfo] {
        videos.filter { !deletedVideoIds.contains($0.asset.localIdentifier) }
    }

    var body: some View {
        List(availableVideos, id: \.asset.localIdentifier) { video in
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "video.fill")
                        .foregroundColor(.red)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(VideoAnalyzer.shared.formatFileSize(video.fileSize))
                            .font(.headline)
                        Text(VideoAnalyzer.shared.formatDuration(video.duration))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Delete button
                    Button(action: {
                        videoToDelete = video
                        showingDeleteAlert = true
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.borderless)
                }

                Text("\(Int(video.resolution.width))×\(Int(video.resolution.height)) @ \(String(format: "%.0f", video.frameRate))fps")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .navigationTitle("Large Videos")
        .alert("Delete Video", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let video = videoToDelete {
                    deleteVideo(video)
                }
            }
        } message: {
            if let video = videoToDelete {
                Text("Delete this large video? (\(VideoAnalyzer.shared.formatFileSize(video.fileSize)))")
            }
        }
        .overlay {
            if availableVideos.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    Text("All large videos deleted!")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private func deleteVideo(_ video: VideoAnalyzer.VideoInfo) {
        Task {
            do {
                print("🗑️ [LargeVideos] Starting video deletion - size: \(video.fileSize)")
                try await PhotoLibraryService.shared.delete(assets: [video.asset])

                await MainActor.run {
                    print("🗑️ [LargeVideos] Video deleted successfully")
                    deletedVideoIds.insert(video.asset.localIdentifier)

                    // Update scan coordinator to track deleted video
                    scanCoordinator.markAssetsAsDeleted([video.asset])

                    // Log activity to CoreData
                    let context = CoreDataStack.shared.viewContext
                    ActivityLog.createDeleteActivity(
                        context: context,
                        count: 1,
                        freedBytes: video.fileSize,
                        category: "Large Videos",
                        timestamp: Date()
                    )
                    CoreDataStack.shared.save(context: context)
                    print("🗑️ [LargeVideos] ActivityLog created and saved")
                }
            } catch {
                print("❌ Failed to delete video: \(error)")
            }
        }
    }
}

// MARK: - Similar Videos List View

struct SimilarVideosListView: View {
    let groups: [VideoAnalyzer.SimilarVideoGroup]
    @EnvironmentObject var scanCoordinator: ScanCoordinator
    @State private var selectedGroup: VideoAnalyzer.SimilarVideoGroup?

    var body: some View {
        List {
            ForEach(groups, id: \.videos.first?.asset.localIdentifier) { group in
                SimilarVideoGroupRow(group: group)
                    .onTapGesture {
                        selectedGroup = group
                    }
            }
        }
        .navigationTitle("Similar Videos")
        .sheet(item: $selectedGroup) { group in
            NavigationView {
                VideoGroupDetailView(group: group)
                    .environmentObject(scanCoordinator)
            }
        }
    }
}

struct SimilarVideoGroupRow: View {
    let group: VideoAnalyzer.SimilarVideoGroup

    var totalSize: Int64 {
        group.videos.reduce(0) { $0 + $1.fileSize }
    }

    var body: some View {
        HStack(spacing: 12) {
            Text("\(group.videos.count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.pink)
                .frame(width: 50)

            VStack(alignment: .leading, spacing: 4) {
                Text("Similar Video Group")
                    .font(.headline)
                Text("\(group.videos.count) videos • \(VideoAnalyzer.shared.formatFileSize(totalSize))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
    }
}

struct VideoGroupDetailView: View {
    let group: VideoAnalyzer.SimilarVideoGroup
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var scanCoordinator: ScanCoordinator
    @State private var deletedVideoIds: Set<String> = []
    @State private var showingDeleteAlert = false
    @State private var videoToDelete: VideoAnalyzer.VideoInfo?

    var availableVideos: [VideoAnalyzer.VideoInfo] {
        group.videos.filter { !deletedVideoIds.contains($0.asset.localIdentifier) }
    }

    var body: some View {
        List(availableVideos, id: \.asset.localIdentifier) { video in
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "video.fill")
                        .foregroundColor(.pink)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(VideoAnalyzer.shared.formatFileSize(video.fileSize))
                            .font(.headline)
                        Text(VideoAnalyzer.shared.formatDuration(video.duration))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Delete button
                    Button(action: {
                        videoToDelete = video
                        showingDeleteAlert = true
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.borderless)
                }

                Text("\(Int(video.resolution.width))×\(Int(video.resolution.height)) @ \(String(format: "%.0f", video.frameRate))fps")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                if let codec = video.codec {
                    Text("Codec: \(codec)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .navigationTitle("Group Details")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .alert("Delete Video", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let video = videoToDelete {
                    deleteVideo(video)
                }
            }
        } message: {
            if let video = videoToDelete {
                Text("Are you sure you want to delete this video? (\(VideoAnalyzer.shared.formatFileSize(video.fileSize)))")
            }
        }
        .overlay {
            if availableVideos.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    Text("All videos deleted!")
                        .font(.headline)
                    Button("Done") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }

    private func deleteVideo(_ video: VideoAnalyzer.VideoInfo) {
        Task {
            do {
                print("🗑️ [VideoGroupDetail] Starting video deletion - size: \(video.fileSize)")
                try await PhotoLibraryService.shared.delete(assets: [video.asset])

                await MainActor.run {
                    print("🗑️ [VideoGroupDetail] Video deleted successfully")
                    deletedVideoIds.insert(video.asset.localIdentifier)

                    // Update scan coordinator to track deleted video
                    scanCoordinator.markAssetsAsDeleted([video.asset])

                    // Log activity to CoreData
                    let context = CoreDataStack.shared.viewContext
                    ActivityLog.createDeleteActivity(
                        context: context,
                        count: 1,
                        freedBytes: video.fileSize,
                        category: "Similar Videos",
                        timestamp: Date()
                    )
                    CoreDataStack.shared.save(context: context)
                    print("🗑️ [VideoGroupDetail] ActivityLog created and saved")

                    // Auto dismiss if all videos are deleted
                    if availableVideos.isEmpty {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            dismiss()
                        }
                    }
                }
            } catch {
                print("❌ Failed to delete video: \(error)")
                // TODO: Show error alert
            }
        }
    }
}

// MARK: - Make SimilarVideoGroup Identifiable

extension VideoAnalyzer.SimilarVideoGroup: Identifiable {
    var id: String {
        videos.first?.asset.localIdentifier ?? UUID().uuidString
    }
}

// MARK: - Photo Optimization View

struct PhotoOptimizationView: View {
    let photos: [PhotoOptimizer.OptimizablePhoto]
    @EnvironmentObject var scanCoordinator: ScanCoordinator
    @State private var isOptimizing = false
    @State private var optimizationProgress: Double = 0
    @State private var currentIndex = 0
    @State private var results: [PhotoOptimizer.OptimizationResult] = []
    @State private var showResults = false
    @State private var deleteOriginals = false

    var totalPotentialSavings: Int64 {
        photos.reduce(0) { $0 + $1.potentialSavings }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with savings info
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.cyan)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Potential Savings")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(PhotoOptimizer.shared.formatFileSize(totalPotentialSavings))
                            .font(.title2)
                            .fontWeight(.bold)
                    }

                    Spacer()

                    Text("\(photos.count)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.cyan)
                }
                .padding()
                .background(Color.cyan.opacity(0.1))
                .cornerRadius(12)

                // Delete originals toggle
                Toggle(isOn: $deleteOriginals) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Delete originals after optimization")
                            .font(.subheadline)
                        Text("Original photos will be moved to Recently Deleted")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .tint(.cyan)

                // Optimize all button
                if !isOptimizing {
                    Button(action: {
                        optimizeAll()
                    }) {
                        HStack {
                            Image(systemName: "wand.and.stars")
                            Text("Optimize All Photos")
                        }
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.cyan)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                } else {
                    VStack(spacing: 8) {
                        ProgressView(value: optimizationProgress)
                            .tint(.cyan)
                        Text("Optimizing \(currentIndex) of \(photos.count)...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()

            // Photo list
            List {
                ForEach(photos, id: \.asset.localIdentifier) { photo in
                    OptimizablePhotoRow(photo: photo)
                }
            }
        }
        .navigationTitle("Optimizable Photos")
        .sheet(isPresented: $showResults) {
            OptimizationResultsView(results: results)
        }
    }

    private func optimizeAll() {
        isOptimizing = true
        optimizationProgress = 0
        currentIndex = 0
        results = []

        Task {
            print("🎨 [PhotoOptimization] Starting optimization - count: \(photos.count), deleteOriginals: \(deleteOriginals)")

            _ = await PhotoOptimizer.shared.optimizePhotos(
                photos: photos,
                configuration: .preset1080p,
                deleteOriginals: deleteOriginals,
                progressHandler: { current, total, result in
                    Task { @MainActor in
                        currentIndex = current
                        optimizationProgress = Double(current) / Double(total)
                        results.append(result)
                    }
                }
            )

            await MainActor.run {
                print("🎨 [PhotoOptimization] Optimization complete")
                isOptimizing = false
                showResults = true

                // Track deleted/optimized assets
                if deleteOriginals {
                    // Original photos were deleted, track them
                    let deletedAssets = photos.map { $0.asset }
                    scanCoordinator.markAssetsAsDeleted(deletedAssets)
                    print("🎨 [PhotoOptimization] Marked \(deletedAssets.count) assets as deleted")
                }

                // Calculate total space saved
                let totalSaved = results.reduce(into: 0) { $0 += $1.savedBytes }
                print("🎨 [PhotoOptimization] Total space saved: \(totalSaved) bytes")

                // Log activity to CoreData
                let context = CoreDataStack.shared.viewContext
                ActivityLog.createOptimizationActivity(
                    context: context,
                    count: photos.count,
                    freedBytes: totalSaved,
                    deletedOriginals: deleteOriginals,
                    timestamp: Date()
                )
                CoreDataStack.shared.save(context: context)
                print("🎨 [PhotoOptimization] ActivityLog created and saved")
            }
        }
    }
}

struct OptimizablePhotoRow: View {
    let photo: PhotoOptimizer.OptimizablePhoto
    @State private var thumbnail: UIImage?

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            Group {
                if let thumbnail = thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    ZStack {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                        ProgressView()
                    }
                }
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text("\(Int(photo.currentResolution.width))×\(Int(photo.currentResolution.height))")
                    .font(.headline)

                Text(PhotoOptimizer.shared.formatFileSize(photo.currentSize))
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 4) {
                    Image(systemName: "arrow.down")
                        .font(.caption2)
                    Text("\(PhotoOptimizer.shared.formatFileSize(photo.potentialSavings)) (\(String(format: "%.0f", photo.savingsPercentage))%)")
                        .font(.caption)
                }
                .foregroundColor(.cyan)
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .task {
            await loadThumbnail()
        }
    }

    private func loadThumbnail() async {
        do {
            let image = try await PhotoLibraryService.shared.loadThumbnail(for: photo.asset)
            await MainActor.run {
                thumbnail = image
            }
        } catch {
            // Failed to load
        }
    }
}

struct OptimizationResultsView: View {
    let results: [PhotoOptimizer.OptimizationResult]
    @Environment(\.dismiss) var dismiss

    var successCount: Int {
        results.filter { $0.success }.count
    }

    var totalSaved: Int64 {
        results.reduce(0) { $0 + $1.savedBytes }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Success summary
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)

                    Text("Optimization Complete!")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Optimized \(successCount) of \(results.count) photos")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("Saved \(PhotoOptimizer.shared.formatFileSize(totalSaved))")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.cyan)
                }
                .padding()

                // Results list
                List {
                    Section("Details") {
                        ForEach(results, id: \.originalAsset.localIdentifier) { result in
                            HStack {
                                Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(result.success ? .green : .red)

                                VStack(alignment: .leading, spacing: 2) {
                                    if result.success {
                                        Text("Saved \(PhotoOptimizer.shared.formatFileSize(result.savedBytes))")
                                            .font(.subheadline)
                                    } else {
                                        Text("Failed")
                                            .font(.subheadline)
                                        if let error = result.error {
                                            Text(error.localizedDescription)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }

                                Spacer()
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Results")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Make OptimizablePhoto Identifiable

extension PhotoOptimizer.OptimizablePhoto: Identifiable {
    var id: String {
        asset.localIdentifier
    }
}

// MARK: - Make SimilarityGroup Identifiable

extension SimilarityService.SimilarityGroup: Identifiable {}

// MARK: - Documents List View

struct DocumentsListView: View {
    let documents: [DocumentDetector.DocumentDetectionResult]
    @State private var selectedType: DocumentDetector.DocumentType?

    var groupedDocuments: [DocumentDetector.DocumentType: [DocumentDetector.DocumentDetectionResult]] {
        DocumentDetector.shared.groupByType(documents)
    }

    var sensitiveCount: Int {
        DocumentDetector.shared.countSensitiveDocuments(documents)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Warning header for sensitive documents
            if sensitiveCount > 0 {
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.shield.fill")
                            .font(.title2)
                            .foregroundColor(.orange)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Sensitive Documents Detected")
                                .font(.headline)
                            Text("\(sensitiveCount) document(s) contain sensitive information")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))

                    Text("Consider moving these to a secure folder or deleting them")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
            }

            // Document types list
            List {
                ForEach(Array(groupedDocuments.keys.sorted { $0.rawValue < $1.rawValue }), id: \.self) { type in
                    let docs = groupedDocuments[type]!

                    DocumentTypeRow(
                        documentType: type,
                        count: docs.count,
                        isSensitive: type.isSensitive
                    )
                    .onTapGesture {
                        selectedType = type
                    }
                }
            }
        }
        .navigationTitle("Documents & IDs")
        .sheet(item: $selectedType) { type in
            NavigationView {
                DocumentTypeDetailView(
                    documentType: type,
                    documents: groupedDocuments[type] ?? []
                )
            }
        }
    }
}

struct DocumentTypeRow: View {
    let documentType: DocumentDetector.DocumentType
    let count: Int
    let isSensitive: Bool

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(isSensitive ? Color.orange.opacity(0.2) : Color.indigo.opacity(0.2))
                    .frame(width: 50, height: 50)

                Image(systemName: documentType.icon)
                    .font(.title3)
                    .foregroundColor(isSensitive ? .orange : .indigo)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(documentType.rawValue)
                        .font(.headline)

                    if isSensitive {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }

                Text("\(count) document\(count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
    }
}

struct DocumentTypeDetailView: View {
    let documentType: DocumentDetector.DocumentType
    let documents: [DocumentDetector.DocumentDetectionResult]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            if documentType.isSensitive {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.orange)

                    Text("Sensitive Information")
                        .font(.headline)

                    Text("These documents may contain personal or financial information. Handle with care.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
            }

            // Documents grid
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 150))
                ], spacing: 16) {
                    ForEach(documents, id: \.asset.localIdentifier) { doc in
                        DocumentCard(document: doc)
                    }
                }
                .padding()
            }
        }
        .navigationTitle(documentType.rawValue)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    // Dismiss
                }
            }
        }
    }
}

struct DocumentCard: View {
    let document: DocumentDetector.DocumentDetectionResult
    @State private var thumbnail: UIImage?

    var body: some View {
        VStack(spacing: 8) {
            // Thumbnail
            Group {
                if let thumbnail = thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    ZStack {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                        ProgressView()
                    }
                }
            }
            .frame(height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: document.documentType.icon)
                        .font(.caption)
                    Text(document.documentType.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(.indigo)

                Text("\(Int(document.confidence * 100))% confident")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                if document.isSensitive {
                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                        Text("Sensitive")
                            .font(.caption2)
                    }
                    .foregroundColor(.orange)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .task {
            await loadThumbnail()
        }
    }

    private func loadThumbnail() async {
        do {
            let image = try await PhotoLibraryService.shared.loadThumbnail(for: document.asset)
            await MainActor.run {
                thumbnail = image
            }
        } catch {
            // Failed to load
        }
    }
}

// MARK: - Make DocumentType Identifiable

extension DocumentDetector.DocumentType: Identifiable {
    public var id: String { rawValue }
}

// MARK: - Preview

#Preview {
    NavigationView {
        SmartAlbumsView(
            scanResults: ScanCoordinator.ScanResults(
                sessionId: UUID(),
                scanDuration: 45.0,
                totalPhotos: 1000,
                totalVideos: 50,
                similarGroups: [],
                blurryPhotos: [],
                darkPhotos: [],
                screenshots: [],
                largeVideos: [],
                similarVideoGroups: [],
                optimizablePhotos: [],
                documents: [],
                contactsResults: nil,
                calendarResults: nil,
                potentialSavingsBytes: 2_500_000_000,
                statistics: CleanupStatistics(
                    totalGroups: 25,
                    totalDuplicates: 150,
                    potentialSavingsBytes: 2_500_000_000,
                    largestGroupSize: 8
                )
            )
        )
    }
}
