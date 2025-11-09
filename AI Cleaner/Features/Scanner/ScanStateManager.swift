//
//  ScanStateManager.swift
//  AI Cleaner
//
//  Manages persistent scan state for background scanning
//

import Foundation

@MainActor
class ScanStateManager {
    static let shared = ScanStateManager()

    private let defaults = UserDefaults.standard

    // Keys
    private enum Keys {
        static let isScanning = "scan_is_scanning"
        static let sessionId = "scan_session_id"
        static let currentStep = "scan_current_step"
        static let currentIndex = "scan_current_index"
        static let totalItems = "scan_total_items"
        static let percentage = "scan_percentage"
        static let startTime = "scan_start_time"
    }

    // MARK: - State Properties

    var isScanning: Bool {
        get { defaults.bool(forKey: Keys.isScanning) }
        set { defaults.set(newValue, forKey: Keys.isScanning) }
    }

    var sessionId: UUID? {
        get {
            guard let uuidString = defaults.string(forKey: Keys.sessionId) else { return nil }
            return UUID(uuidString: uuidString)
        }
        set {
            defaults.set(newValue?.uuidString, forKey: Keys.sessionId)
        }
    }

    var currentStep: String {
        get { defaults.string(forKey: Keys.currentStep) ?? "" }
        set { defaults.set(newValue, forKey: Keys.currentStep) }
    }

    var currentIndex: Int {
        get { defaults.integer(forKey: Keys.currentIndex) }
        set { defaults.set(newValue, forKey: Keys.currentIndex) }
    }

    var totalItems: Int {
        get { defaults.integer(forKey: Keys.totalItems) }
        set { defaults.set(newValue, forKey: Keys.totalItems) }
    }

    var percentage: Double {
        get { defaults.double(forKey: Keys.percentage) }
        set { defaults.set(newValue, forKey: Keys.percentage) }
    }

    var startTime: Date? {
        get {
            guard let timestamp = defaults.object(forKey: Keys.startTime) as? Date else { return nil }
            return timestamp
        }
        set {
            defaults.set(newValue, forKey: Keys.startTime)
        }
    }

    // MARK: - Methods

    func startScan(sessionId: UUID) {
        self.isScanning = true
        self.sessionId = sessionId
        self.startTime = Date()
        self.currentStep = "Starting..."
        self.currentIndex = 0
        self.totalItems = 0
        self.percentage = 0.0
        print("✅ [ScanStateManager] Scan started - Session: \(sessionId)")
    }

    func updateProgress(step: String, current: Int, total: Int) {
        // Throttle updates to avoid excessive writes
        let newPercentage = total > 0 ? Double(current) / Double(total) : 0

        // Only update if there's significant change (>1%)
        if abs(newPercentage - self.percentage) > 0.01 || step != self.currentStep {
            self.currentStep = step
            self.currentIndex = current
            self.totalItems = total
            self.percentage = newPercentage
        }
    }

    func completeScan() {
        self.isScanning = false
        self.percentage = 1.0
        print("✅ [ScanStateManager] Scan completed")
    }

    func cancelScan() {
        self.isScanning = false
        print("⚠️ [ScanStateManager] Scan cancelled")
    }

    func clearState() {
        defaults.removeObject(forKey: Keys.isScanning)
        defaults.removeObject(forKey: Keys.sessionId)
        defaults.removeObject(forKey: Keys.currentStep)
        defaults.removeObject(forKey: Keys.currentIndex)
        defaults.removeObject(forKey: Keys.totalItems)
        defaults.removeObject(forKey: Keys.percentage)
        defaults.removeObject(forKey: Keys.startTime)
        print("🧹 [ScanStateManager] State cleared")
    }

    func getElapsedTime() -> TimeInterval? {
        guard let start = startTime else { return nil }
        return Date().timeIntervalSince(start)
    }
}
