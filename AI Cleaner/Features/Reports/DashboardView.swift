//
//  DashboardView.swift
//  AI Cleaner
//
//  Main dashboard with scan results and reports
//

import SwiftUI
import Charts

struct DashboardView: View {
    @StateObject private var scanCoordinator = ScanCoordinator()
    @State private var showingScanProgress = false
    @State private var showingResults = false
    @State private var showingSmartAlbums = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerView

                    // Scan Button or Results
                    if let results = scanCoordinator.scanResults {
                        resultsCard(results)
                    } else {
                        scanPromptCard
                    }

                    // Quick Stats
                    if let results = scanCoordinator.scanResults {
                        quickStatsView(results)
                    }

                    // Recent Activity
                    recentActivityView
                }
                .padding()
            }
            .navigationTitle("AI Cleaner")
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
            VStack(alignment: .leading, spacing: 4) {
                Text("Hello!")
                    .font(.title)
                    .fontWeight(.bold)
                Text("Keep your photos organized")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            NavigationLink(destination: SettingsView()) {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                    .foregroundColor(.gray)
            }
        }
    }

    // MARK: - Scan Prompt Card

    private var scanPromptCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            VStack(spacing: 8) {
                Text("Start Smart Scan")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Analyze your photo library for duplicates, blurry photos, and more")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: {
                scanCoordinator.startScan()
            }) {
                Text("Start Scan")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(16)
    }

    // MARK: - Results Card

    private func resultsCard(_ results: ScanCoordinator.ScanResults) -> some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Last Scan Results")
                        .font(.headline)
                    Text("Found \(results.statistics.totalDuplicates) items")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: {
                    scanCoordinator.startScan()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
            }

            Divider()

            HStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text(results.formattedSavings)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("Potential Savings")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()
                    .frame(height: 40)

                VStack(spacing: 8) {
                    Text("\(results.totalPhotos)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text("Photos Scanned")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Button(action: {
                showingSmartAlbums = true
            }) {
                Text("View Smart Albums")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
    }

    // MARK: - Quick Stats

    private func quickStatsView(_ results: ScanCoordinator.ScanResults) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Categories")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatCard(
                    icon: "square.on.square",
                    title: "Duplicates",
                    value: "\(results.statistics.totalDuplicates)",
                    color: .blue
                )

                StatCard(
                    icon: "eye.slash",
                    title: "Blurry",
                    value: "\(results.blurryPhotos.count)",
                    color: .orange
                )

                StatCard(
                    icon: "moon",
                    title: "Dark",
                    value: "\(results.darkPhotos.count)",
                    color: .purple
                )

                StatCard(
                    icon: "camera.viewfinder",
                    title: "Screenshots",
                    value: "\(results.screenshots.count)",
                    color: .green
                )
            }
        }
    }

    // MARK: - Recent Activity

    private var recentActivityView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.headline)

            VStack(spacing: 12) {
                ActivityRow(
                    icon: "checkmark.circle.fill",
                    title: "Scan completed",
                    subtitle: "Today at 10:30 AM",
                    color: .green
                )

                ActivityRow(
                    icon: "trash.circle.fill",
                    title: "Deleted 45 photos",
                    subtitle: "Yesterday",
                    color: .red
                )
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
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
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    DashboardView()
}
