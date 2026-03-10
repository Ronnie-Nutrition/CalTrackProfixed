import Foundation
import Combine
import StoreKit
import SwiftUI
import RevenueCat

// MARK: - Subscription Manager (RevenueCat)

@MainActor
class SubscriptionManager: NSObject, ObservableObject {
    static let shared = SubscriptionManager()

    @Published var isSubscriptionActive = false
    @Published var currentSubscription: SubscriptionPlan?
    @Published var availableSubscriptions: [SubscriptionPlan] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isEligibleForIntroOffer = false
    @Published var productsLoadedSuccessfully = false
    @Published var lastLoadError: String?

    // RevenueCat entitlement identifier (must match RevenueCat dashboard)
    private let entitlementID = "CalTrackPro Pro"

    // Keep StoreKit product IDs for reference
    private let productIDs: [String] = [
        "com.caltrackpro.premium.monthly",
        "com.caltrackpro.premium.yearly",
        "com.caltrackpro.premium.lifetime.v2"
    ]

    private var packages: [Package] = []

    override init() {
        super.init()

        // Defer RevenueCat setup to ensure Purchases.configure() has completed
        Task { @MainActor in
            // Set ourselves as the RevenueCat delegate for real-time updates
            if Purchases.isConfigured {
                Purchases.shared.delegate = self
            } else {
                print("[RevenueCat] WARNING: Purchases not configured yet, retrying in 1s...")
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Purchases.isConfigured {
                    Purchases.shared.delegate = self
                } else {
                    print("[RevenueCat] ERROR: Purchases still not configured after retry")
                }
            }

            await loadProductsWithRetry()
            await checkSubscriptionStatus()
        }
    }

    // MARK: - Product Loading with Retry

    func loadProductsWithRetry() async {
        var attempts = 0
        let maxAttempts = 3
        while attempts < maxAttempts && !productsLoadedSuccessfully {
            attempts += 1
            await loadProducts()
            if !productsLoadedSuccessfully && attempts < maxAttempts {
                try? await Task.sleep(nanoseconds: UInt64(attempts) * 1_000_000_000)
            }
        }
    }

    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        lastLoadError = nil

