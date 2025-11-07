//
//  CalendarCleanupView.swift
//  AI Cleaner
//
//  UI for cleaning old calendar events and reminders
//

import SwiftUI
internal import EventKit

struct CalendarCleanupView: View {
    let results: CalendarCleaner.CalendarScanResults

    @State private var selectedTab = 0
    @State private var deletedEventIds = Set<String>()
    @State private var deletedReminderIds = Set<String>()
    @State private var showingDeleteAlert = false
    @State private var eventToDelete: EKEvent?
    @State private var reminderToDelete: EKReminder?
    @State private var isDeleting = false

    var availablePastEvents: [EKEvent] {
        results.pastEvents.filter { !deletedEventIds.contains($0.eventIdentifier) }
    }

    var availableDeclinedEvents: [EKEvent] {
        results.declinedEvents.filter { !deletedEventIds.contains($0.eventIdentifier) }
    }

    var availableReminders: [EKReminder] {
        results.completedReminders.filter { !deletedReminderIds.contains($0.calendarItemIdentifier) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header Stats
            statsHeader
                .padding()

            // Tab Picker
            Picker("Category", selection: $selectedTab) {
                Text("Past Events").tag(0)
                Text("Duplicates").tag(1)
                Text("Declined").tag(2)
                Text("Reminders").tag(3)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            // Content
            TabView(selection: $selectedTab) {
                pastEventsView
                    .tag(0)

                duplicateEventsView
                    .tag(1)

                declinedEventsView
                    .tag(2)

                completedRemindersView
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .navigationTitle("Calendar Cleanup")
        .navigationBarTitleDisplayMode(.large)
        .alert("Delete Event?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let event = eventToDelete {
                    deleteEvent(event)
                } else if let reminder = reminderToDelete {
                    deleteReminder(reminder)
                }
            }
        } message: {
            if eventToDelete != nil {
                Text("This event will be permanently deleted from your calendar.")
            } else {
                Text("This reminder will be permanently deleted.")
            }
        }
    }

    // MARK: - Header Stats

    private var statsHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "calendar.badge.clock")
                    .font(.largeTitle)
                    .foregroundColor(.teal)

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(results.totalCleanableEvents + results.totalCleanableReminders) Items")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Estimated: \(CalendarCleaner.shared.calculateEstimatedSavings(results: results))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Text("Clean up old events and reminders to keep your calendar organized")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.teal.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Past Events View

