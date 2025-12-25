import SwiftUI
import StoreKit

struct PremiumUpgradeView: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedPlan: SubscriptionPlan?
    @State private var showingPurchaseSheet = false
    @State private var isProcessingPurchase = false
    @State private var showingError = false
    
    let sourceFeature: PremiumFeature?
    
    init(sourceFeature: PremiumFeature? = nil) {
        self.sourceFeature = sourceFeature
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Static gradient background (no animations for smooth scrolling)
                LinearGradient(
                    colors: [.purple.opacity(0.3), .blue.opacity(0.2), .indigo.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        headerSection
                        featuresSection
                        subscriptionPlansSection
                        bottomSection
                    }
                    .padding()
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            .navigationTitle("CalTrack Pro Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                subscriptionManager.logSubscriptionEvent(.viewUpgrade)

                // Always attempt to load products on appear with retry
                Task {
                    if subscriptionManager.availableSubscriptions.isEmpty || !subscriptionManager.productsLoadedSuccessfully {
                        print("[PremiumView] Loading products...")
                        await subscriptionManager.loadProductsWithRetry()
                        print("[PremiumView] Products loaded: \(subscriptionManager.availableSubscriptions.count)")
                    }
                }
            }
            .alert("Purchase Error", isPresented: $showingError) {
                Button("OK") {}
            } message: {
                Text(subscriptionManager.errorMessage ?? "An error occurred")
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Premium Logo/Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple, .pink, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: .purple.opacity(0.4), radius: 10)

                Image(systemName: "crown.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 4)
            }
            
            VStack(spacing: 8) {
                Text("Unlock Premium Features")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Take your nutrition tracking to the next level with advanced analytics, meal planning, and AI-powered insights")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Free Trial Card
    
    private var freeTrialCard: some View {
        LiquidGlassCard {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "gift.fill")
                        .font(.title2)
                        .foregroundStyle(
                            LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Free Trial Active")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        if let trialEndDate = subscriptionManager.trialEndDate {
                            let daysLeft = Calendar.current.dateComponents([.day], from: Date(), to: trialEndDate).day ?? 0
                            Text("\(max(daysLeft, 0)) days remaining")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                
                Text("You have access to all premium features during your trial. Upgrade anytime to continue enjoying premium benefits.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            .padding()
        }
    }
    
    // MARK: - Features Section
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Premium Features")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)

            // Use regular Grid instead of LazyVGrid for stable scrolling
            let features = Array(PremiumFeature.allCases)
            VStack(spacing: 16) {
                ForEach(0..<(features.count / 2 + features.count % 2), id: \.self) { row in
                    HStack(spacing: 16) {
                        let firstIndex = row * 2
                        let secondIndex = row * 2 + 1

                        PremiumFeatureCard(
                            feature: features[firstIndex],
                            isHighlighted: features[firstIndex] == sourceFeature,
                            delay: 0
                        )

                        if secondIndex < features.count {
                            PremiumFeatureCard(
                                feature: features[secondIndex],
                                isHighlighted: features[secondIndex] == sourceFeature,
                                delay: 0
                            )
                        } else {
                            Spacer()
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Subscription Plans Section

    private var subscriptionPlansSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose Your Plan")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)

            // Always show fallback cards - they work even without StoreKit
            // This provides consistent layout and prevents scroll glitches
            fallbackSubscriptionCards
                .padding(.horizontal)

            // Purchase button
            fallbackPurchaseButton
                .padding(.horizontal)

            // Required subscription terms disclosure
            subscriptionTermsDisclosure
        }
    }

    // MARK: - Fallback Purchase Button

    private var fallbackPurchaseButton: some View {
        VStack(spacing: 12) {
            if let selected = selectedFallbackPlan {
                Button(action: {
                    purchaseFallbackPlan(selected)
                }) {
                    HStack {
                        if isProcessingPurchase {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "crown.fill")
                                .font(.title2)
                        }

                        Text(isProcessingPurchase ? "Processing..." : "Subscribe Now")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: selected == "yearly" ? [.green, .mint] : [.purple, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .disabled(isProcessingPurchase || subscriptionManager.isLoading)

                Text("Cancel anytime • Secure payment with Apple")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("Select a plan above to continue")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
    }

    // MARK: - Purchase Fallback Plan

    private func purchaseFallbackPlan(_ planType: String) {
        isProcessingPurchase = true

        // Map fallback plan to StoreKit product ID (must match App Store Connect exactly)
        let productID: String
        switch planType {
        case "monthly":
            productID = "com.caltrackpro.premium.monthly"
        case "yearly":
            productID = "com.caltrackpro.premium.yearly"
        case "lifetime":
            productID = "com.caltrackpro.premium.lifetime.v2"
        default:
            isProcessingPurchase = false
            return
        }

        Task {
            print("[Purchase] Attempting to purchase: \(productID)")

            // Try to find the StoreKit product
            var plan = subscriptionManager.availableSubscriptions.first(where: { $0.id == productID })

            // If not found, try loading products first
            if plan == nil {
                print("[Purchase] Product not loaded, attempting to load...")
                await subscriptionManager.loadProductsWithRetry()
                plan = subscriptionManager.availableSubscriptions.first(where: { $0.id == productID })
            }

            // Also try matching by type in case IDs don't match exactly
            if plan == nil {
                print("[Purchase] Trying to match by type...")
                plan = subscriptionManager.availableSubscriptions.first(where: {
                    $0.type.rawValue == planType
                })
            }

            if let plan = plan {
                print("[Purchase] Found plan: \(plan.id), proceeding with purchase")
                let success = await subscriptionManager.purchaseSubscription(plan)
                await MainActor.run {
                    isProcessingPurchase = false
                    if success {
                        dismiss()
                    } else if subscriptionManager.errorMessage != nil {
                        showingError = true
                    }
                }
            } else {
                print("[Purchase] Could not find product. Available: \(subscriptionManager.availableSubscriptions.map { $0.id })")
                await MainActor.run {
                    isProcessingPurchase = false
                    if let lastError = subscriptionManager.lastLoadError {
                        subscriptionManager.errorMessage = "Unable to connect to App Store. Please try again later. (\(lastError))"
                    } else {
                        subscriptionManager.errorMessage = "Subscription products are not available. Please ensure you have an active internet connection and try again."
                    }
                    showingError = true
                }
            }
        }
    }

    // MARK: - Fallback Subscription Cards (for App Store Review compliance)

    @State private var selectedFallbackPlan: String? = nil

    private var fallbackSubscriptionCards: some View {
        VStack(spacing: 12) {
            // Monthly Plan
            FallbackPlanCard(
                title: "Monthly",
                duration: "1 Month",
                price: "$4.99",
                pricePerUnit: "$4.99/month",
                description: "Auto-renews monthly.",
                isPopular: false,
                isSelected: selectedFallbackPlan == "monthly",
                color: .blue,
                onSelect: { selectedFallbackPlan = "monthly" }
            )

            // Yearly Plan
            FallbackPlanCard(
                title: "Yearly",
                duration: "12 Months",
                price: "$39.99",
                pricePerUnit: "$3.33/month",
                description: "Save 44%. Auto-renews yearly.",
                isPopular: true,
                savings: "44% OFF",
                isSelected: selectedFallbackPlan == "yearly",
                color: .green,
                onSelect: { selectedFallbackPlan = "yearly" }
            )

            // Lifetime Plan
            FallbackPlanCard(
                title: "Lifetime",
                duration: "One-Time",
                price: "$79.99",
                pricePerUnit: "Pay once",
                description: "Lifetime access. No subscription.",
                isPopular: false,
                savings: "Best",
                isSelected: selectedFallbackPlan == "lifetime",
                color: .purple,
                onSelect: { selectedFallbackPlan = "lifetime" }
            )
        }
        .drawingGroup()
    }

    // MARK: - Subscription Terms Disclosure (Required by Apple)

    private var subscriptionTermsDisclosure: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Subscription Details")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                Text("• Monthly: $4.99/month, billed every 1 month")
                Text("• Yearly: $39.99/year ($3.33/month), billed every 12 months")
                Text("• Lifetime: $79.99 one-time purchase, no renewal")
            }
            .font(.caption2)
            .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    // MARK: - Purchase Section
    
    private var purchaseSection: some View {
        VStack(spacing: 16) {
            if let plan = selectedPlan {
                Button(action: {
                    purchaseSubscription(plan)
                }) {
                    HStack {
                        if isProcessingPurchase {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "crown.fill")
                                .font(.title2)
                        }
                        
                        Text(isProcessingPurchase ? "Processing..." : "Start Premium")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: plan.isPopular ? [.green, .mint] : [.purple, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .disabled(isProcessingPurchase || subscriptionManager.isLoading)

                Text("Cancel anytime • No hidden fees")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("Select a plan to continue")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Bottom Section

    private var bottomSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                Button("Restore Purchases") {
                    Task {
                        await subscriptionManager.restorePurchases()
                    }
                }
                .font(.subheadline)
                .foregroundColor(.blue)

                Button("Terms of Use") {
                    // Open terms URL (GitHub Pages)
                    if let url = URL(string: "https://ronnie-nutrition.github.io/CalTrackProfixed/terms-of-service.html") {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.subheadline)
                .foregroundColor(.blue)

                Button("Privacy Policy") {
                    // Open privacy URL (GitHub Pages)
                    if let url = URL(string: "https://ronnie-nutrition.github.io/CalTrackProfixed/privacy-policy.html") {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }

            // Detailed auto-renewal disclosure (Required by Apple)
            VStack(spacing: 8) {
                Text("Auto-Renewable Subscription Terms")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                Text("""
Payment will be charged to your Apple ID account at confirmation of purchase. Subscription automatically renews unless it is canceled at least 24 hours before the end of the current period. Your account will be charged for renewal within 24 hours prior to the end of the current period. You can manage and cancel your subscriptions by going to your account settings on the App Store after purchase.
""")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Actions
    
    private func purchaseSubscription(_ plan: SubscriptionPlan) {
        isProcessingPurchase = true
        subscriptionManager.logSubscriptionEvent(.purchaseAttempt(plan.type))
        
        Task {
            let success = await subscriptionManager.purchaseSubscription(plan)
            
            await MainActor.run {
                isProcessingPurchase = false
                
                if success {
                    subscriptionManager.logSubscriptionEvent(.purchaseSuccess(plan.type))
                    dismiss()
                } else {
                    if let error = subscriptionManager.errorMessage {
                        subscriptionManager.logSubscriptionEvent(.purchaseFailure(error))
                        showingError = true
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct PremiumFeatureCard: View {
    let feature: PremiumFeature
    let isHighlighted: Bool
    let delay: Double

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isHighlighted ? .orange.opacity(0.2) : .blue.opacity(0.1))
                    .frame(width: 50, height: 50)

                Image(systemName: feature.icon)
                    .font(.title2)
                    .foregroundColor(isHighlighted ? .orange : .blue)
            }

            VStack(spacing: 4) {
                Text(feature.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)

                Text(feature.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground).opacity(0.8))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isHighlighted ? .orange : Color.gray.opacity(0.3), lineWidth: isHighlighted ? 2 : 1)
        )
    }
}

struct SubscriptionPlanCard: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(plan.title)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)

                            if plan.isPopular {
                                Text("POPULAR")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(.green)
                                    .cornerRadius(8)
                            }

                            Spacer()

                            if let savings = plan.savings {
                                Text(savings)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.green)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.green.opacity(0.15))
                                    .cornerRadius(6)
                            }
                        }

                        // Duration (Required by Apple)
                        Text("Duration: \(plan.durationText)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Text(plan.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(plan.priceFormatted)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(plan.color)

                        // Per-unit pricing (Required by Apple)
                        Text(plan.pricePerUnitText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Introductory offer information
                if let intro = plan.introductoryOffer {
                    HStack {
                        Image(systemName: "gift.fill")
                            .foregroundColor(.green)
                            .font(.caption)

                        Text(formatIntroductoryOffer(intro))
                            .font(.caption)
                            .foregroundColor(.green)
                            .fontWeight(.medium)

                        Spacer()
                    }
                    .padding(.top, 4)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground).opacity(0.8))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? plan.color : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func formatIntroductoryOffer(_ offer: Product.SubscriptionOffer) -> String {
        let period = offer.period

        // Return a generic offer description for all types
        return "\(offer.displayPrice) for \(period.value) \(period.unit.localizedDescription)"
    }
}

// MARK: - Fallback Plan Card (for App Store Review compliance when StoreKit unavailable)

struct FallbackPlanCard: View {
    let title: String
    let duration: String
    let price: String
    let pricePerUnit: String
    let description: String
    let isPopular: Bool
    var savings: String? = nil
    let isSelected: Bool
    let color: Color
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Left side - Plan info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        if isPopular {
                            Text("TOP")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.green)
                                .cornerRadius(4)
                        }

                        if let savings = savings {
                            Text(savings)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(.green.opacity(0.15))
                                .cornerRadius(4)
                        }
                    }

                    // Duration (Required by Apple)
                    Text("Duration: \(duration)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Right side - Price
                VStack(alignment: .trailing, spacing: 2) {
                    Text(price)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(color)

                    Text(pricePerUnit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground).opacity(0.8))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? color : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Premium Feature Access Modifier

struct PremiumFeatureGate: ViewModifier {
    let feature: PremiumFeature
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showUpgrade = false
    
    func body(content: Content) -> some View {
        content
            .disabled(!subscriptionManager.hasAccessTo(feature))
            .overlay(
                Group {
                    if !subscriptionManager.hasAccessTo(feature) {
                        Button(action: {
                            showUpgrade = true
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.ultraThinMaterial)
                                
                                VStack(spacing: 4) {
                                    Image(systemName: "crown.fill")
                                        .font(.title2)
                                        .foregroundColor(.orange)
                                    
                                    Text("Premium")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                    }
                }
            )
            .sheet(isPresented: $showUpgrade) {
                PremiumUpgradeView(sourceFeature: feature)
            }
    }
}

extension View {
    func premiumFeature(_ feature: PremiumFeature) -> some View {
        modifier(PremiumFeatureGate(feature: feature))
    }
}

#Preview {
    PremiumUpgradeView()
}