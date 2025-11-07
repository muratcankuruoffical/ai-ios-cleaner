//
//  SettingsView.swift
//  AI Cleaner
//
//  Settings and preferences screen
//

import SwiftUI
import CoreData
internal import Combine

struct SettingsView: View {
    @StateObject private var revenueCat = RevenueCatManager.shared
    @StateObject private var analytics = AnalyticsManager.shared
    @State private var showingPaywall = false

    var body: some View {
        ZStack {
            CleanerTheme.background.ignoresSafeArea()

            List {
                // Subscription Section
                Section {
                    if revenueCat.isProUser {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(CleanerTheme.accent.opacity(0.15))
                                    .frame(width: 48, height: 48)

                                Image(systemName: "crown.fill")
                                    .foregroundColor(CleanerTheme.iconGray)
                                    .font(.system(size: 20, weight: .semibold))
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Pro Member")
                                    .cleanerFont(.headline)
                                    .foregroundColor(CleanerTheme.textPrimary)
                                Text("Thank you for your support!")
                                    .cleanerFont(.caption)
                                    .foregroundColor(CleanerTheme.textSecondary)
                            }

                            Spacer()
                        }
                    } else {
                        Button(action: {
                            showingPaywall = true
                        }) {
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(CleanerTheme.accent.opacity(0.15))
                                        .frame(width: 48, height: 48)

                                    Image(systemName: "crown.fill")
                                        .foregroundColor(CleanerTheme.iconGray)
                                        .font(.system(size: 20, weight: .semibold))
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Upgrade to Pro")
                                        .cleanerFont(.headline)
                                        .foregroundColor(CleanerTheme.textPrimary)
                                    Text("Unlock all features")
                                        .cleanerFont(.caption)
                                        .foregroundColor(CleanerTheme.textSecondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .foregroundColor(CleanerTheme.iconGray)
                                    .font(.system(size: 14, weight: .semibold))
                            }
                        }
                    }
                }
                .listRowBackground(CleanerTheme.cardBackground)

                // General Section
                Section("General") {
                    NavigationLink(destination: Text("About").foregroundColor(CleanerTheme.textPrimary)) {
                        Label {
                            Text("About")
                                .foregroundColor(CleanerTheme.textPrimary)
                        } icon: {
                            Image(systemName: "info.circle")
                                .foregroundColor(CleanerTheme.iconGray)
                        }
                    }

                    NavigationLink(destination: Text("Privacy Policy").foregroundColor(CleanerTheme.textPrimary)) {
                        Label {
                            Text("Privacy Policy")
                                .foregroundColor(CleanerTheme.textPrimary)
                        } icon: {
                            Image(systemName: "hand.raised")
                                .foregroundColor(CleanerTheme.iconGray)
                        }
                    }

                    Button(action: {
                        // Open app settings
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Label {
                            Text("App Permissions")
                                .foregroundColor(CleanerTheme.textPrimary)
                        } icon: {
                            Image(systemName: "gear")
                                .foregroundColor(CleanerTheme.iconGray)
                        }
                    }
                }
                .listRowBackground(CleanerTheme.cardBackground)

                // Analytics Section
                Section {
                    Toggle(isOn: $analytics.isAnalyticsEnabled) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Analytics")
                                .foregroundColor(CleanerTheme.textPrimary)
                            Text("Help improve the app by sharing anonymous usage data")
                                .cleanerFont(.caption)
                                .foregroundColor(CleanerTheme.textSecondary)
                        }
                    }
                    .tint(CleanerTheme.primary)
                } footer: {
                    Text("Analytics data is anonymous and helps us improve the app. No photos are ever transmitted.")
                        .foregroundColor(CleanerTheme.textTertiary)
                }
                .listRowBackground(CleanerTheme.cardBackground)

                // Data Section
                Section("Data") {
                    Button(action: clearCache) {
                        Label {
                            Text("Clear Cache")
                                .foregroundColor(CleanerTheme.accentRed)
                        } icon: {
                            Image(systemName: "trash")
                                .foregroundColor(CleanerTheme.accentRed)
                        }
                    }

                    Button(action: resetApp) {
                        Label {
                            Text("Reset App")
                                .foregroundColor(CleanerTheme.accentRed)
                        } icon: {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(CleanerTheme.accentRed)
                        }
                    }
                }
                .listRowBackground(CleanerTheme.cardBackground)

                // Support Section
                Section("Support") {
                    Button(action: {
                        // Open email
                        if let url = URL(string: "mailto:support@aicleaner.app") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Label {
                            Text("Contact Support")
                                .foregroundColor(CleanerTheme.textPrimary)
                        } icon: {
                            Image(systemName: "envelope")
                                .foregroundColor(CleanerTheme.iconGray)
                        }
                    }

                    Button(action: {
                        // Rate app
                    }) {
                        Label {
                            Text("Rate App")
                                .foregroundColor(CleanerTheme.textPrimary)
                        } icon: {
                            Image(systemName: "star")
                                .foregroundColor(CleanerTheme.iconGray)
                        }
                    }

                    NavigationLink(destination: Text("Share with Friends").foregroundColor(CleanerTheme.textPrimary)) {
                        Label {
                            Text("Share with Friends")
                                .foregroundColor(CleanerTheme.textPrimary)
                        } icon: {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(CleanerTheme.iconGray)
                        }
                    }
                }
                .listRowBackground(CleanerTheme.cardBackground)

                // App Info
                Section {
                    HStack {
                        Text("Version")
                            .foregroundColor(CleanerTheme.textPrimary)
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundColor(CleanerTheme.textSecondary)
                    }
                }
                .listRowBackground(CleanerTheme.cardBackground)
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Settings")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(CleanerTheme.textPrimary)
            }
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
        .onAppear {
            AnalyticsManager.shared.logSettingsOpened()
        }
    }

    private func clearCache() {
        // Clear Core Data cache
        let context = CoreDataStack.shared.viewContext
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = AssetFingerprint.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try context.execute(deleteRequest)
            try context.save()
        } catch {
            // Cache clear failed - continue anyway
        }
    }

    private func resetApp() {
        // Reset all data
        clearCache()

        // Reset user defaults
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        UserDefaults.standard.synchronize()
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        SettingsView()
    }
}
