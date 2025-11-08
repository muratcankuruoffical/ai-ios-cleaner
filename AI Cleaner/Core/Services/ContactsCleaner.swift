//
//  ContactsCleaner.swift
//  AI Cleaner
//
//  Service for finding duplicate and similar contacts
//

import Foundation
import Contacts

final class ContactsCleaner {
    static let shared = ContactsCleaner()

    private let contactStore = CNContactStore()

    private init() {}

    // MARK: - Authorization

    enum AuthorizationStatus {
        case authorized
        case denied
        case notDetermined
        case restricted
    }

    func checkAuthorizationStatus() -> AuthorizationStatus {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        switch status {
        case .authorized:
            return .authorized
        case .denied:
            return .denied
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        case .limited:
            return .authorized // Treat limited as authorized for our purposes
        @unknown default:
            return .denied
        }
    }

    func requestAuthorization() async -> Bool {
        do {
            return try await contactStore.requestAccess(for: .contacts)
        } catch {
            print("❌ Contacts authorization error: \(error)")
            return false
        }
    }

    // MARK: - Contact Issue Types

    enum ContactIssue: String, CaseIterable {
        case duplicate = "Duplicate"
        case similar = "Similar"
        case noPhone = "No Phone"
        case noEmail = "No Email"
        case incomplete = "Incomplete"
    }

    struct ContactGroup {
        let type: ContactIssue
        let contacts: [CNContact]
        let reason: String

        var count: Int { contacts.count }
        var canDelete: Bool {
            type == .duplicate || type == .similar
        }
    }

    struct DuplicateContactGroup: Identifiable {
        let contacts: [CNContact]
        let matchReason: String

        var id: String {
            contacts.first?.identifier ?? UUID().uuidString
        }

        // The contact to keep (usually the one with more info)
        var primaryContact: CNContact? {
            contacts.max { c1, c2 in
                completenessScore(c1) < completenessScore(c2)
            }
        }

        // Contacts that can be safely deleted
        var duplicates: [CNContact] {
            guard let primary = primaryContact else { return contacts }
            return contacts.filter { $0.identifier != primary.identifier }
        }

        private func completenessScore(_ contact: CNContact) -> Int {
            var score = 0
            if !contact.phoneNumbers.isEmpty { score += 10 }
            if !contact.emailAddresses.isEmpty { score += 10 }
            if !contact.postalAddresses.isEmpty { score += 5 }
            if ((contact.birthday?.description.isEmpty) == nil) ?? false { score += 5 }
            if !contact.organizationName.isEmpty { score += 3 }
            if contact.imageDataAvailable { score += 5 }
            return score
        }
    }

    // MARK: - Scan Contacts

    func scanContacts(progressHandler: ((Int, Int) -> Void)? = nil) async -> ContactsScanResults {
        print("\n📇 SCANNING CONTACTS...")

        var duplicateGroups: [DuplicateContactGroup] = []
        var contactsWithoutPhone: [CNContact] = []
        var contactsWithoutEmail: [CNContact] = []
        var incompleteContacts: [CNContact] = []

        do {
            // Fetch all contacts
            let keysToFetch: [CNKeyDescriptor] = [
                CNContactGivenNameKey as CNKeyDescriptor,
                CNContactFamilyNameKey as CNKeyDescriptor,
                CNContactPhoneNumbersKey as CNKeyDescriptor,
                CNContactEmailAddressesKey as CNKeyDescriptor,
                CNContactPostalAddressesKey as CNKeyDescriptor,
                CNContactOrganizationNameKey as CNKeyDescriptor,
                CNContactBirthdayKey as CNKeyDescriptor,
                CNContactImageDataAvailableKey as CNKeyDescriptor
            ]

            let request = CNContactFetchRequest(keysToFetch: keysToFetch)
            var allContacts: [CNContact] = []

            try contactStore.enumerateContacts(with: request) { contact, _ in
                allContacts.append(contact)
            }

            print("   Found \(allContacts.count) total contacts")

            // Find duplicates and similar contacts
            duplicateGroups = findDuplicates(in: allContacts, progressHandler: progressHandler)

            // Find contacts with issues
            for (index, contact) in allContacts.enumerated() {
                progressHandler?(index, allContacts.count)

                // No phone number
                if contact.phoneNumbers.isEmpty {
                    contactsWithoutPhone.append(contact)
                }

                // No email
                if contact.emailAddresses.isEmpty {
                    contactsWithoutEmail.append(contact)
                }

                // Incomplete (no phone AND no email)
                if contact.phoneNumbers.isEmpty && contact.emailAddresses.isEmpty {
                    incompleteContacts.append(contact)
                }
            }

            print("   📊 Results:")
            print("      Duplicate groups: \(duplicateGroups.count)")
            print("      Contacts without phone: \(contactsWithoutPhone.count)")
            print("      Contacts without email: \(contactsWithoutEmail.count)")
            print("      Incomplete contacts: \(incompleteContacts.count)")

        } catch {
            print("❌ Error scanning contacts: \(error)")
        }

        return ContactsScanResults(
            duplicateGroups: duplicateGroups,
            contactsWithoutPhone: contactsWithoutPhone,
            contactsWithoutEmail: contactsWithoutEmail,
            incompleteContacts: incompleteContacts
        )
    }

