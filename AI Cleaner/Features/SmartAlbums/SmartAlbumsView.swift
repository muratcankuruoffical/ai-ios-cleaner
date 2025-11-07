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
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            CleanerTheme.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header
                    headerView
                        .fadeIn(delay: 0.1)

                    // Albums Grid
                    albumsGrid
                        .fadeIn(delay: 0.2)
                }
                .padding()
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Smart Albums")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(CleanerTheme.textPrimary)
            }
        }
        .sheet(item: $selectedAlbum) { albumType in
            NavigationView {
                albumDetailView(for: albumType)
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Categories Found")
                        .cleanerFont(.title2)
                        .foregroundColor(CleanerTheme.textPrimary)

                    Text("\(totalItemsCount) items to review")
                        .cleanerFont(.subheadline)
                        .foregroundColor(CleanerTheme.textSecondary)
                }

                Spacer()
            }
        }
        .padding(20)
        .cleanerCard()
    }

    // MARK: - Albums Grid

    private var albumsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            if !scanResults.similarGroups.isEmpty {
                AlbumCard(
                    type: .duplicates,
                    count: scanResults.statistics.totalDuplicates,
                    icon: "square.on.square",
                    color: CleanerTheme.primary
                )
                .onTapGesture {
                    selectedAlbum = .duplicates
                }
                .scaleIn(delay: 0.1)
            }

            if !scanResults.blurryPhotos.isEmpty {
                AlbumCard(
                    type: .blurry,
                    count: scanResults.blurryPhotos.count,
                    icon: "eye.slash",
                    color: CleanerTheme.accent
                )
                .onTapGesture {
                    selectedAlbum = .blurry
                }
                .scaleIn(delay: 0.2)
            }

            if !scanResults.darkPhotos.isEmpty {
                AlbumCard(
                    type: .dark,
                    count: scanResults.darkPhotos.count,
                    icon: "moon",
                    color: CleanerTheme.accentGreen
                )
                .onTapGesture {
                    selectedAlbum = .dark
                }
                .scaleIn(delay: 0.3)
            }

            if !scanResults.screenshots.isEmpty {
                AlbumCard(
                    type: .screenshots,
                    count: scanResults.screenshots.count,
                    icon: "camera.viewfinder",
                    color: CleanerTheme.accentRed
                )
                .onTapGesture {
                    selectedAlbum = .screenshots
                }
                .scaleIn(delay: 0.4)
            }

            if !scanResults.largeVideos.isEmpty {
                AlbumCard(
                    type: .largeVideos,
                    count: scanResults.largeVideos.count,
                    icon: "video.fill",
                    color: CleanerTheme.primary
                )
                .onTapGesture {
                    selectedAlbum = .largeVideos
                }
                .scaleIn(delay: 0.5)
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
        }
    }

    private var totalItemsCount: Int {
        scanResults.statistics.totalDuplicates +
        scanResults.blurryPhotos.count +
        scanResults.darkPhotos.count +
        scanResults.screenshots.count +
        scanResults.largeVideos.count
    }
}

// MARK: - Album Types

enum AlbumType: Identifiable {
    case duplicates
    case blurry
    case dark
    case screenshots
    case largeVideos

    var id: String {
        switch self {
        case .duplicates: return "duplicates"
        case .blurry: return "blurry"
        case .dark: return "dark"
        case .screenshots: return "screenshots"
        case .largeVideos: return "largeVideos"
        }
    }

    var displayName: String {
        switch self {
        case .duplicates: return "Similar Photos"
        case .blurry: return "Blurry Photos"
        case .dark: return "Dark Photos"
        case .screenshots: return "Screenshots"
        case .largeVideos: return "Large Videos"
        }
    }
}

// MARK: - Album Card

