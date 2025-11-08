//
//  DashboardView.swift
//  AI Cleaner
//
//  Main dashboard with scan results and reports - Dark Theme
//

import SwiftUI
import Charts
import CoreData
internal import EventKit
internal import Combine

struct DashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var scanCoordinator = ScanCoordinator()
    @State private var showingScanProgress = false
    @State private var showingResults = false
    @State private var showingSmartAlbums = false
    @State private var showingContactsPermissionAlert = false
    @State private var showingCalendarPermissionAlert = false
    @State private var animateContent = false

    // Fetch recent activities from CoreData
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ActivityLog.timestamp, ascending: false)],
        predicate: nil,
        animation: .default
    ) var recentActivities: FetchedResults<ActivityLog>

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

                        // Storage Donut Chart
                        storageDonutCard(scanCoordinator.scanResults)
                            .transition(.scale.combined(with: .opacity))

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
                        recentActivityView
                            .transition(.scale.combined(with: .opacity))

                        // System Health
                        systemHealthView
                            .transition(.scale.combined(with: .opacity))

                        // Storage Recommendations
                        storageRecommendationsWidget
                            .transition(.scale.combined(with: .opacity))

                        // Tools Section
                        toolsSection
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
                            .environmentObject(scanCoordinator)
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
            // Debug: Check if context is properly connected
            print("🔍 [Dashboard] ViewContext: \(viewContext)")
            print("🔍 [Dashboard] Context has coordinator: \(viewContext.persistentStoreCoordinator != nil)")
            print("🔍 [Dashboard] Recent activities count: \(recentActivities.count)")

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

    private func storageDonutCard(_ results: ScanCoordinator.ScanResults?) -> some View {
        let storage = SystemInsights.shared.getStorageInfo()
        let totalSavedBytes = SavingsTracker.shared.totalBytesSaved
        let totalSavedGB = Double(totalSavedBytes) / 1_073_741_824 // Convert to GB

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
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(CleanerTheme.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .multilineTextAlignment(.center)
                        Text("Used")
                            .cleanerFont(.caption)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, minHeight: 50)

                    Divider()
                        .frame(height: 40)
                        .background(CleanerTheme.surface)

                    VStack(spacing: 4) {
                        Text(storage.formatBytes(storage.freeSpace))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(CleanerTheme.accentGreen)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .multilineTextAlignment(.center)
                        Text("Free")
                            .cleanerFont(.caption)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, minHeight: 50)

                    // Total Saved - always show user's achievements
                    Divider()
                        .frame(height: 40)
                        .background(CleanerTheme.surface)

                    VStack(spacing: 4) {
                        Text(String(format: "%.1f GB", totalSavedGB))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(CleanerTheme.accentGreen)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .multilineTextAlignment(.center)
                        Text("Total Saved")
                            .cleanerFont(.caption)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, minHeight: 50)
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
                    Text(results.issuesDescription)
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
                    Text("\(results.totalIssuesFound)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(CleanerTheme.accentRed)
                    Text("Issues Found")
                        .cleanerFont(.caption)
                }
                .frame(maxWidth: .infinity)
            }

            Button(action: {
                showingSmartAlbums = true
            }) {
                Text("View Scan Results")
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

            if recentActivities.isEmpty {
                let _ = print("📊 [Dashboard] Recent activities is EMPTY - count: 0")
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "clock")
                        .font(.system(size: 32))
                        .foregroundColor(CleanerTheme.iconPrimary.opacity(0.5))
                    Text("No recent activity")
                        .cleanerFont(.body)
                        .foregroundColor(CleanerTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(32)
                .card(backgroundColor: CleanerTheme.surface)
            } else {
                let _ = print("📊 [Dashboard] Recent activities FOUND - count: \(recentActivities.count)")
                let _ = recentActivities.prefix(5).forEach { activity in
                    print("   - Activity: \(activity.displayTitle) at \(activity.timestamp?.description ?? "nil")")
                }
                VStack(spacing: 12) {
                    ForEach(Array(recentActivities.prefix(5).enumerated()), id: \.element.id) { index, activity in
                        if index > 0 {
                            Divider()
                                .background(CleanerTheme.cardBackground)
                        }

                        ActivityRow(
                            icon: activity.iconName,
                            title: activity.displayTitle,
                            subtitle: activity.timestamp?.relativeFormatted() ?? "Unknown",
                            color: colorForActivity(activity.iconColor)
                        )
                    }
                }
                .padding(20)
                .card(backgroundColor: CleanerTheme.surface)
            }
        }
    }

    private func colorForActivity(_ colorName: String) -> Color {
        switch colorName {
        case "green": return CleanerTheme.accentGreen
        case "red": return CleanerTheme.accentRed
        case "blue": return CleanerTheme.primary
        case "purple": return Color.purple
        default: return CleanerTheme.iconPrimary
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

        switch contactsAuth {
        case .notDetermined:
            // Request permission directly - show system dialog
            Task { @MainActor in
                do {
                    let granted = await ContactsCleaner.shared.requestAuthorization()
                    if granted {
                        // Permission granted, rescan to get contacts data
                        scanCoordinator.startScan()
                    } else {
                        // User denied, show settings alert
                        showingContactsPermissionAlert = true
                    }
                } catch {
                    print("❌ Contacts authorization error: \(error)")
                    showingContactsPermissionAlert = true
                }
            }
        case .denied, .restricted:
            // Already denied, must go to Settings
            showingContactsPermissionAlert = true
        case .authorized:
            // Permission granted, show results
            if let contactsResults = results.contactsResults, contactsResults.totalDuplicates > 0 {
                showingSmartAlbums = true
            }
        }
    }

    private func handleCalendarCardTap(results: ScanCoordinator.ScanResults) {
        let calendarAuth = CalendarCleaner.shared.checkAuthorizationStatus(for: .event)

        switch calendarAuth {
        case .notDetermined:
            // Request permission directly - show system dialog
            Task { @MainActor in
                do {
                    let granted = await CalendarCleaner.shared.requestAuthorization(for: .event)
                    if granted {
                        // Permission granted, rescan to get calendar data
                        scanCoordinator.startScan()
                    } else {
                        // User denied, show settings alert
                        showingCalendarPermissionAlert = true
                    }
                } catch {
                    print("❌ Calendar authorization error: \(error)")
                    showingCalendarPermissionAlert = true
                }
            }
        case .denied, .restricted:
            // Already denied, must go to Settings
            showingCalendarPermissionAlert = true
        case .authorized:
            // Permission granted, show results
            if let calendarResults = results.calendarResults, calendarResults.totalCleanableEvents > 0 {
                showingSmartAlbums = true
            }
        }
    }

    // MARK: - Storage Recommendations Widget

    private var storageRecommendationsWidget: some View {
        let storage = SystemInsights.shared.getStorageInfo()
        return CompactRecommendationsWidget(storageInfo: storage)
    }

    // MARK: - Tools Section

    private var toolsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("TOOLS")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(CleanerTheme.textSecondary)
                .tracking(1.2)

            NavigationLink(destination: ContactsBackupView()) {
                ToolCard(
                    icon: "person.2.crop.square.stack.fill",
                    title: "Contact Backup",
                    description: "Backup and restore your contacts",
                    color: CleanerTheme.primary
                )
            }
        }
    }
}

// MARK: - Tool Card

struct ToolCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 60, height: 60)

                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(CleanerTheme.textPrimary)

                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(CleanerTheme.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(CleanerTheme.textSecondary)
        }
        .padding(20)
        .background(CleanerTheme.surface)
        .cornerRadius(16)
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