    struct ContactsScanResults {
        let duplicateGroups: [DuplicateContactGroup]
        let contactsWithoutPhone: [CNContact]
        let contactsWithoutEmail: [CNContact]
        let incompleteContacts: [CNContact]

        var totalDuplicates: Int {
            duplicateGroups.reduce(0) { $0 + $1.duplicates.count }
        }
    }

    // MARK: - Find Duplicates

    private func findDuplicates(in contacts: [CNContact], progressHandler: ((Int, Int) -> Void)?) -> [DuplicateContactGroup] {
        var groups: [DuplicateContactGroup] = []
        var processedIds = Set<String>()

        for (index, contact) in contacts.enumerated() {
            progressHandler?(index, contacts.count)

            if processedIds.contains(contact.identifier) {
                continue
            }

            var matchingContacts: [CNContact] = [contact]

            // Find exact matches by phone number
            for otherContact in contacts {
                if otherContact.identifier == contact.identifier ||
                   processedIds.contains(otherContact.identifier) {
                    continue
                }

                // Check phone numbers
                let contactPhones = Set(contact.phoneNumbers.map { normalizePhone($0.value.stringValue) })
                let otherPhones = Set(otherContact.phoneNumbers.map { normalizePhone($0.value.stringValue) })

                if !contactPhones.isEmpty && !otherPhones.isEmpty &&
                   !contactPhones.intersection(otherPhones).isEmpty {
                    matchingContacts.append(otherContact)
                    processedIds.insert(otherContact.identifier)
                    continue
                }

                // Check email addresses
                let contactEmails = Set(contact.emailAddresses.map { $0.value as String }.map { $0.lowercased() })
                let otherEmails = Set(otherContact.emailAddresses.map { $0.value as String }.map { $0.lowercased() })

                if !contactEmails.isEmpty && !otherEmails.isEmpty &&
                   !contactEmails.intersection(otherEmails).isEmpty {
                    matchingContacts.append(otherContact)
                    processedIds.insert(otherContact.identifier)
                    continue
                }

                // Check similar names
                if areSimilarNames(contact, otherContact) {
                    matchingContacts.append(otherContact)
                    processedIds.insert(otherContact.identifier)
                }
            }

            if matchingContacts.count > 1 {
                let reason = determineMatchReason(matchingContacts)
                groups.append(DuplicateContactGroup(contacts: matchingContacts, matchReason: reason))
                processedIds.insert(contact.identifier)
            }
        }

        return groups
    }

    private func normalizePhone(_ phone: String) -> String {
        // Remove all non-digit characters
        let digits = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        // Keep last 10 digits (for US numbers) or 11 (with country code)
        return String(digits.suffix(10))
    }

    private func areSimilarNames(_ c1: CNContact, _ c2: CNContact) -> Bool {
        let name1 = "\(c1.givenName) \(c1.familyName)".lowercased().trimmingCharacters(in: .whitespaces)
        let name2 = "\(c2.givenName) \(c2.familyName)".lowercased().trimmingCharacters(in: .whitespaces)

        if name1.isEmpty || name2.isEmpty {
            return false
        }

        // Exact match
        if name1 == name2 {
            return true
        }

        // First name and last name both match
        if !c1.givenName.isEmpty && !c1.familyName.isEmpty &&
           c1.givenName.lowercased() == c2.givenName.lowercased() &&
           c1.familyName.lowercased() == c2.familyName.lowercased() {
            return true
        }

        // Calculate Levenshtein distance for fuzzy matching
        let distance = levenshteinDistance(name1, name2)
        let maxLength = max(name1.count, name2.count)
        let similarity = 1.0 - (Double(distance) / Double(maxLength))

        return similarity > 0.85 // 85% similar
    }

    private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let s1 = Array(s1)
        let s2 = Array(s2)
        var dist = [[Int]](repeating: [Int](repeating: 0, count: s2.count + 1), count: s1.count + 1)

        for i in 0...s1.count {
            dist[i][0] = i
        }

