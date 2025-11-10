import SwiftUI
import SwiftData

struct MealPlanningView: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showUpgrade = false
    @State private var selectedWeek = Date()
    @State private var mealPlans: [MealPlan] = []
    @State private var showingCreatePlan = false
    @State private var selectedPlan: MealPlan?
    
    var body: some View {
        NavigationStack {
            ZStack {
                GlassmorphismBackground(colors: [.green, .blue, .teal])
                
                if subscriptionManager.hasAccessTo(.mealPlanning) {
                    mealPlanningContent
                } else {
                    premiumRequiredView
                }
            }
            .navigationTitle("Meal Planning")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if subscriptionManager.hasAccessTo(.mealPlanning) {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showingCreatePlan = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingCreatePlan) {
                CreateMealPlanView { plan in
                    mealPlans.append(plan)
                }
            }
            .sheet(item: $selectedPlan) { plan in
                MealPlanDetailView(plan: plan)
            }
        }
        .premiumFeature(.mealPlanning)
    }
    
    // MARK: - Meal Planning Content
    
    private var mealPlanningContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                weekSelector
                dailyMealPlan
                savedMealPlans
                mealPrepSection
            }
            .padding()
        }
    }
    
    private var weekSelector: some View {
        LiquidGlassCard {
            VStack(spacing: 16) {
                HStack {
                    Button(action: previousWeek) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    Text(weekDisplayText)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button(action: nextWeek) {
                        Image(systemName: "chevron.right")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
                
                HStack(spacing: 0) {
                    ForEach(weekDays, id: \.self) { day in
                        VStack(spacing: 4) {
                            Text(dayFormatter.string(from: day))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(dateFormatter.string(from: day))
                                .font(.subheadline)
                                .fontWeight(Calendar.current.isDate(day, inSameDayAs: Date()) ? .bold : .medium)
                                .foregroundColor(Calendar.current.isDate(day, inSameDayAs: Date()) ? .blue : .primary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding()
        }
    }
    
    private var dailyMealPlan: some View {
        VStack(spacing: 16) {
            ForEach(weekDays.prefix(7), id: \.self) { day in
                DayMealPlanCard(
                    date: day,
                    mealPlan: mealPlanForDay(day)
                )
            }
        }
    }
    
    private var savedMealPlans: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Saved Meal Plans")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("View All") {
                    // Navigate to all meal plans
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            if mealPlans.isEmpty {
                EmptyMealPlansView()
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(mealPlans.prefix(4)) { plan in
                        SavedMealPlanCard(plan: plan) {
                            selectedPlan = plan
                        }
                    }
                }
            }
        }
    }
    
    private var mealPrepSection: some View {
        LiquidGlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "checklist")
                        .font(.title2)
                        .foregroundColor(.orange)
                    
                    Text("Meal Prep Checklist")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    MealPrepTaskRow(
                        task: "Generate shopping list",
                        isCompleted: false,
                        action: generateShoppingList
                    )
                    
                    MealPrepTaskRow(
                        task: "Prep vegetables",
                        isCompleted: false,
                        action: {}
                    )
                    
                    MealPrepTaskRow(
                        task: "Cook grains & proteins",
                        isCompleted: false,
                        action: {}
                    )
                    
                    MealPrepTaskRow(
                        task: "Portion containers",
                        isCompleted: false,
                        action: {}
                    )
                }
            }
            .padding()
        }
    }
    
    // MARK: - Premium Required View
    
    private var premiumRequiredView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 12) {
                Text("Meal Planning Premium")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Plan your meals in advance, generate shopping lists, and organize your meal prep with our premium meal planning tools.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            VStack(spacing: 16) {
                PremiumFeatureHighlight(
                    icon: "calendar.badge.plus",
                    title: "Weekly Meal Planning",
                    description: "Plan all your meals for the week"
                )
                
                PremiumFeatureHighlight(
                    icon: "list.clipboard",
                    title: "Smart Shopping Lists",
                    description: "Auto-generated lists from your meal plans"
                )
                
                PremiumFeatureHighlight(
                    icon: "fork.knife.circle",
                    title: "Meal Prep Guides",
                    description: "Step-by-step preparation instructions"
                )
                
                PremiumFeatureHighlight(
                    icon: "bookmark.fill",
                    title: "Save Meal Plans",
                    description: "Reuse your favorite meal combinations"
                )
            }
            
            Button(action: {
                showUpgrade = true
            }) {
                HStack {
                    Image(systemName: "crown.fill")
                        .font(.title2)
                    
                    Text("Upgrade to Premium")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [.green, .mint],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            .liquidPulse(color: .green, intensity: 0.3)
            .padding(.horizontal)
            
            Spacer()
        }
        .sheet(isPresented: $showUpgrade) {
            PremiumUpgradeView(sourceFeature: .mealPlanning)
        }
    }
    
    // MARK: - Helper Methods
    
    private var weekDays: [Date] {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: selectedWeek)?.start ?? selectedWeek
        
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: startOfWeek)
        }
    }
    
    private var weekDisplayText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        let startDate = weekDays.first ?? selectedWeek
        let endDate = weekDays.last ?? selectedWeek
        
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
    
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
    
    private func previousWeek() {
        selectedWeek = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: selectedWeek) ?? selectedWeek
    }
    
    private func nextWeek() {
        selectedWeek = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: selectedWeek) ?? selectedWeek
    }
    
    private func mealPlanForDay(_ date: Date) -> DayMealPlan? {
        // In a real implementation, this would fetch from Core Data or similar
        return nil
    }
    
    private func generateShoppingList() {
        // Generate shopping list from meal plans
    }
}

