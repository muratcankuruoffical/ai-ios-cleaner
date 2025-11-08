//
//  ContactsBackupViewModel.swift
//  AI Cleaner
//
//  ViewModel for ContactsBackupView
//

import Foundation
import Contacts

@MainActor
class ContactsBackupViewModel: ObservableObject {
    @Published var backups: [ContactBackup] = []
    @Published var selectedBackupIds: Set<UUID> = []
    @Published var autoBackupEnabled: Bool = false
    @Published var backupFrequency: ContactsBackupSettings.BackupFrequency = .weekly
    @Published var lastAutoBackupDate: Date?

    @Published var isCreatingBackup = false
    @Published var showingRestoreConfirm = false
    @Published var showingDeleteConfirm = false
    @Published var showingError = false
    @Published var lastError: String?
    @Published var selectedBackup: ContactBackup?

    private let backupManager = ContactsBackupManager.shared

    init() {
        loadSettings()
    }

    var isAllSelected: Bool {
        !backups.isEmpty && selectedBackupIds.count == backups.count
    }

    // MARK: - Load Data

    func loadBackups() async {
        backupManager.refreshBackups()
        backups = backupManager.backups
    }

    private func loadSettings() {
        let settings = backupManager.settings
        autoBackupEnabled = settings.autoBackupEnabled
        backupFrequency = settings.backupFrequency
        lastAutoBackupDate = settings.lastAutoBackupDate
    }

    private func saveSettings() {
        var settings = backupManager.settings
        settings.autoBackupEnabled = autoBackupEnabled
        settings.backupFrequency = backupFrequency
        backupManager.settings = settings
    }

    // MARK: - Selection

    func toggleSelection(_ backup: ContactBackup) {
        if selectedBackupIds.contains(backup.id) {
            selectedBackupIds.remove(backup.id)
        } else {
            selectedBackupIds.insert(backup.id)
        }
    }

    func toggleSelectAll() {
        if isAllSelected {
            selectedBackupIds.removeAll()
        } else {
            selectedBackupIds = Set(backups.map { $0.id })
        }
    }

    // MARK: - Create Backup

    func createBackup() async {
        // Check permissions first
        let authStatus = CNContactStore.authorizationStatus(for: .contacts)

        if authStatus == .notDetermined {
            // Request permission
            let granted = await ContactsCleaner.shared.requestAuthorization()
            if !granted {
                lastError = "Contacts access is required to create backups."
                showingError = true
                return
            }
        } else if authStatus != .authorized {
            lastError = "Contacts access is not authorized. Please enable in Settings."
            showingError = true
            return
        }

        isCreatingBackup = true

        do {
            let backup = try await backupManager.createBackup()
            await loadBackups()

            print("✅ [ContactsBackupVM] Backup created successfully")

        } catch {
            print("❌ [ContactsBackupVM] Backup creation failed: \(error.localizedDescription)")
            lastError = error.localizedDescription
            showingError = true
        }

        isCreatingBackup = false
    }

    // MARK: - Restore Backup

    func restoreBackup(mode: ContactsBackupManager.RestoreMode) async {
        guard let backup = selectedBackup else { return }

        do {
            try await backupManager.restoreBackup(backup, mode: mode)

            print("✅ [ContactsBackupVM] Backup restored successfully")

            // Reset selection
            selectedBackup = nil

        } catch {
            print("❌ [ContactsBackupVM] Restore failed: \(error.localizedDescription)")
            lastError = error.localizedDescription
            showingError = true
        }
    }

    // MARK: - Delete Backups

    func deleteSelectedBackups() {
        do {
            let backupsToDelete = backups.filter { selectedBackupIds.contains($0.id) }
            try backupManager.deleteBackups(backupsToDelete)

            Task {
                await loadBackups()
                selectedBackupIds.removeAll()
            }

            print("✅ [ContactsBackupVM] Deleted \(backupsToDelete.count) backups")

        } catch {
            print("❌ [ContactsBackupVM] Delete failed: \(error.localizedDescription)")
            lastError = error.localizedDescription
            showingError = true
        }
    }

    // MARK: - Settings Changes

    func onAutoBackupToggled() {
        saveSettings()

        if autoBackupEnabled {
            // Trigger auto backup check
            Task {
                do {
                    try await backupManager.checkAndPerformAutoBackup()
                    await loadBackups()
                    lastAutoBackupDate = backupManager.settings.lastAutoBackupDate
                } catch {
                    print("❌ [ContactsBackupVM] Auto backup failed: \(error.localizedDescription)")
                }
            }
        }
    }

    func onFrequencyChanged() {
        saveSettings()
    }
}
