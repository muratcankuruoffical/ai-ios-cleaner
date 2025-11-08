//
//  SwipeDeckView.swift
//  AI Cleaner
//
//  Modern swipe interface for reviewing and deleting photos
//

import SwiftUI
import Photos
internal import Combine

struct SwipeDeckView: View {
    @StateObject private var viewModel: SwipeDeckViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var scanCoordinator: ScanCoordinator

    init(assets: [PHAsset], category: String) {
        _viewModel = StateObject(wrappedValue: SwipeDeckViewModel(assets: assets, category: category))
    }

    var body: some View {
        ZStack {
            // Background
            CleanerTheme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerView
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .background(CleanerTheme.surface)

                // Main Card Stack
                if viewModel.hasMoreCards {
                    ZStack {
                        // Stack of cards (show top 3)
                        ForEach(Array(viewModel.remainingCards.prefix(3).enumerated()), id: \.element) { index, asset in
                            SwipeCardView(
                                asset: asset,
                                index: index,
                                isTop: index == 0,
                                onSwipe: { direction in
                                    viewModel.handleSwipe(direction: direction)
                                }
                            )
                            .offset(y: CGFloat(index * 10))
                            .scaleEffect(1.0 - CGFloat(index) * 0.03)
                            .zIndex(Double(viewModel.remainingCards.count - index))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .padding(.bottom, 12)
                } else {
                    completionView
                }

                // Action Buttons
                if viewModel.hasMoreCards {
                    actionButtonsView
                        .padding(.horizontal, 24)
                        .padding(.vertical, 20)
                        .background(CleanerTheme.surface)
                }
            }
        }
        .navigationTitle("Review Photos")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
        .alert("Delete Photos?", isPresented: $viewModel.showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete \(viewModel.toDelete.count)", role: .destructive) {
                Task {
                    await viewModel.performDeletion(scanCoordinator: scanCoordinator)
                }
            }
        } message: {
            Text("This will delete \(viewModel.toDelete.count) photos. They will be moved to Recently Deleted.")
        }
        .alert("Error", isPresented: $viewModel.showingError) {
            Button("OK") { }
        } message: {
            if let error = viewModel.lastError {
                Text(error.localizedDescription)
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: 16) {
            // Progress
            VStack(alignment: .leading, spacing: 4) {
                Text("\(viewModel.currentIndex + 1) of \(viewModel.totalCards)")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(CleanerTheme.textPrimary)

                ProgressView(value: Double(viewModel.currentIndex), total: Double(viewModel.totalCards))
                    .tint(CleanerTheme.primary)
                    .frame(width: 100)
            }

            Spacer()

            // Stats
            HStack(spacing: 12) {
                StatBadge(
                    icon: "checkmark.circle.fill",
                    count: viewModel.toKeep.count,
                    color: CleanerTheme.accentGreen
                )

                StatBadge(
                    icon: "trash.circle.fill",
                    count: viewModel.toDelete.count,
                    color: CleanerTheme.accentRed
                )
            }

            // Undo Button
            Button(action: {
                viewModel.undo()
            }) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(viewModel.swipeHistory.isEmpty ? CleanerTheme.textSecondary.opacity(0.4) : CleanerTheme.primary)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(viewModel.swipeHistory.isEmpty ? CleanerTheme.cardBackground : CleanerTheme.primary.opacity(0.15))
                    )
            }
            .disabled(viewModel.swipeHistory.isEmpty)
        }
    }

    // MARK: - Completion View

    private var completionView: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [CleanerTheme.accentGreen.opacity(0.3), CleanerTheme.accentGreen.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 90))
                    .foregroundColor(CleanerTheme.accentGreen)
            }

            VStack(spacing: 12) {
                Text("Review Complete!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(CleanerTheme.textPrimary)

                HStack(spacing: 24) {
                    VStack(spacing: 4) {
                        Text("\(viewModel.toKeep.count)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(CleanerTheme.accentGreen)
                        Text("Kept")
                            .font(.system(size: 14))
                            .foregroundColor(CleanerTheme.textSecondary)
                    }

                    Rectangle()
                        .fill(CleanerTheme.textSecondary.opacity(0.3))
                        .frame(width: 1, height: 40)

                    VStack(spacing: 4) {
                        Text("\(viewModel.toDelete.count)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(CleanerTheme.accentRed)
                        Text("To Delete")
                            .font(.system(size: 14))
                            .foregroundColor(CleanerTheme.textSecondary)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 20)
                .background(CleanerTheme.surface)
                .cornerRadius(16)
            }

            Spacer()

            VStack(spacing: 16) {
                if !viewModel.toDelete.isEmpty {
                    Button(action: {
                        viewModel.showingDeleteConfirmation = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Delete \(viewModel.toDelete.count) Photo\(viewModel.toDelete.count == 1 ? "" : "s")")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: [CleanerTheme.accentRed, CleanerTheme.accentRed.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: CleanerTheme.accentRed.opacity(0.4), radius: 12, x: 0, y: 6)
                    }
                }

                Button(action: {
                    dismiss()
                }) {
                    Text("Done")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: [CleanerTheme.primary, Color(hex: "#0066DD")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: CleanerTheme.primary.opacity(0.4), radius: 12, x: 0, y: 6)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Action Buttons

    private var actionButtonsView: some View {
        HStack(spacing: 16) {
            // Keep Button
            Button(action: {
                viewModel.handleSwipe(direction: .left)
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 24, weight: .bold))
                    Text("Keep")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(
                    LinearGradient(
                        colors: [CleanerTheme.accentGreen, CleanerTheme.accentGreen.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: CleanerTheme.accentGreen.opacity(0.3), radius: 12, x: 0, y: 6)
            }

            // Delete Button
            Button(action: {
                viewModel.handleSwipe(direction: .right)
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 24, weight: .bold))
                    Text("Delete")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(
                    LinearGradient(
                        colors: [CleanerTheme.accentRed, CleanerTheme.accentRed.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: CleanerTheme.accentRed.opacity(0.3), radius: 12, x: 0, y: 6)
            }
        }
    }
}

// MARK: - Swipe Card

struct SwipeCardView: View {
    let asset: PHAsset
    let index: Int
    let isTop: Bool
    let onSwipe: (SwipeDirection) -> Void

    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0
    @State private var image: UIImage?

    private let swipeThreshold: CGFloat = 80
    private let velocityThreshold: CGFloat = 1000

    // Calculate optimal card height based on screen size
    private var cardHeight: CGFloat {
        let screenHeight = UIScreen.main.bounds.height
        // Use 65% of available height
        return screenHeight * 0.65
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Card Background with gradient
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [CleanerTheme.surface, CleanerTheme.cardBackground],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)

                // Image
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: cardHeight)
                        .clipped()
                        .cornerRadius(24)
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(CleanerTheme.cardBackground)

                        ProgressView()
                            .tint(CleanerTheme.primary)
                            .scaleEffect(1.5)
                    }
                    .frame(width: geometry.size.width, height: cardHeight)
                }

                // Bottom gradient for info readability
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.black.opacity(0.3),
                        Color.black.opacity(0.7)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 150)
                .cornerRadius(24)

                // Swipe Indicators
                if isTop {
                    swipeIndicators
                }

                // Info Overlay
                infoOverlay
                    .padding(20)
            }
            .frame(width: geometry.size.width, height: cardHeight)
            .offset(x: offset.width, y: 0)
            .rotationEffect(.degrees(rotation))
            .gesture(
                isTop ? DragGesture()
                    .onChanged { gesture in
                        offset = gesture.translation
                        rotation = Double(gesture.translation.width / 20)
                    }
                    .onEnded { gesture in
                        handleDragEnd(gesture)
                    } : nil
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: offset)
        }
        .frame(height: cardHeight)
        .task {
            await loadImage()
        }
    }

    // MARK: - Swipe Indicators

    private var swipeIndicators: some View {
        ZStack {
            // Keep Indicator (Left)
            if offset.width < -50 {
                VStack {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(CleanerTheme.accentGreen)
                                    .frame(width: 100, height: 100)

                                Image(systemName: "checkmark")
                                    .font(.system(size: 50, weight: .bold))
                                    .foregroundColor(.white)
                            }

                            Text("KEEP")
                                .font(.system(size: 20, weight: .black))
                                .foregroundColor(CleanerTheme.accentGreen)
                        }
                        .padding(40)
                    }
                    Spacer()
                }
                .opacity(min(Double(-offset.width / 100), 1.0))
            }

            // Delete Indicator (Right)
            if offset.width > 50 {
                VStack {
                    HStack {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(CleanerTheme.accentRed)
                                    .frame(width: 100, height: 100)

                                Image(systemName: "trash.fill")
                                    .font(.system(size: 45, weight: .bold))
                                    .foregroundColor(.white)
                            }

                            Text("DELETE")
                                .font(.system(size: 20, weight: .black))
                                .foregroundColor(CleanerTheme.accentRed)
                        }
                        .padding(40)
                        Spacer()
                    }
                    Spacer()
                }
                .opacity(min(Double(offset.width / 100), 1.0))
            }
        }
    }

    // MARK: - Info Overlay

    private var infoOverlay: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Date and size
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.system(size: 14, weight: .semibold))
                    Text(formatDate(asset.creationDate))
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundColor(.white)

                HStack(spacing: 8) {
                    Image(systemName: "photo")
                        .font(.system(size: 14, weight: .semibold))
                    Text("\(asset.pixelWidth) × \(asset.pixelHeight)")
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundColor(.white.opacity(0.9))
            }
        }
    }

    // MARK: - Drag Handling

    private func handleDragEnd(_ gesture: DragGesture.Value) {
        let horizontalDistance = gesture.translation.width
        let predictedEnd = gesture.predictedEndTranslation.width

        // Calculate velocity from predicted end position
        let velocity = abs(predictedEnd - horizontalDistance)

        // Determine if swipe should trigger based on distance OR velocity
        let shouldTriggerLeft = horizontalDistance < -swipeThreshold ||
                                (horizontalDistance < -40 && velocity > velocityThreshold)
        let shouldTriggerRight = horizontalDistance > swipeThreshold ||
                                 (horizontalDistance > 40 && velocity > velocityThreshold)

        if shouldTriggerLeft {
            // Swipe left = Keep
            animateSwipe(direction: .left, velocity: velocity)
            onSwipe(.left)
        } else if shouldTriggerRight {
            // Swipe right = Delete
            animateSwipe(direction: .right, velocity: velocity)
            onSwipe(.right)
        } else {
            // Return to center with bounce
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                offset = .zero
                rotation = 0
            }
        }
    }

    private func animateSwipe(direction: SwipeDirection, velocity: CGFloat) {
        let distance: CGFloat = 500

        // Spring animation with overshoot for natural physics
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7, blendDuration: 0.1)) {
            offset = direction == .left
                ? CGSize(width: -distance, height: 0)
                : CGSize(width: distance, height: 0)
            rotation = direction == .left ? -30 : 30
        }

        // Haptic feedback - vary intensity based on swipe velocity
        let isFastSwipe = velocity > velocityThreshold
        let impactFeedback = UIImpactFeedbackGenerator(style: isFastSwipe ? .heavy : .medium)
        impactFeedback.impactOccurred()
    }

    // MARK: - Image Loading

    private func loadImage() async {
        do {
            let loadedImage = try await PhotoLibraryService.shared.loadThumbnail(for: asset)
            await MainActor.run {
                image = loadedImage
            }
        } catch {
            // Silently fail - UI shows placeholder
        }
    }

    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - View Model

