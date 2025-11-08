//
//  ContactsCleanupView.swift
//  AI Cleaner
//
//  UI for cleaning duplicate and similar contacts
//

import SwiftUI
import Contacts
import CoreData

struct ContactsCleanupView: View {
    let results: ContactsCleaner.ContactsScanResults
    @EnvironmentObject var scanCoordinator: ScanCoordinator

    @State private var selectedGroup: ContactsCleaner.DuplicateContactGroup?
    @State private var showingMergeConfirm = false
    @State private var showingDeleteConfirm = false
    @State private var processedGroupIds = Set<String>()
    @State private var isProcessing = false

    var availableGroups: [ContactsCleaner.DuplicateContactGroup] {
        results.duplicateGroups.filter { group in
            !processedGroupIds.contains(group.contacts.first?.identifier ?? "")
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Stats
                statsHeader

                // Duplicate Groups
                if !availableGroups.isEmpty {
                    duplicateGroupsSection
                } else {
                    emptyState
                }

                // Other Issues (without phone/email)
                otherIssuesSection
            }
            .padding()
        }
        .navigationTitle("Duplicate Contacts")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $selectedGroup) { group in
            ContactGroupDetailView(
                group: group,
                onMerge: { mergedGroup in
                    handleMerge(group: mergedGroup)
                },
                onDelete: { deletedGroup in
                    handleDelete(group: deletedGroup)
                }
            )
        }
    }

    // MARK: - Header Stats

    private var statsHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "person.2.fill")
                    .font(.largeTitle)
                    .foregroundColor(.brown)

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(results.totalDuplicates) Duplicates")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Found in \(results.duplicateGroups.count) groups")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            if !availableGroups.isEmpty {
                Text("Review and merge or delete duplicate contacts to clean up your address book")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.brown.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Duplicate Groups Section

    private var duplicateGroupsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Duplicate Groups")
                .font(.headline)

            ForEach(Array(availableGroups.enumerated()), id: \.element.contacts.first?.identifier) { index, group in
                DuplicateGroupCard(group: group, index: index + 1)
                    .onTapGesture {
                        selectedGroup = group
                    }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)

            Text("All Clean!")
                .font(.title2)
                .fontWeight(.bold)

            Text("No duplicate contacts found")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Other Issues Section

    private var otherIssuesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !results.incompleteContacts.isEmpty ||
               !results.contactsWithoutPhone.isEmpty ||
               !results.contactsWithoutEmail.isEmpty {

                Text("Other Issues")
                    .font(.headline)

                if !results.incompleteContacts.isEmpty {
                    InfoCard(
                        icon: "exclamationmark.triangle",
                        title: "Incomplete Contacts",
                        count: results.incompleteContacts.count,
                        description: "Contacts without phone or email",
                        color: .orange
                    )
                }

                if !results.contactsWithoutPhone.isEmpty {
                    InfoCard(
                        icon: "phone.slash",
                        title: "No Phone Number",
                        count: results.contactsWithoutPhone.count,
                        description: "Contacts missing phone numbers",
                        color: .blue
                    )
                }

                if !results.contactsWithoutEmail.isEmpty {
                    InfoCard(
                        icon: "envelope.slash",
                        title: "No Email",
                        count: results.contactsWithoutEmail.count,
                        description: "Contacts missing email addresses",
                        color: .purple
                    )
                }
            }
        }
    }

    // MARK: - Actions

    private func handleMerge(group: ContactsCleaner.DuplicateContactGroup) {
        guard let primary = group.primaryContact else { return }

        isProcessing = true
        Task {
            do {
                print("📇 [ContactsCleanup] Merging \(group.duplicates.count) duplicates into primary contact")
                _ = try await ContactsCleaner.shared.mergeContacts(
                    keep: primary,
                    merge: group.duplicates
                )

                await MainActor.run {
                    processedGroupIds.insert(group.contacts.first?.identifier ?? "")
                    isProcessing = false
                    selectedGroup = nil

                    // Log activity to CoreData
                    let context = CoreDataStack.shared.viewContext
                    ActivityLog.createContactsActivity(
                        context: context,
                        count: group.duplicates.count,
                        category: "Merged \(group.duplicates.count) duplicate\(group.duplicates.count == 1 ? "" : "s")",
                        timestamp: Date()
                    )
                    CoreDataStack.shared.save(context: context)
                    print("📇 [ContactsCleanup] ActivityLog created and saved")
                }
            } catch {
                print("❌ Merge error: \(error)")
                isProcessing = false
            }
        }
    }

    private func handleDelete(group: ContactsCleaner.DuplicateContactGroup) {
        isProcessing = true
        Task {
            do {
                print("📇 [ContactsCleanup] Deleting \(group.duplicates.count) duplicate contacts")
                try await ContactsCleaner.shared.deleteContacts(group.duplicates)

                await MainActor.run {
                    processedGroupIds.insert(group.contacts.first?.identifier ?? "")
                    isProcessing = false
                    selectedGroup = nil

                    // Log activity to CoreData
                    let context = CoreDataStack.shared.viewContext
                    ActivityLog.createContactsActivity(
                        context: context,
                        count: group.duplicates.count,
                        category: "Deleted \(group.duplicates.count) duplicate\(group.duplicates.count == 1 ? "" : "s")",
                        timestamp: Date()
                    )
                    CoreDataStack.shared.save(context: context)
                    print("📇 [ContactsCleanup] ActivityLog created and saved")
                }
            } catch {
                print("❌ Delete error: \(error)")
                isProcessing = false
            }
        }
    }
}

