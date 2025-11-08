//
//  BackupDetailViewModel.swift
//  AI Cleaner
//
//  ViewModel for BackupDetailView
//

import Foundation
import Contacts

struct BackupContactItem: Identifiable {
    let id: UUID
    let serializableContact: SerializableContact
    let displayName: String
    let phoneNumbers: [String]
    let emailAddresses: [String]

    init(from serializable: SerializableContact) {
        self.id = UUID()
        self.serializableContact = serializable

        // Create display name
        let fullName = [serializable.givenName, serializable.familyName]
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        if fullName.isEmpty {
            if !serializable.organizationName.isEmpty {
                self.displayName = serializable.organizationName
            } else if !serializable.emailAddresses.isEmpty {
                self.displayName = serializable.emailAddresses.first ?? "Unknown Contact"
            } else if !serializable.phoneNumbers.isEmpty {
                self.displayName = serializable.phoneNumbers.first?.number ?? "Unknown Contact"
            } else {
                self.displayName = "Unknown Contact"
            }
        } else {
            self.displayName = fullName
        }

        self.phoneNumbers = serializable.phoneNumbers.map { $0.number }
        self.emailAddresses = serializable.emailAddresses
    }
}

@MainActor
class BackupDetailViewModel: ObservableObject {
    @Published var contacts: [BackupContactItem] = []
    @Published var selectedContactIds: Set<UUID> = []
    @Published var isLoading = false
    @Published var isRestoring = false
    @Published var showingRestoreConfirm = false
    @Published var showingError = false
    @Published var showingSuccess = false
    @Published var lastError: String?

    private let backup: ContactBackup
    private let backupManager = ContactsBackupManager.shared
    private let fileManager = FileManager.default

    init(backup: ContactBackup) {
        self.backup = backup
    }

    var isAllSelected: Bool {
        !contacts.isEmpty && selectedContactIds.count == contacts.count
    }

    // MARK: - Load Contacts

    func loadContacts() async {
        isLoading = true

        do {
            // Get backup directory
            let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let backupDirectoryURL = documentsURL.appendingPathComponent("ContactsBackups")
            let fileURL = backupDirectoryURL.appendingPathComponent(backup.fileName)

            // Check file exists
            guard fileManager.fileExists(atPath: fileURL.path) else {
                throw BackupDetailError.fileNotFound
            }

            // Perform heavy operations on background thread
            let loadedContacts = try await Task.detached { [fileURL] () -> [BackupContactItem] in
                // Read file
                let jsonData = try Data(contentsOf: fileURL)

                // Decode JSON
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601

                let backupData = try decoder.decode(ContactsBackupData.self, from: jsonData)

                // Convert to BackupContactItem
                return backupData.contacts.map { BackupContactItem(from: $0) }
            }.value

            contacts = loadedContacts
            print("✅ [BackupDetail] Loaded \(contacts.count) contacts")

        } catch {
            print("❌ [BackupDetail] Failed to load contacts: \(error.localizedDescription)")
            lastError = "Failed to load contacts: \(error.localizedDescription)"
            showingError = true
        }

        isLoading = false
    }

    // MARK: - Selection

    func toggleSelection(_ contact: BackupContactItem) {
        if selectedContactIds.contains(contact.id) {
            selectedContactIds.remove(contact.id)
        } else {
            selectedContactIds.insert(contact.id)
        }
    }

    func toggleSelectAll() {
        if isAllSelected {
            selectedContactIds.removeAll()
        } else {
            selectedContactIds = Set(contacts.map { $0.id })
        }
    }

    // MARK: - Restore Selected

    func restoreSelectedContacts(mode: ContactsBackupManager.RestoreMode) async {
        // Check permissions first
        let authStatus = CNContactStore.authorizationStatus(for: .contacts)

        if authStatus == .notDetermined {
            let granted = await ContactsCleaner.shared.requestAuthorization()
            if !granted {
                lastError = "Contacts access is required to restore contacts."
                showingError = true
                return
            }
        } else if authStatus != .authorized {
            lastError = "Contacts access is not authorized. Please enable in Settings."
            showingError = true
            return
        }

        isRestoring = true

        do {
            // Get selected contacts
            let selectedContacts = contacts
                .filter { selectedContactIds.contains($0.id) }
                .map { $0.serializableContact }

            guard !selectedContacts.isEmpty else {
                throw BackupDetailError.noContactsSelected
            }

            print("♻️ [BackupDetail] Restoring \(selectedContacts.count) contacts - Mode: \(mode)")

            // Perform restore on background thread
            try await Task.detached { [weak self] in
                guard let self = self else { return }

                let contactStore = CNContactStore()

                if mode == .replace {
                    // Delete all existing contacts
                    try await self.deleteAllContacts(using: contactStore)
                    print("🗑️ [BackupDetail] Deleted all existing contacts")
                }

                // Import selected contacts
                let saveRequest = CNSaveRequest()

                for serializableContact in selectedContacts {
                    let mutableContact = serializableContact.toCNContact()
                    saveRequest.add(mutableContact, toContainerWithIdentifier: nil)
                }

                try contactStore.execute(saveRequest)

                print("✅ [BackupDetail] Restored \(selectedContacts.count) contacts")

                // Track in analytics
                await MainActor.run {
                    AnalyticsManager.shared.logEvent("contacts_selective_restore", parameters: [
                        "contact_count": selectedContacts.count,
                        "mode": mode == .merge ? "merge" : "replace"
                    ])
                }
            }.value

            showingSuccess = true
            selectedContactIds.removeAll()

        } catch {
            print("❌ [BackupDetail] Restore failed: \(error.localizedDescription)")
            lastError = error.localizedDescription
            showingError = true
        }

        isRestoring = false
    }

    private func deleteAllContacts(using contactStore: CNContactStore) async throws {
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

    // MARK: - Errors

    enum BackupDetailError: LocalizedError {
        case fileNotFound
        case noContactsSelected

        var errorDescription: String? {
            switch self {
            case .fileNotFound:
                return "Backup file not found. It may have been deleted."
            case .noContactsSelected:
                return "Please select at least one contact to restore."
            }
        }
    }
}