struct AlbumCard: View {
    let type: AlbumType
    let count: Int
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 20) {
            // Icon with gradient background
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 70, height: 70)
                    .blur(radius: 20)

                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 64, height: 64)

                Image(systemName: icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(CleanerTheme.iconGray)
            }

            // Count and Title
            VStack(spacing: 6) {
                Text("\(count)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(CleanerTheme.textPrimary)

                Text(type.displayName)
                    .cleanerFont(.callout)
                    .foregroundColor(CleanerTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 16)
        .background(CleanerTheme.cardBackground)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Duplicates Album View

struct DuplicatesAlbumView: View {
    let groups: [SimilarityService.SimilarityGroup]
    @State private var selectedGroup: SimilarityService.SimilarityGroup?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            CleanerTheme.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 16) {
                    ForEach(Array(groups.enumerated()), id: \.element.id) { index, group in
                        GroupCard(group: group)
                            .onTapGesture {
                                selectedGroup = group
                            }
                            .scaleIn(delay: Double(index) * 0.05)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Similar Photos")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Similar Photos")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(CleanerTheme.textPrimary)
            }
        }
        .sheet(item: $selectedGroup) { group in
            NavigationView {
                SwipeDeckView(assets: group.assets, category: "Duplicates")
            }
        }
    }
}

struct GroupCard: View {
    let group: SimilarityService.SimilarityGroup

    var body: some View {
        HStack(spacing: 16) {
            // Count Badge
            ZStack {
                Circle()
                    .fill(CleanerTheme.primary.opacity(0.15))
                    .frame(width: 56, height: 56)

                Text("\(group.assets.count)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(CleanerTheme.primary)
            }

            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text("Similar Group")
                    .cleanerFont(.headline)
                    .foregroundColor(CleanerTheme.textPrimary)

                Text("\(group.assets.count) similar photos")
                    .cleanerFont(.caption)
                    .foregroundColor(CleanerTheme.textSecondary)
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(CleanerTheme.iconGray)
        }
        .padding(20)
        .background(CleanerTheme.cardBackground)
        .cornerRadius(16)
    }
}

// MARK: - Simple Photo List View

struct SimplePhotoListView: View {
    let photos: [PHAsset]
    let title: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            CleanerTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Review Button
                Button(action: {
                    // Navigate to swipe deck
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "hand.tap")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Review All")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(CleanerTheme.primaryGradient)
                    .cornerRadius(16)
                }
                .padding()

                // Photo Grid
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 100), spacing: 2)
                    ], spacing: 2) {
                        ForEach(photos, id: \.localIdentifier) { asset in
                            PhotoThumbnailView(asset: asset)
                        }
                    }
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(CleanerTheme.textPrimary)
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
                ZStack {
                    Rectangle()
                        .fill(CleanerTheme.surface)

                    ProgressView()
                        .tint(CleanerTheme.iconGray)
                }
            } else {
                ZStack {
                    Rectangle()
                        .fill(CleanerTheme.surface)

                    Image(systemName: "photo")
                        .foregroundColor(CleanerTheme.iconGray)
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
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            CleanerTheme.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 12) {
                    ForEach(Array(videos.enumerated()), id: \.element.asset.localIdentifier) { index, video in
                        VideoRow(video: video)
                            .scaleIn(delay: Double(index) * 0.05)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Large Videos")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Large Videos")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(CleanerTheme.textPrimary)
            }
        }
    }
}

struct VideoRow: View {
    let video: VideoAnalyzer.VideoInfo

    var body: some View {
        HStack(spacing: 16) {
            // Video Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(CleanerTheme.accentRed.opacity(0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: "video.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(CleanerTheme.iconGray)
            }

            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(VideoAnalyzer.shared.formatFileSize(video.fileSize))
                    .cleanerFont(.headline)
                    .foregroundColor(CleanerTheme.textPrimary)

                Text(VideoAnalyzer.shared.formatDuration(video.duration))
                    .cleanerFont(.caption)
                    .foregroundColor(CleanerTheme.textSecondary)

                Text("\(Int(video.resolution.width))×\(Int(video.resolution.height)) @ \(String(format: "%.0f", video.frameRate))fps")
                    .cleanerFont(.caption2)
                    .foregroundColor(CleanerTheme.textTertiary)
            }

            Spacer()
        }
        .padding(16)
        .background(CleanerTheme.cardBackground)
        .cornerRadius(16)
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
