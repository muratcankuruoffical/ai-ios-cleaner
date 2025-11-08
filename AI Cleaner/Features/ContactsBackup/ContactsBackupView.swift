//
//  ContactsBackupView.swift
//  AI Cleaner
//
//  UI for backing up and restoring contacts
//

import SwiftUI
import Contacts

struct ContactsBackupView: View {
    @StateObject private var viewModel = ContactsBackupViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            CleanerTheme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerCard

                    // Auto Backup Settings
                    autoBackupCard

                    // Backups List
                    if viewModel.backups.isEmpty {
                        emptyStateView
                    } else {
                        backupsListCard
                    }

                    // Create Backup Button
                    createBackupButton
                }
                .padding()
            }
        }
        .navigationTitle("Contact Backup")
        .navigationBarTitleDisplayMode(.large)
        .preferredColorScheme(.dark)
        .task {
            await viewModel.loadBackups()
        }
        .alert("Restore Backup?", isPresented: $viewModel.showingRestoreConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Merge with Existing") {
                Task {
                    await viewModel.restoreBackup(mode: .merge)
                }
            }
            Button("Replace All", role: .destructive) {
                Task {
                    await viewModel.restoreBackup(mode: .replace)
                }
            }
        } message: {
            if let backup = viewModel.selectedBackup {
                Text("Restore \(backup.contactCount) contacts from \(backup.formattedDate)?\n\nMerge: Add to existing contacts\nReplace: Delete all and import from backup")
            }
        }
        .alert("Error", isPresented: $viewModel.showingError) {
            Button("OK") { }
        } message: {
            if let error = viewModel.lastError {
                Text(error)
            }
        }
        .alert("Delete Backups?", isPresented: $viewModel.showingDeleteConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                viewModel.deleteSelectedBackups()
            }
        } message: {
            Text("Delete \(viewModel.selectedBackupIds.count) backup(s)? This cannot be undone.")
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                Image(systemName: "person.2.crop.square.stack")
                    .font(.system(size: 48))
                    .foregroundColor(CleanerTheme.primary)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Contact Backup")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(CleanerTheme.textPrimary)

                    Text("\(viewModel.backups.count) backup\(viewModel.backups.count == 1 ? "" : "s") available")
                        .font(.system(size: 14))
                        .foregroundColor(CleanerTheme.textSecondary)
                }

                Spacer()
            }

            Text("Protect your contacts with automatic backups. Restore anytime if you accidentally delete a contact.")
                .font(.system(size: 14))
                .foregroundColor(CleanerTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .background(CleanerTheme.surface)
        .cornerRadius(16)
    }

    // MARK: - Auto Backup Settings

    private var autoBackupCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Auto Backup")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(CleanerTheme.textPrimary)

                Spacer()

                Toggle("", isOn: $viewModel.autoBackupEnabled)
                    .labelsHidden()
                    .tint(CleanerTheme.primary)
                    .onChange(of: viewModel.autoBackupEnabled) { _ in
                        viewModel.onAutoBackupToggled()
                    }
            }

            if viewModel.autoBackupEnabled {
                VStack(spacing: 12) {
                    Divider()
                        .background(CleanerTheme.cardBackground)

                    HStack {
                        Text("Frequency")
                            .font(.system(size: 15))
                            .foregroundColor(CleanerTheme.textSecondary)

                        Spacer()

                        Picker("Frequency", selection: $viewModel.backupFrequency) {
                            ForEach(ContactsBackupSettings.BackupFrequency.allCases, id: \.self) { frequency in
                                Text(frequency.rawValue).tag(frequency)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 180)
                        .onChange(of: viewModel.backupFrequency) { _ in
                            viewModel.onFrequencyChanged()
                        }
                    }

                    if let lastBackup = viewModel.lastAutoBackupDate {
                        HStack {
                            Text("Last Backup")
                                .font(.system(size: 15))
                                .foregroundColor(CleanerTheme.textSecondary)

                            Spacer()

                            Text(lastBackup, style: .relative)
                                .font(.system(size: 15))
                                .foregroundColor(CleanerTheme.textPrimary)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(CleanerTheme.surface)
        .cornerRadius(16)
    }

    // MARK: - Backups List

    private var backupsListCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Backups")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(CleanerTheme.textPrimary)

                Spacer()

                if !viewModel.backups.isEmpty {
                    Button(action: {
                        viewModel.toggleSelectAll()
                    }) {
                        Text(viewModel.isAllSelected ? "Deselect All" : "Select All")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(CleanerTheme.primary)
                    }
                }
            }

            ForEach(viewModel.backups) { backup in
                BackupRow(
                    backup: backup,
                    isSelected: viewModel.selectedBackupIds.contains(backup.id),
                    onSelect: {
                        viewModel.toggleSelection(backup)
                    },
                    onRestore: {
                        viewModel.selectedBackup = backup
                        viewModel.showingRestoreConfirm = true
                    }
                )
            }

            if !viewModel.selectedBackupIds.isEmpty {
                Button(action: {
                    viewModel.showingDeleteConfirm = true
                }) {
                    HStack {
                        Image(systemName: "trash")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Delete Selected (\(viewModel.selectedBackupIds.count))")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(CleanerTheme.accentRed)
                    .cornerRadius(12)
                }
            }
        }
        .padding(20)
        .background(CleanerTheme.surface)
        .cornerRadius(16)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundColor(CleanerTheme.textSecondary)

            VStack(spacing: 8) {
                Text("No Backups Yet")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(CleanerTheme.textPrimary)

                Text("Create your first backup to protect your contacts")
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

    // MARK: - Create Backup Button

    private var createBackupButton: some View {
        Button(action: {
            Task {
                await viewModel.createBackup()
            }
        }) {
            HStack(spacing: 12) {
                if viewModel.isCreatingBackup {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                }

                Text(viewModel.isCreatingBackup ? "Creating Backup..." : "Create New Backup")
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: [CleanerTheme.primary, Color(hex: "#0066DD")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: CleanerTheme.primary.opacity(0.4), radius: 12, x: 0, y: 6)
        }
        .disabled(viewModel.isCreatingBackup)
    }
}

// MARK: - Backup Row

struct BackupRow: View {
    let backup: ContactBackup
    let isSelected: Bool
    let onSelect: () -> Void
    let onRestore: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Selection checkbox
                Button(action: onSelect) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22))
                        .foregroundColor(isSelected ? CleanerTheme.primary : CleanerTheme.textSecondary)
                        .frame(width: 32, height: 32)
                }

                // Backup info
                VStack(alignment: .leading, spacing: 8) {
                    Text(backup.displayName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(CleanerTheme.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: 16) {
                        HStack(spacing: 6) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 12))
                            Text("\(backup.contactCount)")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(CleanerTheme.textSecondary)

                        HStack(spacing: 6) {
                            Image(systemName: "internaldrive")
                                .font(.system(size: 12))
                            Text(backup.formattedSize)
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(CleanerTheme.textSecondary)
                    }
                }

                Spacer(minLength: 8)

                // View Details chevron
                NavigationLink(destination: BackupDetailView(backup: backup)) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(CleanerTheme.textSecondary)
                        .frame(width: 32, height: 32)
                }
            }
            .padding(16)

            // Action buttons row
            HStack(spacing: 12) {
                // View Details button
                NavigationLink(destination: BackupDetailView(backup: backup)) {
                    HStack(spacing: 6) {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 13, weight: .semibold))
                        Text("View Details")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(CleanerTheme.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(CleanerTheme.primary.opacity(0.15))
                    .cornerRadius(8)
                }

                // Restore button
                Button(action: onRestore) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Restore")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(CleanerTheme.accentGreen)
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(CleanerTheme.cardBackground)
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        ContactsBackupView()
    }
}
