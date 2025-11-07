//
//  DashboardView.swift
//  AI Cleaner
//
//  Main dashboard with scan results and reports - Dark Theme
//

import SwiftUI
import Charts
internal import EventKit
internal import Combine

struct DashboardView: View {
    @StateObject private var scanCoordinator = ScanCoordinator()
    @State private var showingScanProgress = false
    @State private var showingResults = false
    @State private var showingSmartAlbums = false
    @State private var showingContactsPermissionAlert = false
    @State private var showingCalendarPermissionAlert = false
    @State private var animateContent = false

    var body: some View {
        NavigationView {
            ZStack {
                // Dark Background
                CleanerTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerView

                        // Storage Donut Chart (if scan completed)
                        if let results = scanCoordinator.scanResults {
                            storageDonutCard(results)
                                .transition(.scale.combined(with: .opacity))
                        }

                        // Scan Button or Results
                        if let results = scanCoordinator.scanResults {
                            resultsCard(results)
                                .transition(.scale.combined(with: .opacity))
                        } else {
                            scanPromptCard
                                .transition(.scale.combined(with: .opacity))
                        }

                        // Quick Stats
                        if let results = scanCoordinator.scanResults {
                            quickStatsView(results)
                                .transition(.scale.combined(with: .opacity))
                        }

                        // Recent Activity
                        if scanCoordinator.scanResults != nil {
                            recentActivityView
                                .transition(.scale.combined(with: .opacity))
                        }

                        // System Health
                        systemHealthView
                            .transition(.scale.combined(with: .opacity))

                        // Storage Recommendations
                        storageRecommendationsWidget
                            .transition(.scale.combined(with: .opacity))
                    }
                    .padding()
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("AI Cleaner")
                        .cleanerFont(.title)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape.fill")
                            .font(.title3)
                            .foregroundColor(CleanerTheme.iconPrimary)
                    }
                }
            }
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
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                animateContent = true
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Hello!")
                    .cleanerFont(.title)
                Text("Keep your photos organized")
                    .cleanerFont(.label)
            }

            Spacer()
        }
    }

    // MARK: - Storage Donut Card

    private func storageDonutCard(_ results: ScanCoordinator.ScanResults) -> some View {
        let storage = SystemInsights.shared.getStorageInfo()
        let potentialSavingsBytes = results.statistics.potentialSavingsBytes
        let potentialSavingsGB = Double(potentialSavingsBytes) / 1_073_741_824 // Convert to GB

        return VStack(spacing: 20) {
            HStack {
                Text("Storage Overview")
                    .cleanerFont(.subtitle)
                Spacer()
            }

            if let storage = storage {
                ZStack {
                    // Background Ring
                    Circle()
                        .stroke(CleanerTheme.surface, lineWidth: 20)
                        .frame(width: 180, height: 180)

                    // Usage Ring
                    Circle()
                        .trim(from: 0, to: storage.usagePercentage / 100)
                        .stroke(
                            LinearGradient(
                                colors: [CleanerTheme.primary, CleanerTheme.accent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 20, lineCap: .round)
                        )
                        .frame(width: 180, height: 180)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeOut(duration: 1.0), value: storage.usagePercentage)

                    // Center Content
                    VStack(spacing: 4) {
                        Text("\(Int(storage.usagePercentage))%")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(CleanerTheme.textPrimary)

                        Text("Used")
                            .cleanerFont(.caption)
                    }
                }

                // Stats Grid
                HStack(spacing: 16) {
                    VStack(spacing: 4) {
                        Text(storage.formatBytes(storage.usedSpace))
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(CleanerTheme.textPrimary)
                        Text("Used")
                            .cleanerFont(.caption)
                    }
                    .frame(maxWidth: .infinity)

                    Divider()
                        .frame(height: 40)
                        .background(CleanerTheme.surface)

                    VStack(spacing: 4) {
                        Text(storage.formatBytes(storage.freeSpace))
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(CleanerTheme.accentGreen)
                        Text("Free")
                            .cleanerFont(.caption)
                    }
                    .frame(maxWidth: .infinity)

                    Divider()
                        .frame(height: 40)
                        .background(CleanerTheme.surface)

                    VStack(spacing: 4) {
                        Text(String(format: "%.1f GB", potentialSavingsGB))
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(CleanerTheme.accent)
                        Text("Can Save")
                            .cleanerFont(.caption)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(24)
        .card(backgroundColor: CleanerTheme.surface)
    }

    // MARK: - Scan Prompt Card

    private var scanPromptCard: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(CleanerTheme.primary)
                .symbolEffect(.bounce, options: .repeat(2))

            VStack(spacing: 8) {
                Text("Start Smart Scan")
                    .cleanerFont(.title)

                Text("Analyze your photo library for duplicates, blurry photos, and more")
                    .cleanerFont(.body)
                    .multilineTextAlignment(.center)
            }

            Button(action: {
                scanCoordinator.startScan()
            }) {
                Text("Start Scan")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [CleanerTheme.primary, Color(hex: "#0066DD")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
            }
        }
        .padding(24)
        .card(backgroundColor: CleanerTheme.surface)
    }

    // MARK: - Results Card

    private func resultsCard(_ results: ScanCoordinator.ScanResults) -> some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Last Scan Results")
                        .cleanerFont(.subtitle)
                    Text("Found \(results.statistics.totalDuplicates) items")
                        .cleanerFont(.caption)
                }

                Spacer()

                Button(action: {
                    scanCoordinator.startScan()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title2)
                        .foregroundColor(CleanerTheme.iconActive)
                        .padding(12)
                        .background(CleanerTheme.primary.opacity(0.2))
                        .clipShape(Circle())
                }
            }

            Divider()
                .background(CleanerTheme.cardBackground)

            HStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text(results.formattedSavings)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(CleanerTheme.accent)
                    Text("Potential Savings")
                        .cleanerFont(.caption)
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .frame(height: 40)
                    .background(CleanerTheme.cardBackground)

                VStack(spacing: 8) {
                    Text("\(results.totalPhotos)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(CleanerTheme.accentGreen)
                    Text("Photos Scanned")
                        .cleanerFont(.caption)
                }
                .frame(maxWidth: .infinity)
            }

            Button(action: {
                showingSmartAlbums = true
            }) {
                Text("View Smart Albums")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [CleanerTheme.primary, Color(hex: "#0066DD")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
            }
        }
        .padding(24)
        .card(backgroundColor: CleanerTheme.surface)
    }

    // MARK: - Quick Stats

    private func quickStatsView(_ results: ScanCoordinator.ScanResults) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("CATEGORIES")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(CleanerTheme.textSecondary)
                .tracking(1.2)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatCard(
                    icon: "rectangle.on.rectangle.angled",
                    title: "Duplicates",
                    value: "\(results.statistics.totalDuplicates)",
                    color: CleanerTheme.iconPrimary
                )

                StatCard(
                    icon: "eye.slash",
                    title: "Blurry",
                    value: "\(results.blurryPhotos.count)",
                    color: CleanerTheme.iconPrimary
                )

                StatCard(
                    icon: "moon",
                    title: "Dark",
                    value: "\(results.darkPhotos.count)",
                    color: CleanerTheme.iconPrimary
                )

                StatCard(
                    icon: "camera.viewfinder",
                    title: "Screenshots",
                    value: "\(results.screenshots.count)",
                    color: CleanerTheme.iconPrimary
                )

                StatCard(
                    icon: "film",
                    title: "Large Videos",
                    value: "\(results.largeVideos.count)",
                    color: CleanerTheme.iconPrimary
                )

                StatCard(
                    icon: "film.stack",
                    title: "Similar Videos",
                    value: "\(results.similarVideoGroups.reduce(0) { $0 + $1.videos.count })",
                    color: CleanerTheme.iconPrimary
                )

                StatCard(
                    icon: "arrow.down.circle",
                    title: "Optimizable",
                    value: "\(results.optimizablePhotos.count)",
                    color: CleanerTheme.iconPrimary
                )

                StatCard(
                    icon: "doc.text",
                    title: "Documents",
                    value: "\(results.documents.count)",
                    color: CleanerTheme.iconPrimary
                )

                // Contacts Card
                Button(action: {
                    handleContactsCardTap(results: results)
                }) {
                    StatCard(
                        icon: "person.2",
                        title: "Contacts",
                        value: "\(results.contactsResults?.totalDuplicates ?? 0)",
                        color: CleanerTheme.iconPrimary
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
                        color: CleanerTheme.iconPrimary
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Recent Activity

    private var recentActivityView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("RECENT ACTIVITY")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(CleanerTheme.textSecondary)
                .tracking(1.2)

            VStack(spacing: 12) {
                ActivityRow(
                    icon: "checkmark.circle.fill",
                    title: "Scan completed",
                    subtitle: "Today at 10:30 AM",
                    color: CleanerTheme.accentGreen
                )

                Divider()
                    .background(CleanerTheme.cardBackground)

                ActivityRow(
                    icon: "trash.circle.fill",
                    title: "Deleted 45 photos",
                    subtitle: "Yesterday",
                    color: CleanerTheme.accentRed
                )
            }
            .padding(20)
            .card(backgroundColor: CleanerTheme.surface)
        }
    }

    // MARK: - System Health

    private var systemHealthView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("SYSTEM HEALTH")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(CleanerTheme.textSecondary)
                .tracking(1.2)

            let health = SystemInsights.shared.calculateSystemHealth()
            let battery = SystemInsights.shared.getBatteryInfo()
            let storage = SystemInsights.shared.getStorageInfo()

            // Overall Health Score
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(colorForStatus(health.statusColor).opacity(0.2))
                            .frame(width: 60, height: 60)

                        Image(systemName: health.statusIcon)
                            .font(.title)
                            .foregroundColor(colorForStatus(health.statusColor))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text("Grade: \(health.grade)")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(CleanerTheme.textPrimary)
                            Text(gradeDescription(health.grade))
                                .cleanerFont(.caption)
                        }
                        Text("\(health.overallScore)% Overall Health")
                            .cleanerFont(.label)
                    }

                    Spacer()
                }

                // Breakdown
                HStack(spacing: 16) {
                    HStack(spacing: 6) {
                        Image(systemName: "battery.100")
                            .font(.caption)
                            .foregroundColor(CleanerTheme.iconPrimary)
                        Text("Battery: \(health.batteryHealth)%")
                            .cleanerFont(.caption)
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "internaldrive")
                            .font(.caption)
                            .foregroundColor(CleanerTheme.iconPrimary)
                        Text("Storage: \(health.storageHealth)%")
                            .cleanerFont(.caption)
                    }
                }

                // Recommendation
                if let recommendation = healthRecommendation(health) {
                    HStack(spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption)
                            .foregroundColor(CleanerTheme.accent)
                        Text(recommendation)
                            .cleanerFont(.caption)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(CleanerTheme.accent.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding(20)
            .card(backgroundColor: CleanerTheme.surface)

            // Battery & Storage Grid
            HStack(spacing: 12) {
                // Battery
                VStack(spacing: 12) {
                    Image(systemName: battery.statusIcon)
                        .font(.title2)
                        .foregroundColor(colorForStatus(battery.statusColor))

                    VStack(spacing: 4) {
                        Text("\(battery.percentage)%")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(CleanerTheme.textPrimary)
                        Text("Battery")
                            .cleanerFont(.caption)
                    }

                    if battery.isLowPowerModeEnabled {
                        Text("Low Power")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(CleanerTheme.accent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(CleanerTheme.accent.opacity(0.2))
                            .cornerRadius(6)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(16)
                .card(backgroundColor: CleanerTheme.surface)

                // Storage
                if let storage = storage {
                    VStack(spacing: 12) {
                        Image(systemName: storage.statusIcon)
                            .font(.title2)
                            .foregroundColor(colorForStatus(storage.statusColor))

                        VStack(spacing: 4) {
                            Text(storage.formatBytes(storage.freeSpace))
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(CleanerTheme.textPrimary)
                            Text("Available")
                                .cleanerFont(.caption)
                        }

                        Text("\(Int(storage.usagePercentage))% Used")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(CleanerTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .card(backgroundColor: CleanerTheme.surface)
                }
            }
        }
    }

    private func colorForStatus(_ status: String) -> Color {
        switch status {
        case "green": return CleanerTheme.accentGreen
        case "orange": return CleanerTheme.accent
        case "red": return CleanerTheme.accentRed
        case "blue": return CleanerTheme.primary
        default: return CleanerTheme.iconPrimary
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

    // MARK: - Storage Recommendations Widget

    private var storageRecommendationsWidget: some View {
        let storage = SystemInsights.shared.getStorageInfo()
        return CompactRecommendationsWidget(storageInfo: storage)
    }
}

// MARK: - Stat Card (Dark Theme)

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(CleanerTheme.textPrimary)

            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(CleanerTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 12)
        .card(backgroundColor: CleanerTheme.surface)
    }
}

// MARK: - Activity Row (Dark Theme)

struct ActivityRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(CleanerTheme.textPrimary)
                Text(subtitle)
                    .cleanerFont(.caption)
            }

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    DashboardView()
}
