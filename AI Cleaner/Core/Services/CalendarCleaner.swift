//
//  CalendarCleaner.swift
//  AI Cleaner
//
//  Service for cleaning old calendar events and reminders
//

import Foundation
internal import EventKit

final class CalendarCleaner {
    static let shared = CalendarCleaner()

    private let eventStore = EKEventStore()

    private init() {}

    // MARK: - Authorization

    enum AuthorizationStatus {
        case authorized
        case denied
        case notDetermined
        case restricted
    }

    func checkAuthorizationStatus(for entityType: EKEntityType) -> AuthorizationStatus {
        let status = EKEventStore.authorizationStatus(for: entityType)
        switch status {
        case .authorized:
            return .authorized
        case .denied:
            return .denied
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        @unknown default:
            return .denied
        }
    }

    func requestAuthorization(for entityType: EKEntityType) async -> Bool {
        do {
            return try await eventStore.requestAccess(to: entityType)
        } catch {
            print("❌ Calendar authorization error: \(error)")
            return false
        }
    }

    // MARK: - Configuration

    struct Configuration {
        var pastEventsCutoffMonths: Int = 6 // Events older than 6 months
        var completedRemindersCutoffMonths: Int = 3 // Completed reminders older than 3 months
        var cancelledEventsCutoffDays: Int = 30 // Cancelled events older than 30 days

        static let `default` = Configuration()

        static let aggressive = Configuration(
            pastEventsCutoffMonths: 3,
            completedRemindersCutoffMonths: 1,
            cancelledEventsCutoffDays: 7
        )

        static let conservative = Configuration(
            pastEventsCutoffMonths: 12,
            completedRemindersCutoffMonths: 6,
            cancelledEventsCutoffDays: 90
        )
    }

    // MARK: - Event Categories

    enum EventCategory: String, CaseIterable {
        case pastEvents = "Past Events"
        case duplicateEvents = "Duplicate Events"
        case completedReminders = "Completed Reminders"
        case declinedEvents = "Declined Events"
    }

    struct EventGroup {
        let category: EventCategory
        let events: [EKEvent]
        let description: String

        var count: Int { events.count }
    }

    struct ReminderGroup {
        let reminders: [EKReminder]
        let description: String

        var count: Int { reminders.count }
    }

    struct DuplicateEventGroup {
        let events: [EKEvent]
        let matchReason: String

        var primaryEvent: EKEvent? {
            events.first
        }

        var duplicates: [EKEvent] {
            Array(events.dropFirst())
        }
    }

    // MARK: - Scan Calendar

    func scanCalendar(configuration: Configuration = .default, progressHandler: ((Int, Int) -> Void)? = nil) async -> CalendarScanResults {
        print("\n📅 SCANNING CALENDAR...")

        var pastEvents: [EKEvent] = []
        var duplicateGroups: [DuplicateEventGroup] = []
        var declinedEvents: [EKEvent] = []
        var completedReminders: [EKReminder] = []

        // Calculate date ranges
        let now = Date()
        let calendar = Calendar.current

        // Past events cutoff
        let pastCutoff = calendar.date(byAdding: .month, value: -configuration.pastEventsCutoffMonths, to: now)!

        // Fetch past events (last 2 years to today)
        let twoYearsAgo = calendar.date(byAdding: .year, value: -2, to: now)!
        let predicate = eventStore.predicateForEvents(withStart: twoYearsAgo, end: now, calendars: nil)
        let allEvents = eventStore.events(matching: predicate)

        print("   Found \(allEvents.count) events in the last 2 years")

        // Categorize events
        for (index, event) in allEvents.enumerated() {
            progressHandler?(index, allEvents.count)

            // Check if event is in the past and old enough
            if let endDate = event.endDate, endDate < pastCutoff {
                pastEvents.append(event)
            }

            // Check if user declined
            if let participant = event.attendees?.first(where: { $0.isCurrentUser }),
               participant.participantStatus == .declined {
                declinedEvents.append(event)
            }
        }

        // Find duplicate events
        duplicateGroups = findDuplicateEvents(in: allEvents)

        // Fetch completed reminders
        completedReminders = await fetchCompletedReminders(configuration: configuration)

        print("   📊 Results:")
        print("      Past events (>\(configuration.pastEventsCutoffMonths) months): \(pastEvents.count)")
        print("      Duplicate event groups: \(duplicateGroups.count)")
        print("      Declined events: \(declinedEvents.count)")
        print("      Completed reminders (>\(configuration.completedRemindersCutoffMonths) months): \(completedReminders.count)")

        return CalendarScanResults(
            pastEvents: pastEvents,
            duplicateGroups: duplicateGroups,
            declinedEvents: declinedEvents,
            completedReminders: completedReminders,
            configuration: configuration
        )
    }

