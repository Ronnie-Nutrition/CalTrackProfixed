import SwiftUI
import SwiftData

struct FoodRecognitionResultView: View {
    let result: FoodRecognitionResult
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var selectedMealType = FoodEntry.MealType.lunch
    @State private var adjustedFoods: [AdjustableFoodItem] = []
    @State private var showingSuccessMessage = false
    @State private var editingFoodIndex: Int? = nil
    @State private var showingFoodSearch = false

    struct AdjustableFoodItem: Identifiable {
        let id = UUID()
        let recognizedFood: RecognizedFood
        var quantity: Double
        var isSelected: Bool = true
        var customName: String? = nil  // User-edited name
        var customNutrition: RecognizedFood.NutritionInfo? = nil  // User-edited nutrition
        var wasEdited: Bool = false  // Track if user manually edited

        var displayName: String {
            customName ?? recognizedFood.name
        }

        var adjustedNutrition: RecognizedFood.NutritionInfo? {
            let baseNutrition = customNutrition ?? recognizedFood.nutritionInfo
            guard let nutrition = baseNutrition else { return nil }
            return nutrition.scaled(to: quantity)
        }

        var displayWeight: String {
            if quantity < 1000 {
                return "\(Int(quantity))g"
            } else {
                return String(format: "%.1fkg", quantity / 1000)
            }
        }
    }
    
    var totalNutrition: (calories: Double, protein: Double, carbs: Double, fat: Double) {
        let selectedFoods = adjustedFoods.filter { $0.isSelected }
        return selectedFoods.reduce((0, 0, 0, 0)) { total, food in
            guard let nutrition = food.adjustedNutrition else { return total }
            return (
                total.0 + nutrition.calories,
                total.1 + nutrition.protein,
                total.2 + nutrition.carbs,
                total.3 + nutrition.fat
            )
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                GlassmorphismBackground(colors: [.green, .blue, .purple])
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header with Image
                        LiquidGlassCard {
                            VStack(spacing: 16) {
                                // Result Image
                                Image(uiImage: result.image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxHeight: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                
                                // Recognition Stats
                                HStack(spacing: 20) {
                                    StatItem(
                                        title: "Items Found",
                                        value: "\(result.recognizedFoods.count)",
                                        icon: "eye.fill",
                                        color: .green
                                    )
                                    
                                    StatItem(
                                        title: "Confidence",
                                        value: "\(Int(result.averageConfidence * 100))%",
                                        icon: "checkmark.circle.fill",
                                        color: .blue
                                    )
                                    
                                    StatItem(
                                        title: "Process Time",
                                        value: String(format: "%.1fs", result.processingTime),
                                        icon: "clock.fill",
                                        color: .orange
                                    )
                                }
                            }
                            .padding()
                        }
                        
                        // Detected Foods
                        LiquidGlassCard {
                            VStack(spacing: 16) {
                                HStack {
                                    Text("Detected Foods")
                                        .font(.headline)
                                        .fontWeight(.semibold)

                                    Spacer()

                                    Text("Tap name to edit")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }

                                if adjustedFoods.isEmpty {
                                    EmptyFoodView()
                                } else {
                                    VStack(spacing: 12) {
                                        ForEach(adjustedFoods.indices, id: \.self) { index in
                                            FoodItemRow(
                                                food: $adjustedFoods[index],
                                                onQuantityChange: { newQuantity in
                                                    adjustedFoods[index].quantity = newQuantity
                                                },
                                                onFoodEdit: {
                                                    editingFoodIndex = index
                                                    showingFoodSearch = true
                                                }
                                            )
                                        }
                                    }
                                }
                            }
                            .padding()
                        }
                        
                        // Nutrition Summary
                        if adjustedFoods.contains(where: { $0.isSelected }) {
                            RecognitionNutritionSummaryCard(nutrition: totalNutrition)
                        }
                        
                        // Meal Type Selection
                        LiquidGlassCard {
                            VStack(spacing: 16) {
                                Text("Add to Meal")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 12) {
                                    ForEach(FoodEntry.MealType.allCases, id: \.self) { mealType in
                                        MealTypeCard(
                                            mealType: mealType,
                                            isSelected: selectedMealType == mealType
                                        ) {
                                            withAnimation(FluidSpring.snappy) {
                                                selectedMealType = mealType
                                            }
                                        }
                                    }
                                }
                            }
                            .padding()
                        }
                        
                        // Action Buttons
                        VStack(spacing: 12) {
                            Button("Add to Food Diary") {
                                addFoodsToFoodDiary()
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.green, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(16)
                            .shadow(color: .green.opacity(0.3), radius: 10)
                            .disabled(adjustedFoods.allSatisfy { !$0.isSelected })
                            
                            Button("Retake Photo") {
                                dismiss()
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.ultraThinMaterial)
                            .foregroundColor(.primary)
                            .cornerRadius(16)
                        }
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
            }
            .alert("Added to Food Diary!", isPresented: $showingSuccessMessage) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Successfully added \(adjustedFoods.filter { $0.isSelected }.count) food item(s) to your diary.")
            }
            .sheet(isPresented: $showingFoodSearch) {
                if let index = editingFoodIndex {
                    FoodEditSearchView(
                        currentFoodName: adjustedFoods[index].displayName,
                        onFoodSelected: { name, nutrition in
                            adjustedFoods[index].customName = name
                            adjustedFoods[index].customNutrition = nutrition
                            adjustedFoods[index].wasEdited = true
                            showingFoodSearch = false
                            editingFoodIndex = nil
                        },
                        onCancel: {
                            showingFoodSearch = false
                            editingFoodIndex = nil
                        }
                    )
                }
            }
        }
        .onAppear {
            setupAdjustableFoods()
        }
    }
    
    // MARK: - Setup
    
    private func setupAdjustableFoods() {
        adjustedFoods = result.recognizedFoods.map { food in
            AdjustableFoodItem(
                recognizedFood: food,
                quantity: food.estimatedWeight ?? 100,
                isSelected: true
            )
        }
    }
    
    // MARK: - Add to Diary
    
    private func addFoodsToFoodDiary() {
        let selectedFoods = adjustedFoods.filter { $0.isSelected }
        
        for adjustableFood in selectedFoods {
            let foodEntry = adjustableFood.recognizedFood.toFoodEntry(
                mealType: selectedMealType,
                quantity: adjustableFood.quantity
            )
            modelContext.insert(foodEntry)
        }
        
        do {
            try modelContext.save()
            showingSuccessMessage = true
        } catch {
            print("Error saving food entries: \(error)")
        }
    }
}

