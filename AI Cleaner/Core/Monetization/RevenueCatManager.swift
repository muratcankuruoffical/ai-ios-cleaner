//
//  RevenueCatManager.swift
//  AI Cleaner
//
//  Manager for RevenueCat integration and subscription management
//

import Foundation
// import RevenueCat // Uncomment when adding RevenueCat via SPM

final class RevenueCatManager: ObservableObject {
    static let shared = RevenueCatManager()

    // MARK: - Published Properties

    @Published var isProUser: Bool = false
    @Published var currentOffering: Offering?
    @Published var customerInfo: CustomerInfo?

    // MARK: - Configuration

    private let apiKey = "YOUR_REVENUECAT_API_KEY" // Replace with your actual key

    struct EntitlementKeys {
        static let pro = "pro"
    }

    struct OfferingKeys {
        static let main = "cleaner_default"
    }

    private init() {}

    // MARK: - Setup

    func configure() {
        // Uncomment when RevenueCat is added via SPM
        /*
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
        */

        print("⚠️ RevenueCat SDK not configured. Add via SPM and uncomment configuration code.")
    }

    // MARK: - Subscription Status

    func checkSubscriptionStatus() async {
        // Uncomment when RevenueCat is added
        /*
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            await MainActor.run {
                self.customerInfo = customerInfo
                self.isProUser = customerInfo.entitlements[EntitlementKeys.pro]?.isActive == true
            }
        } catch {
            print("Failed to fetch customer info: \(error)")
        }
        */

        // Mock for now
        await MainActor.run {
            self.isProUser = false
        }
    }

    // MARK: - Offerings

    func loadOfferings() async throws -> Offering? {
        // Uncomment when RevenueCat is added
        /*
        let offerings = try await Purchases.shared.offerings()
        let offering = offerings.current

        await MainActor.run {
            self.currentOffering = offering
        }

        return offering
        */

        // Mock for now
        return nil
    }

    // MARK: - Purchase

    func purchase(package: Package) async throws -> CustomerInfo {
        // Uncomment when RevenueCat is added
        /*
        let result = try await Purchases.shared.purchase(package: package)

        await MainActor.run {
            self.customerInfo = result.customerInfo
            self.isProUser = result.customerInfo.entitlements[EntitlementKeys.pro]?.isActive == true
        }

        return result.customerInfo
        */

        // Mock for now
        throw RevenueCatError.notConfigured
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
        // Uncomment when RevenueCat is added
        /*
        let customerInfo = try await Purchases.shared.restorePurchases()

        await MainActor.run {
            self.customerInfo = customerInfo
            self.isProUser = customerInfo.entitlements[EntitlementKeys.pro]?.isActive == true
        }
        */

        throw RevenueCatError.notConfigured
    }

    // MARK: - User Management

    func login(userId: String) async throws {
        // Uncomment when RevenueCat is added
        /*
        let (customerInfo, _) = try await Purchases.shared.logIn(userId)

        await MainActor.run {
            self.customerInfo = customerInfo
            self.isProUser = customerInfo.entitlements[EntitlementKeys.pro]?.isActive == true
        }
        */

        throw RevenueCatError.notConfigured
    }

    func logout() async throws {
        // Uncomment when RevenueCat is added
        /*
        let customerInfo = try await Purchases.shared.logOut()

        await MainActor.run {
            self.customerInfo = customerInfo
            self.isProUser = false
        }
        */

        throw RevenueCatError.notConfigured
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

// MARK: - Mock Types (Remove when RevenueCat is added)

struct Offering {
    let monthly: Package?
    let annual: Package?
    let lifetime: Package?
}

struct Package {
    let localizedPriceString: String
    let storeProduct: StoreProduct
}

struct StoreProduct {
    let price: Decimal
}

struct CustomerInfo {
    let entitlements: [String: Entitlement]
}

struct Entitlement {
    let isActive: Bool
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