        do {
            print("[RevenueCat] ========== LOADING OFFERINGS ==========")

            let offerings = try await Purchases.shared.offerings()

            guard let currentOffering = offerings.current else {
                print("[RevenueCat] WARNING: No current offering found!")
                lastLoadError = "No offerings configured in RevenueCat dashboard."
                isLoading = false
                return
            }

            print("[RevenueCat] Current offering: \(currentOffering.identifier)")
            print("[RevenueCat] Available packages: \(currentOffering.availablePackages.count)")

            packages = currentOffering.availablePackages

            availableSubscriptions = packages.compactMap { package in
                createSubscriptionPlan(from: package)
            }.sorted { $0.priority < $1.priority }

            print("[RevenueCat] Created \(availableSubscriptions.count) subscription plans")

            for plan in availableSubscriptions {
                print("[RevenueCat] Plan: \(plan.type.rawValue) - \(plan.priceFormatted)")
            }

            print("[RevenueCat] =========================================")

            productsLoadedSuccessfully = !availableSubscriptions.isEmpty

            if availableSubscriptions.isEmpty {
                lastLoadError = "No subscription plans available."
                print("[RevenueCat] ERROR: \(lastLoadError!)")
            }

            isLoading = false
        } catch {
            print("[RevenueCat] ERROR loading offerings: \(error)")
            lastLoadError = "Error: \(error.localizedDescription)"

            if error.localizedDescription.contains("network") || error.localizedDescription.contains("connection") {
                errorMessage = "Cannot connect to the store. Please check your internet connection."
            } else {
                errorMessage = "Unable to load subscription options. Please try again."
            }
            isLoading = false
        }
    }

    private func createSubscriptionPlan(from package: Package) -> SubscriptionPlan? {
        let storeProduct = package.storeProduct
        let planType: SubscriptionPlanType
        let priority: Int

        // Determine plan type from package type or product ID
        switch package.packageType {
        case .monthly:
            planType = .monthly
            priority = 2
        case .annual:
            planType = .yearly
            priority = 1
        case .lifetime:
            planType = .lifetime
            priority = 3
        default:
            // Fall back to product ID matching
            let productId = storeProduct.productIdentifier
            if productId.contains("monthly") {
                planType = .monthly
                priority = 2
            } else if productId.contains("yearly") {
                planType = .yearly
                priority = 1
            } else if productId.contains("lifetime") {
                planType = .lifetime
                priority = 3
            } else {
                print("[RevenueCat] Unknown package type: \(package.packageType) for \(storeProduct.productIdentifier)")
                return nil
            }
        }

        print("[RevenueCat] Created plan: \(planType.rawValue) from package: \(package.identifier)")

        guard let sk2Product = storeProduct.sk2Product else {
            print("[RevenueCat] WARNING: sk2Product is nil for \(storeProduct.productIdentifier)")
            return nil
        }

        return SubscriptionPlan(
            id: storeProduct.productIdentifier,
            type: planType,
            product: sk2Product,
            package: package,
            priority: priority,
            price: storeProduct.price,
            priceFormatted: storeProduct.localizedPriceString,
            introductoryOffer: sk2Product.subscription?.introductoryOffer,
            promotionalOffers: sk2Product.subscription?.promotionalOffers ?? []
        )
    }

    // MARK: - Subscription Purchase

    func purchaseSubscription(_ plan: SubscriptionPlan) async -> Bool {
        guard let package = plan.package else {
            print("[RevenueCat] ERROR: No package for plan \(plan.id)")
            errorMessage = "Purchase could not be completed. Please try again."
            return false
        }

        isLoading = true
        errorMessage = nil

        print("[RevenueCat] Starting purchase for: \(plan.id)")

        do {
            let (_, customerInfo, _) = try await Purchases.shared.purchase(package: package)

            if customerInfo.entitlements[entitlementID]?.isActive == true {
                print("[RevenueCat] Purchase successful! Entitlement active.")
                await updateSubscriptionStatus(from: customerInfo)
                isLoading = false
                return true
            } else {
                print("[RevenueCat] Purchase completed but entitlement not active")
                await updateSubscriptionStatus(from: customerInfo)
                isLoading = false
                return false
            }
        } catch let error as RevenueCat.ErrorCode {
            print("[RevenueCat] Purchase error: \(error)")
            isLoading = false

            switch error {
            case .purchaseCancelledError:
                // User cancelled - no error message needed
                return false
            case .networkError:
                errorMessage = "Network error. Please check your connection and try again."
            case .storeProblemError:
                errorMessage = "Unable to connect to the App Store. Please try again."
            case .purchaseNotAllowedError:
                errorMessage = "Purchases are not allowed on this device."
            case .purchaseInvalidError:
                errorMessage = "Purchase could not be completed. Please try again."
            default:
                errorMessage = "Purchase could not be completed. Please try again."
            }
            return false
        } catch {
            print("[RevenueCat] Unexpected purchase error: \(error)")
            isLoading = false

            let errorString = error.localizedDescription.lowercased()
            if errorString.contains("cancel") {
                return false
            } else if errorString.contains("network") || errorString.contains("connection") {
                errorMessage = "Network error. Please check your connection and try again."
            } else {
                errorMessage = "Purchase could not be completed. Please try again."
            }
            return false
        }
    }

    // MARK: - Subscription Management

    func restorePurchases() async {
        isLoading = true
        errorMessage = nil

        print("[RevenueCat] Restoring purchases...")

        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            await updateSubscriptionStatus(from: customerInfo)
            print("[RevenueCat] Restore completed. Active: \(isSubscriptionActive)")
            isLoading = false
        } catch {
            print("[RevenueCat] Restore failed: \(error)")
            errorMessage = "Could not restore purchases. Please ensure you're signed in to the App Store."
            isLoading = false
        }
    }

    func checkSubscriptionStatus() async {
        print("[RevenueCat] Checking subscription status...")

        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            await updateSubscriptionStatus(from: customerInfo)
        } catch {
            print("[RevenueCat] Error checking status: \(error)")
        }
    }

    private func updateSubscriptionStatus(from customerInfo: CustomerInfo) async {
        let entitlement = customerInfo.entitlements[entitlementID]
        let isActive = entitlement?.isActive == true

        print("[RevenueCat] Entitlement '\(entitlementID)' active: \(isActive)")

        if let entitlement = entitlement, isActive {
            print("[RevenueCat] Product: \(entitlement.productIdentifier)")
            print("[RevenueCat] Expires: \(entitlement.expirationDate?.description ?? "never (lifetime)")")

            // Match to a loaded plan
            let matchedPlan = availableSubscriptions.first { $0.id == entitlement.productIdentifier }
            currentSubscription = matchedPlan
        } else {
            currentSubscription = nil
        }

        isSubscriptionActive = isActive
        await checkIntroOfferEligibility()
    }

    private func checkIntroOfferEligibility() async {
        if isSubscriptionActive {
            isEligibleForIntroOffer = false
            return
        }

        // RevenueCat tracks intro offer eligibility through offerings
        var eligible = true
        for package in packages {
            if let sk2Product = package.storeProduct.sk2Product,
               let subscription = sk2Product.subscription {
                let isEligible = await subscription.isEligibleForIntroOffer
                if !isEligible {
                    eligible = false
                    break
                }
            }
        }

        isEligibleForIntroOffer = eligible
        print("[RevenueCat] Introductory offer eligibility: \(eligible)")
    }

    // MARK: - Premium Feature Access

    var isPremiumUser: Bool {
        return isSubscriptionActive
    }

    func hasAccessTo(_ feature: PremiumFeature) -> Bool {
        guard isSubscriptionActive else { return false }
        return true
    }

    func requiresPremium(_ feature: PremiumFeature, showUpgrade: Binding<Bool>) -> Bool {
        if hasAccessTo(feature) {
            return false
        } else {
            showUpgrade.wrappedValue = true
            return true
        }
    }

    // MARK: - TikTok Attribution

    /// Call this when a user arrives from a TikTok link or deep link
    func setTikTokAttribution(videoId: String? = nil, campaign: String? = nil) {
        var attributes: [String: String] = [
            "$mediaSource": "TikTok"
        ]
        if let campaign = campaign {
            attributes["$campaign"] = campaign
        }
        if let videoId = videoId {
            attributes["tiktok_video_id"] = videoId
        }
        Purchases.shared.attribution.setAttributes(attributes)
        print("[RevenueCat] TikTok attribution set: \(attributes)")
    }

    // MARK: - Subscription Analytics

    func logSubscriptionEvent(_ event: SubscriptionEvent) {
        // RevenueCat tracks events automatically
        // Add custom logging here if needed
    }
}

