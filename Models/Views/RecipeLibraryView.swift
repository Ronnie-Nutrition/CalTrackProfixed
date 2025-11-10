import SwiftUI
import SwiftData

struct RecipeLibraryView: View {
    @Query private var recipes: [Recipe]
    @State private var showingRecipeBuilder = false
    @State private var searchText = ""
    @State private var selectedCategory = Recipe.Category.all
    @State private var sortOrder = SortOrder.newest
    
    enum SortOrder: String, CaseIterable {
        case newest = "Newest"
        case oldest = "Oldest"
        case nameAZ = "Name A-Z"
        case nameZA = "Name Z-A"
        case cookTime = "Cook Time"
        case difficulty = "Difficulty"
    }
    
    private var filteredRecipes: [Recipe] {
        var filtered = recipes
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { recipe in
                recipe.name.localizedCaseInsensitiveContains(searchText) ||
                recipe.recipeDescription.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Filter by category
        if selectedCategory != .all {
            filtered = filtered.filter { $0.category == selectedCategory }
        }
        
        // Sort
        switch sortOrder {
        case .newest:
            filtered = filtered.sorted { $0.createdAt > $1.createdAt }
        case .oldest:
            filtered = filtered.sorted { $0.createdAt < $1.createdAt }
        case .nameAZ:
            filtered = filtered.sorted { $0.name < $1.name }
        case .nameZA:
            filtered = filtered.sorted { $0.name > $1.name }
        case .cookTime:
            filtered = filtered.sorted { $0.cookingTimeMinutes < $1.cookingTimeMinutes }
        case .difficulty:
            filtered = filtered.sorted { $0.difficulty.sortOrder < $1.difficulty.sortOrder }
        }
        
        return filtered
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                GlassmorphismBackground(colors: [.orange, .red, .pink])
                
                VStack(spacing: 0) {
                    // Header with search and filters
                    LiquidGlassCard {
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "book.closed.fill")
                                    .font(.title)
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.orange, .red],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                
                                VStack(alignment: .leading) {
                                    Text("Recipe Library")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    Text("\(recipes.count) recipes saved")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Button(action: { showingRecipeBuilder = true }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title)
                                        .foregroundColor(.orange)
                                }
                                .liquidPulse(color: .orange, intensity: 0.3)
                            }
                            
                            // Search bar
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.secondary)
                                
                                TextField("Search recipes...", text: $searchText)
                                    .textFieldStyle(.plain)
                                
