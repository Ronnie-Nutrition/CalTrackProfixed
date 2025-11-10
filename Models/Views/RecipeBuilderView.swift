import SwiftUI
import SwiftData

struct RecipeBuilderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appState: AppState
    
    @State private var recipeName = ""
    @State private var recipeDescription = ""
    @State private var servings: Double = 1
    @State private var cookingTime: Double = 30
    @State private var difficulty = Recipe.Difficulty.easy
    @State private var category = Recipe.Category.main
    @State private var ingredients: [Recipe.RecipeIngredient] = []
    @State private var instructions: [String] = [""]
    @State private var selectedImageData: Data?
    
    @State private var showingFoodSearch = false
    @State private var showingImagePicker = false
    @State private var searchText = ""
    @State private var searchResults: [Recipe.SimpleFoodItem] = []
    @State private var isSearching = false
    @State private var showingNutritionPreview = false
    
    var totalNutrition: (calories: Double, protein: Double, carbs: Double, fat: Double) {
        ingredients.reduce((0, 0, 0, 0)) { result, ingredient in
            let multiplier = ingredient.quantity / ingredient.foodItem.servingSize
            return (
                result.0 + (ingredient.foodItem.calories * multiplier),
                result.1 + (ingredient.foodItem.protein * multiplier),
                result.2 + (ingredient.foodItem.carbs * multiplier),
                result.3 + (ingredient.foodItem.fat * multiplier)
            )
        }
    }
    
    var nutritionPerServing: (calories: Double, protein: Double, carbs: Double, fat: Double) {
        let total = totalNutrition
        return (
            total.0 / servings,
            total.1 / servings,
            total.2 / servings,
            total.3 / servings
        )
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                GlassmorphismBackground(colors: [.green, .blue, .purple])
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header Section
                        LiquidGlassCard {
                            VStack(spacing: 16) {
                                HStack {
                                    Image(systemName: "book.fill")
                                        .font(.title)
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.green, .blue],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                    
                                    VStack(alignment: .leading) {
                                        Text("Recipe Builder")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                        Text("Create your custom recipes")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Button(action: { showingNutritionPreview = true }) {
                                        Image(systemName: "chart.bar.fill")
                                            .font(.title3)
                                            .foregroundColor(.blue)
                                    }
                                }
                                
                                // Recipe Image
                                Button(action: { showingImagePicker = true }) {
                                    if let imageData = selectedImageData,
                                       let uiImage = UIImage(data: imageData) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(height: 120)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                    } else {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(.ultraThinMaterial)
                                            .frame(height: 120)
                                            .overlay(
                                                VStack {
                                                    Image(systemName: "camera.fill")
                                                        .font(.title)
                                                        .foregroundColor(.secondary)
                                                    Text("Add Photo")
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                            )
                                    }
                                }
                                .liquidTransition()
                            }
                            .padding()
                        }
                        .padding(.horizontal)
                        
                        // Basic Info Section
                        LiquidGlassCard {
                            VStack(spacing: 16) {
                                Text("Basic Information")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                VStack(spacing: 12) {
                                    CustomTextField(title: "Recipe Name", text: $recipeName, placeholder: "My Amazing Recipe")
                                    CustomTextField(title: "Description", text: $recipeDescription, placeholder: "A delicious and nutritious meal...")
                                    
                                    HStack(spacing: 16) {
                                        VStack(alignment: .leading) {
                                            Text("Servings")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            HStack {
                                                Button("-") { if servings > 1 { servings -= 1 } }
                                                    .foregroundColor(.blue)
                                                Text("\(Int(servings))")
                                                    .frame(minWidth: 40)
                                                    .contentTransition(.numericText())
                                                Button("+") { servings += 1 }
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .trailing) {
                                            Text("Cook Time")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Text("\(Int(cookingTime)) min")
                                                .contentTransition(.numericText())
                                        }
                                    }
                                    
                                    Slider(value: $cookingTime, in: 5...180, step: 5)
                                        .tint(.green)
                                    
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text("Difficulty")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Picker("Difficulty", selection: $difficulty) {
                                                ForEach(Recipe.Difficulty.allCases, id: \.self) { diff in
                                                    Text(diff.rawValue.capitalized).tag(diff)
                                                }
                                            }
                                            .pickerStyle(.segmented)
                                        }
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .trailing) {
                                            Text("Category")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Picker("Category", selection: $category) {
                                                ForEach(Recipe.Category.allCases, id: \.self) { cat in
                                                    Text(cat.rawValue.capitalized).tag(cat)
                                                }
                                            }
                                            .pickerStyle(.menu)
                                        }
                                    }
                                }
                            }
                            .padding()
                        }
                        .padding(.horizontal)
                        
                        // Ingredients Section
                        LiquidGlassCard {
                            VStack(spacing: 16) {
                                HStack {
                                    Text("Ingredients")
                                        .font(.headline)
                                    
                                    Spacer()
                                    
                                    Button("Add Ingredient") {
                                        showingFoodSearch = true
                                    }
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(.blue.opacity(0.2))
                                    .foregroundColor(.blue)
                                    .cornerRadius(12)
                                }
                                
                                if ingredients.isEmpty {
                                    VStack(spacing: 8) {
                                        Image(systemName: "plus.circle.dashed")
                                            .font(.title)
                                            .foregroundColor(.secondary)
                                        Text("No ingredients added yet")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 20)
                                } else {
                                    ForEach(Array(ingredients.enumerated()), id: \.offset) { index, ingredient in
                                        IngredientRow(
                                            ingredient: ingredient,
                                            onQuantityChange: { newQuantity in
                                                ingredients[index].quantity = newQuantity
                                            },
                                            onDelete: {
                                                withAnimation(FluidSpring.bouncy) {
                                                    ingredients.remove(at: index)
                                                }
                                            }
                                        )
                                        .liquidTransition()
                                    }
                                }
                            }
                            .padding()
                        }
                        .padding(.horizontal)
                        
                        // Instructions Section
                        LiquidGlassCard {
                            VStack(spacing: 16) {
                                HStack {
                                    Text("Instructions")
                                        .font(.headline)
                                    
                                    Spacer()
                                    
                                    Button("Add Step") {
                                        withAnimation(FluidSpring.bouncy) {
                                            instructions.append("")
                                        }
                                    }
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(.green.opacity(0.2))
                                    .foregroundColor(.green)
                                    .cornerRadius(12)
                                }
                                
                                ForEach(Array(instructions.enumerated()), id: \.offset) { index, instruction in
                                    HStack(alignment: .top, spacing: 12) {
                                        ZStack {
                                            Circle()
                                                .fill(.green.opacity(0.2))
                                                .frame(width: 24, height: 24)
                                            Text("\(index + 1)")
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .foregroundColor(.green)
                                        }
                                        
                                        TextField("Step \(index + 1)", text: .constant(instruction), axis: .vertical)
                                            .textFieldStyle(.plain)
                                            .onChange(of: instruction) { _, newValue in
                                                instructions[index] = newValue
                                            }
                                        
                                        if instructions.count > 1 {
                                            Button(action: {
                                                withAnimation(FluidSpring.gentle) {
                                                    instructions.remove(at: index)
                                                }
                                            }) {
                                                Image(systemName: "minus.circle.fill")
                                                    .foregroundColor(.red)
                                            }
                                        }
                                    }
                                    .liquidTransition()
                                }
                            }
                            .padding()
                        }
                        .padding(.horizontal)
                        
                        // Nutrition Preview
                        if !ingredients.isEmpty {
                            LiquidGlassCard {
                                VStack(spacing: 16) {
                                    Text("Nutrition Per Serving")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    HStack(spacing: 20) {
                                        NutritionBadge(
                                            title: "Calories",
                                            value: Int(nutritionPerServing.calories),
                                            unit: "cal",
                                            color: .orange,
                                            icon: "flame.fill"
                                        )
                                        
                                        NutritionBadge(
                                            title: "Protein",
                                            value: Int(nutritionPerServing.protein),
                                            unit: "g",
                                            color: .red,
                                            icon: "p.square"
                                        )
                                        
                                        NutritionBadge(
                                            title: "Carbs",
                                            value: Int(nutritionPerServing.carbs),
                                            unit: "g",
                                            color: .blue,
                                            icon: "c.square"
                                        )
                                        
                                        NutritionBadge(
                                            title: "Fat",
                                            value: Int(nutritionPerServing.fat),
                                            unit: "g",
                                            color: .green,
                                            icon: "f.square"
                                        )
                                    }
                                    .animation(FluidSpring.smooth, value: nutritionPerServing.calories)
                                }
                                .padding()
                            }
                            .padding(.horizontal)
                        }
                        
                        // Save Button
                        Button(action: saveRecipe) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Save Recipe")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.green)
                            .foregroundColor(.white)
                            .cornerRadius(16)
                            .shadow(color: .green.opacity(0.3), radius: 10)
                        }
                        .padding(.horizontal)
                        .disabled(recipeName.isEmpty || ingredients.isEmpty)
                        .opacity(recipeName.isEmpty || ingredients.isEmpty ? 0.6 : 1.0)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Recipe Builder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingFoodSearch) {
                FoodSearchSheet(
                    onFoodSelected: { foodItem in
                        addIngredient(foodItem)
                        showingFoodSearch = false
                    }
                )
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImageData: $selectedImageData)
            }
            .sheet(isPresented: $showingNutritionPreview) {
                RecipeNutritionDetailView(
                    totalNutrition: totalNutrition,
                    nutritionPerServing: nutritionPerServing,
                    servings: servings
                )
            }
        }
    }
    
    private func addIngredient(_ foodItem: Recipe.SimpleFoodItem) {
        let ingredient = Recipe.RecipeIngredient(
            foodItem: foodItem,
            quantity: foodItem.servingSize
        )
        withAnimation(FluidSpring.bouncy) {
            ingredients.append(ingredient)
        }
    }
    
    private func saveRecipe() {
        let recipe = Recipe(
            name: recipeName,
            recipeDescription: recipeDescription,
            ingredients: ingredients,
            instructions: instructions.filter { !$0.isEmpty },
            servings: Int(servings),
            cookingTimeMinutes: Int(cookingTime),
            difficulty: difficulty,
            category: category,
            imageData: selectedImageData,
            nutritionPerServing: Recipe.NutritionInfo(
                calories: nutritionPerServing.calories,
                protein: nutritionPerServing.protein,
                carbs: nutritionPerServing.carbs,
                fat: nutritionPerServing.fat
            )
        )
        
        modelContext.insert(recipe)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving recipe: \(error)")
        }
    }
}

