//
//  TermsOfServiceView.swift
//  AI Cleaner
//
//  Terms of Service modal for paywall
//

import SwiftUI

struct TermsOfServiceView: View {
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
                            Text("Terms of Service")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(CleanerTheme.textPrimary)

                            Text("Last Updated: December 2024")
                                .font(.system(size: 14))
                                .foregroundColor(CleanerTheme.textSecondary)
                        }
                        .padding(.bottom, 8)

                        // Sections
                        TermsSection(
                            title: "1. Agreement to Terms",
                            content: """
                            By downloading, installing, or using AI Cleaner ("the App"), you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the App.
                            """
                        )

                        TermsSection(
                            title: "2. License",
                            content: """
                            AI Cleaner grants you a limited, non-exclusive, non-transferable, revocable license to use the App for personal, non-commercial purposes, subject to these Terms.

                            You may not:
                            • Modify, reverse engineer, or decompile the App
                            • Use the App for any illegal or unauthorized purpose
                            • Attempt to gain unauthorized access to our systems
                            • Resell or redistribute the App
                            """
                        )

                        TermsSection(
                            title: "3. Subscription Terms",
                            content: """
                            **Pricing:**
                            • Monthly: $4.99/month
                            • Annual: $29.99/year (Save 40%)
                            • Lifetime: $79.99 one-time payment

                            **Auto-Renewal:**
                            Subscriptions automatically renew unless canceled at least 24 hours before the end of the current period. You will be charged through your Apple ID account.

                            **Cancellation:**
                            You can cancel anytime in your App Store account settings. Cancellation takes effect at the end of the current billing period.

                            **Free Trial:**
                            If offered, the free trial automatically converts to a paid subscription unless canceled before the trial period ends.

                            **Refunds:**
                            Refunds are handled by Apple according to their policies. Contact Apple Support for refund requests.
                            """
                        )

                        TermsSection(
                            title: "4. User Content and Privacy",
                            content: """
                            **On-Device Processing:**
                            All photo analysis happens on your device. We do not upload, store, or transmit your photos or personal data to our servers.

                            **Your Responsibility:**
                            You are responsible for maintaining backups of your photos. While AI Cleaner helps identify duplicates and unwanted content, we recommend backing up important photos before deletion.

                            **Privacy:**
                            Your use of the App is also governed by our Privacy Policy. Please review it to understand our privacy practices.
                            """
                        )

                        TermsSection(
                            title: "5. Disclaimer of Warranties",
                            content: """
                            THE APP IS PROVIDED "AS IS" WITHOUT WARRANTIES OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO:
                            • Accuracy of photo analysis or duplicate detection
                            • Uninterrupted or error-free operation
                            • Compatibility with all devices or iOS versions

                            We strive for accuracy but cannot guarantee that all duplicates will be found or that analysis will be perfect.
                            """
                        )

                        TermsSection(
                            title: "6. Limitation of Liability",
                            content: """
                            TO THE MAXIMUM EXTENT PERMITTED BY LAW, AI CLEANER SHALL NOT BE LIABLE FOR:
                            • Loss of photos or data
                            • Indirect, incidental, or consequential damages
                            • Loss of profits or revenue
                            • Any damages exceeding the amount you paid for the subscription

                            ALWAYS MAINTAIN BACKUPS OF IMPORTANT PHOTOS.
                            """
                        )

                        TermsSection(
                            title: "7. Photo Deletion",
                            content: """
                            **Your Control:**
                            You have full control over photo deletion. The App only suggests duplicates and unwanted photos; you decide what to delete.

                            **Permanent Deletion:**
                            Deleted photos may be recoverable from iOS "Recently Deleted" folder for 30 days. After that, deletion is permanent.

                            **No Recovery:**
                            We cannot recover photos you delete. Please review carefully before deleting.
                            """
                        )

                        TermsSection(
                            title: "8. Updates and Changes",
                            content: """
                            We may update the App to:
                            • Add new features
                            • Fix bugs and improve performance
                            • Comply with iOS updates
                            • Discontinue features

                            We may modify these Terms at any time. Continued use after changes means you accept the modified Terms.
                            """
                        )

                        TermsSection(
                            title: "9. Termination",
                            content: """
                            We may terminate or suspend your access to the App at any time for:
                            • Violation of these Terms
                            • Fraudulent or illegal activity
                            • Abuse of the service

                            You may terminate your use by uninstalling the App and canceling your subscription.
                            """
                        )

                        TermsSection(
                            title: "10. Third-Party Services",
                            content: """
                            The App uses:
                            • Apple's Vision and Core ML frameworks (on-device)
                            • RevenueCat for subscription management
                            • Apple's StoreKit for purchases

                            These services have their own terms and privacy policies.
                            """
                        )

                        TermsSection(
                            title: "11. Governing Law",
                            content: """
                            These Terms are governed by the laws of the United States. Any disputes shall be resolved in accordance with applicable law.
                            """
                        )

                        TermsSection(
                            title: "12. Contact",
                            content: """
                            For questions about these Terms:

                            Email: legal@aicleaner.app
                            Support: support@aicleaner.app
                            """
                        )

                        // Footer
                        Text("© 2024 AI Cleaner. All rights reserved.")
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

// MARK: - Terms Section

struct TermsSection: View {
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
    TermsOfServiceView()
}
