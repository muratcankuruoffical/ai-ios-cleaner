//
//  DashboardView.swift
//  AI Cleaner
//
//  Main dashboard with scan results and reports
//

import SwiftUI
import Charts
internal import Combine

struct DashboardView: View {
    @StateObject private var scanCoordinator = ScanCoordinator()
    @State private var showingScanProgress = false
    @State private var showingResults = false
    @State private var showingSmartAlbums = false

    var body: some View {
        NavigationView {
            ZStack {
                // Dark background
                CleanerTheme.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header
                        headerView
                            .fadeIn(delay: 0.1)

                        // Main Content
                        if let results = scanCoordinator.scanResults {
                            // Storage Overview with Donut Chart
                            storageOverviewCard(results)
                                .scaleIn(delay: 0.2)

                            // Quick Stats Grid
                            quickStatsView(results)
                                .fadeIn(delay: 0.3)

                            // View Smart Albums Button
                            viewAlbumsButton
                                .scaleIn(delay: 0.4)
                        } else {
                            // Scan Prompt Card
                            scanPromptCard
                                .scaleIn(delay: 0.2)
                        }

                        // Recent Activity
                        if scanCoordinator.scanResults != nil {
                            recentActivityView
                                .fadeIn(delay: 0.5)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingScanProgress) {
                ScanProgressView(coordinator: scanCoordinator)
            }
            .sheet(isPresented: $showingResults) {
                if let results = scanCoordinator.scanResults {
                    ScanResultsView(results: results, showingResults: $showingResults)
                }
            }
            .sheet(isPresented: $showingSmartAlbums) {
                if let results = scanCoordinator.scanResults {
                    NavigationView {
                        SmartAlbumsView(scanResults: results)
                    }
                }
            }
            .onChange(of: scanCoordinator.scanState) { _, newState in
                switch newState {
                case .scanning:
                    showingScanProgress = true
                case .completed:
                    showingScanProgress = false
                    showingResults = true
                case .cancelled, .error:
                    showingScanProgress = false
                default:
                    break
                }
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("AI Cleaner")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(CleanerTheme.textPrimary)

                Text("Keep your photos organized")
                    .cleanerFont(.subheadline)
                    .foregroundColor(CleanerTheme.textSecondary)
            }

            Spacer()

            // Settings Button
            NavigationLink(destination: SettingsView()) {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                    .foregroundColor(CleanerTheme.iconGray)
                    .frame(width: 44, height: 44)
                    .background(CleanerTheme.surface)
                    .clipShape(Circle())
            }
        }
    }

    // MARK: - Storage Overview Card

    private func storageOverviewCard(_ results: ScanCoordinator.ScanResults) -> some View {
        VStack(spacing: 20) {
            HStack {
                Text("Storage Analysis")
                    .cleanerFont(.headline)
                    .foregroundColor(CleanerTheme.textPrimary)

                Spacer()

                Button(action: {
                    scanCoordinator.startScan()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Rescan")
                            .cleanerFont(.callout)
                    }
                    .foregroundColor(CleanerTheme.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(CleanerTheme.primary.opacity(0.15))
                    .cornerRadius(12)
                }
            }

            // Donut Chart
            DonutChart(
                value: min(Double(results.potentialSavingsBytes) / Double(results.potentialSavingsBytes + 10_000_000_000), 0.95),
                total: formatBytes(results.potentialSavingsBytes + 10_000_000_000),
                used: results.formattedSavings,
                title: "Can Be Freed"
            )

            // Stats Row
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("\(results.totalPhotos)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(CleanerTheme.accentGreen)
                    Text("Photos")
                        .cleanerFont(.caption)
                        .foregroundColor(CleanerTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .frame(height: 40)
                    .background(CleanerTheme.surface)

                VStack(spacing: 4) {
                    Text("\(results.statistics.totalDuplicates)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(CleanerTheme.accent)
                    Text("Issues Found")
                        .cleanerFont(.caption)
                        .foregroundColor(CleanerTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(24)
        .cleanerCard()
    }

    // MARK: - Scan Prompt Card

    private var scanPromptCard: some View {
        VStack(spacing: 24) {
            // Icon with gradient
            ZStack {
                Circle()
                    .fill(CleanerTheme.primaryGradient)
                    .frame(width: 100, height: 100)
                    .blur(radius: 30)
                    .opacity(0.6)

                Image(systemName: "sparkles")
                    .font(.system(size: 50))
                    .foregroundColor(CleanerTheme.iconGray)
            }
            .pulse()

            VStack(spacing: 12) {
                Text("Start Smart Scan")
                    .cleanerFont(.title2)
                    .foregroundColor(CleanerTheme.textPrimary)

                Text("Analyze your photo library for duplicates, blurry photos, and more using AI")
                    .cleanerFont(.body)
                    .foregroundColor(CleanerTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }

            // Scan Button
            Button(action: {
                scanCoordinator.startScan()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Start Scan")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(CleanerTheme.primaryGradient)
                .cornerRadius(16)
            }
            .padding(.horizontal, 20)

            // Features Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                FeatureTag(icon: "square.on.square", title: "Duplicates")
                FeatureTag(icon: "eye.slash", title: "Blurry")
                FeatureTag(icon: "moon", title: "Dark Photos")
                FeatureTag(icon: "camera.viewfinder", title: "Screenshots")
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 32)
        .cleanerCard()
    }

    // MARK: - Quick Stats

    private func quickStatsView(_ results: ScanCoordinator.ScanResults) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Categories")
                .cleanerFont(.headline)
                .foregroundColor(CleanerTheme.textPrimary)
                .padding(.horizontal, 4)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                AnimatedStatCard(
                    icon: "square.on.square",
                    title: "Duplicates",
                    value: "\(results.statistics.totalDuplicates)",
                    color: CleanerTheme.primary,
                    delay: 0.1
                )

                AnimatedStatCard(
                    icon: "eye.slash",
                    title: "Blurry",
                    value: "\(results.blurryPhotos.count)",
                    color: CleanerTheme.accent,
                    delay: 0.2
                )

                AnimatedStatCard(
                    icon: "moon",
                    title: "Dark",
                    value: "\(results.darkPhotos.count)",
                    color: CleanerTheme.accentGreen,
                    delay: 0.3
                )

                AnimatedStatCard(
                    icon: "camera.viewfinder",
                    title: "Screenshots",
                    value: "\(results.screenshots.count)",
                    color: CleanerTheme.accentRed,
                    delay: 0.4
                )
            }
        }
    }

    // MARK: - View Albums Button

    private var viewAlbumsButton: some View {
        Button(action: {
            showingSmartAlbums = true
        }) {
            HStack(spacing: 12) {
                Image(systemName: "photo.stack")
                    .font(.system(size: 18, weight: .semibold))
                Text("View Smart Albums")
                    .font(.system(size: 18, weight: .semibold))

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.vertical, 18)
            .padding(.horizontal, 24)
            .background(CleanerTheme.primaryGradient)
            .cornerRadius(16)
        }
    }

    // MARK: - Recent Activity

    private var recentActivityView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .cleanerFont(.headline)
                .foregroundColor(CleanerTheme.textPrimary)
                .padding(.horizontal, 4)

            VStack(spacing: 12) {
                ActivityRow(
                    icon: "checkmark.circle.fill",
                    title: "Scan completed",
                    subtitle: "Just now",
                    color: CleanerTheme.accentGreen
                )

                ActivityRow(
                    icon: "photo.stack.fill",
                    title: "\(scanCoordinator.scanResults?.totalPhotos ?? 0) photos analyzed",
                    subtitle: "AI detection complete",
                    color: CleanerTheme.primary
                )
            }
            .padding(16)
            .background(CleanerTheme.cardBackground)
            .cornerRadius(16)
        }
    }

    // MARK: - Helpers

    private func formatBytes(_ bytes: Int64) -> String {
        let gb = Double(bytes) / (1024 * 1024 * 1024)
        if gb >= 1.0 {
            return String(format: "%.1f GB", gb)
        } else {
            let mb = Double(bytes) / (1024 * 1024)
            return String(format: "%.0f MB", mb)
        }
    }
}

// MARK: - Animated Stat Card

struct AnimatedStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    let delay: Double

    @State private var showValue = false

    var body: some View {
        VStack(spacing: 16) {
            // Icon with background
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(CleanerTheme.iconGray)
            }

            VStack(spacing: 6) {
                Text(showValue ? value : "0")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(CleanerTheme.textPrimary)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: showValue)

                Text(title)
                    .cleanerFont(.caption)
                    .foregroundColor(CleanerTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(CleanerTheme.cardBackground)
        .cornerRadius(20)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                showValue = true
            }
        }
    }
}

// MARK: - Feature Tag

struct FeatureTag: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(CleanerTheme.iconGray)

            Text(title)
                .cleanerFont(.callout)
                .foregroundColor(CleanerTheme.textSecondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(CleanerTheme.surface)
        .cornerRadius(12)
    }
}

// MARK: - Activity Row

struct ActivityRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .cleanerFont(.subheadline)
                    .foregroundColor(CleanerTheme.textPrimary)
                Text(subtitle)
                    .cleanerFont(.caption)
                    .foregroundColor(CleanerTheme.textSecondary)
            }

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    DashboardView()
}