        for j in 0...s2.count {
            dist[0][j] = j
        }

        for i in 1...s1.count {
            for j in 1...s2.count {
                let cost = s1[i-1] == s2[j-1] ? 0 : 1
                dist[i][j] = min(
                    dist[i-1][j] + 1,
                    dist[i][j-1] + 1,
                    dist[i-1][j-1] + cost
                )
            }
        }

        return dist[s1.count][s2.count]
    }

    private func determineMatchReason(_ contacts: [CNContact]) -> String {
        // Check what they have in common
        let firstContact = contacts[0]

        for contact in contacts.dropFirst() {
            // Check phone
            let phones1 = Set(firstContact.phoneNumbers.map { normalizePhone($0.value.stringValue) })
            let phones2 = Set(contact.phoneNumbers.map { normalizePhone($0.value.stringValue) })

            if !phones1.intersection(phones2).isEmpty {
                return "Same phone number"
            }

            // Check email
            let emails1 = Set(firstContact.emailAddresses.map { ($0.value as String).lowercased() })
            let emails2 = Set(contact.emailAddresses.map { ($0.value as String).lowercased() })

            if !emails1.intersection(emails2).isEmpty {
                return "Same email address"
            }
        }

        return "Similar name"
    }

    // MARK: - Delete Contacts

    func deleteContacts(_ contacts: [CNContact]) async throws {
        let saveRequest = CNSaveRequest()

        for contact in contacts {
            let mutableContact = contact.mutableCopy() as! CNMutableContact
            saveRequest.delete(mutableContact)
        }

        try contactStore.execute(saveRequest)
        print("✅ Deleted \(contacts.count) contacts")
    }

    // MARK: - Merge Contacts

    func mergeContacts(keep: CNContact, merge: [CNContact]) async throws -> CNContact {
        let mutableContact = keep.mutableCopy() as! CNMutableContact

        // Merge phone numbers
        var allPhones = keep.phoneNumbers
        for contact in merge {
            for phone in contact.phoneNumbers {
                // Add if not already present
                let phoneNumber = normalizePhone(phone.value.stringValue)
                let alreadyHas = allPhones.contains { normalizePhone($0.value.stringValue) == phoneNumber }
                if !alreadyHas {
                    allPhones.append(phone)
                }
            }
        }
        mutableContact.phoneNumbers = allPhones

        // Merge emails
        var allEmails = keep.emailAddresses
        for contact in merge {
            for email in contact.emailAddresses {
                let emailString = (email.value as String).lowercased()
                let alreadyHas = allEmails.contains { ($0.value as String).lowercased() == emailString }
                if !alreadyHas {
                    allEmails.append(email)
                }
            }
        }
        mutableContact.emailAddresses = allEmails

        // Save merged contact
        let saveRequest = CNSaveRequest()
        saveRequest.update(mutableContact)

        // Delete old contacts
        for contact in merge {
            let toDelete = contact.mutableCopy() as! CNMutableContact
            saveRequest.delete(toDelete)
        }

        try contactStore.execute(saveRequest)
        print("✅ Merged \(merge.count) contacts into one")

        return mutableContact as CNContact
    }

    // MARK: - Helper Methods

    func formatContactName(_ contact: CNContact) -> String {
        if !contact.givenName.isEmpty || !contact.familyName.isEmpty {
            return "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
        } else if !contact.organizationName.isEmpty {
            return contact.organizationName
        } else if !contact.phoneNumbers.isEmpty {
            return contact.phoneNumbers.first!.value.stringValue
        } else if !contact.emailAddresses.isEmpty {
            return contact.emailAddresses.first!.value as String
        } else {
            return "Unknown Contact"
        }
    }

    /// Estimate storage size of a contact in bytes
    func estimateContactSize(_ contact: CNContact) -> Int64 {
        var size: Int64 = 2048 // Base size: ~2KB for basic contact info (name, dates, etc.)

        // Phone numbers: ~100 bytes each
        size += Int64(contact.phoneNumbers.count * 100)

        // Email addresses: ~50 bytes each
        size += Int64(contact.emailAddresses.count * 50)

        // Postal addresses: ~200 bytes each
        size += Int64(contact.postalAddresses.count * 200)

        // Organization name: ~100 bytes
        if !contact.organizationName.isEmpty {
            size += 100
        }

        // Contact photo: ~50KB if available
        if contact.imageDataAvailable {
            size += 51200 // 50KB
        }

        return size
    }

    /// Estimate total size of multiple contacts
    func estimateTotalSize(_ contacts: [CNContact]) -> Int64 {
        contacts.reduce(0) { $0 + estimateContactSize($1) }
    }
}