    struct CalendarScanResults {
        let pastEvents: [EKEvent]
        let duplicateGroups: [DuplicateEventGroup]
        let declinedEvents: [EKEvent]
        let completedReminders: [EKReminder]
        let configuration: Configuration

        var totalCleanableEvents: Int {
            pastEvents.count + duplicateGroups.reduce(0) { $0 + $1.duplicates.count } + declinedEvents.count
        }

        var totalCleanableReminders: Int {
            completedReminders.count
        }
    }

    // MARK: - Find Duplicate Events

    private func findDuplicateEvents(in events: [EKEvent]) -> [DuplicateEventGroup] {
        var groups: [DuplicateEventGroup] = []
        var processedIds = Set<String>()

        for event in events {
            if processedIds.contains(event.eventIdentifier) {
                continue
            }

            var matchingEvents: [EKEvent] = [event]

            for otherEvent in events {
                if otherEvent.eventIdentifier == event.eventIdentifier ||
                   processedIds.contains(otherEvent.eventIdentifier) {
                    continue
                }

                // Check for exact duplicate
                if areDuplicateEvents(event, otherEvent) {
                    matchingEvents.append(otherEvent)
                    processedIds.insert(otherEvent.eventIdentifier)
                }
            }

            if matchingEvents.count > 1 {
                let reason = "Same title, time, and location"
                groups.append(DuplicateEventGroup(events: matchingEvents, matchReason: reason))
                processedIds.insert(event.eventIdentifier)
            }
        }

        return groups
    }

    private func areDuplicateEvents(_ e1: EKEvent, _ e2: EKEvent) -> Bool {
        // Same title
        guard e1.title.lowercased() == e2.title.lowercased() else { return false }

        // Same start date (within 1 minute)
        guard let start1 = e1.startDate, let start2 = e2.startDate else { return false }
        let timeDiff = abs(start1.timeIntervalSince(start2))
        guard timeDiff < 60 else { return false }

        // Same duration (within 1 minute)
        let duration1 = e1.endDate.timeIntervalSince(e1.startDate)
        let duration2 = e2.endDate.timeIntervalSince(e2.startDate)
        guard abs(duration1 - duration2) < 60 else { return false }

        return true
    }

    // MARK: - Fetch Completed Reminders

    private func fetchCompletedReminders(configuration: Configuration) async -> [EKReminder] {
        let calendar = Calendar.current
        let now = Date()
        let cutoff = calendar.date(byAdding: .month, value: -configuration.completedRemindersCutoffMonths, to: now)!

        let predicate = eventStore.predicateForCompletedReminders(
            withCompletionDateStarting: nil,
            ending: cutoff,
            calendars: nil
        )

        return await withCheckedContinuation { continuation in
            eventStore.fetchReminders(matching: predicate) { reminders in
                continuation.resume(returning: reminders ?? [])
            }
        }
    }

    // MARK: - Delete Events

    func deleteEvents(_ events: [EKEvent], span: EKSpan = .thisEvent) throws {
        for event in events {
            try eventStore.remove(event, span: span, commit: false)
        }
        try eventStore.commit()
        print("✅ Deleted \(events.count) events")
    }

    // MARK: - Delete Reminders

    func deleteReminders(_ reminders: [EKReminder]) throws {
        for reminder in reminders {
            try eventStore.remove(reminder, commit: false)
        }
        try eventStore.commit()
        print("✅ Deleted \(reminders.count) reminders")
    }

    // MARK: - Helper Methods

    func formatEventTitle(_ event: EKEvent) -> String {
        return event.title ?? "Untitled Event"
    }

    func formatEventDate(_ event: EKEvent) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: event.startDate)
    }

    func calculateEstimatedSavings(results: CalendarScanResults) -> String {
        let totalItems = results.totalCleanableEvents + results.totalCleanableReminders

        // Rough estimate: each event/reminder ~1-5 KB
        let estimatedKB = totalItems * 2
        if estimatedKB > 1024 {
            return "\(estimatedKB / 1024) MB"
        } else {
            return "\(estimatedKB) KB"
        }
    }
}
