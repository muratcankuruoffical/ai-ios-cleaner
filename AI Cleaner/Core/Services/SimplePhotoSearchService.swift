//
//  SimplePhotoSearchService.swift
//  AI Cleaner
//
//  Fallback photo search for simulator (when Vision Framework is unavailable)
//

import Foundation
import Photos
import UIKit

final class SimplePhotoSearchService {
    static let shared = SimplePhotoSearchService()

    private init() {}

    /// Search photos using simple heuristics (for simulator)
    func searchPhotos(query: String) async -> [PHAsset] {
        let keywords = query.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }

        print("📸 [SimplePhotoSearch] Searching for keywords: \(keywords)")

        let fetchOptions = PHFetchOptions()
        let allPhotos = PHAsset.fetchAssets(with: .image, options: fetchOptions)

        var matchingAssets: [PHAsset] = []

        allPhotos.enumerateObjects { asset, _, _ in
            if self.assetMatches(asset, keywords: keywords) {
                matchingAssets.append(asset)
            }
        }

        print("📸 [SimplePhotoSearch] Found \(matchingAssets.count) matches")

        return matchingAssets
    }

    private func assetMatches(_ asset: PHAsset, keywords: [String]) -> Bool {
        for keyword in keywords {
            // Screenshot detection
            if keyword == "screenshot" || keyword == "screen" {
                if isScreenshot(asset) {
                    return true
                }
            }

            // Selfie detection
            if keyword == "selfie" || keyword == "portrait" {
                if asset.mediaSubtypes.contains(.photoScreenshot) == false &&
                   asset.pixelWidth > 0 && asset.pixelHeight > 0 {
                    // Portrait orientation check
                    if asset.pixelHeight > asset.pixelWidth {
                        return true
                    }
                }
            }

            // Panorama
            if keyword == "panorama" || keyword == "pano" {
                if asset.mediaSubtypes.contains(.photoPanorama) {
                    return true
                }
            }

            // HDR
            if keyword == "hdr" {
                if asset.mediaSubtypes.contains(.photoHDR) {
                    return true
                }
            }

            // Live photo
            if keyword == "live" {
                if asset.mediaSubtypes.contains(.photoLive) {
                    return true
                }
            }

            // Recent (last 7 days)
            if keyword == "recent" {
                if let creationDate = asset.creationDate {
                    let daysSince = Calendar.current.dateComponents([.day], from: creationDate, to: Date()).day ?? 0
                    if daysSince <= 7 {
                        return true
                    }
                }
            }

            // Old (older than 1 year)
            if keyword == "old" {
                if let creationDate = asset.creationDate {
                    let daysSince = Calendar.current.dateComponents([.day], from: creationDate, to: Date()).day ?? 0
                    if daysSince >= 365 {
                        return true
                    }
                }
            }

            // Favorite
            if keyword == "favorite" || keyword == "fav" {
                if asset.isFavorite {
                    return true
                }
            }
        }

        return false
    }

    private func isScreenshot(_ asset: PHAsset) -> Bool {
        // Check if it's a screenshot using mediaSubtypes
        if asset.mediaSubtypes.contains(.photoScreenshot) {
            return true
        }

        // Additional heuristic: screenshots are usually in portrait with specific aspect ratios
        let width = CGFloat(asset.pixelWidth)
        let height = CGFloat(asset.pixelHeight)

        if width > 0 && height > 0 {
            let aspectRatio = height / width
            // iPhone screenshots typically have aspect ratios around 2.0-2.2
            if aspectRatio > 1.7 && aspectRatio < 2.3 {
                return true
            }
        }

        return false
    }
}
