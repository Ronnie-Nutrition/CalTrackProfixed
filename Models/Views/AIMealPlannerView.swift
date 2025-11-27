import SwiftUI
import SwiftData

struct AIMealPlannerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var mealPlanService = AIMealPlanningService.shared
    @State private var userProfile: UserProfile?
    
    // Preferences
    @State private var dietType: DietType = .balanced
    @State private var includedMeals: Set<MealType> = [.breakfast, .lunch, .dinner]
    @State private var allergies: String = ""
    @State private var avoidFoods: String = ""
    @State private var favoriteFoods: String = ""
    @State private var maxPrepTime: Double = 30
    @State private var budgetOptimized = false
    @State private var varietyLevel: VarietyLevel = .medium
    @State private var cuisinePreferences: Set<CuisineType> = []
    @State private var startDate = Date()
    
    @State private var showingGeneratedPlan = false
    @State private var generatedPlan: WeeklyMealPlan?
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero Section
                    heroSection
                    
                    // Quick Start Options
                    quickStartSection
                    
                    // Detailed Preferences
                    preferencesSection
                    
                    // Generate Button
                    generateButton
                }
                .padding()
            }
            .background(Color(.systemBackground).edgesIgnoringSafeArea(.all))
            .navigationTitle("AI Meal Planner")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingGeneratedPlan) {
                if let plan = generatedPlan {
                    GeneratedMealPlanView(mealPlan: plan)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .overlay {
                if mealPlanService.isGenerating {
                    generationOverlay
                }
            }
        }
        .onAppear {
            loadUserProfile()
        }
    }
    
    // MARK: - Hero Section
    private var heroSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "wand.and.stars")
                .font(.system(size: 50))
                .foregroundStyle(.linearGradient(
                    colors: [.purple, .blue],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
            
            Text("Personalized Meal Plans")
                .font(.title2)
                .bold()
            
            Text("AI-powered weekly meal planning tailored to your goals")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical)
    }
    
    // MARK: - Quick Start Section
    private var quickStartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Start")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                quickStartOption(
                    title: "Weight Loss",
                    icon: "arrow.down.circle.fill",
                    color: .green
                ) {
                    dietType = .lowCarb
                    budgetOptimized = false
                    varietyLevel = .medium
                }
                
                quickStartOption(
                    title: "Muscle Gain",
                    icon: "figure.strengthtraining.traditional",
                    color: .orange
                ) {
                    dietType = .highProtein
                    includedMeals = [.breakfast, .morningSnack, .lunch, .afternoonSnack, .dinner]
                }
                
                quickStartOption(
                    title: "Balanced Diet",
                    icon: "leaf.fill",
                    color: .blue
                ) {
                    dietType = .balanced
                    varietyLevel = .high
                }
                
                quickStartOption(
                    title: "Budget Friendly",
                    icon: "dollarsign.circle.fill",
                    color: .purple
                ) {
                    budgetOptimized = true
                    varietyLevel = .low
                }
            }
        }
    }
    
    private func quickStartOption(
        title: String,
        icon: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Preferences Section
    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Customize Your Plan")
                .font(.headline)
            
            // Diet Type
            VStack(alignment: .leading, spacing: 8) {
                Text("Diet Type")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Picker("Diet Type", selection: $dietType) {
                    ForEach(DietType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // Meals to Include
            VStack(alignment: .leading, spacing: 8) {
                Text("Meals to Include")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                ForEach(MealType.allCases, id: \.self) { meal in
                    Toggle(meal.rawValue, isOn: Binding(
                        get: { includedMeals.contains(meal) },
                        set: { isIncluded in
                            if isIncluded {
                                includedMeals.insert(meal)
                            } else {
                                includedMeals.remove(meal)
                            }
                        }
                    ))
                }
            }
            
            // Preparation Time
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Max Prep Time")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(maxPrepTime)) minutes")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Slider(value: $maxPrepTime, in: 5...60, step: 5)
            }
            
            // Variety Level
            VStack(alignment: .leading, spacing: 8) {
                Text("Meal Variety")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Picker("Variety", selection: $varietyLevel) {
                    ForEach(VarietyLevel.allCases, id: \.self) { level in
                        Text(level.rawValue).tag(level)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // Budget Optimization
            Toggle("Optimize for Budget", isOn: $budgetOptimized)
            
            // Food Preferences
            VStack(alignment: .leading, spacing: 12) {
                Text("Food Preferences")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextField("Allergies (comma separated)", text: $allergies)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Foods to avoid", text: $avoidFoods)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Favorite foods", text: $favoriteFoods)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            // Start Date
            DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                .datePickerStyle(CompactDatePickerStyle())
        }
    }
    
    // MARK: - Generate Button
    private var generateButton: some View {
        Button(action: generateMealPlan) {
            HStack {
                Image(systemName: "wand.and.stars")
                Text("Generate Weekly Meal Plan")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [.purple, .blue],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(mealPlanService.isGenerating || includedMeals.isEmpty)
    }
    
    // MARK: - Generation Overlay
    private var generationOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                Text("Creating Your Perfect Meal Plan")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Analyzing nutritional needs...")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                
                ProgressView(value: mealPlanService.generationProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .white))
                    .frame(width: 200)
            }
            .padding(40)
            .background(Color.black.opacity(0.8))
            .cornerRadius(20)
        }
    }
    
    // MARK: - Functions
    private func loadUserProfile() {
        let descriptor = FetchDescriptor<UserProfile>()
        if let profiles = try? modelContext.fetch(descriptor),
           let profile = profiles.first {
            self.userProfile = profile
        }
    }
    
    private func generateMealPlan() {
        guard let profile = userProfile else {
            errorMessage = "Please set up your profile first"
            showError = true
            return
        }
        
        let preferences = MealPlanPreferences(
            dietType: dietType,
            includedMeals: includedMeals,
            allergies: allergies.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) },
            avoidFoods: avoidFoods.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) },
            favoriteFoods: favoriteFoods.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) },
            maxPrepTime: Int(maxPrepTime),
            budgetOptimized: budgetOptimized,
            varietyLevel: varietyLevel,
            cuisinePreferences: Array(cuisinePreferences),
            startDate: startDate
        )
        
        Task {
            do {
                let plan = try await mealPlanService.generateWeeklyMealPlan(
                    for: profile,
                    preferences: preferences
                )
                
                await MainActor.run {
                    self.generatedPlan = plan
                    self.showingGeneratedPlan = true
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                }
            }
        }
    }
}

