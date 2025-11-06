//
//  ScanProgressView.swift
//  AI Cleaner
//
//  View for displaying scan progress
//

import SwiftUI
internal import Combine

struct ScanProgressView: View {
    @ObservedObject var coordinator: ScanCoordinator

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Animated Icon
            ProgressRingView(progress: coordinator.progress.percentage)

            VStack(spacing: 12) {
                Text(coordinator.progress.currentStep)
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("\(coordinator.progress.currentItemIndex) / \(coordinator.progress.totalItems)")
                    .font(.body)
                    .foregroundColor(.secondary)

                if coordinator.progress.percentage > 0 {
                    Text(String(format: "%.0f%% Complete", coordinator.progress.percentage * 100))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            ProgressView(value: coordinator.progress.percentage)
                .progressViewStyle(.linear)
                .frame(maxWidth: 300)

            Spacer()

            Button(action: {
                coordinator.cancelScan()
            }) {
                Text("Cancel")
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
            }
            .padding(.bottom, 32)
        }
        .padding()
    }
}

// MARK: - Progress Ring

struct ProgressRingView: View {
    let progress: Double

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                .frame(width: 120, height: 120)

            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [.blue, .purple],
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
                .foregroundColor(.blue)
        }
    }
}

// MARK: - Results View

struct ScanResultsView: View {
    let results: ScanCoordinator.ScanResults
    @Binding var showingResults: Bool

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.green)

                        Text("Scan Complete!")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("Found \(results.statistics.totalDuplicates) items to clean")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 32)

                    // Potential Savings Card
                    VStack(spacing: 16) {
                        Text("Potential Space Savings")
                            .font(.headline)

                        Text(results.formattedSavings)
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.blue)

                        Text("by cleaning suggested items")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(16)
                    .padding(.horizontal)

                    // Categories
                    VStack(spacing: 16) {
                        if !results.similarGroups.isEmpty {
                            CategoryCard(
                                icon: "square.on.square",
                                title: "Similar Photos",
                                count: results.statistics.totalDuplicates,
                                color: .blue
                            )
                        }

                        if !results.blurryPhotos.isEmpty {
                            CategoryCard(
                                icon: "eye.slash",
                                title: "Blurry Photos",
                                count: results.blurryPhotos.count,
                                color: .orange
                            )
                        }

                        if !results.darkPhotos.isEmpty {
                            CategoryCard(
                                icon: "moon",
                                title: "Dark Photos",
                                count: results.darkPhotos.count,
                                color: .purple
                            )
                        }

                        if !results.screenshots.isEmpty {
                            CategoryCard(
                                icon: "camera.viewfinder",
                                title: "Screenshots",
                                count: results.screenshots.count,
                                color: .green
                            )
                        }

                        if !results.largeVideos.isEmpty {
                            CategoryCard(
                                icon: "video.fill",
                                title: "Large Videos",
                                count: results.largeVideos.count,
                                color: .red
                            )
                        }
                    }
                    .padding(.horizontal)

                    // Action Button
                    Button(action: {
                        showingResults = false
                    }) {
                        Text("Start Cleaning")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingResults = false
                    }
                }
            }
        }
    }
}

// MARK: - Category Card

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
                    .font(.headline)
                Text("\(count) items found")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
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