// MARK: - PurchasesDelegate

extension SubscriptionManager: PurchasesDelegate {
    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            print("[RevenueCat] Customer info updated via delegate")
            await updateSubscriptionStatus(from: customerInfo)
        }
    }
}

// MARK: - Subscription Models

struct SubscriptionPlan: Identifiable, Hashable {
    let id: String
    let type: SubscriptionPlanType
    let product: Product
    let package: Package?
    let priority: Int
    let price: Decimal
    let priceFormatted: String
    let introductoryOffer: Product.SubscriptionOffer?
    let promotionalOffers: [Product.SubscriptionOffer]

    var title: String {
        switch type {
        case .monthly:
            return "Monthly Premium"
        case .yearly:
            return "Yearly Premium"
        case .lifetime:
            return "Lifetime Premium"
        }
    }

    var subtitle: String {
        switch type {
        case .monthly:
            return "Billed monthly"
        case .yearly:
            return "Billed annually • Best Value"
        case .lifetime:
            return "One-time purchase"
        }
    }

    var description: String {
        switch type {
        case .monthly:
            return "Full access to all premium features. Auto-renews monthly."
        case .yearly:
            return "Save 44% with annual billing. Auto-renews yearly."
        case .lifetime:
            return "Pay once, premium forever. No subscription."
        }
    }

    var durationText: String {
        switch type {
        case .monthly:
            return "1 Month"
        case .yearly:
            return "12 Months (1 Year)"
        case .lifetime:
            return "Lifetime (One-Time Purchase)"
        }
    }

    var pricePerUnitText: String {
        switch type {
        case .monthly:
            return "\(priceFormatted)/month"
        case .yearly:
            let monthlyPrice = (price as NSDecimalNumber).doubleValue / 12.0
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = product.priceFormatStyle.currencyCode
            let monthlyFormatted = formatter.string(from: NSNumber(value: monthlyPrice)) ?? "$\(String(format: "%.2f", monthlyPrice))"
            return "\(monthlyFormatted)/month"
        case .lifetime:
            return "One-time payment"
        }
    }

    var savings: String? {
        switch type {
        case .yearly:
            return "Save 60%"
        case .lifetime:
            return "Best Deal"
        default:
            return nil
        }
    }

    var isPopular: Bool {
        return type == .yearly
    }

    var color: Color {
        switch type {
        case .monthly:
            return .blue
        case .yearly:
            return .green
        case .lifetime:
            return .purple
        }
    }