// MARK: - Generated Meal Plan View
struct GeneratedMealPlanView: View {
    let mealPlan: WeeklyMealPlan
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDay = 0
    @State private var showingShoppingList = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Summary Card
                    summaryCard
                    
                    // Day Selector
                    daySelector
                    
                    // Daily Plan
                    if selectedDay < mealPlan.dailyPlans.count {
                        dailyPlanView(mealPlan.dailyPlans[selectedDay])
                    }
                }
                .padding()
            }
            .background(Color(.systemBackground))
            .navigationTitle("Your Meal Plan")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: saveToDiary) {
                            Label("Add to Food Diary", systemImage: "calendar.badge.plus")
                        }
                        
                        Button(action: { showingShoppingList = true }) {
                            Label("Shopping List", systemImage: "cart")
                        }
                        
                        Button(action: exportPlan) {
                            Label("Export PDF", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingShoppingList) {
                ShoppingListView(mealPlan: mealPlan)
            }
        }
    }
    
    private var summaryCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Weekly Summary")
                        .font(.headline)
                    Text("\(mealPlan.startDate.formatted(.dateTime.month().day())) - \(mealPlan.endDate.formatted(.dateTime.month().day()))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                Image(systemName: "checkmark.seal.fill")
                    .font(.title)
                    .foregroundColor(.green)
            }
            
            HStack(spacing: 20) {
                nutritionStat(label: "Avg Daily", value: "\(Int(mealPlan.totalCalories / 7))", unit: "cal")
                nutritionStat(label: "Protein", value: "\(Int(mealPlan.totalProtein / 7))", unit: "g")
                nutritionStat(label: "Carbs", value: "\(Int(mealPlan.totalCarbs / 7))", unit: "g")
                nutritionStat(label: "Fat", value: "\(Int(mealPlan.totalFat / 7))", unit: "g")
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func nutritionStat(label: String, value: String, unit: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
            Text(unit)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    private var daySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(0..<7, id: \.self) { day in
                    dayButton(for: day)
                }
            }
        }
    }
    
    private func dayButton(for day: Int) -> some View {
        let date = mealPlan.startDate.addingTimeInterval(Double(day) * 24 * 60 * 60)
        let isSelected = selectedDay == day
        
        return Button(action: { selectedDay = day }) {
            VStack(spacing: 8) {
                Text(date.formatted(.dateTime.weekday(.abbreviated)))
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : .secondary)
                
                Text(date.formatted(.dateTime.day()))
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(width: 60, height: 60)
            .background(isSelected ? Color.blue : Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
    
    private func dailyPlanView(_ dailyPlan: DailyMealPlan) -> some View {
        VStack(spacing: 16) {
            ForEach(dailyPlan.meals) { meal in
                mealCard(meal)
            }
        }
    }
    
    private func mealCard(_ meal: PlannedMeal) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(meal.mealType.rawValue)
                    .font(.headline)
                
                Spacer()
                
                Text("\(Int(meal.totalCalories)) cal")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            ForEach(meal.foods) { food in
                HStack {
                    Text(food.name)
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text("\(Int(food.quantity)) \(food.unit)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if !meal.recipeSuggestions.isEmpty {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recipe Suggestion")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(meal.recipeSuggestions.prefix(1), id: \.name) { recipe in
                        HStack {
                            Image(systemName: "book")
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading) {
                                Text(recipe.name)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                Text(recipe.description)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            
            HStack(spacing: 4) {
                Label("\(meal.preparationTime) min", systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                HStack(spacing: 12) {
                    nutritionLabel("P", value: Int(meal.totalProtein))
                    nutritionLabel("C", value: Int(meal.totalCarbs))
                    nutritionLabel("F", value: Int(meal.totalFat))
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func nutritionLabel(_ label: String, value: Int) -> some View {
        Text("\(label): \(value)g")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    
    private func saveToDiary() {
        // Implementation to save meal plan to food diary
    }
    
    private func exportPlan() {
        // Implementation to export as PDF
    }
}

// MARK: - Shopping List View
struct ShoppingListView: View {
    let mealPlan: WeeklyMealPlan
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(consolidatedIngredients(), id: \.name) { ingredient in
                    HStack {
                        Text(ingredient.name)
                        Spacer()
                        Text("\(Int(ingredient.quantity)) \(ingredient.unit)")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Shopping List")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func consolidatedIngredients() -> [(name: String, quantity: Double, unit: String)] {
        var ingredients: [String: (quantity: Double, unit: String)] = [:]
        
        for dailyPlan in mealPlan.dailyPlans {
            for meal in dailyPlan.meals {
                for food in meal.foods {
                    if let existing = ingredients[food.name] {
                        ingredients[food.name] = (existing.quantity + food.quantity, food.unit)
                    } else {
                        ingredients[food.name] = (food.quantity, food.unit)
                    }
                }
            }
        }
        
        return ingredients.map { (name: $0.key, quantity: $0.value.quantity, unit: $0.value.unit) }
            .sorted { $0.name < $1.name }
    }
}

#Preview {
    AIMealPlannerView()
        .modelContainer(for: [UserProfile.self, FoodEntry.self], inMemory: true)
}