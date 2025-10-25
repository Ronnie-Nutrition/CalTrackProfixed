import SwiftUI
import SwiftData

struct ManualEntryView: View {
    let mealType: FoodEntry.MealType
    @State private var searchText = ""
    @State private var name = ""
    @State private var brand = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @State private var servingSize = ""
    @State private var servingUnit = "g"
    @State private var quantity = "1"
    @State private var showingFoodSearch = false
    @State private var selectedFood: FoodItem?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button(action: { showingFoodSearch = true }) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                            Text("Search Food Database")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                } header: {
                    Text("Quick Search")
                }
                
                Section("Food Details") {
                    TextField("Food Name", text: $name)
                    TextField("Brand (Optional)", text: $brand)
                }
                
                Section("Nutrition per Serving") {
                    HStack {
                        TextField("Serving Size", text: $servingSize)
                            .keyboardType(.decimalPad)
                        
                        Picker("Unit", selection: $servingUnit) {
                            Text("g").tag("g")
                            Text("oz").tag("oz")
                            Text("cup").tag("cup")
                            Text("piece").tag("piece")
                        }
                        .pickerStyle(.menu)
                    }
                    
                    TextField("Calories", text: $calories)
                        .keyboardType(.decimalPad)
                    
                    TextField("Protein (g)", text: $protein)
                        .keyboardType(.decimalPad)
                    
                    TextField("Carbs (g)", text: $carbs)
                        .keyboardType(.decimalPad)
                    
                    TextField("Fat (g)", text: $fat)
                        .keyboardType(.decimalPad)
                }
                
                Section("Quantity") {
                    HStack {
                        Text("Number of servings")
                        Spacer()
                        TextField("1", text: $quantity)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                    }
                }
                
                Section {
                    HStack {
                        Text("Meal")
                        Spacer()
                        Text(mealType.rawValue)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Add Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveEntry()
                    }
                    .disabled(!isValid)
                }
            }
            .sheet(isPresented: $showingFoodSearch) {
                FoodSearchView(selectedFood: $selectedFood)
            }
            .onChange(of: selectedFood) { _, food in
                if let food = food {
                    // Populate fields with selected food data
                    name = food.label
                    calories = String(format: "%.0f", food.nutrients.calories)
                    protein = String(format: "%.1f", food.nutrients.protein)
                    carbs = String(format: "%.1f", food.nutrients.carbs)
                    fat = String(format: "%.1f", food.nutrients.fat)
                    servingSize = "100"
                    servingUnit = "g"
                }
            }
        }
    }
    
    private var isValid: Bool {
        !name.isEmpty &&
        !calories.isEmpty &&
        !protein.isEmpty &&
        !carbs.isEmpty &&
        !fat.isEmpty &&
        !servingSize.isEmpty &&
        !quantity.isEmpty
    }
    
    private func saveEntry() {
        guard let caloriesDouble = Double(calories),
              let proteinDouble = Double(protein),
              let carbsDouble = Double(carbs),
              let fatDouble = Double(fat),
              let servingSizeDouble = Double(servingSize),
              let quantityDouble = Double(quantity) else { return }
        
        let entry = FoodEntry(
            name: name,
            calories: caloriesDouble,
            protein: proteinDouble,
            carbs: carbsDouble,
            fat: fatDouble,
            servingSize: servingSizeDouble,
            servingUnit: servingUnit,
            quantity: quantityDouble * servingSizeDouble,
            mealType: mealType
        )
        
        if !brand.isEmpty {
            entry.brand = brand
        }
        
        modelContext.insert(entry)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving entry: \(error)")
        }
    }
}