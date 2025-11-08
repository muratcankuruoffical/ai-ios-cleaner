//
//  BackupDetailView.swift
//  AI Cleaner
//
//  UI for viewing backup details and restoring individual contacts
//

import SwiftUI
import Contacts

struct BackupDetailView: View {
    let backup: ContactBackup
    @StateObject private var viewModel: BackupDetailViewModel
    @Environment(\.dismiss) private var dismiss

    init(backup: ContactBackup) {
        self.backup = backup
        _viewModel = StateObject(wrappedValue: BackupDetailViewModel(backup: backup))
    }

    var body: some View {
        ZStack {
            CleanerTheme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Backup Info Header
                    backupInfoCard

                    // Contacts List
                    if viewModel.isLoading {
                        loadingView
                    } else if viewModel.contacts.isEmpty {
                        emptyStateView
                    } else {
                        contactsListCard
                    }

                    // Restore Selected Button
                    if !viewModel.selectedContactIds.isEmpty {
                        restoreSelectedButton
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Backup Details")
        .navigationBarTitleDisplayMode(.large)
        .preferredColorScheme(.dark)
        .task {
            await viewModel.loadContacts()
        }
        .alert("Restore Contacts?", isPresented: $viewModel.showingRestoreConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Merge with Existing") {
                Task {
                    await viewModel.restoreSelectedContacts(mode: .merge)
                }
            }
            Button("Replace All", role: .destructive) {
                Task {
                    await viewModel.restoreSelectedContacts(mode: .replace)
                }
            }
        } message: {
            Text("Restore \(viewModel.selectedContactIds.count) contact(s)?\n\nMerge: Add to existing contacts\nReplace: Delete all and import selected")
        }
        .alert("Error", isPresented: $viewModel.showingError) {
            Button("OK") { }
        } message: {
            if let error = viewModel.lastError {
                Text(error)
            }
        }
        .alert("Success", isPresented: $viewModel.showingSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("\(viewModel.restoredContactCount) contact(s) restored successfully!")
        }
    }

    // MARK: - Backup Info Card

    private var backupInfoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 48))
                    .foregroundColor(CleanerTheme.primary)

                VStack(alignment: .leading, spacing: 4) {
                    Text(backup.displayName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(CleanerTheme.textPrimary)

                    Text(backup.formattedDate)
                        .font(.system(size: 14))
                        .foregroundColor(CleanerTheme.textSecondary)
                }

                Spacer()
            }

            Divider()
                .background(CleanerTheme.cardBackground)

            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CONTACTS")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(CleanerTheme.textSecondary)
                    Text("\(backup.contactCount)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(CleanerTheme.textPrimary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("SIZE")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(CleanerTheme.textSecondary)
                    Text(backup.formattedSize)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(CleanerTheme.textPrimary)
                }
            }
        }
        .padding(20)
        .background(CleanerTheme.surface)
        .cornerRadius(16)
    }

    // MARK: - Contacts List

    private var contactsListCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Contacts")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(CleanerTheme.textPrimary)

                Spacer()

                Button(action: {
                    viewModel.toggleSelectAll()
                }) {
                    Text(viewModel.isAllSelected ? "Deselect All" : "Select All")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(CleanerTheme.primary)
                }
            }

            ForEach(viewModel.contacts) { contact in
                ContactRowView(
                    contact: contact,
                    isSelected: viewModel.selectedContactIds.contains(contact.id),
                    onSelect: {
                        viewModel.toggleSelection(contact)
                    }
                )
            }
        }
        .padding(20)
        .background(CleanerTheme.surface)
        .cornerRadius(16)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(CleanerTheme.primary)

            Text("Loading contacts...")
                .font(.system(size: 14))
                .foregroundColor(CleanerTheme.textSecondary)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(CleanerTheme.surface)
        .cornerRadius(16)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(CleanerTheme.textSecondary)

            VStack(spacing: 8) {
                Text("No Contacts Found")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(CleanerTheme.textPrimary)

                Text("This backup file appears to be empty or corrupted")
                    .font(.system(size: 14))
                    .foregroundColor(CleanerTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(CleanerTheme.surface)
        .cornerRadius(16)
    }

    // MARK: - Restore Button

    private var restoreSelectedButton: some View {
        Button(action: {
            viewModel.showingRestoreConfirm = true
        }) {
            HStack(spacing: 12) {
                if viewModel.isRestoring {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "arrow.counterclockwise.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                }

                Text(viewModel.isRestoring ? "Restoring..." : "Restore Selected (\(viewModel.selectedContactIds.count))")
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: [CleanerTheme.accentGreen, Color(hex: "#00AA44")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: CleanerTheme.accentGreen.opacity(0.4), radius: 12, x: 0, y: 6)
        }
        .disabled(viewModel.isRestoring)
    }
}

// MARK: - Contact Row View

struct ContactRowView: View {
    let contact: BackupContactItem
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Selection checkbox
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? CleanerTheme.primary : CleanerTheme.textSecondary)
                    .frame(width: 32, height: 32)

                // Contact info
                VStack(alignment: .leading, spacing: 6) {
                    Text(contact.displayName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(CleanerTheme.textPrimary)
                        .lineLimit(1)

                    if !contact.phoneNumbers.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "phone.fill")
                                .font(.system(size: 11))
                            Text(contact.phoneNumbers.first ?? "")
                                .font(.system(size: 13))
                                .lineLimit(1)
                        }
                        .foregroundColor(CleanerTheme.textSecondary)
                    } else if !contact.emailAddresses.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 11))
                            Text(contact.emailAddresses.first ?? "")
                                .font(.system(size: 13))
                                .lineLimit(1)
                        }
                        .foregroundColor(CleanerTheme.textSecondary)
                    }
                }

                Spacer(minLength: 8)
            }
            .padding(12)
            .background(CleanerTheme.cardBackground)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        BackupDetailView(backup: ContactBackup(
            id: UUID(),
            createdAt: Date(),
            contactCount: 6,
            fileSize: 5120,
            fileName: "test.json"
        ))
    }
}
