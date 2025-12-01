import SwiftUI
import SwiftData
import Foundation

struct FoodSearchView: View {
    @State private var searchText = ""
    @State private var searchResults: [FoodItem] = []
    @State private var isSearching = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var error: Error?
    @Binding var selectedFood: FoodItem?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var isOffline = false
    @State private var showingFoodDetail = false
    @State private var tappedFood: FoodItem?
    @State private var selectedMealType: FoodEntry.MealType = .breakfast
    @State private var servingQuantity: Double = 1.0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Offline Banner
                if isOffline {
                    HStack {
                        Image(systemName: "wifi.slash")
                        Text("Offline - showing cached results")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.orange)
                    .foregroundColor(.white)
                }

                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)

                    TextField("Search foods...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            searchFoods()
                        }
                        .onChange(of: searchText) { _, _ in
                            error = nil
                        }

                    if isSearching {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                .padding()

                // Search Results
                if let error = error {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        Text("Search Error")
                            .font(.headline)
                        Text(error.localizedDescription)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                        Button("Try Again") {
                            searchFoods()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    Spacer()
                } else if searchResults.isEmpty && !searchText.isEmpty && !isSearching {
                    Spacer()
                    VStack(spacing: 20) {
                        Image(systemName: isOffline ? "wifi.slash" : "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text(isOffline ? "No offline results" : "No foods found")
                            .font(.headline)
                        Text(isOffline ? "Connect to internet for more results" : "Try searching for something else")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    Spacer()
                } else if searchResults.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("Search for foods")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Type a food name and press Search")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    List(searchResults, id: \.foodId) { food in
                        FoodSearchResultRow(food: food) {
                            tappedFood = food
                            selectedMealType = .breakfast
                            servingQuantity = 1.0
                            showingFoodDetail = true
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Search Foods")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showingFoodDetail) {
                if let food = tappedFood {
                    FoodDetailSheet(
                        food: food,
                        selectedMealType: $selectedMealType,
                        servingQuantity: $servingQuantity,
                        onAddToLog: { addFoodToLog(food) }
                    )
                }
            }
        }
    }

    private func addFoodToLog(_ food: FoodItem) {
        let entry = FoodEntry(
            name: food.label,
            calories: food.nutrients.calories * servingQuantity,
            protein: food.nutrients.protein * servingQuantity,
            carbs: food.nutrients.carbs * servingQuantity,
            fat: food.nutrients.fat * servingQuantity,
            servingSize: 1.0,
            servingUnit: "serving",
            quantity: servingQuantity,
            mealType: selectedMealType,
            timestamp: Date()
        )
        modelContext.insert(entry)
        showingFoodDetail = false
        dismiss()
    }
    
    private func searchFoods() {
        // Validate search input
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            error = NSError(domain: "InputValidation", code: 0, userInfo: [NSLocalizedDescriptionKey: "Search cannot be empty"])
            return
        }
        
        isSearching = true
        
        NutritionAPIService.shared.searchFood(query: query) { result in
            DispatchQueue.main.async {
                isSearching = false
                
                switch result {
                case .success(let response):
                    // Combine parsed foods and hints
                    var allFoods: [FoodItem] = []
                    allFoods.append(contentsOf: response.parsed.map { $0.food })
                    if let hints = response.hints {
                        allFoods.append(contentsOf: hints.map { $0.food })
                    }
                    searchResults = allFoods
                    
                case .failure(let apiError):
                    self.error = apiError
                    searchResults = []
                    
                    // Log error (Crashlytics integration will be added later)
                    print("Search error: \(apiError.localizedDescription)")
                }
            }
        }
    }
}

struct FoodSearchResultRow: View {
    let food: FoodItem
    let onSelect: () -> Void

