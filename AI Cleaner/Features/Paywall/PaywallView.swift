//
//  PaywallView.swift
//  AI Cleaner
//
//  Paywall for premium subscriptions
//

import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var revenueCat = RevenueCatManager.shared
    @State private var selectedPlan: PlanType = .annual
    @State private var isPurchasing = false
    @State private var showingError = false
    @State private var errorMessage = ""

    enum PlanType {
        case monthly
        case annual
        case lifetime
    }

    var body: some View {
        ZStack {
            // Dark background gradient
            CleanerTheme.backgroundGradient
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    // Close button
                    HStack {
                        Spacer()
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(CleanerTheme.iconGray)
                        }
                    }
                    .padding()

                    // Header
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(CleanerTheme.accentGradient)
                                .frame(width: 100, height: 100)
                                .blur(radius: 40)

                            Image(systemName: "crown.fill")
                                .font(.system(size: 50, weight: .bold))
                                .foregroundColor(CleanerTheme.iconGray)
                        }
                        .scaleIn()

                        VStack(spacing: 12) {
                            Text("Unlock Pro Features")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(CleanerTheme.textPrimary)

                            Text("Get unlimited access to all features")
                                .cleanerFont(.body)
                                .foregroundColor(CleanerTheme.textSecondary)
                        }
                        .fadeIn(delay: 0.1)
                    }

                    // Features
                    VStack(spacing: 16) {
                        PaywallFeatureItem(
                            icon: "infinity",
                            title: "Unlimited Scans",
                            description: "Scan your library as many times as you want"
                        )
                        .fadeIn(delay: 0.2)

                        PaywallFeatureItem(
                            icon: "hand.tap",
                            title: "Unlimited Swipes",
                            description: "No daily limits on photo reviews"
                        )
                        .fadeIn(delay: 0.3)

                        PaywallFeatureItem(
                            icon: "video.fill",
                            title: "Large Video Finder",
                            description: "Find and clean up large video files"
                        )
                        .fadeIn(delay: 0.4)

                        PaywallFeatureItem(
                            icon: "chart.bar.fill",
                            title: "Detailed Reports",
                            description: "Advanced analytics and insights"
                        )
                        .fadeIn(delay: 0.5)

                        PaywallFeatureItem(
                            icon: "sparkles",
                            title: "Priority Support",
                            description: "Get help faster with priority support"
                        )
                        .fadeIn(delay: 0.6)
                    }
                    .padding(.horizontal)

                    // Plans
                    VStack(spacing: 16) {
                        PlanCard(
                            type: .annual,
                            title: "Annual",
                            price: "$29.99/year",
                            badge: "BEST VALUE",
                            savings: "Save 40%",
                            isSelected: selectedPlan == .annual
                        )
                        .onTapGesture {
                            selectedPlan = .annual
                        }
                        .scaleIn(delay: 0.7)

                        PlanCard(
                            type: .monthly,
                            title: "Monthly",
                            price: "$4.99/month",
                            badge: nil,
                            savings: nil,
                            isSelected: selectedPlan == .monthly
                        )
                        .onTapGesture {
                            selectedPlan = .monthly
                        }
                        .scaleIn(delay: 0.8)

                        PlanCard(
                            type: .lifetime,
                            title: "Lifetime",
                            price: "$79.99 once",
                            badge: "ONE TIME",
                            savings: "Best Deal",
                            isSelected: selectedPlan == .lifetime
                        )
                        .onTapGesture {
                            selectedPlan = .lifetime
                        }
                        .scaleIn(delay: 0.9)
                    }
                    .padding(.horizontal)

                    // Purchase Button
                    Button(action: purchase) {
                        HStack(spacing: 12) {
                            if isPurchasing {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.white)
                            } else {
                                Image(systemName: "lock.open.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                Text("Continue")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(CleanerTheme.primaryGradient)
                        .cornerRadius(16)
                    }
                    .disabled(isPurchasing)
                    .padding(.horizontal)
                    .scaleIn(delay: 1.0)

                    // Restore Button
                    Button(action: restore) {
                        Text("Restore Purchases")
                            .cleanerFont(.callout)
                            .foregroundColor(CleanerTheme.textSecondary)
                    }

                    // Terms
                    HStack(spacing: 16) {
                        Button("Terms") { }
                        Button("Privacy") { }
                    }
                    .cleanerFont(.caption2)
                    .foregroundColor(CleanerTheme.textTertiary)
                    .padding(.bottom, 32)
                }
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }

    private func purchase() {
        isPurchasing = true

        Task {
            do {
                switch selectedPlan {
                case .monthly:
                    try await revenueCat.purchaseMonthly()
                case .annual:
                    try await revenueCat.purchaseAnnual()
                case .lifetime:
                    try await revenueCat.purchaseLifetime()
                }

                await MainActor.run {
                    isPurchasing = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isPurchasing = false
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }

    private func restore() {
        Task {
            do {
                try await revenueCat.restorePurchases()
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
}

// MARK: - Feature Item

struct PaywallFeatureItem: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(CleanerTheme.primary.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(CleanerTheme.iconGray)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .cleanerFont(.headline)
                    .foregroundColor(CleanerTheme.textPrimary)
                Text(description)
                    .cleanerFont(.caption)
                    .foregroundColor(CleanerTheme.textSecondary)
            }

            Spacer()
        }
        .padding(16)
        .background(CleanerTheme.cardBackground)
        .cornerRadius(16)
    }
}

// MARK: - Plan Card

struct PlanCard: View {
    let type: PaywallView.PlanType
    let title: String
    let price: String
    let badge: String?
    let savings: String?
    let isSelected: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(title)
                        .cleanerFont(.headline)
                        .foregroundColor(CleanerTheme.textPrimary)

                    if let badge = badge {
                        Text(badge)
                            .cleanerFont(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(CleanerTheme.accent)
                            .foregroundColor(CleanerTheme.background)
                            .cornerRadius(6)
                    }
                }

                Text(price)
                    .cleanerFont(.subheadline)
                    .foregroundColor(CleanerTheme.textSecondary)

                if let savings = savings {
                    Text(savings)
                        .cleanerFont(.caption)
                        .foregroundColor(CleanerTheme.accentGreen)
                }
            }

            Spacer()

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(isSelected ? CleanerTheme.primary : CleanerTheme.textTertiary)
        }
        .padding(20)
        .background(isSelected ? CleanerTheme.cardBackground : CleanerTheme.surface)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? CleanerTheme.primary : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Preview

#Preview {
    PaywallView()
}
