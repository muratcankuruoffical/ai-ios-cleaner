//
//  ContactBackup.swift
//  AI Cleaner
//
//  Model for contact backup metadata
//

import Foundation

struct ContactBackup: Identifiable, Codable {
    let id: UUID
    let createdAt: Date
    let contactCount: Int
    let fileSize: Int64
    let fileName: String

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }

    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }

    var displayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
        return "Backup - \(formatter.string(from: createdAt))"
    }
}

// Auto-backup settings
struct ContactsBackupSettings: Codable {
    var autoBackupEnabled: Bool = false
    var backupFrequency: BackupFrequency = .weekly
    var maxBackups: Int = 10
    var lastAutoBackupDate: Date?

    enum BackupFrequency: String, Codable, CaseIterable {
        case daily = "Daily"
        case weekly = "Weekly"

        var days: Int {
            switch self {
            case .daily: return 1
            case .weekly: return 7
            }
        }
    }
}