// MARK: - Supporting Views

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct FoodItemRow: View {
    @Binding var food: FoodRecognitionResultView.AdjustableFoodItem
    let onQuantityChange: (Double) -> Void
    let onFoodEdit: () -> Void

    @State private var showingQuantityAdjustment = false
    @State private var tempQuantity: String = ""

    var body: some View {
        HStack(spacing: 12) {
            // Selection Toggle
            Button(action: {
                withAnimation(FluidSpring.snappy) {
                    food.isSelected.toggle()
                }
            }) {
                Image(systemName: food.isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(food.isSelected ? .green : .secondary)
            }

            // Food Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    // Tappable food name with edit indicator
                    Button(action: onFoodEdit) {
                        HStack(spacing: 4) {
                            Text(food.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(food.wasEdited ? .blue : .primary)

                            Image(systemName: food.wasEdited ? "checkmark.circle.fill" : "pencil.circle")
                                .font(.caption)
                                .foregroundColor(food.wasEdited ? .green : .blue.opacity(0.7))
                        }
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: food.recognizedFood.category.icon)
                            .font(.caption)
                        Text(food.recognizedFood.category.rawValue)
                            .font(.caption)
                    }
                    .foregroundColor(food.recognizedFood.category.color)
                }

                HStack {
                    if food.wasEdited {
                        Text("Edited")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        Text("\(Int(food.recognizedFood.confidence * 100))% confidence")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if let nutrition = food.adjustedNutrition {
                        Text("\(Int(nutrition.calories)) cal")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                    }
                }

                // Quantity Adjustment
                Button(action: {
                    tempQuantity = String(Int(food.quantity))
                    showingQuantityAdjustment = true
                }) {
                    HStack {
                        Image(systemName: "scale.3d")
                            .font(.caption)
                        Text(food.displayWeight)
                            .font(.caption)
                            .fontWeight(.medium)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption2)
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.blue.opacity(0.1))
                    .cornerRadius(8)
                }
            }

            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .opacity(food.isSelected ? 1.0 : 0.6)
        .alert("Adjust Quantity", isPresented: $showingQuantityAdjustment) {
            TextField("Grams", text: $tempQuantity)
                .keyboardType(.numberPad)

            Button("Cancel", role: .cancel) {}
            Button("Update") {
                if let newQuantity = Double(tempQuantity), newQuantity > 0 {
                    food.quantity = newQuantity
                    onQuantityChange(newQuantity)
                }
            }
        } message: {
            Text("Enter the weight in grams for \(food.displayName)")
        }
    }
}

