import SwiftUI
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
    @State private var isOffline = false
    
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
                            selectedFood = food
                            dismiss()
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
        }
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
