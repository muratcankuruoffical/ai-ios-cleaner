//
//  SavingsTracker.swift
//  AI Cleaner
//
//  Tracks total bytes saved by user across all cleanup operations
//

import Foundation

final class SavingsTracker {
    static let shared = SavingsTracker()

    private let userDefaults = UserDefaults.standard
    private let totalBytesSavedKey = "totalBytesSaved"

    private init() {}

    // MARK: - Public Methods

    /// Get total bytes saved by user across all time
    var totalBytesSaved: Int64 {
        return userDefaults.object(forKey: totalBytesSavedKey) as? Int64 ?? 0
    }

    /// Add bytes to total saved
    func addSavedBytes(_ bytes: Int64) {
        let current = totalBytesSaved
        let new = current + bytes
        userDefaults.set(new, forKey: totalBytesSavedKey)

        print("💾 [SavingsTracker] Added \(formatBytes(bytes)) to total savings")
        print("💾 [SavingsTracker] New total: \(formatBytes(new))")
    }

    /// Reset total saved (for testing or user reset)
    func reset() {
        userDefaults.set(0, forKey: totalBytesSavedKey)
        print("💾 [SavingsTracker] Reset total savings to 0")
    }

    // MARK: - Computed Properties

    var totalSavedMB: Double {
        Double(totalBytesSaved) / (1024 * 1024)
    }

    var totalSavedGB: Double {
        Double(totalBytesSaved) / (1024 * 1024 * 1024)
    }

    var formattedTotalSaved: String {
        if totalSavedGB >= 1.0 {
            return String(format: "%.2f GB", totalSavedGB)
        } else if totalSavedMB >= 1.0 {
            return String(format: "%.1f MB", totalSavedMB)
        } else {
            return String(format: "%.0f KB", Double(totalBytesSaved) / 1024)
        }
    }

    // MARK: - Helper

    private func formatBytes(_ bytes: Int64) -> String {
        let gb = Double(bytes) / (1024 * 1024 * 1024)
        if gb >= 1.0 {
            return String(format: "%.2f GB", gb)
        }

        let mb = Double(bytes) / (1024 * 1024)
        if mb >= 1.0 {
            return String(format: "%.1f MB", mb)
        }

        let kb = Double(bytes) / 1024
        return String(format: "%.0f KB", kb)
    }
}
