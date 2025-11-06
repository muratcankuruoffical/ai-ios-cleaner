//
//  AnalyticsManager.swift
//  AI Cleaner
//
//  Manager for Firebase Analytics and event tracking
//

import Foundation
// import FirebaseAnalytics // Uncomment when adding Firebase via SPM
// import FirebaseCrashlytics

final class AnalyticsManager {
    static let shared = AnalyticsManager()

    @Published var isAnalyticsEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(isAnalyticsEnabled, forKey: "analytics_enabled")
            updateAnalyticsStatus()
        }
    }

    private init() {
        isAnalyticsEnabled = UserDefaults.standard.bool(forKey: "analytics_enabled")
        if !UserDefaults.standard.bool(forKey: "analytics_preference_set") {
            // Default to enabled on first launch
            isAnalyticsEnabled = true
            UserDefaults.standard.set(true, forKey: "analytics_preference_set")
        }
    }

    // MARK: - Configuration

    func configure() {
        // Uncomment when Firebase is added via SPM
        /*
        FirebaseApp.configure()
        Analytics.setAnalyticsCollectionEnabled(isAnalyticsEnabled)
        */

        print("⚠️ Firebase SDK not configured. Add via SPM and uncomment configuration code.")
    }

    private func updateAnalyticsStatus() {
        // Uncomment when Firebase is added
        /*
        Analytics.setAnalyticsCollectionEnabled(isAnalyticsEnabled)
        */
    }

    // MARK: - Event Logging

    func logEvent(_ name: String, parameters: [String: Any]? = nil) {
        guard isAnalyticsEnabled else { return }

        // Uncomment when Firebase is added
        /*
        Analytics.logEvent(name, parameters: parameters)
        */

        print("📊 Analytics Event: \(name)", parameters ?? [:])
    }

    // MARK: - Screen Tracking

    func logScreenView(_ screenName: String, screenClass: String? = nil) {
        var parameters: [String: Any] = [
            AnalyticsParameterScreenName: screenName
        ]

        if let screenClass = screenClass {
            parameters[AnalyticsParameterScreenClass] = screenClass
        }

        logEvent(AnalyticsEventScreenView, parameters: parameters)
    }

    // MARK: - App Events

    func logAppLaunch() {
        logEvent("app_launch")
    }

    func logAppBackground() {
        logEvent("app_background")
    }

    func logAppForeground() {
        logEvent("app_foreground")
    }

    // MARK: - Onboarding Events

    func logOnboardingStarted() {
        logEvent("onboarding_started")
    }

    func logOnboardingCompleted() {
        logEvent("onboarding_completed")
    }

    func logPermissionRequested(permissionType: String) {
        logEvent("permission_requested", parameters: [
            "permission_type": permissionType
        ])
    }

    func logPermissionGranted(permissionType: String) {
        logEvent("permission_granted", parameters: [
            "permission_type": permissionType
        ])
    }

    func logPermissionDenied(permissionType: String) {
        logEvent("permission_denied", parameters: [
            "permission_type": permissionType
        ])
    }

    // MARK: - Scan Events

    func logScanStarted(photoCount: Int) {
        logEvent("scan_started", parameters: [
            "photo_count": photoCount
        ])
    }

    func logScanCompleted(
        photoCount: Int,
        duration: TimeInterval,
        duplicatesFound: Int,
        blurryFound: Int,
        screenshotsFound: Int
    ) {
        logEvent("scan_completed", parameters: [
            "photo_count": photoCount,
            "duration_seconds": Int(duration),
            "duplicates_found": duplicatesFound,
            "blurry_found": blurryFound,
            "screenshots_found": screenshotsFound
        ])
    }

    func logScanCancelled(duration: TimeInterval, progress: Double) {
        logEvent("scan_cancelled", parameters: [
            "duration_seconds": Int(duration),
            "progress_percent": Int(progress * 100)
        ])
    }

    // MARK: - Cleanup Events

    func logCleanupStarted(itemCount: Int, category: String) {
        logEvent("cleanup_started", parameters: [
            "item_count": itemCount,
            "category": category
        ])
    }

    func logCleanupCompleted(
        itemCount: Int,
        category: String,
        bytesFreed: Int64
    ) {
        logEvent("cleanup_completed", parameters: [
            "item_count": itemCount,
            "category": category,
            "bytes_freed": bytesFreed,
            "mb_freed": Int(bytesFreed / (1024 * 1024))
        ])
    }

    func logItemSwiped(direction: String, category: String) {
        logEvent("item_swiped", parameters: [
            "direction": direction,
            "category": category
        ])
    }

    // MARK: - Paywall Events

    func logPaywallShown(source: String) {
        logEvent("paywall_shown", parameters: [
            "source": source
        ])
    }

    func logPaywallDismissed(source: String, duration: TimeInterval) {
        logEvent("paywall_dismissed", parameters: [
            "source": source,
            "duration_seconds": Int(duration)
        ])
    }

    func logPurchaseStarted(productId: String, price: String) {
        logEvent("purchase_started", parameters: [
            "product_id": productId,
            "price": price
        ])
    }

    func logPurchaseCompleted(productId: String, price: String, revenue: Decimal) {
        logEvent(AnalyticsEventPurchase, parameters: [
            AnalyticsParameterItemID: productId,
            AnalyticsParameterPrice: price,
            AnalyticsParameterValue: revenue,
            AnalyticsParameterCurrency: "USD"
        ])
    }

    func logPurchaseFailed(productId: String, error: String) {
        logEvent("purchase_failed", parameters: [
            "product_id": productId,
            "error": error
        ])
    }

    func logPurchaseRestored() {
        logEvent("purchase_restored")
    }

    // MARK: - Feature Usage

    func logSmartAlbumOpened(albumType: String) {
        logEvent("smart_album_opened", parameters: [
            "album_type": albumType
        ])
    }

    func logReportViewed(reportType: String) {
        logEvent("report_viewed", parameters: [
            "report_type": reportType
        ])
    }

    func logSettingsOpened() {
        logEvent("settings_opened")
    }

    // MARK: - Error Logging

    func logError(_ error: Error, context: String) {
        logEvent("error_occurred", parameters: [
            "error_description": error.localizedDescription,
            "context": context
        ])

        // Also log to Crashlytics if available
        /*
        Crashlytics.crashlytics().record(error: error)
        */
    }

    func logNonFatalError(message: String, context: [String: Any]? = nil) {
        var parameters: [String: Any] = [
            "message": message
        ]

        if let context = context {
            parameters.merge(context) { (_, new) in new }
        }

        logEvent("non_fatal_error", parameters: parameters)
    }

    // MARK: - User Properties

    func setUserProperty(value: String?, forName name: String) {
        guard isAnalyticsEnabled else { return }

        // Uncomment when Firebase is added
        /*
        Analytics.setUserProperty(value, forName: name)
        */

        print("👤 User Property: \(name) = \(value ?? "nil")")
    }

    func setUserId(_ userId: String?) {
        guard isAnalyticsEnabled else { return }

        // Uncomment when Firebase is added
        /*
        Analytics.setUserID(userId)
        */
    }

    func setProUser(_ isPro: Bool) {
        setUserProperty(value: isPro ? "true" : "false", forName: "is_pro_user")
    }

    func setPhotoLibrarySize(_ count: Int) {
        setUserProperty(value: "\(count)", forName: "photo_library_size")
    }
}

// MARK: - Mock Constants (Remove when Firebase is added)

let AnalyticsEventScreenView = "screen_view"
let AnalyticsEventPurchase = "purchase"
let AnalyticsParameterScreenName = "screen_name"
let AnalyticsParameterScreenClass = "screen_class"
let AnalyticsParameterItemID = "item_id"
let AnalyticsParameterPrice = "price"
let AnalyticsParameterValue = "value"
let AnalyticsParameterCurrency = "currency"
