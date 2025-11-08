//
//  StorageRecommendations.swift
//  AI Cleaner
//
//  Storage cleaning recommendations and guidance
//

import Foundation
import UIKit

final class StorageRecommendations {
    static let shared = StorageRecommendations()

    private init() {}

    // MARK: - Recommendation Types

    enum RecommendationType: String, CaseIterable {
        case safariCache = "Clear Safari Cache"
        case largeAttachments = "Delete Large Attachments"
        case offloadApps = "Offload Unused Apps"
        case reviewAppStorage = "Review App Storage"
        case deleteOldMessages = "Delete Old Messages"
        case managePhotos = "Optimize Photos"
        case reviewDownloads = "Review Downloads"
        case clearAppCaches = "Clear App Caches"
    }

    struct Recommendation: Identifiable {
        var id: String { type.rawValue }
        let type: RecommendationType
        let title: String
        let description: String
        let estimatedSavings: String
        let icon: String
        let priority: Priority
        let deepLink: DeepLink?
        let instructions: [String]

        enum Priority: Int {
            case high = 3
            case medium = 2
            case low = 1
        }
    }

    enum DeepLink {
        case iphoneStorage
        case safariSettings
        case generalSettings
        case messagesSettings

        var url: URL? {
            switch self {
            case .iphoneStorage:
                return URL(string: "App-prefs:General&path=STORAGE_MGMT")
            case .safariSettings:
                return URL(string: "App-prefs:SAFARI")
            case .generalSettings:
                return URL(string: "App-prefs:General")
            case .messagesSettings:
                return URL(string: "App-prefs:MESSAGES")
            }
        }

        var fallbackURL: URL? {
            // Fallback to main settings if deep link doesn't work
            return URL(string: UIApplication.openSettingsURLString)
        }
    }

    // MARK: - Get Recommendations

    func getRecommendations(basedOn storageInfo: SystemInsights.StorageInfo?) -> [Recommendation] {
        guard let storage = storageInfo else {
            return getGeneralRecommendations()
        }

        var recommendations: [Recommendation] = []
        let usagePercentage = storage.usagePercentage

        // High priority if storage > 80%
        if usagePercentage > 80 {
            recommendations.append(contentsOf: getHighPriorityRecommendations())
        }

        // Medium priority if storage > 60%
        if usagePercentage > 60 {
            recommendations.append(contentsOf: getMediumPriorityRecommendations())
        }

        // Always show general recommendations
        recommendations.append(contentsOf: getLowPriorityRecommendations())

        return recommendations.sorted { $0.priority.rawValue > $1.priority.rawValue }
    }

    // MARK: - Priority-based Recommendations

    private func getHighPriorityRecommendations() -> [Recommendation] {
        return [
            Recommendation(
                type: .reviewAppStorage,
                title: "Review Large Apps",
                description: "Check which apps are using the most space and delete unused ones",
                estimatedSavings: "Up to 5 GB",
                icon: "externaldrive.fill",
                priority: .high,
                deepLink: .iphoneStorage,
                instructions: [
                    "Open Settings app",
                    "Tap 'General' → 'iPhone Storage'",
                    "Review apps sorted by size",
                    "Delete or offload unused apps",
                    "Check app documents and data"
                ]
            ),
            Recommendation(
                type: .largeAttachments,
                title: "Delete Large Attachments",
                description: "Remove photos, videos, and files from Messages",
                estimatedSavings: "Up to 2 GB",
                icon: "paperclip",
                priority: .high,
                deepLink: .messagesSettings,
                instructions: [
                    "Open Messages app",
                    "Tap any conversation",
                    "Tap contact name at top",
                    "Scroll down to 'Photos' and 'Attachments'",
                    "Delete unnecessary files"
                ]
            ),
            Recommendation(
                type: .safariCache,
                title: "Clear Safari Data",
                description: "Remove website data, cookies, and browsing history",
                estimatedSavings: "Up to 1 GB",
                icon: "safari",
                priority: .high,
                deepLink: .safariSettings,
                instructions: [
                    "Open Settings app",
                    "Scroll down and tap 'Safari'",
                    "Tap 'Clear History and Website Data'",
                    "Confirm by tapping 'Clear History and Data'"
                ]
            )
        ]
    }

