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
                GlassmorphismBackground(colors: [.purple, .blue, .indigo])
                
                ScrollView {
                    VStack(spacing: 24) {
                        headerSection
                        
                        if subscriptionManager.hasFreeTrial {
                            freeTrialCard
                        }
                        
                        featuresSection
                        subscriptionPlansSection
                        
                        if !subscriptionManager.hasFreeTrial {
                            purchaseSection
                        }
                        
                        bottomSection
                    }
                    .padding()
                }
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
                
                if subscriptionManager.availableSubscriptions.isEmpty {
                    Task {
                        await subscriptionManager.loadProducts()
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
                    .liquidPulse(color: .purple, intensity: 0.5)
                
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
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(Array(PremiumFeature.allCases.enumerated()), id: \.element) { index, feature in
                    PremiumFeatureCard(
                        feature: feature,
                        isHighlighted: feature == sourceFeature,
                        delay: Double(index) * 0.1
                    )
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
            
            VStack(spacing: 12) {
                ForEach(subscriptionManager.availableSubscriptions) { plan in
                    SubscriptionPlanCard(
                        plan: plan,
                        isSelected: selectedPlan == plan,
                        onSelect: { selectedPlan = plan }
                    )
                }
            }
            .padding(.horizontal)
        }
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
                .liquidPulse(color: plan.color, intensity: 0.3)
                
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
                
                Button("Terms of Service") {
                    // Open terms URL
                    if let url = URL(string: "https://caltrackpro.com/terms") {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.subheadline)
                .foregroundColor(.blue)
                
                Button("Privacy Policy") {
                    // Open privacy URL
                    if let url = URL(string: "https://ronnie-nutrition.github.io/CalTrackProfixed/privacy-policy.html") {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            Text("Subscriptions will be charged to your iTunes account. Your subscription automatically renews unless cancelled at least 24 hours before the end of the current period.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
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
    
    @State private var isVisible = false
    
    var body: some View {
        LiquidGlassCard {
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
                        .multilineTextAlignment(.center)
                    
                    Text(feature.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }
            }
            .padding()
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isHighlighted ? .orange : .clear, lineWidth: 2)
            )
        }
        .scaleEffect(isVisible ? 1 : 0.8)
        .opacity(isVisible ? 1 : 0)
        .animation(
            .spring(response: 0.6, dampingFraction: 0.8)
            .delay(delay),
            value: isVisible
        )
        .onAppear {
            isVisible = true
        }
    }
}

struct SubscriptionPlanCard: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            LiquidGlassCard {
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(plan.title)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
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
                                        .foregroundColor(.orange)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(.orange.opacity(0.1))
                                        .cornerRadius(6)
                                }
                            }
                            
                            Text(plan.subtitle)
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
                            
                            if plan.type != .lifetime {
                                Text("/ \(plan.type == .monthly ? "month" : "year")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
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
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? plan.color : .clear, lineWidth: 2)
                )
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatIntroductoryOffer(_ offer: Product.SubscriptionOffer) -> String {
        let period = offer.period
        
        // Return a generic offer description for all types
        return "\(offer.displayPrice) for \(period.value) \(period.unit.localizedDescription)"
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