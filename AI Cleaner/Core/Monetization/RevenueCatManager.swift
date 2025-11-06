//
//  RevenueCatManager.swift
//  AI Cleaner
//
//  Manager for RevenueCat integration and subscription management
//

import Foundation
import RevenueCat

final class RevenueCatManager: ObservableObject {
    static let shared = RevenueCatManager()

    // MARK: - Published Properties

    @Published var isProUser: Bool = false
    @Published var currentOffering: Offering?
    @Published var customerInfo: CustomerInfo?

    // MARK: - Configuration

    private var apiKey: String {
        // Read API key from Info.plist (populated from Config.xcconfig)
        guard let key = Bundle.main.object(forInfoDictionaryKey: "REVENUECAT_API_KEY") as? String,
              !key.isEmpty,
              !key.contains("YOUR_REVENUECAT") else {
            fatalError("""
                RevenueCat API key not configured.

                Setup steps:
                1. Copy Config.example.xcconfig to Config.xcconfig
                2. Add your RevenueCat API key to Config.xcconfig
                3. In Xcode: Project > Info > Configurations > Set Config.xcconfig for Debug & Release
                4. Add REVENUECAT_API_KEY to Info.plist as $(REVENUECAT_API_KEY)

                See README.md for detailed instructions.
                """)
        }
        return key
    }

    struct EntitlementKeys {
        static let pro = "pro"
    }

    struct OfferingKeys {
        static let main = "cleaner_default"
    }

    private init() {}

    // MARK: - Setup

    func configure() {
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: apiKey)

        // Set user attributes
        Purchases.shared.attribution.setAttributes([
            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        ])

        // Check initial subscription status
        Task {
            await checkSubscriptionStatus()
        }
    }

    // MARK: - Subscription Status

    func checkSubscriptionStatus() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            await MainActor.run {
                self.customerInfo = customerInfo
                self.isProUser = customerInfo.entitlements[EntitlementKeys.pro]?.isActive == true
            }
        } catch {
            // Error will be handled by caller if needed
        }
    }

    // MARK: - Offerings

    func loadOfferings() async throws -> Offering? {
        let offerings = try await Purchases.shared.offerings()
        let offering = offerings.current

        await MainActor.run {
            self.currentOffering = offering
        }

        return offering
    }

    // MARK: - Purchase

    func purchase(package: Package) async throws -> CustomerInfo {
        let result = try await Purchases.shared.purchase(package: package)

        await MainActor.run {
            self.customerInfo = result.customerInfo
            self.isProUser = result.customerInfo.entitlements[EntitlementKeys.pro]?.isActive == true
        }

        return result.customerInfo
    }

    func purchaseMonthly() async throws {
        guard let offering = try await loadOfferings(),
              let monthlyPackage = offering.monthly else {
            throw RevenueCatError.packageNotAvailable
        }

        _ = try await purchase(package: monthlyPackage)
    }

    func purchaseAnnual() async throws {
        guard let offering = try await loadOfferings(),
              let annualPackage = offering.annual else {
            throw RevenueCatError.packageNotAvailable
        }

        _ = try await purchase(package: annualPackage)
    }

    func purchaseLifetime() async throws {
        guard let offering = try await loadOfferings(),
              let lifetimePackage = offering.lifetime else {
            throw RevenueCatError.packageNotAvailable
        }

        _ = try await purchase(package: lifetimePackage)
    }

    // MARK: - Restore

    func restorePurchases() async throws {
        let customerInfo = try await Purchases.shared.restorePurchases()

        await MainActor.run {
            self.customerInfo = customerInfo
            self.isProUser = customerInfo.entitlements[EntitlementKeys.pro]?.isActive == true
        }
    }

    // MARK: - User Management

    func login(userId: String) async throws {
        let (customerInfo, _) = try await Purchases.shared.logIn(userId)

        await MainActor.run {
            self.customerInfo = customerInfo
            self.isProUser = customerInfo.entitlements[EntitlementKeys.pro]?.isActive == true
        }
    }

    func logout() async throws {
        let customerInfo = try await Purchases.shared.logOut()

        await MainActor.run {
            self.customerInfo = customerInfo
            self.isProUser = false
        }
    }

    // MARK: - Pricing Information

    func getMonthlyPrice() async -> String? {
        guard let offering = try? await loadOfferings(),
              let monthlyPackage = offering.monthly else {
            return nil
        }

        return monthlyPackage.localizedPriceString
    }

    func getAnnualPrice() async -> String? {
        guard let offering = try? await loadOfferings(),
              let annualPackage = offering.annual else {
            return nil
        }

        return annualPackage.localizedPriceString
    }

    func getAnnualSavings() async -> String? {
        guard let offering = try? await loadOfferings(),
              let monthlyPackage = offering.monthly,
              let annualPackage = offering.annual else {
            return nil
        }

        let monthlyPrice = monthlyPackage.storeProduct.price
        let annualPrice = annualPackage.storeProduct.price

        let yearlyCostOfMonthly = monthlyPrice * 12
        let savings = yearlyCostOfMonthly - annualPrice
        let savingsPercentage = (savings / yearlyCostOfMonthly) * 100

        return String(format: "%.0f%%", savingsPercentage)
    }
}

// MARK: - Errors

enum RevenueCatError: Error, LocalizedError {
    case notConfigured
    case packageNotAvailable
    case purchaseFailed
    case restoreFailed

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "RevenueCat is not configured. Please add the SDK via SPM."
        case .packageNotAvailable:
            return "The requested package is not available"
        case .purchaseFailed:
            return "Purchase failed"
        case .restoreFailed:
            return "Failed to restore purchases"
        }
    }
}
