import SwiftUI
import SwiftData
import WidgetKit

// Local struct to represent food product details from API
struct ProductDetails {
    let name: String
    let brand: String?
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let servingSize: Double
    let servingUnit: String
}

struct EnhancedProductDetailsView: View {
    let barcode: String
    @State private var productDetails: ProductDetails?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var quantity: Double = 1
    @State private var selectedMealType = FoodEntry.MealType.snack
    @State private var showManualSearch = false
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    loadingView
                } else if let error = errorMessage {
                    errorView(error: error)
                } else if let details = productDetails {
                    productDetailsView(details: details)
                }
            }
            .navigationTitle("Product Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Cancel") { dismiss() })
        }
        .onAppear {
            loadProductDetails()
        }
        .sheet(isPresented: $showManualSearch) {
            FoodSearchView(selectedFood: .constant(nil))
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
            
            Text("Searching for product...")
                .font(.headline)
            
            Text("Barcode: \(barcode)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
    
    private func errorView(error: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "barcode.viewfinder")
                .font(.system(size: 60))
                .foregroundColor(.orange)
                .overlay(
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.red)
                        .background(Circle().fill(.white))
                        .offset(x: 25, y: 25)
                )
            
            Text("Product Not Found")
                .font(.title2)
                .bold()
            
            Text("We couldn't find nutrition information for this barcode.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                Button(action: { showManualSearch = true }) {
                    Label("Search Manually", systemImage: "magnifyingglass")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                
                Button(action: { dismiss() }) {
                    Label("Scan Again", systemImage: "camera.viewfinder")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 40)
        }
        .padding()
    }
    
    private func productDetailsView(details: ProductDetails) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Product Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(details.name)
                        .font(.largeTitle)
                        .bold()
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                    
                    if let brand = details.brand, !brand.isEmpty {
                        Text(brand)
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "barcode")
                            .foregroundColor(.secondary)
                        Text(barcode)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                
                // Nutrition Facts Card
                nutritionFactsCard(details: details)
                
                // Quantity Selector
                quantitySelector
                
                // Meal Type Selector
                mealTypeSelector
                
                // Add to Diary Button
                addToDiaryButton(details: details)
            }
            .padding(.vertical)
        }
    }
    
    private func nutritionFactsCard(details: ProductDetails) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Nutrition Facts")
                    .font(.headline)
                Spacer()
                Text("Per \(Int(details.servingSize)) \(details.servingUnit)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            VStack(spacing: 12) {
                nutritionRow(label: "Calories", value: details.calories * quantity, unit: "kcal", color: .orange)
                nutritionRow(label: "Protein", value: details.protein * quantity, unit: "g", color: .red)
                nutritionRow(label: "Carbohydrates", value: details.carbs * quantity, unit: "g", color: .blue)
                nutritionRow(label: "Fat", value: details.fat * quantity, unit: "g", color: .green)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private func nutritionRow(label: String, value: Double, unit: String, color: Color) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(label)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("\(value, specifier: "%.1f") \(unit)")
                .bold()
        }
    }
    
    private var quantitySelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quantity")
                .font(.headline)
                .padding(.horizontal)
            
            HStack {
                Button(action: { if quantity > 0.5 { quantity -= 0.5 } }) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.accentColor)
                        .font(.title2)
                }
                
                Spacer()
                
                Text("\(quantity, specifier: "%.1f") servings")
                    .font(.title3)
                    .bold()
                
                Spacer()
                
                Button(action: { if quantity < 10 { quantity += 0.5 } }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.accentColor)
                        .font(.title2)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
    
    private var mealTypeSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Meal Type")
                .font(.headline)
                .padding(.horizontal)
            
            Picker("Meal", selection: $selectedMealType) {
                ForEach(FoodEntry.MealType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
        }
    }
    
    private func addToDiaryButton(details: ProductDetails) -> some View {
        Button(action: { addToFoodDiary(details: details) }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                Text("Add to Food Diary")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
    
    private func loadProductDetails() {
        // First try to look up the barcode using the nutrition API
        NutritionAPIService.shared.lookupBarcode(barcode) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let apiFood):
                    // Convert API FoodItem to our local ProductDetails
                    productDetails = ProductDetails(
                        name: apiFood.label,
                        brand: apiFood.categoryLabel,
                        calories: apiFood.nutrients.calories,
                        protein: apiFood.nutrients.protein,
                        carbs: apiFood.nutrients.carbs,
                        fat: apiFood.nutrients.fat,
                        servingSize: 100,
                        servingUnit: "g"
                    )
                    isLoading = false
                    
                case .failure(_):
                    // If barcode lookup fails, try a general search
                    searchByBarcode()
                }
            }
        }
    }
    
    private func searchByBarcode() {
        // As a fallback, search for the barcode as a text query
        NutritionAPIService.shared.searchFood(query: barcode) { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success(let response):
                    if let firstResult = response.hints?.first?.food ?? response.parsed.first?.food {
                        productDetails = ProductDetails(
                            name: firstResult.label,
                            brand: firstResult.categoryLabel,
                            calories: firstResult.nutrients.calories,
                            protein: firstResult.nutrients.protein,
                            carbs: firstResult.nutrients.carbs,
                            fat: firstResult.nutrients.fat,
                            servingSize: 100,
                            servingUnit: "g"
                        )
                    } else {
                        errorMessage = "No nutrition information found for this product."
                    }
                    
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func addToFoodDiary(details: ProductDetails) {
        let entry = FoodEntry(
            name: details.name,
            calories: details.calories,
            protein: details.protein,
            carbs: details.carbs,
            fat: details.fat,
            servingSize: details.servingSize,
            servingUnit: details.servingUnit,
            quantity: quantity,
            mealType: selectedMealType
        )

        entry.barcode = barcode
        entry.brand = details.brand

        modelContext.insert(entry)

        do {
            try modelContext.save()

            // Refresh widgets with new data
            WidgetCenter.shared.reloadAllTimelines()

            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()

            dismiss()
        } catch {
            print("Error saving food entry: \(error)")
        }
    }
}

#Preview {
    EnhancedProductDetailsView(barcode: "1234567890")
        .modelContainer(for: [FoodEntry.self, UserProfile.self, Recipe.self], inMemory: true)
}