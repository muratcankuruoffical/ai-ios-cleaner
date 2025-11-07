//
//  ScanProgressView.swift
//  AI Cleaner
//
//  View for displaying scan progress - Dark Theme
//

import SwiftUI
internal import Combine

struct ScanProgressView: View {
    @ObservedObject var coordinator: ScanCoordinator

    var body: some View {
        ZStack {
            CleanerTheme.background
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Animated Icon
                ProgressRingView(progress: coordinator.progress.percentage)

                VStack(spacing: 12) {
                    Text(coordinator.progress.currentStep)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(CleanerTheme.textPrimary)

                    Text("\(coordinator.progress.currentItemIndex) / \(coordinator.progress.totalItems)")
                        .cleanerFont(.body)

                    if coordinator.progress.percentage > 0 {
                        Text(String(format: "%.0f%% Complete", coordinator.progress.percentage * 100))
                            .cleanerFont(.caption)
                    }
                }

                ProgressView(value: coordinator.progress.percentage)
                    .progressViewStyle(.linear)
                    .tint(CleanerTheme.primary)
                    .frame(maxWidth: 300)

                Spacer()

                Button(action: {
                    coordinator.cancelScan()
                }) {
                    Text("Cancel")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(CleanerTheme.accentRed)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(CleanerTheme.accentRed.opacity(0.15))
                        .cornerRadius(12)
                }
                .padding(.bottom, 32)
            }
            .padding()
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Progress Ring (Dark Theme)

struct ProgressRingView: View {
    let progress: Double

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(CleanerTheme.surface, lineWidth: 12)
                .frame(width: 120, height: 120)

            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [CleanerTheme.primary, CleanerTheme.accent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 120, height: 120)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: progress)

            // Icon
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(CleanerTheme.primary)
        }
    }
}

// MARK: - Results View (Dark Theme)

struct ScanResultsView: View {
    let results: ScanCoordinator.ScanResults
    @Binding var showingResults: Bool

    var body: some View {
        NavigationView {
            ZStack {
                CleanerTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(CleanerTheme.accentGreen.opacity(0.2))
                                    .frame(width: 100, height: 100)

                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 64))
                                    .foregroundColor(CleanerTheme.accentGreen)
                            }

                            Text("Scan Complete!")
                                .cleanerFont(.title)

                            Text("Found \(results.statistics.totalDuplicates) items to clean")
                                .cleanerFont(.body)
                        }
                        .padding(.top, 32)

                        // Potential Savings Card
                        VStack(spacing: 16) {
                            Text("Potential Space Savings")
                                .cleanerFont(.subtitle)

                            Text(results.formattedSavings)
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(CleanerTheme.accent)

                            Text("by cleaning suggested items")
                                .cleanerFont(.caption)
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity)
                        .card(backgroundColor: CleanerTheme.surface)
                        .padding(.horizontal)

                        // Categories
                        VStack(spacing: 12) {
                            if !results.similarGroups.isEmpty {
                                CategoryCard(
                                    icon: "rectangle.on.rectangle.angled",
                                    title: "Similar Photos",
                                    count: results.statistics.totalDuplicates,
                                    color: CleanerTheme.iconPrimary
                                )
                            }

                            if !results.blurryPhotos.isEmpty {
                                CategoryCard(
                                    icon: "eye.slash",
                                    title: "Blurry Photos",
                                    count: results.blurryPhotos.count,
                                    color: CleanerTheme.iconPrimary
                                )
                            }

                            if !results.darkPhotos.isEmpty {
                                CategoryCard(
                                    icon: "moon",
                                    title: "Dark Photos",
                                    count: results.darkPhotos.count,
                                    color: CleanerTheme.iconPrimary
                                )
                            }

                            if !results.screenshots.isEmpty {
                                CategoryCard(
                                    icon: "camera.viewfinder",
                                    title: "Screenshots",
                                    count: results.screenshots.count,
                                    color: CleanerTheme.iconPrimary
                                )
                            }

                            if !results.largeVideos.isEmpty {
                                CategoryCard(
                                    icon: "film",
                                    title: "Large Videos",
                                    count: results.largeVideos.count,
                                    color: CleanerTheme.iconPrimary
                                )
                            }
                        }
                        .padding(.horizontal)

                        // Action Button
                        Button(action: {
                            showingResults = false
                        }) {
                            Text("Start Cleaning")
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
                        .padding(.horizontal)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingResults = false
                    }
                    .foregroundColor(CleanerTheme.primary)
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}

// MARK: - Category Card (Dark Theme)

struct CategoryCard: View {
    let icon: String
    let title: String
    let count: Int
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(CleanerTheme.textPrimary)
                Text("\(count) items found")
                    .cleanerFont(.caption)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(CleanerTheme.iconPrimary)
        }
        .padding(16)
        .card(backgroundColor: CleanerTheme.surface)
    }
}

// MARK: - Preview

#Preview("Progress") {
    ScanProgressView(coordinator: ScanCoordinator())
}

#Preview("Results") {
    ScanResultsView(
        results: ScanCoordinator.ScanResults(
            sessionId: UUID(),
            scanDuration: 45.0,
            totalPhotos: 1000,
            totalVideos: 50,
            similarGroups: [],
            blurryPhotos: [],
            darkPhotos: [],
            screenshots: [],
            largeVideos: [],
            similarVideoGroups: [],
            optimizablePhotos: [],
            documents: [],
            contactsResults: nil,
            calendarResults: nil,
            potentialSavingsBytes: 2_500_000_000,
            statistics: CleanupStatistics(
                totalGroups: 25,
                totalDuplicates: 150,
                potentialSavingsBytes: 2_500_000_000,
                largestGroupSize: 8
            )
        ),
        showingResults: .constant(true)
    )
}