@MainActor
class SwipeDeckViewModel: ObservableObject {
    @Published var remainingCards: [PHAsset]
    @Published var toKeep: [PHAsset] = []
    @Published var toDelete: [PHAsset] = []
    @Published var swipeHistory: [(asset: PHAsset, direction: SwipeDirection)] = []

    @Published var showingDeleteConfirmation = false
    @Published var showingError = false
    @Published var lastError: Error?

    let category: String
    let totalCards: Int

    var currentIndex: Int {
        totalCards - remainingCards.count
    }

    var hasMoreCards: Bool {
        !remainingCards.isEmpty
    }

    init(assets: [PHAsset], category: String) {
        self.remainingCards = assets
        self.category = category
        self.totalCards = assets.count
    }

    func handleSwipe(direction: SwipeDirection) {
        guard let asset = remainingCards.first else { return }

        swipeHistory.append((asset, direction))

        switch direction {
        case .left:
            toKeep.append(asset)
        case .right:
            toDelete.append(asset)
        }

        remainingCards.removeFirst()

        AnalyticsManager.shared.logItemSwiped(
            direction: direction == .left ? "keep" : "delete",
            category: category
        )
    }

    func undo() {
        guard let last = swipeHistory.popLast() else { return }

        remainingCards.insert(last.asset, at: 0)

        if last.direction == .left {
            toKeep.removeAll { $0 == last.asset }
        } else {
            toDelete.removeAll { $0 == last.asset }
        }
    }