// MARK: - Supporting Views

struct CustomTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .cornerRadius(8)
        }
    }
}

struct IngredientRow: View {
    let ingredient: RecipeIngredient
    let onQuantityChange: (Double) -> Void
    let onDelete: () -> Void
    
    @State private var editingQuantity = false
    @State private var quantityText = ""
    
    var body: some View {
        HStack(spacing: 12) {
            // Food info
            VStack(alignment: .leading, spacing: 2) {
                Text(ingredient.foodItem.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    Text("\(Int(ingredient.quantity))")
                        .foregroundColor(.blue)
                        .onTapGesture {
                            editingQuantity = true
                            quantityText = "\(Int(ingredient.quantity))"
                        }
                    
                    Text(ingredient.foodItem.servingUnit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Nutrition preview
            HStack(spacing: 8) {
                let multiplier = ingredient.quantity / ingredient.foodItem.servingSize
                
                Text("\(Int(ingredient.foodItem.calories * multiplier)) cal")
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .cornerRadius(4)
            }
            
            // Delete button
            Button(action: onDelete) {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 8)
        .alert("Edit Quantity", isPresented: $editingQuantity) {
            TextField("Quantity", text: $quantityText)
                .keyboardType(.numberPad)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                if let newQuantity = Double(quantityText) {
                    onQuantityChange(newQuantity)
                }
            }
        }
    }
}

struct NutritionBadge: View {
    let title: String
    let value: Int
    let unit: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            Text("\(value)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .contentTransition(.numericText())
            
            Text(unit)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Supporting Models

struct RecipeIngredient: Codable, Identifiable {
    let id = UUID()
    let foodItem: Recipe.SimpleFoodItem
    var quantity: Double
}

// MARK: - Food Search Sheet

struct FoodSearchSheet: View {
    let onFoodSelected: (Recipe.SimpleFoodItem) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var searchResults: [Recipe.SimpleFoodItem] = []
    @State private var isSearching = false
    
    private let commonFoods = [
        Recipe.SimpleFoodItem(name: "Chicken Breast", brand: nil, barcode: nil, calories: 165, protein: 31, carbs: 0, fat: 4, servingSize: 100, servingUnit: "g"),
        Recipe.SimpleFoodItem(name: "Brown Rice", brand: nil, barcode: nil, calories: 110, protein: 2.6, carbs: 22, fat: 0.9, servingSize: 100, servingUnit: "g"),
        Recipe.SimpleFoodItem(name: "Broccoli", brand: nil, barcode: nil, calories: 25, protein: 3, carbs: 5, fat: 0.3, servingSize: 100, servingUnit: "g"),
        Recipe.SimpleFoodItem(name: "Olive Oil", brand: nil, barcode: nil, calories: 884, protein: 0, carbs: 0, fat: 100, servingSize: 100, servingUnit: "ml"),
        Recipe.SimpleFoodItem(name: "Eggs", brand: nil, barcode: nil, calories: 155, protein: 13, carbs: 1.1, fat: 11, servingSize: 100, servingUnit: "g"),
        Recipe.SimpleFoodItem(name: "Salmon", brand: nil, barcode: nil, calories: 180, protein: 25, carbs: 0, fat: 8, servingSize: 100, servingUnit: "g")
    ]
    
    var body: some View {
        NavigationStack {
            VStack {
                SearchBar(text: $searchText, onSearchButtonClicked: performSearch)
                
                List {
                    if searchText.isEmpty {
                        Section("Common Ingredients") {
                            ForEach(commonFoods) { food in
                                FoodRowView(food: food) {
                                    onFoodSelected(food)
                                }
                            }
                        }
                    } else if isSearching {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Searching...")
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(Color.clear)
                    } else {
                        ForEach(searchResults) { food in
                            FoodRowView(food: food) {
                                onFoodSelected(food)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Ingredient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else { return }
        
        isSearching = true
        
        // Simulate API search with delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Filter common foods or use real API
            searchResults = commonFoods.filter {
                $0.name.lowercased().contains(searchText.lowercased())
            }
            isSearching = false
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    let onSearchButtonClicked: () -> Void
    
    var body: some View {
        HStack {
            TextField("Search ingredients...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onSubmit {
                    onSearchButtonClicked()
                }
            
            Button("Search", action: onSearchButtonClicked)
                .disabled(text.isEmpty)
        }
        .padding()
    }
}

struct FoodRowView: View {
    let food: Recipe.SimpleFoodItem
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(food.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    Text("\(Int(food.calories)) cal")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("per \(Int(food.servingSize)) \(food.servingUnit)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button("Add") {
                onTap()
            }
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(.blue.opacity(0.2))
            .foregroundColor(.blue)
            .cornerRadius(8)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

struct RecipeNutritionDetailView: View {
    let totalNutrition: (calories: Double, protein: Double, carbs: Double, fat: Double)
    let nutritionPerServing: (calories: Double, protein: Double, carbs: Double, fat: Double)
    let servings: Double
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Nutrition Breakdown")
                    .font(.title2)
                    .fontWeight(.bold)
                
                VStack(spacing: 16) {
                    NutritionComparisonRow(
                        title: "Calories",
                        total: Int(totalNutrition.calories),
                        perServing: Int(nutritionPerServing.calories),
                        unit: "cal",
                        color: .orange
                    )
                    
                    NutritionComparisonRow(
                        title: "Protein",
                        total: Int(totalNutrition.protein),
                        perServing: Int(nutritionPerServing.protein),
                        unit: "g",
                        color: .red
                    )
                    
                    NutritionComparisonRow(
                        title: "Carbs",
                        total: Int(totalNutrition.carbs),
                        perServing: Int(nutritionPerServing.carbs),
                        unit: "g",
                        color: .blue
                    )
                    
                    NutritionComparisonRow(
                        title: "Fat",
                        total: Int(totalNutrition.fat),
                        perServing: Int(nutritionPerServing.fat),
                        unit: "g",
                        color: .green
                    )
                }
                .padding()
                
                Text("Total servings: \(Int(servings))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Nutrition Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct NutritionComparisonRow: View {
    let title: String
    let total: Int
    let perServing: Int
    let unit: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(color)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(total) \(unit)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text("\(perServing) \(unit) per serving")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    RecipeBuilderView()
        .modelContainer(for: [Recipe.self, FoodEntry.self])
        .environmentObject(AppState())
}