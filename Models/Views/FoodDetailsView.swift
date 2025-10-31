import SwiftUI
import SwiftData

struct FoodDetailsView: View {
    let detectedFood: DetectedFood
    let mealType: FoodEntry.MealType
    @State private var selectedFood: DetectedFood
    @State private var quantity: Double = 1.0
    @State private var customServingSize: String = ""
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    init(detectedFood: DetectedFood, mealType: FoodEntry.MealType) {
        self.detectedFood = detectedFood
        self.mealType = mealType
        _selectedFood = State(initialValue: detectedFood)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Food Image
                    if let image = detectedFood.image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .cornerRadius(12)
                    }
                    
                    // Confidence Indicator
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(confidenceColor)
                        Text("\(Int(selectedFood.confidence * 100))% confident")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    // Food Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Detected Food")
                            .font(.headline)
                        
                        ForEach([detectedFood] + detectedFood.alternatives) { food in
                            FoodOptionRow(food: food, isSelected: selectedFood.id == food.id) {
                                selectedFood = food
                                customServingSize = "\(food.servingSize)"
                            }
                        }
                    }
                    .padding()
                    
                    // Serving Size
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Serving Details")
                            .font(.headline)
                        
                        HStack {
                            Text("Quantity")
                            Spacer()
                            HStack(spacing: 20) {
                                Button(action: {
                                    if quantity > 0.25 {
                                        quantity -= 0.25
                                    }
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                }
                                
                                Text("\(quantity, specifier: "%.2f")")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .frame(width: 60)
                                
                                Button(action: {
                                    quantity += 0.25
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        
                        HStack {
                            Text("Serving Size")
                            Spacer()
                            TextField("Size", text: $customServingSize)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                                .keyboardType(.decimalPad)
                            Text(selectedFood.servingUnit)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    
                    // Nutrition Summary
                    NutritionSummaryCard(
                        calories: selectedFood.calories * quantity,
                        protein: selectedFood.protein * quantity,
                        carbs: selectedFood.carbs * quantity,
                        fat: selectedFood.fat * quantity
                    )
                    .padding(.horizontal)
                    
                    // Action Buttons
                    HStack(spacing: 16) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                        
                        Button("Add to Diary") {
                            saveFoodEntry()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding()
                }
            }
            .navigationTitle("Confirm Food")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var confidenceColor: Color {
        if selectedFood.confidence >= 0.8 {
            return .green
        } else if selectedFood.confidence >= 0.6 {
            return .orange
        } else {
            return .red
        }
    }
    
    private func saveFoodEntry() {
        let servingSize = Double(customServingSize) ?? selectedFood.servingSize
        
        let entry = FoodEntry(
            name: selectedFood.name,
            calories: selectedFood.calories,
            protein: selectedFood.protein,
            carbs: selectedFood.carbs,
            fat: selectedFood.fat,
            servingSize: servingSize,
            servingUnit: selectedFood.servingUnit,
            quantity: quantity * servingSize,
            mealType: mealType
        )
        
        if let imageData = detectedFood.image?.jpegData(compressionQuality: 0.8) {
            entry.imageData = imageData
        }
        
        modelContext.insert(entry)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving food entry: \(error)")
        }
    }
}

struct FoodOptionRow: View {
    let food: DetectedFood
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(food.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("\(Int(food.calories)) cal • \(Int(food.servingSize))\(food.servingUnit)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(10)
        }
    }
}

struct NutritionSummaryCard: View {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Nutrition Facts")
                .font(.headline)
            
            HStack {
                VStack {
                    Text("\(Int(calories))")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Calories")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                    .frame(height: 40)
                
                MacroColumn(value: protein, label: "Protein", color: .red)
                MacroColumn(value: carbs, label: "Carbs", color: .orange)
                MacroColumn(value: fat, label: "Fat", color: .yellow)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct MacroColumn: View {
    let value: Double
    let label: String
    let color: Color
    
    var body: some View {
        VStack {
            Text("\(Int(value))g")
                .font(.headline)
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}