//
//  SettingsView.swift
//  AI Cleaner
//
//  Settings and preferences screen - Dark Theme
//

import SwiftUI
import CoreData

struct SettingsView: View {
    @StateObject private var revenueCat = RevenueCatManager.shared
    @StateObject private var analytics = AnalyticsManager.shared
    @State private var showingPaywall = false

    var body: some View {
        ZStack {
            CleanerTheme.background
                .ignoresSafeArea()

            List {
            // Subscription Section
            Section {
                if revenueCat.isProUser {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Pro Member")
                                .font(.headline)
                            Text("Thank you for your support!")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "crown.fill")
                            .foregroundColor(.yellow)
                    }
                } else {
                    Button(action: {
                        showingPaywall = true
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Upgrade to Pro")
                                    .font(.headline)
                                Text("Unlock all features")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "crown.fill")
                                .foregroundColor(.yellow)
                        }
                    }
                }
            }

            // General Section
            Section("General") {
                NavigationLink(destination: Text("About")) {
                    Label("About", systemImage: "info.circle")
                }

                NavigationLink(destination: Text("Privacy Policy")) {
                    Label("Privacy Policy", systemImage: "hand.raised")
                }

                Button(action: {
                    // Open app settings
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Label("App Permissions", systemImage: "gear")
                }
            }

            // Analytics Section
            Section {
                Toggle(isOn: $analytics.isAnalyticsEnabled) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Analytics")
                        Text("Help improve the app by sharing anonymous usage data")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } footer: {
                Text("Analytics data is anonymous and helps us improve the app. No photos are ever transmitted.")
            }

            // Data Section
            Section("Data") {
                Button(action: clearCache) {
                    Label("Clear Cache", systemImage: "trash")
                        .foregroundColor(.red)
                }

                Button(action: resetApp) {
                    Label("Reset App", systemImage: "arrow.clockwise")
                        .foregroundColor(.red)
                }
            }

            // Support Section
            Section("Support") {
                Button(action: {
                    // Open email
                    if let url = URL(string: "mailto:support@aicleaner.app") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Label("Contact Support", systemImage: "envelope")
                }

                Button(action: {
                    // Rate app
                }) {
                    Label("Rate App", systemImage: "star")
                }

                NavigationLink(destination: Text("Share with Friends")) {
                    Label("Share with Friends", systemImage: "square.and.arrow.up")
                }
            }

            // App Info
            Section {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                        .foregroundColor(.secondary)
                }
            }
            }
            .scrollContentBackground(.hidden)
            .listStyle(.insetGrouped)
        }
        .navigationTitle("Settings")
        .preferredColorScheme(.dark)
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
