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
    @State private var selectedAlbum: AlbumType?

    var body: some View {
        List {
            Section("Categories") {
                if !scanResults.similarGroups.isEmpty {
                    AlbumRow(
                        type: .duplicates,
                        count: scanResults.statistics.totalDuplicates,
                        icon: "square.on.square",
                        color: .blue
                    )
                    .onTapGesture {
                        selectedAlbum = .duplicates
                    }
                }

                if !scanResults.blurryPhotos.isEmpty {
                    AlbumRow(
                        type: .blurry,
                        count: scanResults.blurryPhotos.count,
                        icon: "eye.slash",
                        color: .orange
                    )
                    .onTapGesture {
                        selectedAlbum = .blurry
                    }
                }

                if !scanResults.darkPhotos.isEmpty {
                    AlbumRow(
                        type: .dark,
                        count: scanResults.darkPhotos.count,
                        icon: "moon",
                        color: .purple
                    )
                    .onTapGesture {
                        selectedAlbum = .dark
                    }
                }

                if !scanResults.screenshots.isEmpty {
                    AlbumRow(
                        type: .screenshots,
                        count: scanResults.screenshots.count,
                        icon: "camera.viewfinder",
                        color: .green
                    )
                    .onTapGesture {
                        selectedAlbum = .screenshots
                    }
                }

                if !scanResults.largeVideos.isEmpty {
                    AlbumRow(
                        type: .largeVideos,
                        count: scanResults.largeVideos.count,
                        icon: "video.fill",
                        color: .red
                    )
                    .onTapGesture {
                        selectedAlbum = .largeVideos
                    }
                }

                if !scanResults.similarVideoGroups.isEmpty {
                    AlbumRow(
                        type: .similarVideos,
                        count: scanResults.similarVideoGroups.reduce(0) { $0 + $1.videos.count },
                        icon: "video.badge.plus",
                        color: .pink
                    )
                    .onTapGesture {
                        selectedAlbum = .similarVideos
                    }
                }

                if !scanResults.optimizablePhotos.isEmpty {
                    AlbumRow(
                        type: .optimizable,
                        count: scanResults.optimizablePhotos.count,
                        icon: "arrow.down.circle",
                        color: .cyan
                    )
                    .onTapGesture {
                        selectedAlbum = .optimizable
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
            DuplicatesAlbumView(groups: scanResults.similarGroups)
        case .blurry:
            SimplePhotoListView(
                photos: scanResults.blurryPhotos.map { $0.asset },
                title: "Blurry Photos"
            )
        case .dark:
            SimplePhotoListView(
                photos: scanResults.darkPhotos.map { $0.asset },
                title: "Dark Photos"
            )
        case .screenshots:
            SimplePhotoListView(
                photos: scanResults.screenshots,
                title: "Screenshots"
            )
        case .largeVideos:
            LargeVideosListView(videos: scanResults.largeVideos)
        case .similarVideos:
            SimilarVideosListView(groups: scanResults.similarVideoGroups)
        case .optimizable:
            PhotoOptimizationView(photos: scanResults.optimizablePhotos)
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

    var id: String {
        switch self {
        case .duplicates: return "duplicates"
        case .blurry: return "blurry"
        case .dark: return "dark"
        case .screenshots: return "screenshots"
        case .largeVideos: return "largeVideos"
        case .similarVideos: return "similarVideos"
        case .optimizable: return "optimizable"
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

    var body: some View {
        VStack {
            Button(action: {
                // Navigate to swipe deck
            }) {
                Text("Review All")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
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

    var body: some View {
        List(videos, id: \.asset.localIdentifier) { video in
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
                }

                Text("\(Int(video.resolution.width))×\(Int(video.resolution.height)) @ \(String(format: "%.0f", video.frameRate))fps")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .navigationTitle("Large Videos")
    }
}

// MARK: - Similar Videos List View

struct SimilarVideosListView: View {
    let groups: [VideoAnalyzer.SimilarVideoGroup]
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

    var body: some View {
        List(group.videos, id: \.asset.localIdentifier) { video in
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
                        // TODO: Implement deletion
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
                    // Dismiss
                }
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
            let allResults = await PhotoOptimizer.shared.optimizePhotos(
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
                isOptimizing = false
                showResults = true
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
