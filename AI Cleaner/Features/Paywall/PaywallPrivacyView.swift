//
//  PaywallPrivacyView.swift
//  AI Cleaner
//
//  Privacy Policy modal for paywall (condensed version)
//

import SwiftUI

struct PaywallPrivacyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                CleanerTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        VStack(alignment: .leading, spacing: 12) {
                            Image(systemName: "hand.raised.fill")
                                .font(.system(size: 40))
                                .foregroundColor(CleanerTheme.primary)

                            Text("Privacy Policy")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(CleanerTheme.textPrimary)

                            Text("We respect your privacy")
                                .font(.system(size: 16))
                                .foregroundColor(CleanerTheme.textSecondary)
                        }
                        .padding(.bottom, 8)

                        // Quick Summary
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Privacy at a Glance")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(CleanerTheme.textPrimary)

                            VStack(spacing: 12) {
                                PrivacyHighlight(
                                    icon: "lock.shield.fill",
                                    title: "100% On-Device",
                                    description: "All photo analysis happens on your iPhone"
                                )

                                PrivacyHighlight(
                                    icon: "icloud.slash.fill",
                                    title: "No Cloud Upload",
                                    description: "Your photos never leave your device"
                                )

                                PrivacyHighlight(
                                    icon: "eye.slash.fill",
                                    title: "No Tracking",
                                    description: "We don't track or collect personal data"
                                )

                                PrivacyHighlight(
                                    icon: "hand.raised.fill",
                                    title: "Your Control",
                                    description: "You decide what to delete, always"
                                )
                            }
                        }
                        .padding(20)
                        .background(CleanerTheme.surface)
                        .cornerRadius(16)

                        // What We Collect
                        PrivacyInfoSection(
                            title: "What We Collect",
                            content: """
                            **On-Device Only:**
                            • Photo analysis happens locally
                            • No photos uploaded to servers
                            • No personal data collected

                            **Optional Analytics:**
                            • Anonymous usage statistics
                            • Crash reports for improvements
                            • Can be disabled in Settings

                            **Subscription:**
                            • Managed by Apple
                            • We don't see payment details
                            """
                        )

                        // How We Use Data
                        PrivacyInfoSection(
                            title: "How We Protect You",
                            content: """
                            • iOS sandboxing protects all data
                            • Apple's secure frameworks only
                            • No network transmission of photos
                            • Local encrypted storage
                            • You can clear cache anytime
                            """
                        )

                        // Third-Party Services
                        PrivacyInfoSection(
                            title: "Third-Party Services",
                            content: """
                            We use:
                            • RevenueCat (subscription management)
                            • Apple Vision & Core ML (on-device AI)
                            • Apple StoreKit (purchases)

                            None receive your photos or personal content.
                            """
                        )

                        // Contact & Full Policy
                        VStack(spacing: 16) {
                            Button(action: {
                                // Open full privacy in Settings
                                dismiss()
                            }) {
                                HStack {
                                    Text("Read Full Privacy Policy")
                                        .font(.system(size: 16, weight: .semibold))
                                    Spacer()
                                    Image(systemName: "arrow.right")
                                }
                                .foregroundColor(CleanerTheme.primary)
                                .padding(16)
                                .background(CleanerTheme.surface)
                                .cornerRadius(12)
                            }

                            Button(action: {
                                if let url = URL(string: "mailto:privacy@aicleaner.app") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack {
                                    Image(systemName: "envelope.fill")
                                    Text("Contact: privacy@aicleaner.app")
                                        .font(.system(size: 14))
                                }
                                .foregroundColor(CleanerTheme.textSecondary)
                                .padding(12)
                            }
                        }

                        // Footer
                        Text("Last Updated: December 2024")
                            .font(.system(size: 13))
                            .foregroundColor(CleanerTheme.textTertiary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 32)
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(CleanerTheme.iconPrimary)
                    }
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}

// MARK: - Privacy Highlight

struct PrivacyHighlight: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
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
            }

            Spacer()
        }
    }
}

// MARK: - Privacy Info Section

struct PrivacyInfoSection: View {
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(CleanerTheme.textPrimary)

            Text(content)
                .font(.system(size: 15))
                .foregroundColor(CleanerTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CleanerTheme.surface)
        .cornerRadius(16)
    }
}

// MARK: - Preview

#Preview {
    PaywallPrivacyView()
}
