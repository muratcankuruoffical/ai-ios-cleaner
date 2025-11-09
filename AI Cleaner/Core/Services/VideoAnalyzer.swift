//
//  VideoAnalyzer.swift
//  AI Cleaner
//
//  Service for analyzing videos (size, duplicates, etc.)
//

import Foundation
internal import Photos
import AVFoundation
import UIKit

final class VideoAnalyzer {
    static let shared = VideoAnalyzer()

    private init() {}

    // MARK: - Configuration

    struct Configuration {
        var largeVideoThresholdMB: Int64 = 200
        var similarityThreshold: TimeInterval = 2.0 // seconds

        static let `default` = Configuration()
    }

    // MARK: - Video Information

    struct VideoInfo {
        let asset: PHAsset
        let duration: TimeInterval
        let fileSize: Int64
        let resolution: CGSize
        let frameRate: Float
        let codec: String?
        let isLarge: Bool
    }

    func analyzeVideo(asset: PHAsset, configuration: Configuration = .default) async throws -> VideoInfo {
        guard asset.mediaType == .video else {
            throw VideoAnalyzerError.notAVideo
        }

        let duration = asset.duration
        let resolution = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)

        // Get file size
        let resources = PHAssetResource.assetResources(for: asset)
        var fileSize: Int64 = 0

        if let resource = resources.first,
           let size = resource.value(forKey: "fileSize") as? Int64 {
            fileSize = size
        }

        // Get detailed video info
        let avAsset = try await loadAVAsset(for: asset)
        var frameRate: Float = 0
        var codec: String?

        if let videoTrack = try? await avAsset.loadTracks(withMediaType: .video).first {
            frameRate = try await videoTrack.load(.nominalFrameRate)

            if let formatDescriptions = try? await videoTrack.load(.formatDescriptions),
               let formatDescription = formatDescriptions.first {
                let codecType = CMFormatDescriptionGetMediaSubType(formatDescription)
                codec = fourCCToString(codecType)
            }
        }

        let isLarge = fileSize > (configuration.largeVideoThresholdMB * 1024 * 1024)

