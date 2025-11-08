//
//  ContactsBackupManager.swift
//  AI Cleaner
//
//  Manager for backing up and restoring contacts
//

import Foundation
import Contacts

final class ContactsBackupManager {
    static let shared = ContactsBackupManager()

    private let contactStore = CNContactStore()
    private let fileManager = FileManager.default
    private let userDefaults = UserDefaults.standard

    private let backupDirectoryName = "ContactsBackups"
    private let settingsKey = "contactsBackupSettings"
    private let backupsMetadataKey = "contactsBackupsMetadata"

    private init() {
        createBackupDirectoryIfNeeded()
    }

    // MARK: - Backup Directory

    private var backupDirectoryURL: URL {
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsURL.appendingPathComponent(backupDirectoryName)
    }

    private func createBackupDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: backupDirectoryURL.path) {
            try? fileManager.createDirectory(at: backupDirectoryURL, withIntermediateDirectories: true)
            print("📁 [ContactsBackup] Created backup directory at: \(backupDirectoryURL.path)")
        }
    }

    // MARK: - Settings

    var settings: ContactsBackupSettings {
        get {
            guard let data = userDefaults.data(forKey: settingsKey),
                  let settings = try? JSONDecoder().decode(ContactsBackupSettings.self, from: data) else {
                return ContactsBackupSettings()
            }
            return settings
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                userDefaults.set(data, forKey: settingsKey)
            }
        }
    }

    // MARK: - Backup Metadata

    private(set) var backups: [ContactBackup] = []

    private func loadBackups() {
        guard let data = userDefaults.data(forKey: backupsMetadataKey),
              let backups = try? JSONDecoder().decode([ContactBackup].self, from: data) else {
            self.backups = []
            return
        }
        self.backups = backups.sorted { $0.createdAt > $1.createdAt }
        print("📋 [ContactsBackup] Loaded \(backups.count) backups")
    }

    private func saveBackupsMetadata() {
        if let data = try? JSONEncoder().encode(backups) {
            userDefaults.set(data, forKey: backupsMetadataKey)
        }
    }

    func refreshBackups() {
        loadBackups()
    }

    // MARK: - Create Backup

    func createBackup() async throws -> ContactBackup {
        print("💾 [ContactsBackup] Starting backup creation...")

        // Check authorization
        let authStatus = CNContactStore.authorizationStatus(for: .contacts)
        guard authStatus == .authorized else {
            throw BackupError.unauthorized
        }

        // Perform heavy operations on background thread
        let (contactCount, jsonData) = try await Task.detached { [weak self] () -> (Int, Data) in
            guard let self = self else {
                throw BackupError.importFailed
            }

            // Fetch all contacts
            let keysToFetch: [CNKeyDescriptor] = [
                CNContactIdentifierKey as CNKeyDescriptor,
                CNContactGivenNameKey as CNKeyDescriptor,
                CNContactFamilyNameKey as CNKeyDescriptor,
                CNContactPhoneNumbersKey as CNKeyDescriptor,
                CNContactEmailAddressesKey as CNKeyDescriptor,
                CNContactPostalAddressesKey as CNKeyDescriptor,
                CNContactOrganizationNameKey as CNKeyDescriptor,
                CNContactBirthdayKey as CNKeyDescriptor
            ]

            var allContacts: [CNContact] = []
            let fetchRequest = CNContactFetchRequest(keysToFetch: keysToFetch)

            try self.contactStore.enumerateContacts(with: fetchRequest) { contact, _ in
                allContacts.append(contact)
            }

            print("📇 [ContactsBackup] Fetched \(allContacts.count) contacts")

            guard !allContacts.isEmpty else {
                throw BackupError.importFailed
            }

            // Convert to SerializableContact
            let serializableContacts = allContacts.map { SerializableContact(from: $0) }

            // Create backup data structure
            let backupData = ContactsBackupData(
                version: "1.0",
                createdAt: Date(),
                contacts: serializableContacts
            )

            // Encode to JSON
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted

            let jsonData = try encoder.encode(backupData)
            print("✅ [ContactsBackup] JSON serialization successful - \(jsonData.count) bytes")

            return (allContacts.count, jsonData)
        }.value

        // Create backup file
        let backupId = UUID()
        let fileName = "\(backupId.uuidString).json"
        let fileURL = backupDirectoryURL.appendingPathComponent(fileName)

        try jsonData.write(to: fileURL)

        // Get file size
        let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
        let fileSize = attributes[.size] as? Int64 ?? 0

        // Create metadata
        let backup = ContactBackup(
            id: backupId,
            createdAt: Date(),
            contactCount: contactCount,
            fileSize: fileSize,
            fileName: fileName
        )

        // Save to metadata
        loadBackups()
        backups.insert(backup, at: 0)

        // Enforce max backups limit
        let maxBackups = settings.maxBackups
        if backups.count > maxBackups {
            let backupsToDelete = Array(backups[maxBackups...])
            for oldBackup in backupsToDelete {
                try? deleteBackupFile(oldBackup)
            }
            backups = Array(backups.prefix(maxBackups))
        }

        saveBackupsMetadata()

        print("✅ [ContactsBackup] Backup created successfully: \(fileName)")
        print("   Contact count: \(contactCount)")
        print("   File size: \(backup.formattedSize)")

        // Track in analytics
        AnalyticsManager.shared.logEvent("contacts_backup_created", parameters: [
            "contact_count": contactCount,
            "file_size": fileSize
        ])

        return backup
    }

    // MARK: - Restore Backup

    enum RestoreMode {
        case merge      // Add to existing contacts
        case replace    // Delete all and import
    }

    func restoreBackup(_ backup: ContactBackup, mode: RestoreMode) async throws {
        print("♻️ [ContactsBackup] Starting restore - Mode: \(mode)")

        // Check authorization
        let authStatus = CNContactStore.authorizationStatus(for: .contacts)
        guard authStatus == .authorized else {
            throw BackupError.unauthorized
        }

        // Perform heavy operations on background thread
        try await Task.detached { [weak self] in
            guard let self = self else {
                throw BackupError.importFailed
            }

            // Read backup file
            let fileURL = self.backupDirectoryURL.appendingPathComponent(backup.fileName)
            guard self.fileManager.fileExists(atPath: fileURL.path) else {
                throw BackupError.backupFileNotFound
            }

            let jsonData = try Data(contentsOf: fileURL)

            // Decode JSON
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let backupData = try decoder.decode(ContactsBackupData.self, from: jsonData)
            print("📇 [ContactsBackup] Loaded \(backupData.contacts.count) contacts from backup (version \(backupData.version))")

            if mode == .replace {
                // Delete all existing contacts
                try await self.deleteAllContacts()
                print("🗑️ [ContactsBackup] Deleted all existing contacts")
            }

            // Import contacts
            let saveRequest = CNSaveRequest()

            for serializableContact in backupData.contacts {
                let mutableContact = serializableContact.toCNContact()
                saveRequest.add(mutableContact, toContainerWithIdentifier: nil)
            }

            try self.contactStore.execute(saveRequest)

            print("✅ [ContactsBackup] Restore completed - \(backupData.contacts.count) contacts")

            // Track in analytics
            await MainActor.run {
                AnalyticsManager.shared.logEvent("contacts_backup_restored", parameters: [
                    "contact_count": backupData.contacts.count,
                    "mode": mode == .merge ? "merge" : "replace"
                ])
            }
        }.value
    }

    private func deleteAllContacts() async throws {
        let fetchRequest = CNContactFetchRequest(keysToFetch: [CNContactIdentifierKey as CNKeyDescriptor])

        var contactsToDelete: [CNContact] = []
        try contactStore.enumerateContacts(with: fetchRequest) { contact, _ in
            contactsToDelete.append(contact)
        }

        let saveRequest = CNSaveRequest()
        for contact in contactsToDelete {
            let mutableContact = contact.mutableCopy() as! CNMutableContact
            saveRequest.delete(mutableContact)
        }

        try contactStore.execute(saveRequest)
    }

    // MARK: - Delete Backup

    func deleteBackup(_ backup: ContactBackup) throws {
        print("🗑️ [ContactsBackup] Deleting backup: \(backup.fileName)")

        try deleteBackupFile(backup)

        loadBackups()
        backups.removeAll { $0.id == backup.id }
        saveBackupsMetadata()

        print("✅ [ContactsBackup] Backup deleted")
    }

    private func deleteBackupFile(_ backup: ContactBackup) throws {
        let fileURL = backupDirectoryURL.appendingPathComponent(backup.fileName)
        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        }
    }

    func deleteBackups(_ backups: [ContactBackup]) throws {
        for backup in backups {
            try deleteBackup(backup)
        }
    }

    // MARK: - Auto Backup

    func checkAndPerformAutoBackup() async throws {
        guard settings.autoBackupEnabled else { return }

        let now = Date()
        let shouldBackup: Bool

        if let lastBackup = settings.lastAutoBackupDate {
            let daysSinceLastBackup = Calendar.current.dateComponents([.day], from: lastBackup, to: now).day ?? 0
            shouldBackup = daysSinceLastBackup >= settings.backupFrequency.days
        } else {
            shouldBackup = true
        }

        if shouldBackup {
            print("⏰ [ContactsBackup] Performing auto backup...")
            _ = try await createBackup()

            var updatedSettings = settings
            updatedSettings.lastAutoBackupDate = now
            settings = updatedSettings

            print("✅ [ContactsBackup] Auto backup completed")
        }
    }

    // MARK: - Errors

    enum BackupError: LocalizedError {
        case unauthorized
        case backupFileNotFound
        case importFailed

        var errorDescription: String? {
            switch self {
            case .unauthorized:
                return "Contacts access is not authorized. Please enable in Settings."
            case .backupFileNotFound:
                return "Backup file not found. It may have been deleted."
            case .importFailed:
                return "Failed to import contacts from backup."
            }
        }
    }
}