                                if !searchText.isEmpty {
                                    Button(action: { searchText = "" }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial)
                            .cornerRadius(20)
                            
                            // Filter controls
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    // Category filter
                                    Menu {
                                        ForEach([Recipe.Category.all] + Recipe.Category.allCases.filter { $0 != .all }, id: \.self) { category in
                                            Button(action: { selectedCategory = category }) {
                                                Label(category.rawValue.capitalized, systemImage: selectedCategory == category ? "checkmark" : "")
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Image(systemName: "line.horizontal.3.decrease.circle")
                                            Text(selectedCategory.rawValue.capitalized)
                                        }
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(.orange.opacity(0.2))
                                        .foregroundColor(.orange)
                                        .cornerRadius(12)
                                    }
                                    
                                    // Sort menu
                                    Menu {
                                        ForEach(SortOrder.allCases, id: \.self) { order in
                                            Button(action: { sortOrder = order }) {
                                                Label(order.rawValue, systemImage: sortOrder == order ? "checkmark" : "")
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Image(systemName: "arrow.up.arrow.down")
                                            Text(sortOrder.rawValue)
                                        }
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(.blue.opacity(0.2))
                                        .foregroundColor(.blue)
                                        .cornerRadius(12)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding()
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Recipe list
                    if filteredRecipes.isEmpty {
                        Spacer()
                        
                        LiquidGlassCard {
                            VStack(spacing: 16) {
                                if recipes.isEmpty {
                                    Image(systemName: "book.closed")
                                        .font(.system(size: 60))
                                        .foregroundColor(.secondary)
                                    
                                    Text("No Recipes Yet")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    
                                    Text("Create your first recipe to start building your personal cookbook!")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                    
                                    Button("Create Recipe") {
                                        showingRecipeBuilder = true
                                    }
                                    .font(.headline)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(.orange)
                                    .foregroundColor(.white)
                                    .cornerRadius(20)
                                    .shadow(color: .orange.opacity(0.3), radius: 10)
                                } else {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 40))
                                        .foregroundColor(.secondary)
                                    
                                    Text("No Results")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                    
                                    Text("Try adjusting your search or filters")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .padding(40)
                        }
                        .padding(.horizontal)
                        
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(filteredRecipes) { recipe in
                                    NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                                        RecipeCard(recipe: recipe)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingRecipeBuilder) {
                RecipeBuilderView()
            }
        }
    }
}

struct RecipeCard: View {
    let recipe: Recipe
    @State private var isHovered = false
    
    private var difficultyColor: Color {
        switch recipe.difficulty {
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        }
    }
    
    var body: some View {
        LiquidGlassCard {
            VStack(spacing: 12) {
                // Recipe image or placeholder
                if let imageData = recipe.imageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [.orange.opacity(0.3), .red.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 120)
                        .overlay(
                            VStack {
                                Image(systemName: recipe.category.icon)
                                    .font(.title)
                                    .foregroundColor(.orange)
                                Text(recipe.category.rawValue.capitalized)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        )
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    // Recipe name
                    Text(recipe.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Description
                    if !recipe.recipeDescription.isEmpty {
                        Text(recipe.recipeDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    // Recipe metadata
                    HStack(spacing: 16) {
                        // Cook time
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption)
                                .foregroundColor(.blue)
                            Text("\(recipe.cookingTimeMinutes)m")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        
                        // Servings
                        HStack(spacing: 4) {
                            Image(systemName: "person.2")
                                .font(.caption)
                                .foregroundColor(.green)
                            Text("\(recipe.servings)")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        
                        Spacer()
                        
                        // Difficulty
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(difficultyColor)
                            Text(recipe.difficulty.rawValue.capitalized)
                                .font(.caption)
                                .foregroundColor(difficultyColor)
                        }
                    }
                    
                    // Nutrition preview
                    if let nutrition = recipe.nutritionPerServing {
                        HStack(spacing: 12) {
                            Text("\(Int(nutrition.calories)) cal")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.orange.opacity(0.2))
                                .foregroundColor(.orange)
                                .cornerRadius(4)
                            
                            Text("\(Int(nutrition.protein))g protein")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.red.opacity(0.2))
                                .foregroundColor(.red)
                                .cornerRadius(4)
                            
                            Spacer()
                            
                            Text("per serving")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding()
        }
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .onHover { hovering in
            withAnimation(FluidSpring.gentle) {
                isHovered = hovering
            }
        }
    }
}

struct RecipeDetailView: View {
    let recipe: Recipe
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var showingDeleteAlert = false
    @State private var selectedIngredientScale: Double = 1.0
    
    var scaledIngredients: [Recipe.RecipeIngredient] {
        recipe.ingredients.map { ingredient in
            var scaled = ingredient
            scaled.quantity = ingredient.quantity * selectedIngredientScale
            return scaled
        }
    }
    
    var scaledNutrition: Recipe.NutritionInfo? {
        guard let nutrition = recipe.nutritionPerServing else { return nil }
        return Recipe.NutritionInfo(
            calories: nutrition.calories * selectedIngredientScale,
            protein: nutrition.protein * selectedIngredientScale,
            carbs: nutrition.carbs * selectedIngredientScale,
            fat: nutrition.fat * selectedIngredientScale
        )
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Hero image/header
                if let imageData = recipe.imageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.2), radius: 10)
                } else {
                    LiquidGlassCard {
                        VStack(spacing: 12) {
                            Image(systemName: recipe.category.icon)
                                .font(.system(size: 60))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.orange, .red],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            Text(recipe.name)
                                .font(.title2)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                        }
                        .padding(40)
                    }
                }
                
                // Recipe info
                LiquidGlassCard {
                    VStack(spacing: 16) {
                        Text(recipe.name)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        if !recipe.recipeDescription.isEmpty {
                            Text(recipe.recipeDescription)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        HStack(spacing: 20) {
                            VStack {
                                Image(systemName: "clock")
                                    .foregroundColor(.blue)
                                Text("\(recipe.cookingTimeMinutes)")
                                    .fontWeight(.semibold)
                                Text("minutes")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack {
                                Image(systemName: "person.2")
                                    .foregroundColor(.green)
                                Text("\(recipe.servings)")
                                    .fontWeight(.semibold)
                                Text("servings")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.orange)
                                Text(recipe.difficulty.rawValue.capitalized)
                                    .fontWeight(.semibold)
                                Text("difficulty")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                }
                
                // Serving size adjuster
                LiquidGlassCard {
                    VStack(spacing: 12) {
                        Text("Adjust Servings")
                            .font(.headline)
                        
                        HStack {
                            Button("-") {
                                if selectedIngredientScale > 0.5 {
                                    selectedIngredientScale -= 0.5
                                }
                            }
                            .foregroundColor(.blue)
                            .disabled(selectedIngredientScale <= 0.5)
                            
                            Text("\(selectedIngredientScale, specifier: "%.1f")×")
                                .frame(minWidth: 60)
                                .contentTransition(.numericText())
                            
                            Button("+") {
                                if selectedIngredientScale < 5.0 {
                                    selectedIngredientScale += 0.5
                                }
                            }
                            .foregroundColor(.blue)
                            .disabled(selectedIngredientScale >= 5.0)
                        }
                        .font(.title2)
                        
                        Text("Original recipe serves \(recipe.servings)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
                
                // Ingredients
                LiquidGlassCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Ingredients")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        ForEach(scaledIngredients, id: \.id) { ingredient in
                            HStack {
                                Text("•")
                                    .foregroundColor(.orange)
                                    .fontWeight(.bold)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(ingredient.foodItem.name)
                                        .fontWeight(.medium)
                                    
                                    Text("\(ingredient.quantity, specifier: "%.0f") \(ingredient.foodItem.servingUnit)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                        }
                    }
                    .padding()
                }
                
                // Instructions
                LiquidGlassCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Instructions")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        ForEach(Array(recipe.instructions.enumerated()), id: \.offset) { index, instruction in
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
                                
                                Text(instruction)
                                    .font(.body)
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                Spacer()
                            }
                        }
                    }
                    .padding()
                }
                
                // Nutrition
                if let nutrition = scaledNutrition {
                    LiquidGlassCard {
                        VStack(spacing: 16) {
                            Text("Nutrition (Per Adjusted Serving)")
                                .font(.headline)
                            
                            HStack(spacing: 20) {
                                VStack {
                                    Text("\(Int(nutrition.calories))")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.orange)
                                        .contentTransition(.numericText())
                                    Text("Calories")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                VStack {
                                    Text("\(Int(nutrition.protein))g")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.red)
                                        .contentTransition(.numericText())
                                    Text("Protein")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                VStack {
                                    Text("\(Int(nutrition.carbs))g")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                        .contentTransition(.numericText())
                                    Text("Carbs")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                VStack {
                                    Text("\(Int(nutrition.fat))g")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.green)
                                        .contentTransition(.numericText())
                                    Text("Fat")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding()
                    }
                }
                
                // Action buttons
                VStack(spacing: 12) {
                    Button("Add to Food Diary") {
                        addRecipeToFoodDiary()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.green)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .shadow(color: .green.opacity(0.3), radius: 10)
                    
                    Button("Delete Recipe") {
                        showingDeleteAlert = true
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.red.opacity(0.1))
                    .foregroundColor(.red)
                    .cornerRadius(16)
                }
            }
            .padding()
        }
        .background(GlassmorphismBackground(colors: [.orange, .red, .pink]).opacity(0.3))
        .navigationBarBackButtonHidden(false)
        .alert("Delete Recipe", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteRecipe()
            }
        } message: {
            Text("Are you sure you want to delete this recipe? This action cannot be undone.")
        }
    }
    
    private func addRecipeToFoodDiary() {
        guard let nutrition = scaledNutrition else { return }
        
        let foodEntry = FoodEntry(
            name: recipe.name,
            calories: nutrition.calories,
            protein: nutrition.protein,
            carbs: nutrition.carbs,
            fat: nutrition.fat,
            servingSize: 1,
            servingUnit: "serving",
            quantity: 1,
            mealType: .lunch // Default to lunch, user can change later
        )
        
        modelContext.insert(foodEntry)
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving food entry: \(error)")
        }
    }
    
    private func deleteRecipe() {
        modelContext.delete(recipe)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error deleting recipe: \(error)")
        }
    }
}

// MARK: - Extensions

extension Recipe.Category {
    var icon: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.fill"
        case .snack: return "leaf.fill"
        case .dessert: return "birthday.cake.fill"
        case .main: return "fork.knife"
        case .side: return "square.grid.2x2.fill"
        case .drink: return "cup.and.saucer.fill"
        case .all: return "square.grid.3x3.fill"
        }
    }
}

extension Recipe.Difficulty {
    var sortOrder: Int {
        switch self {
        case .easy: return 1
        case .medium: return 2
        case .hard: return 3
        }
    }
}

#Preview {
    RecipeLibraryView()
        .modelContainer(for: [Recipe.self, FoodEntry.self])
}