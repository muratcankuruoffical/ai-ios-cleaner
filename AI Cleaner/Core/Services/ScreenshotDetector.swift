//
//  ScreenshotDetector.swift
//  AI Cleaner
//
//  Service for detecting screenshots
//

import Foundation
internal import Photos
import UIKit
import UniformTypeIdentifiers

final class ScreenshotDetector {
    static let shared = ScreenshotDetector()

    private init() {}

    // MARK: - Screenshot Detection

    struct DetectionResult {
        let isScreenshot: Bool
        let confidence: Float // 0.0 - 1.0
        let reasons: [DetectionReason]
    }

    enum DetectionReason {
        case mediaSubtype
        case aspectRatio
        case metadata
        case fileName
        case commonScreenshotResolution

        var description: String {
            switch self {
            case .mediaSubtype: return "Media subtype indicates screenshot"
            case .aspectRatio: return "Aspect ratio matches device screen"
            case .metadata: return "Metadata indicates screenshot"
            case .fileName: return "Filename suggests screenshot"
            case .commonScreenshotResolution: return "Resolution matches common device"
            }
        }
    }

    func detectScreenshot(asset: PHAsset) async -> DetectionResult {
        var reasons: [DetectionReason] = []
        var confidenceScore: Float = 0.0

        // Check media subtype (most reliable)
        if asset.mediaSubtypes.contains(.photoScreenshot) {
            reasons.append(.mediaSubtype)
            confidenceScore += 0.5
        }

        // Check aspect ratio
        let width = asset.pixelWidth
        let height = asset.pixelHeight
        if isCommonScreenshotAspectRatio(width: width, height: height) {
            reasons.append(.aspectRatio)
            confidenceScore += 0.2
        }

        // Check if resolution matches known devices
        if isCommonScreenshotResolution(width: width, height: height) {
            reasons.append(.commonScreenshotResolution)
            confidenceScore += 0.15
        }

        // Check metadata and resources
        let resources = PHAssetResource.assetResources(for: asset)
        for resource in resources {
            // Check original filename
            let filename = resource.originalFilename.lowercased()
            if filename.contains("screenshot") || filename.contains("screen shot") ||
               filename.hasPrefix("img_") || filename.hasPrefix("screen") {
                reasons.append(.fileName)
                confidenceScore += 0.15
                break
            }
        }

        let isScreenshot = confidenceScore >= 0.5

        return DetectionResult(
            isScreenshot: isScreenshot,
            confidence: min(confidenceScore, 1.0),
            reasons: reasons
        )
    }

    // MARK: - Aspect Ratio Analysis

    private func isCommonScreenshotAspectRatio(width: Int, height: Int) -> Bool {
        let ratio = Double(max(width, height)) / Double(min(width, height))

        // Common device aspect ratios
        let commonRatios: [Double] = [
            16.0/9.0,   // 1.777 - Most Android, older iPhones
            19.5/9.0,   // 2.166 - iPhone X, XS, 11 Pro
            19.0/9.0,   // 2.111 - Many Android devices
            20.0/9.0,   // 2.222 - iPhone 12, 13
            2.16,       // 2.16 - iPhone 14 Pro, 15 Pro
            4.0/3.0,    // 1.333 - iPad
            3.0/2.0,    // 1.5 - Some tablets
        ]

        for commonRatio in commonRatios {
            if abs(ratio - commonRatio) < 0.05 {
                return true
            }
        }

        return false
    }

    private func isCommonScreenshotResolution(width: Int, height: Int) -> Bool {
        let w = max(width, height)
        let h = min(width, height)

        // Common iPhone screenshot resolutions
        let iphoneResolutions: [(Int, Int)] = [
            (1125, 2436), // iPhone X, XS, 11 Pro
            (1170, 2532), // iPhone 12, 12 Pro, 13, 13 Pro
            (1179, 2556), // iPhone 14 Pro, 15 Pro
            (1284, 2778), // iPhone 12 Pro Max, 13 Pro Max
            (1290, 2796), // iPhone 14 Pro Max, 15 Pro Max
            (828, 1792),  // iPhone XR, 11
            (1242, 2688), // iPhone XS Max
            (750, 1334),  // iPhone 6, 7, 8
            (1242, 2208), // iPhone 6+, 7+, 8+
        ]

        // Common iPad screenshot resolutions
        let ipadResolutions: [(Int, Int)] = [
            (1536, 2048), // iPad, iPad Air
            (1668, 2224), // iPad Pro 10.5"
            (1668, 2388), // iPad Pro 11"
            (2048, 2732), // iPad Pro 12.9"
        ]

        let allResolutions = iphoneResolutions + ipadResolutions

        for (resW, resH) in allResolutions {
            if (w == resW && h == resH) || (w == resH && h == resW) {
                return true
            }
        }

        return false
    }

    // MARK: - Batch Processing

    func detectScreenshots(
        in assets: [PHAsset],
        progressHandler: ((Int, Int) -> Void)? = nil
    ) async -> [DetectionResult] {
        var results: [DetectionResult] = []

        for (index, asset) in assets.enumerated() {
            let result = await detectScreenshot(asset: asset)
            results.append(result)

            progressHandler?(index + 1, assets.count)

            if index % 20 == 0 {
                await Task.yield()
            }
        }

        return results
    }

    func filterScreenshots(assets: [PHAsset]) async -> [PHAsset] {
        var screenshots: [PHAsset] = []

        for asset in assets {
            let result = await detectScreenshot(asset: asset)
            if result.isScreenshot {
                screenshots.append(asset)
            }
        }

        return screenshots
    }

    // MARK: - Statistics

    func countScreenshots(in assets: [PHAsset]) async -> Int {
        var count = 0

        for asset in assets {
            let result = await detectScreenshot(asset: asset)
            if result.isScreenshot {
                count += 1
            }
        }

        return count
    }
}