    func performDeletion(scanCoordinator: ScanCoordinator?) async {
        print("🗑️ [SwipeDeck] Starting deletion - count: \(toDelete.count), category: \(category)")
        AnalyticsManager.shared.logCleanupStarted(itemCount: toDelete.count, category: category)

        do {
            try await PhotoLibraryService.shared.delete(assets: toDelete)
            print("🗑️ [SwipeDeck] Photos deleted successfully")

            // Calculate freed space (approximate)
            var freedBytes: Int64 = 0
            for asset in toDelete {
                freedBytes += await PhotoLibraryService.shared.getAssetSize(for: asset)
            }
            print("🗑️ [SwipeDeck] Freed bytes calculated: \(freedBytes)")

            AnalyticsManager.shared.logCleanupCompleted(
                itemCount: toDelete.count,
                category: category,
                bytesFreed: freedBytes
            )

            // Log activity to CoreData and update scan coordinator
            await MainActor.run {
                print("🗑️ [SwipeDeck] Creating ActivityLog on MainActor")
                let context = CoreDataStack.shared.viewContext
                ActivityLog.createDeleteActivity(
                    context: context,
                    count: toDelete.count,
                    freedBytes: freedBytes,
                    category: category,
                    timestamp: Date()
                )
                print("🗑️ [SwipeDeck] Saving context...")
                CoreDataStack.shared.save(context: context)
                print("🗑️ [SwipeDeck] Context saved successfully")

                // Update scan coordinator to track deleted assets
                if let coordinator = scanCoordinator {
                    coordinator.markAssetsAsDeleted(toDelete)
                }

                // Track total savings
                SavingsTracker.shared.addSavedBytes(freedBytes)
            }

            toDelete.removeAll()
        } catch {
            print("❌ [SwipeDeck] Deletion error: \(error.localizedDescription)")
            lastError = error
            showingError = true
            AnalyticsManager.shared.logError(error, context: "deletion")
        }
    }
}

// MARK: - Enums

enum SwipeDirection {
    case left  // Keep
    case right // Delete
}

// MARK: - Stat Badge

struct StatBadge: View {
    let icon: String
    let count: Int
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
            Text("\(count)")
                .font(.system(size: 15, weight: .bold))
        }
        .foregroundColor(color)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color.opacity(0.2))
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        SwipeDeckView(assets: [], category: "Duplicates")
    }
}
