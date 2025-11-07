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
    @State private var showingContactsPermissionAlert = false
    @State private var showingCalendarPermissionAlert = false

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
                    // Quick Stats
                    if let results = scanCoordinator.scanResults {
                        quickStatsView(results)
                    }

                    // Recent Activity
                    recentActivityView

                    // System Health (Battery + Storage)
                    systemHealthView

                    // Storage Recommendations
                    storageRecommendationsWidget
                }
                .padding()
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
            .alert("Contacts Permission Required", isPresented: $showingContactsPermissionAlert) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Please grant Contacts permission in Settings to scan for duplicate contacts.")
            }
            .alert("Calendar Permission Required", isPresented: $showingCalendarPermissionAlert) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Please grant Calendar permission in Settings to scan for old events.")
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
                    color: .green
                )

                StatCard(
                    icon: "video.fill",
                    title: "Large Videos",
                    value: "\(results.largeVideos.count)",
                    color: .red
                )

                StatCard(
                    icon: "video.badge.plus",
                    title: "Similar Videos",
                    value: "\(results.similarVideoGroups.reduce(0) { $0 + $1.videos.count })",
                    color: .pink
                )

                StatCard(
                    icon: "arrow.down.circle",
                    title: "Optimizable",
                    value: "\(results.optimizablePhotos.count)",
                    color: .cyan
                )

                StatCard(
                    icon: "doc.text",
                    title: "Documents",
                    value: "\(results.documents.count)",
                    color: .indigo
                )

                // Contacts Card
                Button(action: {
                    handleContactsCardTap(results: results)
                }) {
                    StatCard(
                        icon: "person.2.fill",
                        title: "Duplicate Contacts",
                        value: "\(results.contactsResults?.totalDuplicates ?? 0)",
                        color: .brown
                    )
                }
                .buttonStyle(.plain)

                // Calendar Card
                Button(action: {
                    handleCalendarCardTap(results: results)
                }) {
                    StatCard(
                        icon: "calendar.badge.clock",
                        title: "Old Events",
                        value: "\(results.calendarResults?.totalCleanableEvents ?? 0)",
                        color: .teal
                    )
                }
                .buttonStyle(.plain)
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

    // MARK: - System Health

    private var systemHealthView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("System Health")
                .font(.headline)

            let health = SystemInsights.shared.calculateSystemHealth()
            let battery = SystemInsights.shared.getBatteryInfo()
            let storage = SystemInsights.shared.getStorageInfo()

            // Overall Health Score
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 16) {
                    Image(systemName: health.statusIcon)
                        .font(.largeTitle)
                        .foregroundColor(colorForStatus(health.statusColor))

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text("Grade: \(health.grade)")
                                .font(.title)
                                .fontWeight(.bold)
                            Text(gradeDescription(health.grade))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Text("\(health.overallScore)% Overall Health")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }

                // Breakdown
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "battery.100")
                            .font(.caption)
                        Text("Battery: \(health.batteryHealth)%")
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)

                    HStack(spacing: 4) {
                        Image(systemName: "internaldrive")
                            .font(.caption)
                        Text("Storage: \(health.storageHealth)%")
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                }

                // Recommendation
                if let recommendation = healthRecommendation(health) {
                    HStack(spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text(recommendation)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(colorForStatus(health.statusColor).opacity(0.1))
            .cornerRadius(12)
        }
    }

    // MARK: - System Health

    private var systemHealthView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("System Health")
                .font(.headline)

            let health = SystemInsights.shared.calculateSystemHealth()
            let battery = SystemInsights.shared.getBatteryInfo()
            let storage = SystemInsights.shared.getStorageInfo()

            // Overall Health Score
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 16) {
                    Image(systemName: health.statusIcon)
                        .font(.largeTitle)
                        .foregroundColor(colorForStatus(health.statusColor))

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text("Grade: \(health.grade)")
                                .font(.title)
                                .fontWeight(.bold)
                            Text(gradeDescription(health.grade))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Text("\(health.overallScore)% Overall Health")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }

                // Breakdown
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "battery.100")
                            .font(.caption)
                        Text("Battery: \(health.batteryHealth)%")
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)

                    HStack(spacing: 4) {
                        Image(systemName: "internaldrive")
                            .font(.caption)
                        Text("Storage: \(health.storageHealth)%")
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                }

                // Recommendation
                if let recommendation = healthRecommendation(health) {
                    HStack(spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text(recommendation)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(colorForStatus(health.statusColor).opacity(0.1))
            .cornerRadius(12)

            // Battery & Storage Grid
            HStack(spacing: 16) {
                // Battery
                VStack(spacing: 12) {
                    Image(systemName: battery.statusIcon)
                        .font(.title)
                        .foregroundColor(colorForStatus(battery.statusColor))

                    VStack(spacing: 4) {
                        Text("\(battery.percentage)%")
                            .font(.title3)
                            .fontWeight(.bold)
                        Text("Battery")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if battery.isLowPowerModeEnabled {
                        Text("Low Power Mode")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(colorForStatus(battery.statusColor).opacity(0.1))
                .cornerRadius(12)

                // Storage
                if let storage = storage {
                    VStack(spacing: 12) {
                        Image(systemName: storage.statusIcon)
                            .font(.title)
                            .foregroundColor(colorForStatus(storage.statusColor))

                        VStack(spacing: 4) {
                            Text(storage.formatBytes(storage.freeSpace))
                                .font(.title3)
                                .fontWeight(.bold)
                            Text("Available")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Text("\(Int(storage.usagePercentage))% Used")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(colorForStatus(storage.statusColor).opacity(0.1))
                    .cornerRadius(12)
                }
            }
        }
    }

    private func colorForStatus(_ status: String) -> Color {
        switch status {
        case "green": return .green
        case "orange": return .orange
        case "red": return .red
        case "blue": return .blue
        default: return .gray
        }
    }

    private func gradeDescription(_ grade: String) -> String {
        switch grade {
        case "A": return "Excellent"
        case "B": return "Good"
        case "C": return "Fair"
        case "D": return "Poor"
        case "F": return "Needs Attention"
        default: return ""
        }
    }

    private func healthRecommendation(_ health: SystemInsights.SystemHealthScore) -> String? {
        if health.storageHealth < 30 {
            return "Storage is almost full. Delete unnecessary files to improve performance."
        } else if health.batteryHealth < 20 {
            return "Battery is low. Charge your device."
        } else if health.overallScore >= 80 {
            return nil // No recommendation needed for good health
        } else if health.overallScore >= 60 {
            return "Consider freeing up some storage space."
        } else {
            return "Your device needs attention. Use AI Cleaner to free up space!"
        }
    }

    // MARK: - Card Tap Handlers

    private func handleContactsCardTap(results: ScanCoordinator.ScanResults) {
        let contactsAuth = ContactsCleaner.shared.checkAuthorizationStatus()

        if contactsAuth != .authorized {
            // Show permission alert
            showingContactsPermissionAlert = true
        } else if let contactsResults = results.contactsResults, contactsResults.totalDuplicates > 0 {
            // Navigate to contacts view
            showingSmartAlbums = true
        }
    }

    private func handleCalendarCardTap(results: ScanCoordinator.ScanResults) {
        let calendarAuth = CalendarCleaner.shared.checkAuthorizationStatus(for: .event)

        if calendarAuth != .authorized {
            // Show permission alert
            showingCalendarPermissionAlert = true
        } else if let calendarResults = results.calendarResults, calendarResults.totalCleanableEvents > 0 {
            // Navigate to calendar view
            showingSmartAlbums = true
        }
    }

    // MARK: - Storage Recommendations

    private var storageRecommendationsWidget: some View {
        let storage = SystemInsights.shared.getStorageInfo()
        return CompactRecommendationsWidget(storageInfo: storage)
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