    private func getMediumPriorityRecommendations() -> [Recommendation] {
        return [
            Recommendation(
                type: .offloadApps,
                title: "Offload Unused Apps",
                description: "Remove apps but keep their data for later",
                estimatedSavings: "Up to 3 GB",
                icon: "arrow.down.app",
                priority: .medium,
                deepLink: .iphoneStorage,
                instructions: [
                    "Go to Settings → General → iPhone Storage",
                    "Enable 'Offload Unused Apps' (at the top)",
                    "Or manually offload specific apps",
                    "Tap an app → 'Offload App'",
                    "Documents and data will be preserved"
                ]
            ),
            Recommendation(
                type: .managePhotos,
                title: "Use AI Cleaner",
                description: "Delete duplicates, blurry photos, and optimize images",
                estimatedSavings: "Varies",
                icon: "photo.on.rectangle.angled",
                priority: .medium,
                deepLink: nil,
                instructions: [
                    "Tap 'Start Scan' on the main screen",
                    "Review similar and duplicate photos",
                    "Delete blurry or dark photos",
                    "Optimize 4K photos to 1080p",
                    "Free up significant space!"
                ]
            ),
            Recommendation(
                type: .deleteOldMessages,
                title: "Auto-Delete Old Messages",
                description: "Set messages to delete after 30 days",
                estimatedSavings: "Up to 500 MB",
                icon: "message",
                priority: .medium,
                deepLink: .messagesSettings,
                instructions: [
                    "Open Settings app",
                    "Scroll down and tap 'Messages'",
                    "Tap 'Keep Messages'",
                    "Select '30 Days' or '1 Year'",
                    "Confirm deletion of older messages"
                ]
            )
        ]
    }

    private func getLowPriorityRecommendations() -> [Recommendation] {
        return [
            Recommendation(
                type: .reviewDownloads,
                title: "Check Downloads Folder",
                description: "Remove downloaded files you no longer need",
                estimatedSavings: "Varies",
                icon: "arrow.down.circle",
                priority: .low,
                deepLink: nil,
                instructions: [
                    "Open Files app",
                    "Tap 'Browse' at the bottom",
                    "Tap 'Downloads' folder",
                    "Review and delete unnecessary files",
                    "Empty trash if available"
                ]
            ),
            Recommendation(
                type: .clearAppCaches,
                title: "Clear Individual App Caches",
                description: "Delete cache from apps like Instagram, Twitter, etc.",
                estimatedSavings: "Up to 1 GB",
                icon: "trash",
                priority: .low,
                deepLink: nil,
                instructions: [
                    "Open each app's settings",
                    "Look for 'Clear Cache' or 'Storage'",
                    "For apps without clear cache:",
                    "Delete and reinstall the app",
                    "Sign back in to restore your data"
                ]
            )
        ]
    }

    private func getGeneralRecommendations() -> [Recommendation] {
        // Return all recommendations when storage info is unavailable
        return getHighPriorityRecommendations() +
               getMediumPriorityRecommendations() +
               getLowPriorityRecommendations()
    }

    // MARK: - Deep Link Helpers

    func openDeepLink(_ deepLink: DeepLink) {
        guard let url = deepLink.url ?? deepLink.fallbackURL else { return }

        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else if let fallback = deepLink.fallbackURL {
            UIApplication.shared.open(fallback, options: [:], completionHandler: nil)
        }
    }

    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    // MARK: - Formatted Helpers

    func getTopRecommendations(count: Int = 3, basedOn storageInfo: SystemInsights.StorageInfo?) -> [Recommendation] {
        let allRecommendations = getRecommendations(basedOn: storageInfo)
        return Array(allRecommendations.prefix(count))
    }

    func getRecommendationsByPriority(_ priority: Recommendation.Priority, basedOn storageInfo: SystemInsights.StorageInfo?) -> [Recommendation] {
        return getRecommendations(basedOn: storageInfo).filter { $0.priority == priority }
    }
}