        return VideoInfo(
            asset: asset,
            duration: duration,
            fileSize: fileSize,
            resolution: resolution,
            frameRate: frameRate,
            codec: codec,
            isLarge: isLarge
        )
    }

    // MARK: - Large Video Detection

    func findLargeVideos(
        assets: [PHAsset],
        thresholdMB: Int64 = 200,
        progressHandler: ((Int, Int) -> Void)? = nil
    ) async -> [VideoInfo] {
        var largeVideos: [VideoInfo] = []
        let config = Configuration(largeVideoThresholdMB: thresholdMB)

        for (index, asset) in assets.enumerated() {
            guard asset.mediaType == .video else { continue }

            do {
                let info = try await analyzeVideo(asset: asset, configuration: config)
                if info.isLarge {
                    largeVideos.append(info)
                }
            } catch {
                // Skip failed videos
            }

            progressHandler?(index + 1, assets.count)

            if index % 10 == 0 {
                await Task.yield()
            }
        }

        return largeVideos.sorted { $0.fileSize > $1.fileSize }
    }

    // MARK: - Similar Video Detection (Basic)

    struct SimilarVideoGroup {
        let videos: [VideoInfo]
        let similarityReason: SimilarityReason

        enum SimilarityReason {
            case sameDuration
            case sameResolution
            case sameDurationAndResolution
        }
    }

    func findSimilarVideos(
        assets: [PHAsset],
        durationThreshold: TimeInterval = 2.0,
        progressHandler: ((Int, Int) -> Void)? = nil
    ) async -> [SimilarVideoGroup] {
        var videoInfos: [VideoInfo] = []

        // Analyze all videos
        for (index, asset) in assets.enumerated() {
            guard asset.mediaType == .video else { continue }

            do {
                let info = try await analyzeVideo(asset: asset)
                videoInfos.append(info)
            } catch {
                // Skip failed videos
            }

            progressHandler?(index + 1, assets.count)

            if index % 10 == 0 {
                await Task.yield()
            }
        }

        // Group by similarity
        var groups: [SimilarVideoGroup] = []
        var processed = Set<Int>()

        for i in 0..<videoInfos.count {
            guard !processed.contains(i) else { continue }

            var similarGroup: [VideoInfo] = [videoInfos[i]]
            processed.insert(i)

            for j in (i + 1)..<videoInfos.count {
                guard !processed.contains(j) else { continue }

                let video1 = videoInfos[i]
                let video2 = videoInfos[j]

                let durationMatch = abs(video1.duration - video2.duration) < durationThreshold
                let resolutionMatch = video1.resolution == video2.resolution

                if durationMatch && resolutionMatch {
                    similarGroup.append(video2)
                    processed.insert(j)
                }
            }

            if similarGroup.count >= 2 {
                let group = SimilarVideoGroup(
                    videos: similarGroup,
                    similarityReason: .sameDurationAndResolution
                )
                groups.append(group)
            }
        }

        return groups.sorted { $0.videos.count > $1.videos.count }
    }

    // MARK: - Video Thumbnail Generation

    func generateThumbnail(for asset: PHAsset, at time: TimeInterval = 0) async throws -> UIImage {
        let avAsset = try await loadAVAsset(for: asset)
        let generator = AVAssetImageGenerator(asset: avAsset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 512, height: 512)

        let cmTime = CMTime(seconds: time, preferredTimescale: 600)

        // Use new async API for iOS 18+
        let cgImage: CGImage
        if #available(iOS 18.0, *) {
            cgImage = try await withCheckedThrowingContinuation { continuation in
                generator.generateCGImageAsynchronously(for: cmTime) { image, _, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let image = image {
                        continuation.resume(returning: image)
                    } else {
                        continuation.resume(throwing: VideoAnalyzerError.failedToGenerateThumbnail)
                    }
                }
            }
        } else {
            cgImage = try generator.copyCGImage(at: cmTime, actualTime: nil)
        }

        return UIImage(cgImage: cgImage)
    }

    // MARK: - Utilities

    private func loadAVAsset(for asset: PHAsset) async throws -> AVAsset {
        try await withCheckedThrowingContinuation { continuation in
            let options = PHVideoRequestOptions()
            options.isNetworkAccessAllowed = true

            PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { avAsset, _, info in
                if let error = info?[PHImageErrorKey] as? Error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let avAsset = avAsset else {
                    continuation.resume(throwing: VideoAnalyzerError.failedToLoadAsset)
                    return
                }

                continuation.resume(returning: avAsset)
            }
        }
    }

    private func fourCCToString(_ fourCC: FourCharCode) -> String {
        let bytes: [CChar] = [
            CChar((fourCC >> 24) & 0xFF),
            CChar((fourCC >> 16) & 0xFF),
            CChar((fourCC >> 8) & 0xFF),
            CChar(fourCC & 0xFF),
            0
        ]
        return String(cString: bytes)
    }

    // MARK: - Statistics

    func calculateTotalSize(videos: [VideoInfo]) -> Int64 {
        videos.reduce(0) { $0 + $1.fileSize }
    }

    func calculateTotalDuration(videos: [VideoInfo]) -> TimeInterval {
        videos.reduce(0) { $0 + $1.duration }
    }

    func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        let seconds = Int(duration) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Errors

enum VideoAnalyzerError: Error, LocalizedError {
    case notAVideo
    case failedToLoadAsset
    case failedToGenerateThumbnail

    var errorDescription: String? {
        switch self {
        case .notAVideo:
            return "Asset is not a video"
        case .failedToLoadAsset:
            return "Failed to load video asset"
        case .failedToGenerateThumbnail:
            return "Failed to generate video thumbnail"
        }
    }
}