    // Check if text is likely English (basic heuristic)
    private func isLikelyEnglish(_ text: String) -> Bool {
        // Check for common non-English characters/patterns
        let nonEnglishPatterns = ["é", "è", "ê", "ë", "à", "â", "ô", "û", "ù", "ç", "œ", "ñ", "ü", "ö", "ä"]
        for pattern in nonEnglishPatterns {
            if text.lowercased().contains(pattern) {
                return false
            }
        }
        // Also filter out if it looks like a category code
        if text.count < 3 || text.uppercased() == text {
            return false
        }
        return true
    }

    // Get a clean category label
    private var cleanCategoryLabel: String? {
        guard let category = food.categoryLabel else { return nil }
        // Only show if it's likely English and not a generic code
        if isLikelyEnglish(category) && !category.contains("food") {
            return category
        }
        // Fall back to showing a simple food type based on category
        if let cat = food.category {
            switch cat {
            case "Generic foods": return "Generic Food"
            case "Packaged foods": return "Packaged Food"
            case "Fast foods": return "Fast Food"
            default: return nil
            }
        }
        return nil
    }

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 4) {
                Text(food.label)
                    .font(.headline)
                    .foregroundColor(.primary)

                if let category = cleanCategoryLabel {
                    Text(category)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack {
                    NutrientLabel(value: food.nutrients.calories, unit: "cal")
                    NutrientLabel(value: food.nutrients.protein, unit: "g", label: "protein")
                    NutrientLabel(value: food.nutrients.carbs, unit: "g", label: "carbs")
                    NutrientLabel(value: food.nutrients.fat, unit: "g", label: "fat")
                }
                .font(.caption)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct NutrientLabel: View {
    let value: Double
    let unit: String
    var label: String? = nil

    var body: some View {
        HStack(spacing: 2) {
            Text(String(format: "%.1f", value))
                .fontWeight(.medium)
            Text(unit)
            if let label = label {
                Text("∙ \(label)")
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Food Detail Sheet

struct FoodDetailSheet: View {
    let food: FoodItem
    @Binding var selectedMealType: FoodEntry.MealType
    @Binding var servingQuantity: Double
    let onAddToLog: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Food Info Card
                    VStack(spacing: 16) {
                        Text(food.label)
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)

                        if let category = food.categoryLabel {
                            Text(category)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        // Nutrition Summary
                        HStack(spacing: 20) {
                            NutritionCircle(
                                value: food.nutrients.calories * servingQuantity,
                                label: "Cal",
                                color: .red
                            )
                            NutritionCircle(
                                value: food.nutrients.protein * servingQuantity,
                                label: "Protein",
                                color: .blue
                            )
                            NutritionCircle(
                                value: food.nutrients.carbs * servingQuantity,
                                label: "Carbs",
                                color: .orange
                            )
                            NutritionCircle(
                                value: food.nutrients.fat * servingQuantity,
                                label: "Fat",
                                color: .yellow
                            )
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)

                    // Serving Quantity
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Serving Size")
                            .font(.headline)

                        Stepper(value: $servingQuantity, in: 0.25...10, step: 0.25) {
                            HStack {
                                Text("Quantity:")
                                Spacer()
                                Text(String(format: "%.2f", servingQuantity))
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)

                    // Meal Type Selector
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Add to Meal")
                            .font(.headline)

                        HStack(spacing: 8) {
                            ForEach(FoodEntry.MealType.allCases, id: \.self) { mealType in
                                MealTypeButton(
                                    mealType: mealType,
                                    isSelected: selectedMealType == mealType
                                ) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedMealType = mealType
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)

                    // Add Button
                    Button(action: onAddToLog) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                            Text("Add to Food Diary")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Food Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct NutritionCircle: View {
    let value: Double
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 60, height: 60)

                Text(String(format: "%.0f", value))
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct MealTypeButton: View {
    let mealType: FoodEntry.MealType
    let isSelected: Bool
    let action: () -> Void

    private var icon: String {
        switch mealType {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.stars.fill"
        case .snack: return "carrot.fill"
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3)
                Text(mealType.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                isSelected
                    ? LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    : LinearGradient(
                        colors: [Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
            )
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isSelected ? Color.clear : Color.secondary.opacity(0.3),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
