//
//  PaywallView.swift
//  AI Cleaner
//
//  Paywall for premium subscriptions - Dark Theme
//

import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var revenueCat = RevenueCatManager.shared
    @State private var selectedPlan: PlanType = .annual
    @State private var isPurchasing = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingTerms = false
    @State private var showingPrivacy = false

    enum PlanType {
        case monthly
        case annual
        case lifetime
    }

    var body: some View {
        ZStack {
            // Dark Background with Gradient
            LinearGradient(
                colors: [CleanerTheme.background, Color(hex: "#000000")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    // Close button
                    HStack {
                        Spacer()
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(CleanerTheme.iconPrimary)
                        }
                    }
                    .padding()

                    // Header
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [CleanerTheme.accent.opacity(0.3), CleanerTheme.accent.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)

                            Image(systemName: "crown.fill")
                                .font(.system(size: 50))
                                .foregroundColor(CleanerTheme.accent)
                        }

                        Text("Unlock Pro Features")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(CleanerTheme.textPrimary)

                        Text("Get unlimited access to all features")
                            .cleanerFont(.body)
                    }

                    // Features
                    VStack(spacing: 16) {
                        FeatureItem(
                            icon: "magnifyingglass.circle.fill",
                            title: "AI Photo Search",
                            description: "Search photos using natural language"
                        )

                        FeatureItem(
                            icon: "square.grid.3x3.topleft.filled",
                            title: "Smart Albums",
                            description: "Auto-categorized albums for quick access"
                        )

                        FeatureItem(
                            icon: "photo.stack",
                            title: "Smart Duplicate Detection",
                            description: "AI finds true duplicates and similar photos"
                        )

                        FeatureItem(
                            icon: "film",
                            title: "Video Management",
                            description: "Find large and duplicate videos"
                        )

                        FeatureItem(
                            icon: "doc.text.magnifyingglass",
                            title: "Document Detection",
                            description: "AI identifies IDs, receipts, and invoices"
                        )

                        FeatureItem(
                            icon: "person.2.crop.square.stack",
                            title: "Contact Backup",
                            description: "Auto backup and restore your contacts"
                        )

                        FeatureItem(
                            icon: "calendar.badge.clock",
                            title: "Calendar Cleaner",
                            description: "Remove old events and duplicates"
                        )

                        FeatureItem(
                            icon: "arrow.down.circle",
                            title: "Photo Optimization",
                            description: "Reduce 4K photos to 1080p to save space"
                        )

                        FeatureItem(
                            icon: "chart.bar.fill",
                            title: "Detailed Reports",
                            description: "Advanced analytics and storage insights"
                        )

                        FeatureItem(
                            icon: "sparkles",
                            title: "Priority Support",
                            description: "Get help faster with premium support"
                        )
                    }
                    .padding(20)
                    .card(backgroundColor: CleanerTheme.surface)
                    .padding(.horizontal)

                    // Plans
                    VStack(spacing: 12) {
                        PlanCard(
                            type: .annual,
                            title: "Annual",
                            price: "$29.99/year",
                            badge: "BEST VALUE",
                            savings: "Save 40%",
                            isSelected: selectedPlan == .annual
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) {
                                selectedPlan = .annual
                            }
                        }

                        PlanCard(
                            type: .monthly,
                            title: "Monthly",
                            price: "$4.99/month",
                            badge: nil,
                            savings: nil,
                            isSelected: selectedPlan == .monthly
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) {
                                selectedPlan = .monthly
                            }
                        }

                        PlanCard(
                            type: .lifetime,
                            title: "Lifetime",
                            price: "$79.99 once",
                            badge: "ONE TIME",
                            savings: "Best Deal",
                            isSelected: selectedPlan == .lifetime
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) {
                                selectedPlan = .lifetime
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Purchase Button
                    Button(action: purchase) {
                        HStack {
                            if isPurchasing {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.white)
                            } else {
                                Text("Continue")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .foregroundColor(.white)
                        .background(
                            LinearGradient(
                                colors: [CleanerTheme.primary, Color(hex: "#0066DD")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                    }
                    .disabled(isPurchasing)
                    .padding(.horizontal)

                    // Restore Button
                    Button(action: restore) {
                        Text("Restore Purchases")
                            .cleanerFont(.label)
                    }

                    // Terms
                    HStack(spacing: 16) {
                        Button("Terms") {
                            showingTerms = true
                        }
                        Button("Privacy") {
                            showingPrivacy = true
                        }
                    }
                    .font(.caption2)
                    .foregroundColor(CleanerTheme.textSecondary)
                    .padding(.bottom, 32)
                }
            }
        }
        .preferredColorScheme(.dark)
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showingTerms) {
            TermsOfServiceView()
        }
        .sheet(isPresented: $showingPrivacy) {
            PaywallPrivacyView()
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

// MARK: - Feature Item (Dark Theme)

struct FeatureItem: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(CleanerTheme.primary.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(CleanerTheme.primary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(CleanerTheme.textPrimary)
                Text(description)
                    .cleanerFont(.caption)
            }

            Spacer()
        }
    }
}

// MARK: - Plan Card (Dark Theme)

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
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(isSelected ? CleanerTheme.primary : CleanerTheme.textPrimary)

                    if let badge = badge {
                        Text(badge)
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(CleanerTheme.accent)
                            .foregroundColor(CleanerTheme.background)
                            .cornerRadius(6)
                    }
                }

                Text(price)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? CleanerTheme.textPrimary : CleanerTheme.textSecondary)

                if let savings = savings {
                    Text(savings)
                        .cleanerFont(.caption)
                        .foregroundColor(isSelected ? CleanerTheme.accentGreen : CleanerTheme.textTertiary)
                }
            }

            Spacer()

            ZStack {
                Circle()
                    .stroke(isSelected ? CleanerTheme.primary : CleanerTheme.iconPrimary, lineWidth: 2)
                    .frame(width: 28, height: 28)

                if isSelected {
                    Circle()
                        .fill(CleanerTheme.primary)
                        .frame(width: 16, height: 16)
                }
            }
        }
        .padding(20)
        .background(isSelected ? CleanerTheme.primary.opacity(0.1) : CleanerTheme.surface)
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
