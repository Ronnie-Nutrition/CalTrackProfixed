import SwiftUI
import StoreKit

struct PremiumUpgradeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: PremiumPlan = .monthly
    @State private var isLoading = false
    
    enum PremiumPlan: CaseIterable {
        case monthly, yearly
        
        var title: String {
            switch self {
            case .monthly: return "Monthly"
            case .yearly: return "Yearly"
            }
        }
        
        var price: String {
            switch self {
            case .monthly: return "$4.99"
            case .yearly: return "$39.99"
            }
        }
        
        var savings: String? {
            switch self {
            case .monthly: return nil
            case .yearly: return "Save 33%"
            }
        }
        
        var description: String {
            switch self {
            case .monthly: return "per month"
            case .yearly: return "per year"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.yellow, .orange],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "crown.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                        }
                        
                        Text("CalTrackPro Premium")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Unlock advanced features and take your nutrition tracking to the next level")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // Features
                    VStack(spacing: 16) {
                        Text("Premium Features")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(spacing: 12) {
                            PremiumFeatureRow(
                                icon: "heart.fill",
                                title: "Apple Health Integration",
                                description: "Sync nutrition data and import workout calories",
                                color: .red
                            )
                            
                            PremiumFeatureRow(
                                icon: "chart.line.uptrend.xyaxis",
                                title: "Advanced Analytics",
                                description: "Weekly reports, trends, and personalized insights",
                                color: .blue
                            )
                            
                            PremiumFeatureRow(
                                icon: "calendar",
                                title: "Meal Planning",
                                description: "AI-powered meal suggestions and recipe creation",
                                color: .green
                            )
                            
                            PremiumFeatureRow(
                                icon: "target",
                                title: "Smart Goals",
                                description: "Personalized targets and achievement tracking",
                                color: .purple
                            )
                            
                            PremiumFeatureRow(
                                icon: "bell.badge.fill",
                                title: "Smart Reminders",
                                description: "Intelligent notifications and meal timing",
                                color: .orange
                            )
                            
                            PremiumFeatureRow(
                                icon: "camera.filters",
                                title: "AI Food Recognition",
                                description: "Advanced photo analysis and food identification",
                                color: .pink
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Pricing plans
                    VStack(spacing: 16) {
                        Text("Choose Your Plan")
                            .font(.headline)
                        
                        VStack(spacing: 12) {
                            ForEach(PremiumPlan.allCases, id: \.self) { plan in
                                PricingPlanCard(
                                    plan: plan,
                                    isSelected: selectedPlan == plan
                                ) {
                                    selectedPlan = plan
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Purchase button
                    Button(action: purchasePremium) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "crown.fill")
                            }
                            
                            Text(isLoading ? "Processing..." : "Start Premium - \(selectedPlan.price)")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isLoading)
                    .padding(.horizontal)
                    
                    // Footer
                    VStack(spacing: 8) {
                        Text("✓ Cancel anytime")
                        Text("✓ 7-day free trial")
                        Text("✓ All features included")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    // Legal links
                    HStack(spacing: 20) {
                        Button("Terms of Service") {
                            // Open terms
                        }
                        
                        Button("Privacy Policy") {
                            // Open privacy policy
                        }
                        
                        Button("Restore Purchases") {
                            restorePurchases()
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                .padding(.vertical)
            }
            .navigationTitle("Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func purchasePremium() {
        isLoading = true
        
        // Simulate purchase process
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isLoading = false
            // Here you would integrate with StoreKit 2
            // For now, just dismiss
            dismiss()
        }
    }
    
    private func restorePurchases() {
        // Implement restore purchases
        print("Restoring purchases...")
    }
}

struct PremiumFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 18))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

struct PricingPlanCard: View {
    let plan: PremiumUpgradeView.PremiumPlan
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(plan.title)
                            .font(.headline)
                        
                        if let savings = plan.savings {
                            Text(savings)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    
                    Text(plan.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(plan.price)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if plan == .yearly {
                        Text("$3.33/month")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .font(.title2)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    PremiumUpgradeView()
}