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

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
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
            }
        } catch {
            print("Failed to load thumbnail: \(error)")
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
