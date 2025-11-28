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
            ZStack {
                VStack(spacing: 0) {
                    // Offline Banner  
                    if isOffline {
                        HStack {
                            Image(systemName: "wifi.slash")
                            Text("Offline - showing cached results")
                        }
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                    }
                    
                    VStack {
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
                            error = nil // Clear error when typing
                        }
                    
                    if isSearching {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                .padding()
                
                // Search Results
                if let error = error {
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
                    .padding(.top, 50)
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
            }
            }
            .navigationTitle("Search Foods")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
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
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 4) {
                Text(food.label)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if let category = food.categoryLabel {
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