// MARK: - Supporting Views

struct DayMealPlanCard: View {
    let date: Date
    let mealPlan: DayMealPlan?
    
    @State private var showingAddMeal = false
    
    var body: some View {
        LiquidGlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(dayFormatter.string(from: date))
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(dateFormatter.string(from: date))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button(action: {
                        showingAddMeal = true
                    }) {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.green)
                    }
                }
                
                if let plan = mealPlan {
                    VStack(spacing: 8) {
                        ForEach(plan.meals) { meal in
                            MealPlanRow(meal: meal)
                        }
                    }
                } else {
                    Text("No meals planned")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical)
                }
            }
            .padding()
        }
        .sheet(isPresented: $showingAddMeal) {
            AddMealToPlanView(date: date)
        }
    }
    
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }()
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()
}

struct SavedMealPlanCard: View {
    let plan: MealPlan
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            LiquidGlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text(plan.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                    
                    Text("\(plan.totalMeals) meals")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("\(plan.estimatedCalories) cal")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.blue.opacity(0.1))
                            .cornerRadius(4)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MealPlanRow: View {
    let meal: PlannedMeal
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(meal.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(meal.mealType.rawValue.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(meal.calories) cal")
                .font(.caption)
                .foregroundColor(.blue)
        }
        .padding(.vertical, 4)
    }
}

struct MealPrepTaskRow: View {
    let task: String
    @State var isCompleted: Bool
    let action: () -> Void
    
    var body: some View {
        HStack {
            Button(action: {
                isCompleted.toggle()
            }) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isCompleted ? .green : .gray)
            }
            
            Text(task)
                .font(.subheadline)
                .strikethrough(isCompleted)
                .foregroundColor(isCompleted ? .secondary : .primary)
            
            Spacer()
            
            Button("Start", action: action)
                .font(.caption)
                .foregroundColor(.blue)
        }
    }
}

struct PremiumFeatureHighlight: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.green)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal)
    }
}

struct EmptyMealPlansView: View {
    var body: some View {
        LiquidGlassCard {
            VStack(spacing: 16) {
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 40))
                    .foregroundColor(.secondary)
                
                VStack(spacing: 8) {
                    Text("No meal plans yet")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Create your first meal plan to get started with organized nutrition planning")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
        }
    }
}

// MARK: - Data Models

struct MealPlan: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let description: String?
    let days: [DayMealPlan]
    let createdDate: Date
    let tags: [String]
    
    var totalMeals: Int {
        days.reduce(0) { $0 + $1.meals.count }
    }
    
    var estimatedCalories: Int {
        days.reduce(0) { total, day in
            total + day.meals.reduce(0) { $0 + $1.calories }
        }
    }
}

struct DayMealPlan: Identifiable {
    let id = UUID()
    let date: Date
    let meals: [PlannedMeal]
    
    var totalCalories: Int {
        meals.reduce(0) { $0 + $1.calories }
    }
}

struct PlannedMeal: Identifiable {
    let id = UUID()
    let name: String
    let mealType: MealType
    let calories: Int
    let ingredients: [String]?
    let prepTime: TimeInterval?
    let recipeId: String?
    
    enum MealType: String, CaseIterable {
        case breakfast, lunch, dinner, snack
    }
}

// MARK: - Placeholder Views

struct CreateMealPlanView: View {
    let onSave: (MealPlan) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Text("Create Meal Plan")
                .navigationTitle("New Meal Plan")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") { dismiss() }
                    }
                }
        }
    }
}

struct MealPlanDetailView: View {
    let plan: MealPlan
    
    var body: some View {
        NavigationStack {
            Text("Meal Plan Detail")
                .navigationTitle(plan.name)
        }
    }
}

struct AddMealToPlanView: View {
    let date: Date
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Text("Add Meal")
                .navigationTitle("Add Meal")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") { dismiss() }
                    }
                }
        }
    }
}

#Preview {
    MealPlanningView()
}