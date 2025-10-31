import SwiftUI
import SwiftData

struct EditFoodEntryView: View {
    let entry: FoodEntry
    @State private var name: String
    @State private var calories: String
    @State private var protein: String
    @State private var carbs: String
    @State private var fat: String
    @State private var quantity: String
    @State private var mealType: FoodEntry.MealType
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    init(entry: FoodEntry) {
        self.entry = entry
        _name = State(initialValue: entry.name)
        _calories = State(initialValue: "\(entry.calories)")
        _protein = State(initialValue: "\(entry.protein)")
        _carbs = State(initialValue: "\(entry.carbs)")
        _fat = State(initialValue: "\(entry.fat)")
        _quantity = State(initialValue: "\(entry.quantity)")
        _mealType = State(initialValue: entry.mealType)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Food Details") {
                    TextField("Food Name", text: $name)
                    
                    Picker("Meal", selection: $mealType) {
                        ForEach(FoodEntry.MealType.allCases, id: \.self) { meal in
                            Text(meal.rawValue).tag(meal)
                        }
                    }
                }
                
                Section("Nutrition per Serving") {
                    HStack {
                        Text("Serving: \(Int(entry.servingSize)) \(entry.servingUnit)")
                            .foregroundColor(.secondary)
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
                        Text("Total amount")
                        Spacer()
                        TextField("Quantity", text: $quantity)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text(entry.servingUnit)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                }
            }
        }
    }
    
    private func saveChanges() {
        guard let caloriesDouble = Double(calories),
              let proteinDouble = Double(protein),
              let carbsDouble = Double(carbs),
              let fatDouble = Double(fat),
              let quantityDouble = Double(quantity) else { return }
        
        entry.name = name
        entry.calories = caloriesDouble
        entry.protein = proteinDouble
        entry.carbs = carbsDouble
        entry.fat = fatDouble
        entry.quantity = quantityDouble
        entry.mealType = mealType
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error updating entry: \(error)")
        }
    }
}