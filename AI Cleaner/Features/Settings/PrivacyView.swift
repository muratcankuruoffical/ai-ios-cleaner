//
//  PrivacyView.swift
//  AI Cleaner
//
//  Privacy Policy page
//

import SwiftUI

struct PrivacyView: View {
    var body: some View {
        ZStack {
            CleanerTheme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 48))
                            .foregroundColor(CleanerTheme.primary)

                        Text("Privacy Policy")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(CleanerTheme.textPrimary)

                        Text("Last Updated: December 2024")
                            .font(.system(size: 14))
                            .foregroundColor(CleanerTheme.textSecondary)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(CleanerTheme.surface)
                    .cornerRadius(16)

                    // TL;DR
                    PrivacySection(
                        icon: "checkmark.shield.fill",
                        title: "Privacy in Brief",
                        content: """
                        AI Cleaner is designed with privacy as a core principle:

                        • All photo analysis happens on your device
                        • We don't upload, store, or transmit your photos
                        • We don't track your location or personal data
                        • We don't sell your data to third parties
                        • Optional analytics are completely anonymous
                        """
                    )

                    // What We Collect
                    PrivacySection(
                        icon: "doc.text",
                        title: "Information We Collect",
                        content: """
                        **On-Device Processing:**
                        All photo analysis, AI processing, and similarity detection happens entirely on your iPhone. Your photos never leave your device.

                        **Optional Anonymous Analytics:**
                        If you enable analytics, we collect:
                        • App usage statistics (scan count, feature usage)
                        • Device type and iOS version
                        • Crash reports and performance data
                        • NO photo content, metadata, or personal information

                        **Subscription Information:**
                        If you purchase a subscription, Apple processes the transaction through your Apple ID. We receive only:
                        • Subscription status (active/inactive)
                        • Purchase date and expiration
                        • NO payment details or personal information
                        """
                    )

                    // How We Use Your Data
                    PrivacySection(
                        icon: "gear",
                        title: "How We Use Information",
                        content: """
                        **On-Device Features:**
                        Photo analysis, duplicate detection, and all AI features run locally on your device using Apple's frameworks (Vision, Core ML).

                        **Anonymous Analytics (Optional):**
                        Used only to:
                        • Improve app performance and stability
                        • Understand which features are most useful
                        • Fix bugs and crashes

                        **Subscription Management:**
                        We use RevenueCat to manage subscriptions securely. They may collect:
                        • Anonymous device identifiers
                        • Subscription status
                        See RevenueCat's privacy policy: https://www.revenuecat.com/privacy
                        """
                    )

                    // Photo Access
                    PrivacySection(
                        icon: "photo.on.rectangle",
                        title: "Photo Library Access",
                        content: """
                        AI Cleaner requests access to your photo library to:
                        • Scan for duplicates and similar photos
                        • Analyze photo quality (blur, darkness)
                        • Detect screenshots and documents
                        • Search photos using AI

                        **Your Control:**
                        • You can grant limited or full photo access
                        • You can revoke access anytime in iOS Settings
                        • We only access photos you explicitly allow
                        • Photos are NEVER uploaded to servers
                        """
                    )

                    // Contacts & Calendar
                    PrivacySection(
                        icon: "person.crop.circle",
                        title: "Contacts & Calendar Access",
                        content: """
                        **Contacts Backup (Optional):**
                        If you enable contact backup:
                        • Backups are stored locally on your device
                        • We don't upload contacts to any server
                        • You can export backups to iCloud or other locations

                        **Calendar Cleaner (Optional):**
                        • Analyzes calendar for old/duplicate events
                        • All processing is on-device
                        • We don't access or store calendar data
                        """
                    )

                    // Data Security
                    PrivacySection(
                        icon: "lock.shield",
                        title: "Data Security",
                        content: """
                        **On-Device Security:**
                        • All data is protected by iOS sandboxing
                        • App uses Apple's secure frameworks
                        • No network transmission of photos or personal data

                        **Storage:**
                        • Scan results and analysis cached locally
                        • All data protected by iOS encryption
                        • You can clear cache anytime in Settings
                        """
                    )

                    // Third-Party Services
                    PrivacySection(
                        icon: "link",
                        title: "Third-Party Services",
                        content: """
                        AI Cleaner uses these third-party services:

                        **RevenueCat (Subscription Management):**
                        • Manages in-app purchases and subscriptions
                        • Privacy Policy: https://www.revenuecat.com/privacy

                        **Apple Services:**
                        • Vision Framework (on-device photo analysis)
                        • Core ML (on-device machine learning)
                        • StoreKit (in-app purchases)

                        None of these services receive your photos or personal content.
                        """
                    )

                    // Your Rights
                    PrivacySection(
                        icon: "hand.raised",
                        title: "Your Privacy Rights",
                        content: """
                        You have the right to:
                        • Access your data (stored locally on your device)
                        • Delete your data (clear cache in Settings)
                        • Opt-out of analytics (toggle in Settings)
                        • Revoke photo/contact access (iOS Settings)
                        • Request data deletion (contact support)

                        **Data Deletion:**
                        To delete all app data:
                        1. Go to Settings → Reset App
                        2. Or uninstall the app from your device
                        """
                    )

                    // Children's Privacy
                    PrivacySection(
                        icon: "figure.and.child.holdinghands",
                        title: "Children's Privacy",
                        content: """
                        AI Cleaner is not directed to children under 13. We do not knowingly collect personal information from children. If you are a parent and believe your child has used this app, please contact us at privacy@aicleaner.app.
                        """
                    )

                    // Changes to Privacy Policy
                    PrivacySection(
                        icon: "arrow.triangle.2.circlepath",
                        title: "Changes to This Policy",
                        content: """
                        We may update this Privacy Policy from time to time. We will notify you of significant changes by:
                        • Updating the "Last Updated" date
                        • Showing an in-app notification
                        • Sending a notification if required by law

                        Continued use of the app after changes means you accept the updated policy.
                        """
                    )

                    // Contact
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Contact Us")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(CleanerTheme.textPrimary)

                        Text("If you have questions about this Privacy Policy, please contact us:")
                            .font(.system(size: 15))
                            .foregroundColor(CleanerTheme.textSecondary)

                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(CleanerTheme.primary)
                                Text("privacy@aicleaner.app")
                                    .font(.system(size: 14))
                                    .foregroundColor(CleanerTheme.textSecondary)
                            }

                            Button(action: {
                                if let url = URL(string: "mailto:privacy@aicleaner.app") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                Text("Send Email")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(CleanerTheme.primary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(CleanerTheme.primary.opacity(0.15))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(CleanerTheme.surface)
                    .cornerRadius(16)

                    // Footer
                    Text("© 2024 AI Cleaner. All rights reserved.")
                        .font(.system(size: 13))
                        .foregroundColor(CleanerTheme.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom, 32)
                }
                .padding()
            }
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.large)
        .preferredColorScheme(.dark)
    }
}

// MARK: - Privacy Section

struct PrivacySection: View {
    let icon: String
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(CleanerTheme.primary)

                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(CleanerTheme.textPrimary)
            }

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
    NavigationView {
        PrivacyView()
    }
}
