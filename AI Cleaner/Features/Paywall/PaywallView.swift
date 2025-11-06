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
            // Background gradient
            LinearGradient(
                colors: [.blue, .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
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
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .padding()

                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.yellow)

                        Text("Unlock Pro Features")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Text("Get unlimited access to all features")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))
                    }

                    // Features
                    VStack(spacing: 20) {
                        FeatureItem(
                            icon: "infinity",
                            title: "Unlimited Scans",
                            description: "Scan your library as many times as you want"
                        )

                        FeatureItem(
                            icon: "hand.tap",
                            title: "Unlimited Swipes",
                            description: "No daily limits on photo reviews"
                        )

                        FeatureItem(
                            icon: "video.fill",
                            title: "Large Video Finder",
                            description: "Find and clean up large video files"
                        )

                        FeatureItem(
                            icon: "chart.bar.fill",
                            title: "Detailed Reports",
                            description: "Advanced analytics and insights"
                        )

                        FeatureItem(
                            icon: "sparkles",
                            title: "Priority Support",
                            description: "Get help faster with priority support"
                        )
                    }
                    .padding()
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(20)
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
                    }
                    .padding(.horizontal)

                    // Purchase Button
                    Button(action: purchase) {
                        HStack {
                            if isPurchasing {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.blue)
                            } else {
                                Text("Continue")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.blue)
                        .cornerRadius(12)
                    }
                    .disabled(isPurchasing)
                    .padding(.horizontal)

                    // Restore Button
                    Button(action: restore) {
                        Text("Restore Purchases")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }

                    // Terms
                    HStack(spacing: 16) {
                        Button("Terms") { }
                        Button("Privacy") { }
                    }
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
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

struct FeatureItem: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.yellow)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }

            Spacer()
        }
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
                        .font(.headline)
                        .foregroundColor(isSelected ? .blue : .white)

                    if let badge = badge {
                        Text(badge)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.yellow)
                            .foregroundColor(.black)
                            .cornerRadius(4)
                    }
                }

                Text(price)
                    .font(.body)
                    .foregroundColor(isSelected ? .blue : .white.opacity(0.8))

                if let savings = savings {
                    Text(savings)
                        .font(.caption)
                        .foregroundColor(isSelected ? .blue : .white.opacity(0.7))
                }
            }

            Spacer()

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundColor(isSelected ? .blue : .white.opacity(0.5))
        }
        .padding()
        .background(isSelected ? Color.white : Color.white.opacity(0.15))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Preview

#Preview {
    PaywallView()
}
