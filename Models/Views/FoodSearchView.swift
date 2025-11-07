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
    @ObservedObject private var networkMonitor = NetworkMonitor.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    // Offline Banner
                    OfflineBanner()
                    
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
                        .onChange(of: searchText) { _ in
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
                    NetworkErrorView(error: error) {
                        searchFoods()
                    }
                    .padding()
                    Spacer()
                } else if searchResults.isEmpty && !searchText.isEmpty && !isSearching {
                    VStack(spacing: 20) {
                        Image(systemName: networkMonitor.isConnected ? "magnifyingglass" : "wifi.slash")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text(networkMonitor.isConnected ? "No foods found" : "No offline results")
                            .font(.headline)
                        Text(networkMonitor.isConnected ? "Try searching for something else" : "Connect to internet for more results")
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
        let validation = InputValidator.validateSearchQuery(searchText)
        guard validation.isValid, let query = validation.value else {
            error = NSError(domain: "InputValidation", code: 0, userInfo: [NSLocalizedDescriptionKey: validation.error ?? "Invalid search query"])
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
                    
                    // Log error
                    CrashlyticsManager.shared.recordError(apiError, additionalInfo: [
                        "screen": "FoodSearchView",
                        "query": searchText
                    ])
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
