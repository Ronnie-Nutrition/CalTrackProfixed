import Foundation
import Combine
import StoreKit
import SwiftUI

// MARK: - Subscription Manager

@MainActor
class SubscriptionManager: NSObject, ObservableObject {
    static let shared = SubscriptionManager()

    @Published var isSubscriptionActive = false
    @Published var currentSubscription: SubscriptionPlan?
    @Published var availableSubscriptions: [SubscriptionPlan] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasFreeTrial = true
    @Published var trialEndDate: Date?
    @Published var productsLoadedSuccessfully = false
    @Published var lastLoadError: String?

    // Subscription product IDs - MUST match App Store Connect configuration exactly
    // These must be configured in App Store Connect under "In-App Purchases"
    private let productIDs: [String] = [
        "com.caltrackpro.premium.monthly",
        "com.caltrackpro.premium.yearly",
        "com.caltrackpro.premium.lifetime.v2"
    ]

    private var products: [Product] = []
    private var transactionListener: Task<Void, Error>?
    private var loadAttempts = 0
    private let maxLoadAttempts = 3

    override init() {
        super.init()

        // Start listening for transaction updates
        transactionListener = listenForTransactions()

        // Load initial subscription status
        Task {
            await loadProductsWithRetry()
            await checkSubscriptionStatus()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Product Loading with Retry

    func loadProductsWithRetry() async {
        loadAttempts = 0
        while loadAttempts < maxLoadAttempts && !productsLoadedSuccessfully {
            loadAttempts += 1
            await loadProducts()

            if !productsLoadedSuccessfully && loadAttempts < maxLoadAttempts {
                // Wait before retrying (exponential backoff)
                try? await Task.sleep(nanoseconds: UInt64(loadAttempts) * 1_000_000_000)
            }
        }
    }

    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        lastLoadError = nil

        do {
            print("[StoreKit] ========== LOADING PRODUCTS ==========")
            print("[StoreKit] Requesting products for IDs: \(productIDs)")
            print("[StoreKit] Bundle ID: \(Bundle.main.bundleIdentifier ?? "unknown")")

            products = try await Product.products(for: productIDs)

            print("[StoreKit] ========== PRODUCTS LOADED ==========")
            print("[StoreKit] Total products returned: \(products.count)")

            if products.isEmpty {
                print("[StoreKit] WARNING: No products returned!")
                print("[StoreKit] Possible causes:")
                print("[StoreKit] 1. Product IDs don't match App Store Connect exactly")
                print("[StoreKit] 2. Products not in 'Ready to Submit' status")
                print("[StoreKit] 3. Paid Apps Agreement not signed")
                print("[StoreKit] 4. Products not available in this storefront")
            }

            for product in products {
                print("[StoreKit] Product found:")
                print("[StoreKit]   - ID: \(product.id)")
                print("[StoreKit]   - Name: \(product.displayName)")
                print("[StoreKit]   - Price: \(product.displayPrice)")
                print("[StoreKit]   - Type: \(product.type)")
                if let subscription = product.subscription {
                    print("[StoreKit]   - Subscription period: \(subscription.subscriptionPeriod)")
                    print("[StoreKit]   - Is family shareable: \(product.isFamilyShareable)")
                }
            }

            availableSubscriptions = products.compactMap { product in
                createSubscriptionPlan(from: product)
            }.sorted { $0.priority < $1.priority }

            print("[StoreKit] Created \(availableSubscriptions.count) subscription plans")
            print("[StoreKit] =========================================")

            productsLoadedSuccessfully = !availableSubscriptions.isEmpty

            if products.isEmpty {
                lastLoadError = "No products returned from App Store. Verify product IDs in App Store Connect match exactly: \(productIDs.joined(separator: ", "))"
                print("[StoreKit] ERROR: \(lastLoadError!)")
            } else if availableSubscriptions.isEmpty {
                lastLoadError = "Products loaded but could not create subscription plans. Check product type configuration."
                print("[StoreKit] ERROR: \(lastLoadError!)")
            }

            isLoading = false
        } catch let error as StoreKitError {
            print("[StoreKit] StoreKitError loading products: \(error)")
            lastLoadError = "StoreKit error: \(error)"

            await MainActor.run {
                switch error {
                case .networkError:
                    errorMessage = "Cannot connect to App Store. Please check your internet connection."
                case .systemError:
                    errorMessage = "System error loading subscriptions. Please try again."
                case .notAvailableInStorefront:
                    errorMessage = "Subscriptions not available in your region."
                default:
                    errorMessage = "Unable to load subscription options. Please try again."
                }
                isLoading = false
            }
        } catch {
            let errorDesc = error.localizedDescription
            lastLoadError = "Error: \(errorDesc)"
            print("[StoreKit] ERROR loading products: \(error)")
            print("[StoreKit] Error type: \(type(of: error))")
            print("[StoreKit] Error description: \(errorDesc)")

            await MainActor.run {
                if errorDesc.contains("network") || errorDesc.contains("connection") {
                    errorMessage = "Cannot connect to App Store. Please check your internet connection."
                } else {
                    errorMessage = "Unable to load subscription options. Please try again."
                }
                isLoading = false
            }
        }
    }

    private func createSubscriptionPlan(from product: Product) -> SubscriptionPlan? {
        let planType: SubscriptionPlanType
        let priority: Int

        // Determine plan type from product ID - match exact IDs first, then patterns
        switch product.id {
        case "com.caltrackpro.premium.monthly":
            planType = .monthly
            priority = 2
        case "com.caltrackpro.premium.yearly":
            planType = .yearly
            priority = 1
        case "com.caltrackpro.premium.lifetime.v2", "com.caltrackpro.premium.lifetime":
            planType = .lifetime
            priority = 3
        case let id where id.contains("monthly"):
            planType = .monthly
            priority = 2
        case let id where id.contains("yearly"):
            planType = .yearly
            priority = 1
        case let id where id.contains("lifetime"):
            planType = .lifetime
            priority = 3
        default:
            print("[StoreKit] Unknown product ID: \(product.id)")
            return nil
        }

        // Handle both subscriptions (including non-renewing) and non-consumables
        let introOffer: Product.SubscriptionOffer?
        let promoOffers: [Product.SubscriptionOffer]

        if let subscription = product.subscription {
            // This is a subscription product (auto-renewable or non-renewing)
            introOffer = subscription.introductoryOffer
            promoOffers = subscription.promotionalOffers
            print("[StoreKit] Product \(product.id) is subscription type")
        } else {
            // This is a non-consumable - no subscription offers
            introOffer = nil
            promoOffers = []
            print("[StoreKit] Product \(product.id) is non-consumable type")
        }

        print("[StoreKit] Created plan: \(planType.rawValue) from product: \(product.id)")

        return SubscriptionPlan(
            id: product.id,
            type: planType,
            product: product,
            priority: priority,
            price: product.price,
            priceFormatted: product.displayPrice,
            introductoryOffer: introOffer,
            promotionalOffers: promoOffers
        )
    }
    
    // MARK: - Subscription Purchase

    func purchaseSubscription(_ plan: SubscriptionPlan) async -> Bool {
        isLoading = true
        errorMessage = nil

        print("[StoreKit] Starting purchase for: \(plan.id)")

        do {
            let result = try await plan.product.purchase()

            switch result {
            case .success(let verification):
                print("[StoreKit] Purchase successful, verifying...")
                let transaction = try checkVerified(verification)
                await transaction.finish()
                print("[StoreKit] Transaction finished: \(transaction.productID)")
                await checkSubscriptionStatus()
                isLoading = false
                return true

            case .userCancelled:
                print("[StoreKit] User cancelled purchase")
                isLoading = false
                return false

            case .pending:
                print("[StoreKit] Purchase pending (Ask to Buy or other)")
                isLoading = false
                errorMessage = "Purchase is pending approval. Once approved, your subscription will be activated automatically."
                return false

            @unknown default:
                print("[StoreKit] Unknown purchase result")
                isLoading = false
                errorMessage = "An unexpected error occurred. Please try again."
                return false
            }

        } catch StoreKitError.userCancelled {
            print("[StoreKit] StoreKit user cancelled")
            isLoading = false
            return false
        } catch StoreKitError.notAvailableInStorefront {
            print("[StoreKit] Product not available in storefront")
            await MainActor.run {
                isLoading = false
                errorMessage = "This subscription is not available in your region."
            }
            return false
        } catch StoreKitError.networkError(let underlyingError) {
            print("[StoreKit] Network error: \(underlyingError)")
            await MainActor.run {
                isLoading = false
                errorMessage = "Network error. Please check your connection and try again."
            }
            return false
        } catch StoreKitError.systemError(let underlyingError) {
            print("[StoreKit] System error: \(underlyingError)")
            await MainActor.run {
                isLoading = false
                errorMessage = "A system error occurred. Please restart the app and try again."
            }
            return false
        } catch StoreKitError.notEntitled {
            print("[StoreKit] Not entitled error")
            await MainActor.run {
                isLoading = false
                errorMessage = "Unable to complete purchase. Please try again."
            }
            return false
        } catch SubscriptionError.failedVerification {
            print("[StoreKit] Transaction verification failed")
            await MainActor.run {
                isLoading = false
                errorMessage = "Unable to verify purchase. Please try again or contact support."
            }
            return false
        } catch {
            print("[StoreKit] Purchase error: \(error)")
            print("[StoreKit] Error type: \(type(of: error))")
            print("[StoreKit] Error description: \(error.localizedDescription)")
            await MainActor.run {
                isLoading = false
                // Provide user-friendly error message
                let errorString = error.localizedDescription.lowercased()
                if errorString.contains("cancel") {
                    // User cancelled - don't show error
                    errorMessage = nil
                } else if errorString.contains("network") || errorString.contains("connection") {
                    errorMessage = "Network error. Please check your connection and try again."
                } else if errorString.contains("not signed") || errorString.contains("sign in") {
                    errorMessage = "Please sign in to the App Store to complete your purchase."
                } else if errorString.contains("sandbox") {
                    errorMessage = "Unable to connect to the App Store. Please try again."
                } else {
                    errorMessage = "Purchase could not be completed. Please try again."
                }
            }
            return false
        }
    }
    
    // MARK: - Subscription Management

    func restorePurchases() async {
        isLoading = true
        errorMessage = nil

        print("[StoreKit] Restoring purchases...")

        do {
            try await AppStore.sync()
            await checkSubscriptionStatus()
            print("[StoreKit] Restore completed. Active: \(isSubscriptionActive)")
            isLoading = false
        } catch {
            print("[StoreKit] Restore failed: \(error)")
            await MainActor.run {
                errorMessage = "Could not restore purchases. Please ensure you're signed in to the App Store."
                isLoading = false
            }
        }
    }

    func checkSubscriptionStatus() async {
        var activeSubscription: SubscriptionPlan?
        var hasActiveSubscription = false

        print("[StoreKit] Checking subscription status...")

        // Check current entitlements
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                print("[StoreKit] Found entitlement: \(transaction.productID)")

                // First try to match with loaded subscriptions
                if let subscription = availableSubscriptions.first(where: { $0.id == transaction.productID }) {
                    // Check if subscription is still valid
                    if let expirationDate = transaction.expirationDate {
                        if expirationDate > Date() {
                            print("[StoreKit] Active subscription until: \(expirationDate)")
                            hasActiveSubscription = true
                            activeSubscription = subscription
                        } else {
                            print("[StoreKit] Subscription expired: \(expirationDate)")
                        }
                    } else {
                        // No expiration = lifetime purchase (non-consumable)
                        print("[StoreKit] Lifetime purchase detected")
                        hasActiveSubscription = true
                        activeSubscription = subscription
                    }
                } else {
                    // Product not in our loaded list - might be a lifetime or different product ID
                    // Still grant access if it's one of our products
                    let productId = transaction.productID.lowercased()
                    if productId.contains("caltrackpro") || productId.contains("premium") {
                        print("[StoreKit] Recognized product (not loaded): \(transaction.productID)")
                        if let expirationDate = transaction.expirationDate {
                            if expirationDate > Date() {
                                hasActiveSubscription = true
                            }
                        } else {
                            // Lifetime purchase
                            hasActiveSubscription = true
                        }
                    }
                }

            } catch {
                print("[StoreKit] Transaction verification failed: \(error)")
            }
        }