struct EmptyFoodView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            
            Text("No Food Detected")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Our AI couldn't identify any food items in this image. Try retaking the photo with better lighting or a clearer view of the food.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}

struct RecognitionNutritionSummaryCard: View {
    let nutrition: (calories: Double, protein: Double, carbs: Double, fat: Double)
    
    var body: some View {
        LiquidGlassCard {
            VStack(spacing: 16) {
                Text("Nutrition Summary")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    NutritionPill(
                        title: "Calories",
                        value: "\(Int(nutrition.calories))",
                        unit: "cal",
                        color: .orange
                    )
                    
                    NutritionPill(
                        title: "Protein",
                        value: String(format: "%.1f", nutrition.protein),
                        unit: "g",
                        color: .red
                    )
                    
                    NutritionPill(
                        title: "Carbs",
                        value: String(format: "%.1f", nutrition.carbs),
                        unit: "g",
                        color: .blue
                    )
                    
                    NutritionPill(
                        title: "Fat",
                        value: String(format: "%.1f", nutrition.fat),
                        unit: "g",
                        color: .green
                    )
                }
            }
            .padding()
        }
    }
}

struct NutritionPill: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(unit)
                .font(.caption2)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 60)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct MealTypeCard: View {
    let mealType: FoodEntry.MealType
    let isSelected: Bool
    let onTap: () -> Void
    
    private var icon: String {
        switch mealType {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.fill"
        case .snack: return "leaf.fill"
        }
    }
    
    private var color: Color {
        switch mealType {
        case .breakfast: return .orange
        case .lunch: return .yellow
        case .dinner: return .purple
        case .snack: return .green
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : color)
                
                Text(mealType.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity, minHeight: 60)
            .background(
                isSelected ?
                LinearGradient(colors: [color, color.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                LinearGradient(colors: [.clear], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? .clear : .secondary.opacity(0.3), lineWidth: 1)
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Food Edit Search View

struct FoodEditSearchView: View {
    let currentFoodName: String
    let onFoodSelected: (String, RecognizedFood.NutritionInfo) -> Void
    let onCancel: () -> Void

    @State private var searchText = ""
    @State private var searchResults: [FoodSearchResult] = []
    @State private var isSearching = false
    @State private var showManualEntry = false
    @State private var manualName = ""
    @State private var manualCalories = ""
    @State private var manualProtein = ""
    @State private var manualCarbs = ""
    @State private var manualFat = ""

    struct FoodSearchResult: Identifiable {
        let id = UUID()
        let name: String
        let nutrition: RecognizedFood.NutritionInfo
        let source: String
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search for correct food...", text: $searchText)
                        .textFieldStyle(.plain)
                        .autocapitalization(.none)
                        .onSubmit {
                            performSearch()
                        }
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding()

                // Current food indicator
                HStack {
                    Text("Current:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(currentFoodName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                    Spacer()
                }
                .padding(.horizontal)

                Divider()
                    .padding(.top, 8)

                if isSearching {
                    Spacer()
                    ProgressView("Searching...")
                    Spacer()
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No results found")
                            .font(.headline)
                        Text("Try a different search term or enter manually")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    List {
                        // Common foods section
                        if searchText.isEmpty {
                            Section("Common Foods") {
                                ForEach(commonFoods) { food in
                                    FoodEditSearchResultRow(food: food) {
                                        onFoodSelected(food.name, food.nutrition)
                                    }
                                }
                            }
                        }

                        // Search results
                        if !searchResults.isEmpty {
                            Section("Search Results") {
                                ForEach(searchResults) { food in
                                    FoodEditSearchResultRow(food: food) {
                                        onFoodSelected(food.name, food.nutrition)
                                    }
                                }
                            }
                        }

                        // Manual entry option
                        Section {
                            Button(action: { showManualEntry = true }) {
                                HStack {
                                    Image(systemName: "square.and.pencil")
                                        .foregroundColor(.blue)
                                    Text("Enter food manually")
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Edit Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
            }
            .sheet(isPresented: $showManualEntry) {
                ManualFoodEntrySheet(
                    initialName: searchText.isEmpty ? currentFoodName : searchText,
                    onSave: { name, nutrition in
                        onFoodSelected(name, nutrition)
                    },
                    onCancel: {
                        showManualEntry = false
                    }
                )
            }
            .onAppear {
                searchText = currentFoodName
                performSearch()
            }
        }
    }

    private func performSearch() {
        guard !searchText.isEmpty else {
            searchResults = []
            return
        }

        isSearching = true

        // Search in local database
        let query = searchText.lowercased()
        searchResults = nutritionDatabase.compactMap { (name, nutrition) in
            if name.lowercased().contains(query) {
                return FoodSearchResult(name: name, nutrition: nutrition, source: "Database")
            }
            return nil
        }.prefix(20).map { $0 }

        isSearching = false
    }

    // Common foods for quick selection
    private var commonFoods: [FoodSearchResult] {
        [
            FoodSearchResult(name: "Grilled Chicken Breast", nutrition: .init(calories: 165, protein: 31, carbs: 0, fat: 3.6, fiber: 0, sugar: 0), source: "Common"),
            FoodSearchResult(name: "White Rice (cooked)", nutrition: .init(calories: 130, protein: 2.7, carbs: 28, fat: 0.3, fiber: 0.4, sugar: 0), source: "Common"),
            FoodSearchResult(name: "Steamed Broccoli", nutrition: .init(calories: 35, protein: 2.4, carbs: 7, fat: 0.4, fiber: 2.6, sugar: 1.5), source: "Common"),
            FoodSearchResult(name: "Grilled Salmon", nutrition: .init(calories: 208, protein: 20, carbs: 0, fat: 13, fiber: 0, sugar: 0), source: "Common"),
            FoodSearchResult(name: "Mixed Green Salad", nutrition: .init(calories: 20, protein: 1.5, carbs: 3.5, fat: 0.2, fiber: 1.8, sugar: 1), source: "Common"),
            FoodSearchResult(name: "Scrambled Eggs (2)", nutrition: .init(calories: 182, protein: 12, carbs: 2, fat: 14, fiber: 0, sugar: 1), source: "Common"),
            FoodSearchResult(name: "Toast with Butter", nutrition: .init(calories: 150, protein: 3, carbs: 20, fat: 7, fiber: 1, sugar: 2), source: "Common"),
            FoodSearchResult(name: "Banana", nutrition: .init(calories: 105, protein: 1.3, carbs: 27, fat: 0.4, fiber: 3.1, sugar: 14), source: "Common"),
        ]
    }

    // Local nutrition database (per 100g)
    private var nutritionDatabase: [(String, RecognizedFood.NutritionInfo)] {
        [
            ("Chicken Breast (grilled)", RecognizedFood.NutritionInfo(calories: 165, protein: 31, carbs: 0, fat: 3.6, fiber: 0, sugar: 0)),
            ("Chicken Thigh", RecognizedFood.NutritionInfo(calories: 209, protein: 26, carbs: 0, fat: 11, fiber: 0, sugar: 0)),
            ("Beef Steak", RecognizedFood.NutritionInfo(calories: 271, protein: 26, carbs: 0, fat: 18, fiber: 0, sugar: 0)),
            ("Ground Beef", RecognizedFood.NutritionInfo(calories: 250, protein: 26, carbs: 0, fat: 15, fiber: 0, sugar: 0)),
            ("Salmon (grilled)", RecognizedFood.NutritionInfo(calories: 208, protein: 20, carbs: 0, fat: 13, fiber: 0, sugar: 0)),
            ("Tuna", RecognizedFood.NutritionInfo(calories: 132, protein: 29, carbs: 0, fat: 1, fiber: 0, sugar: 0)),
            ("Shrimp", RecognizedFood.NutritionInfo(calories: 99, protein: 24, carbs: 0, fat: 0.3, fiber: 0, sugar: 0)),
            ("Pork Chop", RecognizedFood.NutritionInfo(calories: 231, protein: 25, carbs: 0, fat: 14, fiber: 0, sugar: 0)),
            ("Turkey Breast", RecognizedFood.NutritionInfo(calories: 135, protein: 30, carbs: 0, fat: 1, fiber: 0, sugar: 0)),
            ("White Rice", RecognizedFood.NutritionInfo(calories: 130, protein: 2.7, carbs: 28, fat: 0.3, fiber: 0.4, sugar: 0)),
            ("Brown Rice", RecognizedFood.NutritionInfo(calories: 112, protein: 2.6, carbs: 24, fat: 0.9, fiber: 1.8, sugar: 0)),
            ("Pasta (cooked)", RecognizedFood.NutritionInfo(calories: 131, protein: 5, carbs: 25, fat: 1.1, fiber: 1.8, sugar: 0.6)),
            ("Bread (white)", RecognizedFood.NutritionInfo(calories: 265, protein: 9, carbs: 49, fat: 3.2, fiber: 2.7, sugar: 5)),
            ("Bread (whole wheat)", RecognizedFood.NutritionInfo(calories: 247, protein: 13, carbs: 41, fat: 3.4, fiber: 7, sugar: 6)),
            ("Potato (baked)", RecognizedFood.NutritionInfo(calories: 93, protein: 2.5, carbs: 21, fat: 0.1, fiber: 2.2, sugar: 1)),
            ("Sweet Potato", RecognizedFood.NutritionInfo(calories: 86, protein: 1.6, carbs: 20, fat: 0.1, fiber: 3, sugar: 4)),
            ("Broccoli", RecognizedFood.NutritionInfo(calories: 35, protein: 2.4, carbs: 7, fat: 0.4, fiber: 2.6, sugar: 1.5)),
            ("Spinach", RecognizedFood.NutritionInfo(calories: 23, protein: 2.9, carbs: 3.6, fat: 0.4, fiber: 2.2, sugar: 0.4)),
            ("Carrots", RecognizedFood.NutritionInfo(calories: 41, protein: 0.9, carbs: 10, fat: 0.2, fiber: 2.8, sugar: 5)),
            ("Green Beans", RecognizedFood.NutritionInfo(calories: 31, protein: 1.8, carbs: 7, fat: 0.1, fiber: 3.4, sugar: 1.4)),
            ("Corn", RecognizedFood.NutritionInfo(calories: 96, protein: 3.4, carbs: 21, fat: 1.5, fiber: 2.4, sugar: 4.5)),
            ("Peas", RecognizedFood.NutritionInfo(calories: 81, protein: 5.4, carbs: 14, fat: 0.4, fiber: 5.1, sugar: 5.7)),
            ("Apple", RecognizedFood.NutritionInfo(calories: 52, protein: 0.3, carbs: 14, fat: 0.2, fiber: 2.4, sugar: 10)),
            ("Banana", RecognizedFood.NutritionInfo(calories: 89, protein: 1.1, carbs: 23, fat: 0.3, fiber: 2.6, sugar: 12)),
            ("Orange", RecognizedFood.NutritionInfo(calories: 47, protein: 0.9, carbs: 12, fat: 0.1, fiber: 2.4, sugar: 9)),
            ("Strawberries", RecognizedFood.NutritionInfo(calories: 32, protein: 0.7, carbs: 8, fat: 0.3, fiber: 2, sugar: 5)),
            ("Grapes", RecognizedFood.NutritionInfo(calories: 69, protein: 0.7, carbs: 18, fat: 0.2, fiber: 0.9, sugar: 16)),
            ("Egg (whole)", RecognizedFood.NutritionInfo(calories: 155, protein: 13, carbs: 1.1, fat: 11, fiber: 0, sugar: 1.1)),
            ("Egg White", RecognizedFood.NutritionInfo(calories: 52, protein: 11, carbs: 0.7, fat: 0.2, fiber: 0, sugar: 0.7)),
            ("Cheese (cheddar)", RecognizedFood.NutritionInfo(calories: 403, protein: 25, carbs: 1.3, fat: 33, fiber: 0, sugar: 0.5)),
            ("Milk (whole)", RecognizedFood.NutritionInfo(calories: 61, protein: 3.2, carbs: 4.8, fat: 3.3, fiber: 0, sugar: 5)),
            ("Greek Yogurt", RecognizedFood.NutritionInfo(calories: 59, protein: 10, carbs: 3.6, fat: 0.7, fiber: 0, sugar: 3.2)),
            ("Almonds", RecognizedFood.NutritionInfo(calories: 579, protein: 21, carbs: 22, fat: 50, fiber: 12, sugar: 4)),
            ("Peanut Butter", RecognizedFood.NutritionInfo(calories: 588, protein: 25, carbs: 20, fat: 50, fiber: 6, sugar: 9)),
            ("Avocado", RecognizedFood.NutritionInfo(calories: 160, protein: 2, carbs: 9, fat: 15, fiber: 7, sugar: 0.7)),
            ("Olive Oil", RecognizedFood.NutritionInfo(calories: 884, protein: 0, carbs: 0, fat: 100, fiber: 0, sugar: 0)),
            ("Butter", RecognizedFood.NutritionInfo(calories: 717, protein: 0.9, carbs: 0.1, fat: 81, fiber: 0, sugar: 0.1)),
        ]
    }
}

struct FoodEditSearchResultRow: View {
    let food: FoodEditSearchView.FoodSearchResult
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(food.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    HStack(spacing: 12) {
                        Text("\(Int(food.nutrition.calories)) cal")
                            .foregroundColor(.orange)
                        Text("P: \(Int(food.nutrition.protein))g")
                            .foregroundColor(.red)
                        Text("C: \(Int(food.nutrition.carbs))g")
                            .foregroundColor(.blue)
                        Text("F: \(Int(food.nutrition.fat))g")
                            .foregroundColor(.green)
                    }
                    .font(.caption)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct ManualFoodEntrySheet: View {
    let initialName: String
    let onSave: (String, RecognizedFood.NutritionInfo) -> Void
    let onCancel: () -> Void

    @State private var name: String = ""
    @State private var calories: String = ""
    @State private var protein: String = ""
    @State private var carbs: String = ""
    @State private var fat: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Food Name") {
                    TextField("Food name", text: $name)
                }

                Section("Nutrition (per 100g)") {
                    HStack {
                        Text("Calories")
                        Spacer()
                        TextField("0", text: $calories)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("cal")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Protein")
                        Spacer()
                        TextField("0", text: $protein)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("g")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Carbs")
                        Spacer()
                        TextField("0", text: $carbs)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("g")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Fat")
                        Spacer()
                        TextField("0", text: $fat)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("g")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Manual Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        let nutrition = RecognizedFood.NutritionInfo(
                            calories: Double(calories) ?? 0,
                            protein: Double(protein) ?? 0,
                            carbs: Double(carbs) ?? 0,
                            fat: Double(fat) ?? 0,
                            fiber: nil,
                            sugar: nil
                        )
                        onSave(name, nutrition)
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                name = initialName
            }
        }
    }
}

#Preview {
    let mockResult = FoodRecognitionResult(
        image: UIImage(systemName: "photo")!,
        recognizedFoods: [
            RecognizedFood(
                name: "Apple",
                confidence: 0.95,
                boundingBox: CGRect(x: 0.1, y: 0.1, width: 0.3, height: 0.3),
                nutritionInfo: RecognizedFood.NutritionInfo(calories: 52, protein: 0.3, carbs: 14, fat: 0.2, fiber: 2.4, sugar: 10),
                estimatedWeight: 150,
                category: .fruits
            )
        ],
        processingTime: 1.5,
        confidence: 0.95
    )

    return FoodRecognitionResultView(result: mockResult)
        .modelContainer(for: [FoodEntry.self])
}