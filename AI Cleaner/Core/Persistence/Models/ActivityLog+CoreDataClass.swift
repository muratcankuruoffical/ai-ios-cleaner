//
//  ActivityLog+CoreDataClass.swift
//  AI Cleaner
//
//  Core Data entity class for ActivityLog
//

import Foundation
import CoreData

@objc(ActivityLog)
public class ActivityLog: NSManagedObject {

    // MARK: - Activity Types

    enum ActivityType: String {
        case scanCompleted = "scan_completed"
        case photosDeleted = "photos_deleted"
        case cacheCleared = "cache_cleared"
        case optimizationCompleted = "optimization_completed"
        case calendarCleaned = "calendar_cleaned"
        case contactsCleaned = "contacts_cleaned"
    }

    // MARK: - Helper Methods

    var activityType: ActivityType? {
        guard let type = type else { return nil }
        return ActivityType(rawValue: type)
    }

    var formattedItemCount: String {
        let count = Int(itemCount)
        if count == 0 { return "" }

        switch activityType {
        case .scanCompleted:
            return "\(count) photos"
        case .photosDeleted:
            return "\(count) photos"
        case .cacheCleared:
            return formatBytes(Int64(freedBytes))
        case .optimizationCompleted:
            return "\(count) photos"
        case .calendarCleaned:
            return "\(count) items"
        case .contactsCleaned:
            return "\(count) contacts"
        case .none:
            return "\(count) items"
        }
    }

    var displayTitle: String {
        switch activityType {
        case .scanCompleted:
            return "Scan completed"
        case .photosDeleted:
            // Use category to differentiate between photos and videos
            if let category = category {
                if category.lowercased().contains("video") {
                    return "Deleted \(itemCount) video\(itemCount == 1 ? "" : "s")"
                } else {
                    return "Deleted \(itemCount) photo\(itemCount == 1 ? "" : "s")"
                }
            }
            return "Deleted \(itemCount) item\(itemCount == 1 ? "" : "s")"
        case .cacheCleared:
            return "Cache cleared"
        case .optimizationCompleted:
            return "Optimized \(itemCount) photo\(itemCount == 1 ? "" : "s")"
        case .calendarCleaned:
            if let category = category {
                return "Deleted \(itemCount) \(category.lowercased())"
            }
            return "Deleted \(itemCount) calendar item\(itemCount == 1 ? "" : "s")"
        case .contactsCleaned:
            if let category = category {
                return category // e.g., "Merged 3 contacts" or "Deleted 2 duplicates"
            }
            return "Cleaned \(itemCount) contact\(itemCount == 1 ? "" : "s")"
        case .none:
            return "Activity completed"
        }
    }

    var iconName: String {
        switch activityType {
        case .scanCompleted:
            return "checkmark.circle.fill"
        case .photosDeleted:
            return "trash.circle.fill"
        case .cacheCleared:
            return "arrow.clockwise.circle.fill"
        case .optimizationCompleted:
            return "wand.and.stars.fill"
        case .calendarCleaned:
            return "calendar.badge.minus"
        case .contactsCleaned:
            return "person.crop.circle.badge.checkmark"
        case .none:
            return "circle.fill"
        }
    }

    var iconColor: String {
        switch activityType {
        case .scanCompleted:
            return "green"
        case .photosDeleted:
            return "red"
        case .cacheCleared:
            return "blue"
        case .optimizationCompleted:
            return "purple"
        case .calendarCleaned:
            return "teal"
        case .contactsCleaned:
            return "brown"
        case .none:
            return "gray"
        }
    }

    // MARK: - Factory Methods

    @discardableResult
    static func createScanActivity(
        context: NSManagedObjectContext,
        photoCount: Int,
        timestamp: Date = Date()
    ) -> ActivityLog {
        print("📊 [ActivityLog] Creating scan activity - photoCount: \(photoCount)")
        let activity = ActivityLog(context: context)
        activity.id = UUID()
        activity.type = ActivityType.scanCompleted.rawValue
        activity.itemCount = Int32(photoCount)
        activity.timestamp = timestamp
        activity.freedBytes = 0
        activity.category = nil
        print("📊 [ActivityLog] Scan activity created - ID: \(activity.id?.uuidString ?? "nil")")
        return activity
    }

    @discardableResult
    static func createDeleteActivity(
        context: NSManagedObjectContext,
        count: Int,
        freedBytes: Int64,
        category: String,
        timestamp: Date = Date()
    ) -> ActivityLog {
        print("📊 [ActivityLog] Creating delete activity - count: \(count), bytes: \(freedBytes), category: \(category)")
        let activity = ActivityLog(context: context)
        activity.id = UUID()
        activity.type = ActivityType.photosDeleted.rawValue
        activity.itemCount = Int32(count)
        activity.freedBytes = freedBytes
        activity.category = category
        activity.timestamp = timestamp
        print("📊 [ActivityLog] Delete activity created - ID: \(activity.id?.uuidString ?? "nil")")
        return activity
    }

    @discardableResult
    static func createOptimizationActivity(
        context: NSManagedObjectContext,
        count: Int,
        freedBytes: Int64,
        deletedOriginals: Bool,
        timestamp: Date = Date()
    ) -> ActivityLog {
        print("📊 [ActivityLog] Creating optimization activity - count: \(count), bytes: \(freedBytes), deletedOriginals: \(deletedOriginals)")
        let activity = ActivityLog(context: context)
        activity.id = UUID()
        activity.type = ActivityType.optimizationCompleted.rawValue
        activity.itemCount = Int32(count)
        activity.freedBytes = freedBytes
        activity.category = deletedOriginals ? "Optimized (originals deleted)" : "Optimized (originals kept)"
        activity.timestamp = timestamp
        print("📊 [ActivityLog] Optimization activity created - ID: \(activity.id?.uuidString ?? "nil")")
        return activity
    }

    @discardableResult
    static func createCalendarActivity(
        context: NSManagedObjectContext,
        count: Int,
        category: String, // e.g., "past events", "reminders", "declined events"
        timestamp: Date = Date()
    ) -> ActivityLog {
        print("📊 [ActivityLog] Creating calendar activity - count: \(count), category: \(category)")
        let activity = ActivityLog(context: context)
        activity.id = UUID()
        activity.type = ActivityType.calendarCleaned.rawValue
        activity.itemCount = Int32(count)
        activity.freedBytes = 0
        activity.category = category
        activity.timestamp = timestamp
        print("📊 [ActivityLog] Calendar activity created - ID: \(activity.id?.uuidString ?? "nil")")
        return activity
    }

    @discardableResult
    static func createContactsActivity(
        context: NSManagedObjectContext,
        count: Int,
        category: String, // e.g., "Merged 3 contacts", "Deleted 2 duplicates"
        timestamp: Date = Date()
    ) -> ActivityLog {
        print("📊 [ActivityLog] Creating contacts activity - count: \(count), category: \(category)")
        let activity = ActivityLog(context: context)
        activity.id = UUID()
        activity.type = ActivityType.contactsCleaned.rawValue
        activity.itemCount = Int32(count)
        activity.freedBytes = 0
        activity.category = category
        activity.timestamp = timestamp
        print("📊 [ActivityLog] Contacts activity created - ID: \(activity.id?.uuidString ?? "nil")")
        return activity
    }

    // MARK: - Formatting

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