        print("[StoreKit] Final status - Active: \(hasActiveSubscription)")

        await MainActor.run {
            isSubscriptionActive = hasActiveSubscription
            currentSubscription = activeSubscription
            updateFreeTrial()
        }
    }
    
    private func updateFreeTrial() {
        let trialKey = "com.caltrackpro.freetrial.used"
        let trialEndKey = "com.caltrackpro.freetrial.enddate"
        
        if !UserDefaults.standard.bool(forKey: trialKey) {
            // Free trial not used yet
            hasFreeTrial = true
            
            if trialEndDate == nil {
                // Set 7-day trial period
                let endDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
                UserDefaults.standard.set(endDate, forKey: trialEndKey)
                trialEndDate = endDate
            } else {
                trialEndDate = UserDefaults.standard.object(forKey: trialEndKey) as? Date
            }
            
            // Check if trial has expired
            if let endDate = trialEndDate, endDate < Date() {
                hasFreeTrial = false
                UserDefaults.standard.set(true, forKey: trialKey)
            }
            
        } else {
            hasFreeTrial = false
            trialEndDate = nil
        }
    }
    
    // MARK: - Premium Feature Access
    
    var isPremiumUser: Bool {
        // Only check subscription status (not free trial) so upgrade options are visible
        return isSubscriptionActive
    }
    
    func hasAccessTo(_ feature: PremiumFeature) -> Bool {
        // Free trial gives access to all features
        if hasFreeTrial {
            return true
        }
        
        // Check subscription status
        guard isSubscriptionActive else { return false }
        
        // All premium features are available with any active subscription
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
    
    // MARK: - Transaction Verification

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(let unverifiedTransaction, let verificationError):
            // Log detailed verification failure for debugging
            print("[StoreKit] Transaction verification failed:")
            print("[StoreKit] - Transaction: \(unverifiedTransaction)")
            print("[StoreKit] - Error: \(verificationError)")

            // In sandbox/review environment, Apple sometimes has verification issues
            // We still throw but with better logging for debugging
            throw SubscriptionError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Transaction Listener
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let strongSelf = self else { continue }
                do {
                    let transaction = try await MainActor.run { [strongSelf] in
                        try strongSelf.checkVerified(result)
                    }
                    await transaction.finish()
                    await strongSelf.checkSubscriptionStatus()
                } catch {
                    print("Transaction failed verification: \(error)")
                }
            }
        }
    }
    
    // MARK: - Subscription Analytics
    
    func logSubscriptionEvent(_ event: SubscriptionEvent) {
        // Log to analytics service (Firebase, etc.)
        // CrashlyticsManager.shared.logSubscriptionEvent(event)
    }
}

// MARK: - Subscription Models

struct SubscriptionPlan: Identifiable, Hashable {
    let id: String
    let type: SubscriptionPlanType
    let product: Product
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

    // Duration text (Required by Apple Guideline 3.1.2)
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

    // Per-unit pricing text (Required by Apple Guideline 3.1.2)
    var pricePerUnitText: String {
        switch type {
        case .monthly:
            return "\(priceFormatted)/month"
        case .yearly:
            // Calculate monthly equivalent
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

// MARK: - Crashlytics Extension (disabled - enable when Firebase is configured)
// extension CrashlyticsManager {
//     func logSubscriptionEvent(_ event: SubscriptionEvent) {
//         logEvent(event.eventName, parameters: [:])
//     }
// }
