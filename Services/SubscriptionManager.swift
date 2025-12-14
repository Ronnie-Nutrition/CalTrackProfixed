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
    
    // Subscription product IDs - MUST match App Store Connect configuration
    private let productIDs: [String] = [
        "com.easyaiflows.CalTrackProFixed.premium.monthly",
        "com.easyaiflows.CalTrackProFixed.premium.annual",
        "com.easyaiflows.CalTrackProFixed.premium.lifetime"
    ]
    
    private var products: [Product] = []
    private var transactionListener: Task<Void, Error>?
    
    override init() {
        super.init()

        // TEMPORARY: Disabled for testing until StoreKit is properly configured
        /*
        // Start listening for transaction updates
        transactionListener = listenForTransactions()

        // Load initial subscription status
        Task {
            await loadProducts()
            await checkSubscriptionStatus()
        }
        */
    }
    
    deinit {
        transactionListener?.cancel()
    }
    
    // MARK: - Product Loading
    
    func loadProducts() async {
        isLoading = true
        
        do {
            products = try await Product.products(for: productIDs)
            
            availableSubscriptions = products.compactMap { product in
                createSubscriptionPlan(from: product)
            }.sorted { $0.priority < $1.priority }
            
            isLoading = false
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load subscription options: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    private func createSubscriptionPlan(from product: Product) -> SubscriptionPlan? {
        guard let subscription = product.subscription else { return nil }
        
        let planType: SubscriptionPlanType
        let priority: Int
        
        switch product.id {
        case "com.easyaiflows.CalTrackProFixed.premium.monthly":
            planType = .monthly
            priority = 2
        case "com.easyaiflows.CalTrackProFixed.premium.annual":
            planType = .yearly
            priority = 1
        case "com.easyaiflows.CalTrackProFixed.premium.lifetime":
            planType = .lifetime
            priority = 3
        default:
            return nil
        }
        
        return SubscriptionPlan(
            id: product.id,
            type: planType,
            product: product,
            priority: priority,
            price: product.price,
            priceFormatted: product.displayPrice,
            introductoryOffer: subscription.introductoryOffer,
            promotionalOffers: subscription.promotionalOffers
        )
    }
    
    // MARK: - Subscription Purchase
    
    func purchaseSubscription(_ plan: SubscriptionPlan) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await plan.product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await checkSubscriptionStatus()
                isLoading = false
                return true
                
            case .userCancelled:
                isLoading = false
                return false
                
            case .pending:
                isLoading = false
                errorMessage = "Purchase is pending approval"
                return false
                
            @unknown default:
                isLoading = false
                errorMessage = "Unknown purchase result"
                return false
            }
            
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = "Purchase failed: \(error.localizedDescription)"
            }
            return false
        }
    }
    
    // MARK: - Subscription Management
    
    func restorePurchases() async {
        isLoading = true
        
        do {
            try await AppStore.sync()
            await checkSubscriptionStatus()
            isLoading = false
        } catch {
            await MainActor.run {
                errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    func checkSubscriptionStatus() async {
        var activeSubscription: SubscriptionPlan?
        var hasActiveSubscription = false
        
        // Check current entitlements
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                if let subscription = availableSubscriptions.first(where: { $0.id == transaction.productID }) {
                    
                    // Check if subscription is still valid
                    if let expirationDate = transaction.expirationDate {
                        if expirationDate > Date() {
                            hasActiveSubscription = true
                            activeSubscription = subscription
                        }
                    } else {
                        // Lifetime subscription
                        hasActiveSubscription = true
                        activeSubscription = subscription
                    }
                }
                
            } catch {
                print("Transaction verification failed: \(error)")
            }
        }
        
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
        // TEMPORARY: Always return true for testing until StoreKit is configured
        return true
        // return isSubscriptionActive || hasFreeTrial
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
        case .unverified:
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
            return "Full access to all premium features"
        case .yearly:
            return "Save 60% with annual billing"
        case .lifetime:
            return "Pay once, premium forever"
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