// MARK: - Duplicate Group Card

struct DuplicateGroupCard: View {
    let group: ContactsCleaner.DuplicateContactGroup
    let index: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Group \(index)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.brown)

                Spacer()

                Text(group.matchReason)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            // Contact names
            ForEach(group.contacts.prefix(3), id: \.identifier) { contact in
                HStack(spacing: 8) {
                    Image(systemName: contact == group.primaryContact ? "star.fill" : "person.fill")
                        .font(.caption)
                        .foregroundColor(contact == group.primaryContact ? .yellow : .gray)

                    Text(ContactsCleaner.shared.formatContactName(contact))
                        .font(.subheadline)
                        .fontWeight(contact == group.primaryContact ? .semibold : .regular)

                    if contact == group.primaryContact {
                        Text("(Keep)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            if group.contacts.count > 3 {
                Text("+ \(group.contacts.count - 3) more")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("Tap to review")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.brown.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Contact Group Detail View

struct ContactGroupDetailView: View {
    let group: ContactsCleaner.DuplicateContactGroup
    let onMerge: (ContactsCleaner.DuplicateContactGroup) -> Void
    let onDelete: (ContactsCleaner.DuplicateContactGroup) -> Void

    @Environment(\.dismiss) var dismiss
    @State private var showingMergeAlert = false
    @State private var showingDeleteAlert = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Match Reason
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        Text(group.matchReason)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)

                    // Primary Contact
                    if let primary = group.primaryContact {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Recommended to Keep")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            ContactDetailCard(contact: primary, isPrimary: true)
                        }
                    }

                    // Duplicates
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Duplicates (\(group.duplicates.count))")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        ForEach(group.duplicates, id: \.identifier) { contact in
                            ContactDetailCard(contact: contact, isPrimary: false)
                        }
                    }

                    // Actions
                    VStack(spacing: 12) {
                        Button(action: { showingMergeAlert = true }) {
                            HStack {
                                Image(systemName: "arrow.triangle.merge")
                                Text("Merge Contacts")
                            }
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }

                        Button(action: { showingDeleteAlert = true }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete Duplicates")
                            }
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Duplicate Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Merge Contacts?", isPresented: $showingMergeAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Merge", role: .destructive) {
                    onMerge(group)
                }
            } message: {
                Text("This will merge all contact information into one contact and delete the duplicates.")
            }
            .alert("Delete Duplicates?", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    onDelete(group)
                }
            } message: {
                Text("This will delete \(group.duplicates.count) duplicate contact(s). This action cannot be undone.")
            }
        }
    }
}

// MARK: - Contact Detail Card

struct ContactDetailCard: View {
    let contact: CNContact
    let isPrimary: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if isPrimary {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                }

                Text(ContactsCleaner.shared.formatContactName(contact))
                    .font(.headline)

                Spacer()
            }

            // Phone numbers
            ForEach(contact.phoneNumbers, id: \.identifier) { phone in
                HStack(spacing: 8) {
                    Image(systemName: "phone.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                    Text(phone.value.stringValue)
                        .font(.subheadline)
                }
            }

            // Emails
            ForEach(contact.emailAddresses, id: \.identifier) { email in
                HStack(spacing: 8) {
                    Image(systemName: "envelope.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Text(email.value as String)
                        .font(.subheadline)
                }
            }

            // Organization
            if !contact.organizationName.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "building.2.fill")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(contact.organizationName)
                        .font(.subheadline)
                }
            }
        }
        .padding()
        .background(isPrimary ? Color.yellow.opacity(0.1) : Color.gray.opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isPrimary ? Color.yellow : Color.gray.opacity(0.2), lineWidth: isPrimary ? 2 : 1)
        )
    }
}

// MARK: - Info Card

struct InfoCard: View {
    let icon: String
    let title: String
    let count: Int
    let description: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        ContactsCleanupView(
            results: ContactsCleaner.ContactsScanResults(
                duplicateGroups: [],
                contactsWithoutPhone: [],
                contactsWithoutEmail: [],
                incompleteContacts: []
            )
        )
    }
}