    static func == (lhs: SubscriptionPlan, rhs: SubscriptionPlan) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

enum SubscriptionPlanType: String, CaseIterable {
    case monthly = "monthly"
    case yearly = "yearly"
    case lifetime = "lifetime"
}

// MARK: - Premium Features

enum PremiumFeature: String, CaseIterable {
    case aiFoodRecognition = "ai_food_recognition"
    case advancedAnalytics = "advanced_analytics"
    case mealPlanning = "meal_planning"
    case unlimitedRecipes = "unlimited_recipes"
    case exportData = "export_data"
    case prioritySupport = "priority_support"
    case advancedGoals = "advanced_goals"
    case nutrientTrends = "nutrient_trends"
    case customMacros = "custom_macros"
    case batchLogging = "batch_logging"
    case smartInsights = "smart_insights"

    var displayName: String {
        switch self {
        case .aiFoodRecognition:
            return "AI Food Recognition"
        case .advancedAnalytics:
            return "Advanced Analytics"
        case .mealPlanning:
            return "Meal Planning & Prep"
        case .unlimitedRecipes:
            return "Unlimited Recipes"
        case .exportData:
            return "Data Export"
        case .prioritySupport:
            return "Priority Support"
        case .advancedGoals:
            return "Advanced Goals"
        case .nutrientTrends:
            return "Nutrient Trends"
        case .customMacros:
            return "Custom Macros"
        case .batchLogging:
            return "Batch Logging"
        case .smartInsights:
            return "AI-Powered Insights"
        }
    }

    var description: String {
        switch self {
        case .aiFoodRecognition:
            return "Scan food with your camera for instant nutrition analysis"
        case .advancedAnalytics:
            return "Detailed nutrition trends and comprehensive reports"
        case .mealPlanning:
            return "Plan meals in advance with shopping lists"
        case .unlimitedRecipes:
            return "Save unlimited custom recipes and meal combinations"
        case .exportData:
            return "Export your data to CSV, PDF, or sync with other apps"
        case .prioritySupport:
            return "Get help faster with priority customer support"
        case .advancedGoals:
            return "Set complex goals with custom timeframes and targets"
        case .nutrientTrends:
            return "Track micronutrients and vitamin intake over time"
        case .customMacros:
            return "Create custom macro targets beyond basic ratios"
        case .batchLogging:
            return "Log multiple foods at once and save meal templates"
        case .smartInsights:
            return "AI-powered recommendations and health insights"
        }
    }

    var icon: String {
        switch self {
        case .aiFoodRecognition:
            return "camera.viewfinder"
        case .advancedAnalytics:
            return "chart.line.uptrend.xyaxis"
        case .mealPlanning:
            return "calendar.badge.plus"
        case .unlimitedRecipes:
            return "book.fill"
        case .exportData:
            return "square.and.arrow.up"
        case .prioritySupport:
            return "headphones"
        case .advancedGoals:
            return "target"
        case .nutrientTrends:
            return "waveform.path.ecg"
        case .customMacros:
            return "slider.horizontal.3"
        case .batchLogging:
            return "plus.square.on.square"
        case .smartInsights:
            return "brain.head.profile"
        }
    }
}

// MARK: - Subscription Events

enum SubscriptionEvent {
    case viewUpgrade
    case startTrial
    case purchaseAttempt(SubscriptionPlanType)
    case purchaseSuccess(SubscriptionPlanType)
    case purchaseFailure(String)
    case restore
    case cancel

    var eventName: String {
        switch self {
        case .viewUpgrade:
            return "subscription_view_upgrade"
        case .startTrial:
            return "subscription_start_trial"
        case .purchaseAttempt(let type):
            return "subscription_purchase_attempt_\(type.rawValue)"
        case .purchaseSuccess(let type):
            return "subscription_purchase_success_\(type.rawValue)"
        case .purchaseFailure:
            return "subscription_purchase_failure"
        case .restore:
            return "subscription_restore"
        case .cancel:
            return "subscription_cancel"
        }
    }
}

// MARK: - Subscription Errors

enum SubscriptionError: LocalizedError {
    case failedVerification
    case productNotFound
    case purchaseFailed
    case userCancelled

    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Failed to verify purchase"
        case .productNotFound:
            return "Subscription not available"
        case .purchaseFailed:
            return "Purchase failed"
        case .userCancelled:
            return "Purchase was cancelled"
        }
    }
}