    private var pastEventsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if availablePastEvents.isEmpty {
                    emptyState(icon: "checkmark.circle.fill", message: "No past events to clean")
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Events older than \(results.configuration.pastEventsCutoffMonths) months")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)

                        ForEach(availablePastEvents.prefix(100), id: \.eventIdentifier) { event in
                            EventRow(event: event) {
                                eventToDelete = event
                                showingDeleteAlert = true
                            }
                        }

                        if availablePastEvents.count > 100 {
                            Text("+ \(availablePastEvents.count - 100) more events")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding()
                        }

                        // Delete All Button
                        if !availablePastEvents.isEmpty {
                            Button(action: { deleteAllPastEvents() }) {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("Delete All Past Events")
                                }
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .padding()
                        }
                    }
                }
            }
            .padding(.vertical)
        }
    }

    // MARK: - Duplicate Events View

    private var duplicateEventsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if results.duplicateGroups.isEmpty {
                    emptyState(icon: "checkmark.circle.fill", message: "No duplicate events found")
                } else {
                    ForEach(Array(results.duplicateGroups.enumerated()), id: \.element.events.first?.eventIdentifier) { index, group in
                        DuplicateEventGroupCard(group: group, index: index + 1) {
                            deleteDuplicateGroup(group)
                        }
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Declined Events View

    private var declinedEventsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if availableDeclinedEvents.isEmpty {
                    emptyState(icon: "checkmark.circle.fill", message: "No declined events")
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Events you declined")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)

                        ForEach(availableDeclinedEvents, id: \.eventIdentifier) { event in
                            EventRow(event: event) {
                                eventToDelete = event
                                showingDeleteAlert = true
                            }
                        }

                        if !availableDeclinedEvents.isEmpty {
                            Button(action: { deleteAllDeclinedEvents() }) {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("Delete All Declined Events")
                                }
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .padding()
                        }
                    }
                }
            }
            .padding(.vertical)
        }
    }

    // MARK: - Completed Reminders View

    private var completedRemindersView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if availableReminders.isEmpty {
                    emptyState(icon: "checkmark.circle.fill", message: "No completed reminders")
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reminders completed over \(results.configuration.completedRemindersCutoffMonths) months ago")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)

                        ForEach(availableReminders, id: \.calendarItemIdentifier) { reminder in
                            ReminderRow(reminder: reminder) {
                                reminderToDelete = reminder
                                showingDeleteAlert = true
                            }
                        }

                        if !availableReminders.isEmpty {
                            Button(action: { deleteAllReminders() }) {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("Delete All Completed Reminders")
                                }
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .padding()
                        }
                    }
                }
            }
            .padding(.vertical)
        }
    }

    // MARK: - Empty State

    private func emptyState(icon: String, message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.green)

            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Delete Actions

    private func deleteEvent(_ event: EKEvent) {
        isDeleting = true
        Task {
            do {
                try CalendarCleaner.shared.deleteEvents([event])
                await MainActor.run {
                    deletedEventIds.insert(event.eventIdentifier)
                    isDeleting = false
                }
            } catch {
                print("❌ Delete event error: \(error)")
                isDeleting = false
            }
        }
    }

    private func deleteReminder(_ reminder: EKReminder) {
        isDeleting = true
        Task {
            do {
                try CalendarCleaner.shared.deleteReminders([reminder])
                await MainActor.run {
                    deletedReminderIds.insert(reminder.calendarItemIdentifier)
                    isDeleting = false
                }
            } catch {
                print("❌ Delete reminder error: \(error)")
                isDeleting = false
            }
        }
    }

    private func deleteAllPastEvents() {
        Task {
            do {
                try CalendarCleaner.shared.deleteEvents(availablePastEvents)
                await MainActor.run {
                    for event in availablePastEvents {
                        deletedEventIds.insert(event.eventIdentifier)
                    }
                }
            } catch {
                print("❌ Delete all events error: \(error)")
            }
        }
    }

    private func deleteAllDeclinedEvents() {
        Task {
            do {
                try CalendarCleaner.shared.deleteEvents(availableDeclinedEvents)
                await MainActor.run {
                    for event in availableDeclinedEvents {
                        deletedEventIds.insert(event.eventIdentifier)
                    }
                }
            } catch {
                print("❌ Delete all declined events error: \(error)")
            }
        }
    }

    private func deleteAllReminders() {
        Task {
            do {
                try CalendarCleaner.shared.deleteReminders(availableReminders)
                await MainActor.run {
                    for reminder in availableReminders {
                        deletedReminderIds.insert(reminder.calendarItemIdentifier)
                    }
                }
            } catch {
                print("❌ Delete all reminders error: \(error)")
            }
        }
    }

    private func deleteDuplicateGroup(_ group: CalendarCleaner.DuplicateEventGroup) {
        Task {
            do {
                try CalendarCleaner.shared.deleteEvents(group.duplicates)
                await MainActor.run {
                    for event in group.duplicates {
                        deletedEventIds.insert(event.eventIdentifier)
                    }
                }
            } catch {
                print("❌ Delete duplicate group error: \(error)")
            }
        }
    }
}

// MARK: - Event Row

struct EventRow: View {
    let event: EKEvent
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(CalendarCleaner.shared.formatEventTitle(event))
                    .font(.headline)

                Text(CalendarCleaner.shared.formatEventDate(event))
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let location = event.location, !location.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.caption2)
                        Text(location)
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Reminder Row

struct ReminderRow: View {
    let reminder: EKReminder
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)

            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title ?? "Untitled")
                    .font(.headline)

                if let completionDate = reminder.completionDate {
                    Text("Completed \(formatDate(completionDate))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Duplicate Event Group Card

struct DuplicateEventGroupCard: View {
    let group: CalendarCleaner.DuplicateEventGroup
    let index: Int
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Group \(index)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.teal)

                Spacer()

                Text(group.matchReason)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            // Event title
            if let title = group.events.first?.title {
                Text(title)
                    .font(.headline)
            }

            Text("\(group.events.count) duplicate events")
                .font(.caption)
                .foregroundColor(.secondary)

            Button(action: onDelete) {
                HStack {
                    Image(systemName: "trash")
                    Text("Delete \(group.duplicates.count) Duplicates")
                }
                .font(.caption)
                .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color.teal.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        CalendarCleanupView(
            results: CalendarCleaner.CalendarScanResults(
                pastEvents: [],
                duplicateGroups: [],
                declinedEvents: [],
                completedReminders: [],
                configuration: .default
            )
        )
    }
}
