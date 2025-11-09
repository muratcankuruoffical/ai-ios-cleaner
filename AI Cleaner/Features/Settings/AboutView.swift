//
//  AboutView.swift
//  AI Cleaner
//
//  About page with app information
//

import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            CleanerTheme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    // App Icon & Info
                    VStack(spacing: 20) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 24)
                                .fill(
                                    LinearGradient(
                                        colors: [CleanerTheme.primary.opacity(0.3), CleanerTheme.primary.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 120)

                            Image(systemName: "sparkles")
                                .font(.system(size: 60, weight: .bold))
                                .foregroundColor(CleanerTheme.primary)
                        }
                        .shadow(color: CleanerTheme.primary.opacity(0.3), radius: 20, x: 0, y: 10)

                        VStack(spacing: 8) {
                            Text("AI Cleaner")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(CleanerTheme.textPrimary)

                            Text("Smart Photo & Storage Manager")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(CleanerTheme.textSecondary)

                            Text("Version \(appVersion)")
                                .font(.system(size: 14))
                                .foregroundColor(CleanerTheme.textTertiary)
                        }
                    }
                    .padding(.top, 20)

                    // Description
                    VStack(alignment: .leading, spacing: 16) {
                        Text("About AI Cleaner")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(CleanerTheme.textPrimary)

                        Text("AI Cleaner is your intelligent photo library assistant, powered by advanced AI technology. We help you reclaim valuable storage space by identifying and removing duplicate photos, blurry shots, screenshots, and other unwanted content.")
                            .font(.system(size: 15))
                            .foregroundColor(CleanerTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(CleanerTheme.surface)
                    .cornerRadius(16)
                    .padding(.horizontal)

                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Key Features")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(CleanerTheme.textPrimary)

                        VStack(spacing: 12) {
                            FeatureRow(icon: "photo.on.rectangle.angled", title: "Smart Duplicate Detection", description: "AI-powered similarity analysis finds true duplicates and near-duplicates")

                            FeatureRow(icon: "eye.slash", title: "Blurry Photo Finder", description: "Automatically detect and remove out-of-focus images")

                            FeatureRow(icon: "moonphase.waning.crescent", title: "Dark Photo Cleaner", description: "Find underexposed or extremely dark photos")

                            FeatureRow(icon: "camera.viewfinder", title: "Screenshot Manager", description: "Quickly identify and organize screenshots")

                            FeatureRow(icon: "film", title: "Large Video Finder", description: "Locate storage-hungry video files")

                            FeatureRow(icon: "doc.text.magnifyingglass", title: "Document Detection", description: "AI identifies ID cards, invoices, and receipts")

                            FeatureRow(icon: "magnifyingglass.circle", title: "AI Photo Search", description: "Search your photos using natural language")

                            FeatureRow(icon: "square.grid.3x3.topleft.filled", title: "Smart Albums", description: "Auto-categorized albums for easy browsing")

                            FeatureRow(icon: "person.2.crop.square.stack", title: "Contact Backup", description: "Automatic backup and restore for your contacts")

                            FeatureRow(icon: "calendar.badge.clock", title: "Calendar Cleaner", description: "Remove old events and duplicate calendar entries")
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(CleanerTheme.surface)
                    .cornerRadius(16)
                    .padding(.horizontal)

                    // Privacy & Security
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Privacy & Security")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(CleanerTheme.textPrimary)

                        VStack(spacing: 12) {
                            InfoRow(icon: "lock.shield", title: "100% Private", description: "All processing happens on your device. Your photos never leave your iPhone.")

                            InfoRow(icon: "icloud.slash", title: "No Cloud Upload", description: "We don't upload, store, or transmit your photos to any server.")

                            InfoRow(icon: "eye.slash.fill", title: "No Tracking", description: "We don't track your photos, location, or personal data.")

                            InfoRow(icon: "checkmark.shield", title: "Secure by Design", description: "Built with Apple's privacy-first frameworks and guidelines.")
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(CleanerTheme.surface)
                    .cornerRadius(16)
                    .padding(.horizontal)

                    // Technology
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Technology")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(CleanerTheme.textPrimary)

                        Text("AI Cleaner leverages Apple's advanced on-device machine learning frameworks including Vision, Core ML, and Neural Engine to provide fast, accurate, and completely private photo analysis.")
                            .font(.system(size: 15))
                            .foregroundColor(CleanerTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(CleanerTheme.surface)
                    .cornerRadius(16)
                    .padding(.horizontal)

                    // Support
                    VStack(spacing: 12) {
                        Button(action: {
                            if let url = URL(string: "mailto:support@aicleaner.app") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .font(.system(size: 16))
                                Text("Contact Support")
                                    .font(.system(size: 16, weight: .semibold))
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 14))
                            }
                            .foregroundColor(CleanerTheme.primary)
                            .padding(16)
                            .background(CleanerTheme.surface)
                            .cornerRadius(12)
                        }

                        Button(action: {
                            // TODO: Add rate app functionality
                        }) {
                            HStack {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 16))
                                Text("Rate AI Cleaner")
                                    .font(.system(size: 16, weight: .semibold))
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 14))
                            }
                            .foregroundColor(CleanerTheme.primary)
                            .padding(16)
                            .background(CleanerTheme.surface)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)

                    // Copyright
                    Text("© 2024 AI Cleaner. All rights reserved.")
                        .font(.system(size: 13))
                        .foregroundColor(CleanerTheme.textTertiary)
                        .padding(.bottom, 32)
                }
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.large)
        .preferredColorScheme(.dark)
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(CleanerTheme.primary)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(CleanerTheme.textPrimary)

                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(CleanerTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Info Row

struct InfoRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(CleanerTheme.accentGreen)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(CleanerTheme.textPrimary)

                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(CleanerTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        AboutView()
    }
}
