//
//  AIPhotoSearchView.swift
//  AI Cleaner
//
//  AI-powered photo search with natural language
//

import SwiftUI
import Photos

struct AIPhotoSearchView: View {
    @StateObject private var viewModel = AIPhotoSearchViewModel()
    @State private var searchText = ""
    @State private var animateHeader = false
    @State private var animateSearchBar = false

    // Popular search suggestions
    private let suggestions = [
        ("magnifyingglass", "Screenshots", "screenshots"),
        ("fork.knife", "Food & Drinks", "food"),
        ("figure.walk", "Gym & Fitness", "gym"),
        ("doc.text", "Documents", "document"),
        ("airplane", "Travel", "travel"),
        ("cat", "Pets", "cat dog animal"),
        ("beach.umbrella", "Beach", "beach"),
        ("person.2", "People", "person people"),
        ("building.2", "Buildings", "building architecture"),
        ("leaf", "Nature", "nature tree plant")
    ]

    var body: some View {
        NavigationView {
            ZStack {
                CleanerTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                            .opacity(animateHeader ? 1 : 0)
                            .offset(y: animateHeader ? 0 : -20)

                        // Search Bar
                        searchBarSection
                            .opacity(animateSearchBar ? 1 : 0)
                            .offset(y: animateSearchBar ? 0 : 20)

                        // Content
                        if viewModel.isSearching {
                            searchingView
                        } else if !viewModel.searchResults.isEmpty {
                            searchResultsSection
                        } else if searchText.isEmpty {
                            suggestionsSection
                        } else if viewModel.hasSearched {
                            noResultsView
                        }

                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .preferredColorScheme(.dark)
            .onAppear {
                withAnimation(.easeOut(duration: 0.6)) {
                    animateHeader = true
                }
                withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                    animateSearchBar = true
                }
                viewModel.initializeIfNeeded()
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "sparkles.rectangle.stack.fill")
                    .font(.system(size: 32))
                    .foregroundColor(CleanerTheme.primary)
                    .symbolEffect(.pulse, options: .repeating)

                Spacer()

                if viewModel.isIndexing {
                    HStack(spacing: 8) {
                        ProgressView()
                            .tint(CleanerTheme.primary)
                            .scaleEffect(0.8)

                        Text("Indexing \(viewModel.indexingProgress)/\(viewModel.totalPhotos)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(CleanerTheme.textSecondary)
                    }
                }
            }

            Text("AI Photo Search")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(CleanerTheme.textPrimary)

            Text("Search your photos using natural language")
                .font(.system(size: 15))
                .foregroundColor(CleanerTheme.textSecondary)
        }
    }

    // MARK: - Search Bar

    private var searchBarSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18))
                .foregroundColor(CleanerTheme.textSecondary)

            TextField("Try 'photos at the gym' or 'screenshots'", text: $searchText)
                .font(.system(size: 16))
                .foregroundColor(CleanerTheme.textPrimary)
                .submitLabel(.search)
                .onSubmit {
                    performSearch()
                }

            if !searchText.isEmpty {
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        searchText = ""
                        viewModel.clearResults()
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(CleanerTheme.textSecondary)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(16)
        .background(CleanerTheme.surface)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(CleanerTheme.primary.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Suggestions

    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("POPULAR SEARCHES")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(CleanerTheme.textSecondary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(Array(suggestions.enumerated()), id: \.offset) { index, suggestion in
                    SuggestionCard(
                        icon: suggestion.0,
                        title: suggestion.1,
                        query: suggestion.2
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3)) {
                            searchText = suggestion.2
                            performSearch()
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                    .animation(.easeOut(duration: 0.3).delay(Double(index) * 0.05), value: animateSearchBar)
                }
            }
        }
    }

    // MARK: - Search Results

    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("RESULTS")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(CleanerTheme.textSecondary)

                Spacer()

                Text("\(viewModel.searchResults.count) photos found")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(CleanerTheme.primary)
            }

            PhotoGridView(assets: viewModel.searchResults)
        }
    }

    // MARK: - States

    private var searchingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .tint(CleanerTheme.primary)
                .scaleEffect(1.5)

            Text("Searching...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(CleanerTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }

    private var noResultsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(CleanerTheme.textSecondary)
                .symbolEffect(.bounce, options: .nonRepeating)

            VStack(spacing: 8) {
                Text("No Photos Found")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(CleanerTheme.textPrimary)

                Text("Try different keywords or search terms")
                    .font(.system(size: 14))
                    .foregroundColor(CleanerTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }

    // MARK: - Actions

    private func performSearch() {
        guard !searchText.isEmpty else { return }

        hideKeyboard()

        withAnimation(.easeInOut(duration: 0.3)) {
            viewModel.search(query: searchText)
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Suggestion Card

struct SuggestionCard: View {
    let icon: String
    let title: String
    let query: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(CleanerTheme.primary)

            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(CleanerTheme.textPrimary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(CleanerTheme.surface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(CleanerTheme.cardBackground.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Photo Grid

struct PhotoGridView: View {
    let assets: [PHAsset]

    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 2) {
            ForEach(Array(assets.enumerated()), id: \.element.localIdentifier) { index, asset in
                PhotoThumbnailView(asset: asset)
                    .aspectRatio(1, contentMode: .fill)
                    .transition(.scale.combined(with: .opacity))
                    .animation(.easeOut(duration: 0.3).delay(Double(index) * 0.02), value: assets.count)
            }
        }
        .cornerRadius(8)
    }
}

// MARK: - Preview

#Preview {
    AIPhotoSearchView()
}
