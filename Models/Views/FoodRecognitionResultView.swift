import SwiftUI
import SwiftData

struct FoodRecognitionResultView: View {
    let result: FoodRecognitionResult
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var selectedMealType = FoodEntry.MealType.lunch
    @State private var adjustedFoods: [AdjustableFoodItem] = []
    @State private var showingSuccessMessage = false
    
    struct AdjustableFoodItem: Identifiable {
        let id = UUID()
        let recognizedFood: RecognizedFood
        var quantity: Double
        var isSelected: Bool = true
        
        var adjustedNutrition: RecognizedFood.NutritionInfo? {
            guard let nutrition = recognizedFood.nutritionInfo else { return nil }
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
                                    
                                    Text("Tap to adjust portions")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
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
                            NutritionSummaryCard(nutrition: totalNutrition)
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
                    Text(food.recognizedFood.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
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
                    Text("\(Int(food.recognizedFood.confidence * 100))% confidence")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
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
            Text("Enter the weight in grams for \(food.recognizedFood.name)")
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

struct NutritionSummaryCard: View {
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