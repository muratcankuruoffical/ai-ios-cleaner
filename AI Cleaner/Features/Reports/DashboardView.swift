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
    @State private var showingStorageRecommendations = false

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

                            // System Health
                            systemHealthView
                                .fadeIn(delay: 0.5)

                            // Storage Recommendations
                            storageRecommendationsWidget
                                .fadeIn(delay: 0.6)
                        } else {
                            // Scan Prompt Card
                            scanPromptCard
                                .scaleIn(delay: 0.2)
                        }

                        // Recent Activity
                        if scanCoordinator.scanResults != nil {
                            recentActivityView
                                .fadeIn(delay: 0.7)
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
            .sheet(isPresented: $showingStorageRecommendations) {
                if let storage = SystemInsights.shared.getStorageInfo() {
                    NavigationView {
                        StorageRecommendationsView(storageInfo: storage)
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
                    Text("\(totalIssuesCount(results))")
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

                // New categories with unified colors
                if !results.largeVideos.isEmpty {
                    AnimatedStatCard(
                        icon: "video.fill",
                        title: "Large Videos",
                        value: "\(results.largeVideos.count)",
                        color: CleanerTheme.accentRed,
                        delay: 0.5
                    )
                }

                if !results.similarVideoGroups.isEmpty {
                    AnimatedStatCard(
                        icon: "video.badge.plus",
                        title: "Similar Videos",
                        value: "\(results.similarVideoGroups.reduce(0) { $0 + $1.videos.count })",
                        color: CleanerTheme.primary,
                        delay: 0.6
                    )
                }

                if !results.optimizablePhotos.isEmpty {
                    AnimatedStatCard(
                        icon: "arrow.down.circle",
                        title: "Optimizable",
                        value: "\(results.optimizablePhotos.count)",
                        color: CleanerTheme.accent,
                        delay: 0.7
                    )
                }

                if !results.documents.isEmpty {
                    AnimatedStatCard(
                        icon: "doc.text",
                        title: "Documents",
                        value: "\(results.documents.count)",
                        color: CleanerTheme.accentGreen,
                        delay: 0.8
                    )
                }

                // Contacts Card with permission check
                if let contactsResults = results.contactsResults, contactsResults.totalDuplicates > 0 {
                    Button(action: {
                        handleContactsCardTap(results: results)
                    }) {
                        AnimatedStatCard(
                            icon: "person.2.fill",
                            title: "Contacts",
                            value: "\(contactsResults.totalDuplicates)",
                            color: CleanerTheme.primary,
                            delay: 0.9
                        )
                    }
                    .buttonStyle(.plain)
                }

                // Calendar Card with permission check
                if let calendarResults = results.calendarResults, calendarResults.totalCleanableEvents > 0 {
                    Button(action: {
                        handleCalendarCardTap(results: results)
                    }) {
                        AnimatedStatCard(
                            icon: "calendar.badge.clock",
                            title: "Old Events",
                            value: "\(calendarResults.totalCleanableEvents)",
                            color: CleanerTheme.accentGreen,
                            delay: 1.0
                        )
                    }
                    .buttonStyle(.plain)
                }
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

    // MARK: - System Health

    private var systemHealthView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("System Health")
                .cleanerFont(.headline)
                .foregroundColor(CleanerTheme.textPrimary)
                .padding(.horizontal, 4)

            let health = SystemInsights.shared.calculateSystemHealth()
            let battery = SystemInsights.shared.getBatteryInfo()
            let storage = SystemInsights.shared.getStorageInfo()

            // Overall Health Score
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(colorForStatus(health.statusColor).opacity(0.2))
                            .frame(width: 56, height: 56)

                        Image(systemName: health.statusIcon)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(CleanerTheme.iconGray)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text("Grade: \(health.grade)")
                                .cleanerFont(.title2)
                                .foregroundColor(CleanerTheme.textPrimary)
                            Text(gradeDescription(health.grade))
                                .cleanerFont(.caption)
                                .foregroundColor(CleanerTheme.textSecondary)
                        }
                        Text("\(health.overallScore)% Overall Health")
                            .cleanerFont(.subheadline)
                            .foregroundColor(CleanerTheme.textSecondary)
                    }

                    Spacer()
                }

                // Recommendation
                if let recommendation = healthRecommendation(health) {
                    HStack(spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption)
                            .foregroundColor(CleanerTheme.accent)
                        Text(recommendation)
                            .cleanerFont(.caption)
                            .foregroundColor(CleanerTheme.textSecondary)
                    }
                    .padding(12)
                    .background(CleanerTheme.accent.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding(20)
            .background(CleanerTheme.cardBackground)
            .cornerRadius(16)

            // Battery & Storage Grid
            HStack(spacing: 16) {
                // Battery
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(colorForStatus(battery.statusColor).opacity(0.15))
                            .frame(width: 48, height: 48)

                        Image(systemName: battery.statusIcon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(CleanerTheme.iconGray)
                    }

                    VStack(spacing: 4) {
                        Text("\(battery.percentage)%")
                            .cleanerFont(.headline)
                            .foregroundColor(CleanerTheme.textPrimary)
                        Text("Battery")
                            .cleanerFont(.caption)
                            .foregroundColor(CleanerTheme.textSecondary)
                    }

                    if battery.isLowPowerModeEnabled {
                        Text("Low Power")
                            .cleanerFont(.caption2)
                            .foregroundColor(CleanerTheme.accent)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(CleanerTheme.cardBackground)
                .cornerRadius(16)

                // Storage
                if let storage = storage {
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(colorForStatus(storage.statusColor).opacity(0.15))
                                .frame(width: 48, height: 48)

                            Image(systemName: storage.statusIcon)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(CleanerTheme.iconGray)
                        }

                        VStack(spacing: 4) {
                            Text(storage.formatBytes(storage.freeSpace))
                                .cleanerFont(.headline)
                                .foregroundColor(CleanerTheme.textPrimary)
                            Text("Available")
                                .cleanerFont(.caption)
                                .foregroundColor(CleanerTheme.textSecondary)
                        }

                        Text("\(Int(storage.usagePercentage))% Used")
                            .cleanerFont(.caption2)
                            .foregroundColor(CleanerTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(CleanerTheme.cardBackground)
                    .cornerRadius(16)
                }
            }
        }
    }

    // MARK: - Storage Recommendations Widget

    private var storageRecommendationsWidget: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Storage Tips")
                    .cleanerFont(.headline)
                    .foregroundColor(CleanerTheme.textPrimary)

                Spacer()

                Button(action: {
                    showingStorageRecommendations = true
                }) {
                    Text("See All")
                        .cleanerFont(.callout)
                        .foregroundColor(CleanerTheme.primary)
                }
            }
            .padding(.horizontal, 4)

            if let storage = SystemInsights.shared.getStorageInfo() {
                let recommendations = StorageRecommendations.shared.generateRecommendations(for: storage)

                VStack(spacing: 12) {
                    ForEach(recommendations.prefix(3), id: \.title) { recommendation in
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(priorityColor(recommendation.priority).opacity(0.15))
                                    .frame(width: 40, height: 40)

                                Image(systemName: iconForCategory(recommendation.category))
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(CleanerTheme.iconGray)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(recommendation.title)
                                    .cleanerFont(.subheadline)
                                    .foregroundColor(CleanerTheme.textPrimary)
                                Text(recommendation.description)
                                    .cleanerFont(.caption)
                                    .foregroundColor(CleanerTheme.textSecondary)
                                    .lineLimit(2)
                            }

                            Spacer()
                        }
                        .padding(12)
                        .background(CleanerTheme.cardBackground)
                        .cornerRadius(12)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func totalIssuesCount(_ results: ScanCoordinator.ScanResults) -> Int {
        var count = results.statistics.totalDuplicates +
                   results.blurryPhotos.count +
                   results.darkPhotos.count +
                   results.screenshots.count +
                   results.largeVideos.count +
                   results.similarVideoGroups.reduce(0) { $0 + $1.videos.count } +
                   results.optimizablePhotos.count +
                   results.documents.count

        if let contactsResults = results.contactsResults {
            count += contactsResults.totalDuplicates
        }

        if let calendarResults = results.calendarResults {
            count += calendarResults.totalCleanableEvents
        }

        return count
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let gb = Double(bytes) / (1024 * 1024 * 1024)
        if gb >= 1.0 {
            return String(format: "%.1f GB", gb)
        } else {
            let mb = Double(bytes) / (1024 * 1024)
            return String(format: "%.0f MB", mb)
        }
    }

    private func colorForStatus(_ status: String) -> Color {
        switch status {
        case "green": return CleanerTheme.accentGreen
        case "orange": return CleanerTheme.accent
        case "red": return CleanerTheme.accentRed
        case "blue": return CleanerTheme.primary
        default: return CleanerTheme.iconGray
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
            return nil
        } else if health.overallScore >= 60 {
            return "Consider freeing up some storage space."
        } else {
            return "Your device needs attention. Use AI Cleaner to free up space!"
        }
    }

    private func handleContactsCardTap(results: ScanCoordinator.ScanResults) {
        let contactsAuth = ContactsCleaner.shared.checkAuthorizationStatus()

        if contactsAuth != .authorized {
            showingContactsPermissionAlert = true
        } else if let contactsResults = results.contactsResults, contactsResults.totalDuplicates > 0 {
            showingSmartAlbums = true
        }
    }

    private func handleCalendarCardTap(results: ScanCoordinator.ScanResults) {
        let calendarAuth = CalendarCleaner.shared.checkAuthorizationStatus(for: .event)

        if calendarAuth != .authorized {
            showingCalendarPermissionAlert = true
        } else if let calendarResults = results.calendarResults, calendarResults.totalCleanableEvents > 0 {
            showingSmartAlbums = true
        }
    }

    private func priorityColor(_ priority: StorageRecommendations.RecommendationPriority) -> Color {
        switch priority {
        case .high:
            return CleanerTheme.accentRed
        case .medium:
            return CleanerTheme.accent
        case .low:
            return CleanerTheme.primary
        }
    }

    private func iconForCategory(_ category: StorageRecommendations.RecommendationCategory) -> String {
        switch category {
        case .photos:
            return "photo.stack"
        case .videos:
            return "video.fill"
        case .cache:
            return "trash"
        case .apps:
            return "square.stack.3d.up"
        case .duplicates:
            return "square.on.square"
        case .system:
            return "internaldrive"
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
