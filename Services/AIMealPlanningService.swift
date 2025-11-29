import Foundation
import Combine
import SwiftUI

// MARK: - AI Meal Planning Service
class AIMealPlanningService: ObservableObject {
    static let shared = AIMealPlanningService()
    
    @Published var currentMealPlan: WeeklyMealPlan?
    @Published var isGenerating = false
    @Published var generationProgress: Double = 0.0
    
    private let nutritionService = NutritionAPIService.shared
    private let userDefaults = UserDefaults.standard

    // Async wrapper for the completion-based searchFood
    private func searchFoodAsync(query: String) async -> [FoodItem]? {
        await withCheckedContinuation { continuation in
            nutritionService.searchFood(query: query) { result in
                switch result {
                case .success(let response):
                    // Extract FoodItems from both parsed AND hints
                    var foods = response.parsed.map { $0.food }
                    // Also get foods from hints (this is where most results are)
                    if let hints = response.hints {
                        foods.append(contentsOf: hints.map { $0.food })
                    }
                    continuation.resume(returning: foods.isEmpty ? nil : foods)
                case .failure:
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    // Built-in food database for offline use
    private func getBuiltInFoods(for mealType: MealType) -> [FoodOption] {
        switch mealType {
        case .breakfast:
            return [
                FoodOption(name: "Scrambled Eggs", brand: nil, calories: 140, protein: 12, carbs: 1.2, fat: 10, fiber: 0, standardServing: 100, unit: "g", estimatedCost: 2.0, preparationTime: 10, preparationNotes: "Whisk eggs and cook in pan"),
                FoodOption(name: "Oatmeal", brand: nil, calories: 150, protein: 5, carbs: 27, fat: 3, fiber: 4, standardServing: 150, unit: "g", estimatedCost: 1.0, preparationTime: 5, preparationNotes: "Cook with water or milk"),
                FoodOption(name: "Greek Yogurt", brand: nil, calories: 100, protein: 17, carbs: 6, fat: 0.7, fiber: 0, standardServing: 170, unit: "g", estimatedCost: 2.5, preparationTime: 0, preparationNotes: "Ready to eat"),
                FoodOption(name: "Whole Wheat Toast", brand: nil, calories: 80, protein: 4, carbs: 15, fat: 1, fiber: 2, standardServing: 30, unit: "g", estimatedCost: 0.5, preparationTime: 2, preparationNotes: "Toast until golden"),
                FoodOption(name: "Banana", brand: nil, calories: 105, protein: 1.3, carbs: 27, fat: 0.4, fiber: 3, standardServing: 120, unit: "g", estimatedCost: 0.5, preparationTime: 0, preparationNotes: "Ready to eat"),
                FoodOption(name: "Bacon", brand: nil, calories: 180, protein: 12, carbs: 0.5, fat: 14, fiber: 0, standardServing: 40, unit: "g", estimatedCost: 3.0, preparationTime: 10, preparationNotes: "Pan fry until crispy")
            ]
        case .morningSnack, .afternoonSnack:
            return [
                FoodOption(name: "Apple", brand: nil, calories: 95, protein: 0.5, carbs: 25, fat: 0.3, fiber: 4, standardServing: 180, unit: "g", estimatedCost: 1.0, preparationTime: 0, preparationNotes: "Ready to eat"),
                FoodOption(name: "Almonds", brand: nil, calories: 160, protein: 6, carbs: 6, fat: 14, fiber: 3.5, standardServing: 28, unit: "g", estimatedCost: 2.0, preparationTime: 0, preparationNotes: "Ready to eat"),
                FoodOption(name: "Protein Bar", brand: nil, calories: 200, protein: 20, carbs: 22, fat: 7, fiber: 3, standardServing: 60, unit: "g", estimatedCost: 3.0, preparationTime: 0, preparationNotes: "Ready to eat"),
                FoodOption(name: "Cheese Stick", brand: nil, calories: 80, protein: 7, carbs: 0, fat: 6, fiber: 0, standardServing: 28, unit: "g", estimatedCost: 1.0, preparationTime: 0, preparationNotes: "Ready to eat")
            ]
        case .lunch:
            return [
                FoodOption(name: "Grilled Chicken Breast", brand: nil, calories: 165, protein: 31, carbs: 0, fat: 3.6, fiber: 0, standardServing: 100, unit: "g", estimatedCost: 4.0, preparationTime: 20, preparationNotes: "Season and grill 6-8 min per side"),
                FoodOption(name: "Turkey Sandwich", brand: nil, calories: 300, protein: 24, carbs: 30, fat: 10, fiber: 3, standardServing: 200, unit: "g", estimatedCost: 5.0, preparationTime: 5, preparationNotes: "Layer turkey, lettuce, tomato on bread"),
                FoodOption(name: "Garden Salad", brand: nil, calories: 50, protein: 3, carbs: 10, fat: 0.5, fiber: 4, standardServing: 150, unit: "g", estimatedCost: 3.0, preparationTime: 5, preparationNotes: "Mix greens and vegetables"),
                FoodOption(name: "Brown Rice", brand: nil, calories: 110, protein: 2.6, carbs: 22, fat: 0.9, fiber: 2, standardServing: 100, unit: "g", estimatedCost: 1.0, preparationTime: 25, preparationNotes: "Cook in water until tender"),
                FoodOption(name: "Tuna Salad", brand: nil, calories: 180, protein: 25, carbs: 2, fat: 8, fiber: 0, standardServing: 100, unit: "g", estimatedCost: 4.0, preparationTime: 10, preparationNotes: "Mix tuna with mayo and seasonings")
            ]
        case .dinner:
            return [
                FoodOption(name: "Grilled Salmon", brand: nil, calories: 180, protein: 25, carbs: 0, fat: 8, fiber: 0, standardServing: 100, unit: "g", estimatedCost: 8.0, preparationTime: 15, preparationNotes: "Season and bake at 400°F for 12-15 min"),
                FoodOption(name: "Lean Beef Steak", brand: nil, calories: 250, protein: 26, carbs: 0, fat: 15, fiber: 0, standardServing: 100, unit: "g", estimatedCost: 10.0, preparationTime: 15, preparationNotes: "Grill to desired doneness"),
                FoodOption(name: "Steamed Broccoli", brand: nil, calories: 35, protein: 2.4, carbs: 7, fat: 0.4, fiber: 2.6, standardServing: 100, unit: "g", estimatedCost: 2.0, preparationTime: 8, preparationNotes: "Steam until tender"),
                FoodOption(name: "Baked Potato", brand: nil, calories: 160, protein: 4, carbs: 37, fat: 0.2, fiber: 4, standardServing: 150, unit: "g", estimatedCost: 1.0, preparationTime: 45, preparationNotes: "Bake at 400°F for 45 min"),
                FoodOption(name: "Pasta with Marinara", brand: nil, calories: 280, protein: 10, carbs: 52, fat: 4, fiber: 4, standardServing: 200, unit: "g", estimatedCost: 3.0, preparationTime: 15, preparationNotes: "Cook pasta and top with sauce"),
                FoodOption(name: "Grilled Chicken Breast", brand: nil, calories: 165, protein: 31, carbs: 0, fat: 3.6, fiber: 0, standardServing: 100, unit: "g", estimatedCost: 4.0, preparationTime: 20, preparationNotes: "Season and grill 6-8 min per side")
            ]
        }
    }
    
    // MARK: - Meal Plan Generation
    func generateWeeklyMealPlan(
        for profile: UserProfile,
        preferences: MealPlanPreferences
    ) async throws -> WeeklyMealPlan {
        
        await MainActor.run {
            isGenerating = true
            generationProgress = 0.0
        }
        
        var dailyPlans: [DailyMealPlan] = []
        
        for day in 0..<7 {
            await MainActor.run {
                generationProgress = Double(day) / 7.0
            }
            
            let dailyPlan = try await generateDailyMealPlan(
                for: profile,
                preferences: preferences,
                dayOfWeek: day
            )
            dailyPlans.append(dailyPlan)
        }
        
        let weeklyPlan = WeeklyMealPlan(
            id: UUID().uuidString,
            startDate: preferences.startDate,
            endDate: preferences.startDate.addingTimeInterval(7 * 24 * 60 * 60),
            dailyPlans: dailyPlans,
            preferences: preferences,
            totalCalories: dailyPlans.reduce(0) { $0 + $1.totalCalories },
            totalProtein: dailyPlans.reduce(0) { $0 + $1.totalProtein },
            totalCarbs: dailyPlans.reduce(0) { $0 + $1.totalCarbs },
            totalFat: dailyPlans.reduce(0) { $0 + $1.totalFat }
        )
        
        await MainActor.run {
            self.currentMealPlan = weeklyPlan
            self.isGenerating = false
            self.generationProgress = 1.0
        }
        
        // Save to cache
        saveMealPlanToCache(weeklyPlan)
        
        return weeklyPlan
    }
    
    // MARK: - Daily Meal Plan Generation
    private func generateDailyMealPlan(
        for profile: UserProfile,
        preferences: MealPlanPreferences,
        dayOfWeek: Int
    ) async throws -> DailyMealPlan {
        
        let targetCalories = profile.dailyCalorieTarget
        let targetMacros = calculateTargetMacros(profile: profile, preferences: preferences)
        
        // Generate meals based on preferences
        var meals: [PlannedMeal] = []
        
        // Breakfast
        if preferences.includedMeals.contains(.breakfast) {
            let breakfast = try await generateMeal(
                mealType: .breakfast,
                targetCalories: targetCalories * 0.25,
                targetMacros: scaleMacros(targetMacros, by: 0.25),
                preferences: preferences,
                dayVariation: dayOfWeek
            )
            meals.append(breakfast)
        }
        
        // Morning Snack
        if preferences.includedMeals.contains(.morningSnack) {
            let snack = try await generateMeal(
                mealType: .morningSnack,
                targetCalories: targetCalories * 0.10,
                targetMacros: scaleMacros(targetMacros, by: 0.10),
                preferences: preferences,
                dayVariation: dayOfWeek
            )
            meals.append(snack)
        }
        
        // Lunch
        if preferences.includedMeals.contains(.lunch) {
            let lunch = try await generateMeal(
                mealType: .lunch,
                targetCalories: targetCalories * 0.30,
                targetMacros: scaleMacros(targetMacros, by: 0.30),
                preferences: preferences,
                dayVariation: dayOfWeek
            )
            meals.append(lunch)
        }
        
        // Afternoon Snack
        if preferences.includedMeals.contains(.afternoonSnack) {
            let snack = try await generateMeal(
                mealType: .afternoonSnack,
                targetCalories: targetCalories * 0.10,
                targetMacros: scaleMacros(targetMacros, by: 0.10),
                preferences: preferences,
                dayVariation: dayOfWeek
            )
            meals.append(snack)
        }
        
        // Dinner
        if preferences.includedMeals.contains(.dinner) {
            let dinner = try await generateMeal(
                mealType: .dinner,
                targetCalories: targetCalories * 0.25,
                targetMacros: scaleMacros(targetMacros, by: 0.25),
                preferences: preferences,
                dayVariation: dayOfWeek
            )
            meals.append(dinner)
        }
        
        let dailyPlan = DailyMealPlan(
            date: preferences.startDate.addingTimeInterval(Double(dayOfWeek) * 24 * 60 * 60),
            meals: meals,
            totalCalories: meals.reduce(0) { $0 + $1.totalCalories },
            totalProtein: meals.reduce(0) { $0 + $1.totalProtein },
            totalCarbs: meals.reduce(0) { $0 + $1.totalCarbs },
            totalFat: meals.reduce(0) { $0 + $1.totalFat }
        )
        
        return dailyPlan
    }
    
    // MARK: - Meal Generation
    private func generateMeal(
        mealType: MealType,
        targetCalories: Double,
        targetMacros: MacroTargets,
        preferences: MealPlanPreferences,
        dayVariation: Int
    ) async throws -> PlannedMeal {
        
        // Get appropriate food items based on meal type and preferences
        let foodOptions = try await getFoodOptions(
            for: mealType,
            preferences: preferences,
            targetCalories: targetCalories
        )
        
        // Use AI logic to select optimal combination
        let selectedFoods = selectOptimalFoodCombination(
            from: foodOptions,
            targetCalories: targetCalories,
            targetMacros: targetMacros,
            preferences: preferences,
            dayVariation: dayVariation
        )
        
        let plannedMeal = PlannedMeal(
            mealType: mealType,
            foods: selectedFoods,
            totalCalories: selectedFoods.reduce(0) { $0 + $1.calories },
            totalProtein: selectedFoods.reduce(0) { $0 + $1.protein },
            totalCarbs: selectedFoods.reduce(0) { $0 + $1.carbs },
            totalFat: selectedFoods.reduce(0) { $0 + $1.fat },
            preparationTime: estimatePreparationTime(foods: selectedFoods),
            recipeSuggestions: generateRecipeSuggestions(for: selectedFoods, mealType: mealType)
        )
        
        return plannedMeal
    }
    
    // MARK: - Food Selection AI
    private func selectOptimalFoodCombination(
        from options: [FoodOption],
        targetCalories: Double,
        targetMacros: MacroTargets,
        preferences: MealPlanPreferences,
        dayVariation: Int
    ) -> [PlannedFood] {
        
        var selectedFoods: [PlannedFood] = []
        var remainingCalories = targetCalories
        var remainingMacros = targetMacros
        
        // Smart selection algorithm
        let sortedOptions = options.sorted { food1, food2 in
            // Score based on macro fit, variety, and preferences
            let score1 = calculateFoodScore(
                food: food1,
                targetMacros: remainingMacros,
                preferences: preferences,
                dayVariation: dayVariation
            )
            let score2 = calculateFoodScore(
                food: food2,
                targetMacros: remainingMacros,
                preferences: preferences,
                dayVariation: dayVariation
            )
            return score1 > score2
        }
        
        // Select foods until we meet targets
        for option in sortedOptions {
            guard remainingCalories > 50 else { break }
            
            // Calculate optimal serving size
            let servingMultiplier = min(
                remainingCalories / option.calories,
                2.0 // Max 2x standard serving
            )
            
            if servingMultiplier >= 0.25 { // Min 1/4 serving
                let plannedFood = PlannedFood(
                    name: option.name,
                    brand: option.brand,
                    quantity: option.standardServing * servingMultiplier,
                    unit: option.unit,
                    calories: option.calories * servingMultiplier,
                    protein: option.protein * servingMultiplier,
                    carbs: option.carbs * servingMultiplier,
                    fat: option.fat * servingMultiplier,
                    fiber: option.fiber * servingMultiplier,
                    preparationNotes: option.preparationNotes
                )
                
                selectedFoods.append(plannedFood)
                
                // Update remaining targets
                remainingCalories -= plannedFood.calories
                remainingMacros.protein -= plannedFood.protein
                remainingMacros.carbs -= plannedFood.carbs
                remainingMacros.fat -= plannedFood.fat
            }
        }
        
        return selectedFoods
    }
    
    // MARK: - Scoring Algorithm
    private func calculateFoodScore(
        food: FoodOption,
        targetMacros: MacroTargets,
        preferences: MealPlanPreferences,
        dayVariation: Int
    ) -> Double {
        var score = 100.0
        
        // Macro fit score (40% weight)
        let proteinFit = 1 - abs(food.protein - targetMacros.protein) / max(targetMacros.protein, 1)
        let carbsFit = 1 - abs(food.carbs - targetMacros.carbs) / max(targetMacros.carbs, 1)
        let fatFit = 1 - abs(food.fat - targetMacros.fat) / max(targetMacros.fat, 1)
        score += (proteinFit + carbsFit + fatFit) * 40 / 3
        
        // Variety score (20% weight) - Boost different foods on different days
        let varietyHash = food.name.hashValue ^ dayVariation
        let varietyScore = Double(abs(varietyHash) % 100) / 100.0
        score += varietyScore * 20
        
        // Preference alignment (20% weight)
        if preferences.favoriteFoods.contains(food.name) {
            score += 20
        }
        if preferences.avoidFoods.contains(food.name) {
            score -= 50
        }
        
        // Preparation time (10% weight)
        let prepScore: Double = food.preparationTime <= preferences.maxPrepTime ? 10.0 : 0.0
        score += prepScore
        
        // Cost efficiency (10% weight)
        if preferences.budgetOptimized {
            let costScore = (5 - min(food.estimatedCost, 5)) * 2
            score += costScore
        }
        
        return max(0, score)
    }
    
    // MARK: - Recipe Generation
    private func generateRecipeSuggestions(
        for foods: [PlannedFood],
        mealType: MealType
    ) -> [RecipeSuggestion] {
        
        var suggestions: [RecipeSuggestion] = []
        
        // Simple combination recipes
        if foods.count >= 2 {
            let mainIngredients = foods.map { $0.name }
            
            switch mealType {
            case .breakfast:
                if mainIngredients.contains(where: { $0.lowercased().contains("egg") }) &&
                   mainIngredients.contains(where: { $0.lowercased().contains("bread") }) {
                    suggestions.append(RecipeSuggestion(
                        name: "Classic Breakfast Sandwich",
                        description: "Layer eggs, cheese, and any meat between toasted bread",
                        estimatedTime: 10
                    ))
                }
            case .lunch, .dinner:
                if mainIngredients.contains(where: { $0.lowercased().contains("chicken") }) &&
                   mainIngredients.contains(where: { $0.lowercased().contains("vegetable") }) {
                    suggestions.append(RecipeSuggestion(
                        name: "Stir-Fry Bowl",
                        description: "Quick stir-fry with protein and vegetables over rice",
                        estimatedTime: 15
                    ))
                }
            default:
                break
            }
        }
        
        // Add a simple preparation suggestion
        suggestions.append(RecipeSuggestion(
            name: "Simple Assembly",
            description: "Prepare each item separately and combine on plate",
            estimatedTime: 5
        ))
        
        return suggestions
    }
    
    // MARK: - Helper Functions
    private func calculateTargetMacros(
        profile: UserProfile,
        preferences: MealPlanPreferences
    ) -> MacroTargets {
        let calories = profile.dailyCalorieTarget
        
        switch preferences.dietType {
        case .balanced:
            return MacroTargets(
                protein: calories * 0.30 / 4,
                carbs: calories * 0.40 / 4,
                fat: calories * 0.30 / 9
            )
        case .lowCarb:
            return MacroTargets(
                protein: calories * 0.35 / 4,
                carbs: calories * 0.20 / 4,
                fat: calories * 0.45 / 9
            )
        case .highProtein:
            return MacroTargets(
                protein: calories * 0.40 / 4,
                carbs: calories * 0.35 / 4,
                fat: calories * 0.25 / 9
            )
        case .mediterranean:
            return MacroTargets(
                protein: calories * 0.25 / 4,
                carbs: calories * 0.45 / 4,
                fat: calories * 0.30 / 9
            )
        case .vegan:
            return MacroTargets(
                protein: calories * 0.25 / 4,
                carbs: calories * 0.50 / 4,
                fat: calories * 0.25 / 9
            )
        }
    }
    
    private func scaleMacros(_ macros: MacroTargets, by factor: Double) -> MacroTargets {
        return MacroTargets(
            protein: macros.protein * factor,
            carbs: macros.carbs * factor,
            fat: macros.fat * factor
        )
    }
    
    private func estimatePreparationTime(foods: [PlannedFood]) -> Int {
        return foods.reduce(0) { max($0, $1.estimatedPrepTime ?? 5) } + 5
    }
    
    // MARK: - Data Fetching
    private func getFoodOptions(
        for mealType: MealType,
        preferences: MealPlanPreferences,
        targetCalories: Double
    ) async throws -> [FoodOption] {
        
        var searchTerms: [String] = []
        
        // Build search terms based on meal type
        switch mealType {
        case .breakfast:
            searchTerms = ["eggs", "oatmeal", "yogurt", "toast", "cereal", "fruit", "bacon", "smoothie"]
        case .morningSnack, .afternoonSnack:
            searchTerms = ["nuts", "fruit", "protein bar", "yogurt", "cheese", "crackers"]
        case .lunch:
            searchTerms = ["sandwich", "salad", "soup", "chicken", "fish", "rice", "vegetables"]
        case .dinner:
            searchTerms = ["chicken", "beef", "fish", "pasta", "rice", "vegetables", "salad"]
        }
        
        // Filter based on dietary restrictions
        searchTerms = filterSearchTermsForDiet(searchTerms, preferences: preferences)
        
        var allOptions: [FoodOption] = []
        
        // Fetch foods for each search term
        for term in searchTerms.prefix(5) { // Limit API calls
            if let foods = await searchFoodAsync(query: term) {
                let options = foods.prefix(3).map { food in
                    FoodOption(
                        name: food.label,
                        brand: food.category,
                        calories: food.nutrients.calories,
                        protein: food.nutrients.protein,
                        carbs: food.nutrients.carbs,
                        fat: food.nutrients.fat,
                        fiber: food.nutrients.fiber,
                        standardServing: 100,
                        unit: "g",
                        estimatedCost: estimateFoodCost(food.label),
                        preparationTime: estimatePreparationTime(food.label),
                        preparationNotes: generatePreparationNotes(food.label, mealType: mealType)
                    )
                }
                allOptions.append(contentsOf: options)
            }
        }
        
        // Add user's favorite foods if appropriate
        if let cachedFavorites = getCachedFavoriteFoods() {
            let appropriateFavorites = cachedFavorites.filter { food in
                isFoodAppropriateForMeal(food, mealType: mealType)
            }
            allOptions.append(contentsOf: appropriateFavorites)
        }

        // FALLBACK: If no options from API, use built-in foods
        if allOptions.isEmpty {
            allOptions = getBuiltInFoods(for: mealType)
        }

        return allOptions
    }
    
    private func filterSearchTermsForDiet(
        _ terms: [String],
        preferences: MealPlanPreferences
    ) -> [String] {
        var filtered = terms
        
        switch preferences.dietType {
        case .vegan:
            filtered = filtered.filter { term in
                !["eggs", "chicken", "beef", "fish", "bacon", "cheese", "yogurt"].contains(term)
            }
            filtered.append(contentsOf: ["tofu", "tempeh", "beans", "quinoa"])
        case .lowCarb:
            filtered = filtered.filter { term in
                !["pasta", "rice", "cereal", "toast", "oatmeal"].contains(term)
            }
        default:
            break
        }
        
        return filtered
    }
    
    // MARK: - Caching
    private func saveMealPlanToCache(_ plan: WeeklyMealPlan) {
        if let encoded = try? JSONEncoder().encode(plan) {
            userDefaults.set(encoded, forKey: "cached_meal_plan")
            userDefaults.set(Date(), forKey: "meal_plan_generated_date")
        }
    }
    
    private func getCachedMealPlan() -> WeeklyMealPlan? {
        guard let data = userDefaults.data(forKey: "cached_meal_plan"),
              let plan = try? JSONDecoder().decode(WeeklyMealPlan.self, from: data) else {
            return nil
        }
        
        // Check if plan is still fresh (less than 7 days old)
        if let generatedDate = userDefaults.object(forKey: "meal_plan_generated_date") as? Date,
           Date().timeIntervalSince(generatedDate) < 7 * 24 * 60 * 60 {
            return plan
        }
        
        return nil
    }
    
    private func getCachedFavoriteFoods() -> [FoodOption]? {
        // This would typically fetch from your local database
        // For now, return some common favorites
        return [
            FoodOption(
                name: "Greek Yogurt",
                brand: "Generic",
                calories: 100,
                protein: 10,
                carbs: 6,
                fat: 0,
                fiber: 0,
                standardServing: 170,
                unit: "g",
                estimatedCost: 2.5,
                preparationTime: 0,
                preparationNotes: "Ready to eat"
            ),
            FoodOption(
                name: "Grilled Chicken Breast",
                brand: "Generic",
                calories: 165,
                protein: 31,
                carbs: 0,
                fat: 3.6,
                fiber: 0,
                standardServing: 100,
                unit: "g",
                estimatedCost: 3.5,
                preparationTime: 20,
                preparationNotes: "Season and grill for 6-8 minutes per side"
            )
        ]
    }
    
    // MARK: - Helper Functions
    private func estimateFoodCost(_ foodName: String) -> Double {
        // Simple cost estimation based on food type
        let expensiveFoods = ["salmon", "beef", "shrimp", "avocado"]
        let cheapFoods = ["rice", "pasta", "beans", "potatoes"]
        
        for expensive in expensiveFoods {
            if foodName.lowercased().contains(expensive) {
                return Double.random(in: 4...8)
            }
        }
        
        for cheap in cheapFoods {
            if foodName.lowercased().contains(cheap) {
                return Double.random(in: 0.5...2)
            }
        }
        
        return Double.random(in: 2...4)
    }
    
    private func estimatePreparationTime(_ foodName: String) -> Int {
        let quickFoods = ["yogurt", "fruit", "nuts", "protein bar", "cheese"]
        let slowFoods = ["chicken", "beef", "fish", "pasta", "rice"]
        
        for quick in quickFoods {
            if foodName.lowercased().contains(quick) {
                return 0
            }
        }
        
        for slow in slowFoods {
            if foodName.lowercased().contains(slow) {
                return 20
            }
        }
        
        return 10
    }
    
    private func generatePreparationNotes(_ foodName: String, mealType: MealType) -> String {
        if foodName.lowercased().contains("chicken") {
            return "Season with herbs and spices. Grill, bake at 375°F for 20-25 min, or pan-fry"
        } else if foodName.lowercased().contains("eggs") {
            return "Scrambled, fried, boiled, or made into an omelet"
        } else if foodName.lowercased().contains("salad") {
            return "Mix greens, add preferred toppings and dressing"
        }
        return "Prepare as desired"
    }
    
    private func isFoodAppropriateForMeal(_ food: FoodOption, mealType: MealType) -> Bool {
        let breakfastFoods = ["eggs", "cereal", "oatmeal", "yogurt", "bacon", "toast"]
        let snackFoods = ["nuts", "fruit", "bar", "cheese", "crackers"]
        
        switch mealType {
        case .breakfast:
            return breakfastFoods.contains { food.name.lowercased().contains($0) }
        case .morningSnack, .afternoonSnack:
            return snackFoods.contains { food.name.lowercased().contains($0) }
        default:
            return true
        }
    }
}

// MARK: - Data Models
struct WeeklyMealPlan: Codable, Identifiable {
    let id: String
    let startDate: Date
    let endDate: Date
    let dailyPlans: [DailyMealPlan]
    let preferences: MealPlanPreferences
    let totalCalories: Double
    let totalProtein: Double
    let totalCarbs: Double
    let totalFat: Double
}

struct DailyMealPlan: Codable, Identifiable {
    var id = UUID()
    let date: Date
    let meals: [PlannedMeal]
    let totalCalories: Double
    let totalProtein: Double
    let totalCarbs: Double
    let totalFat: Double
}

struct PlannedMeal: Codable, Identifiable {
    var id = UUID()
    let mealType: MealType
    let foods: [PlannedFood]
    let totalCalories: Double
    let totalProtein: Double
    let totalCarbs: Double
    let totalFat: Double
    let preparationTime: Int
    let recipeSuggestions: [RecipeSuggestion]
}

struct PlannedFood: Codable, Identifiable {
    var id = UUID()
    let name: String
    let brand: String?
    let quantity: Double
    let unit: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double
    let preparationNotes: String?
    var estimatedPrepTime: Int? = 10
}

struct FoodOption {
    let name: String
    let brand: String?
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double
    let standardServing: Double
    let unit: String
    let estimatedCost: Double
    let preparationTime: Int
    let preparationNotes: String?
}

struct RecipeSuggestion: Codable {
    let name: String
    let description: String
    let estimatedTime: Int
}

struct MealPlanPreferences: Codable {
    let dietType: DietType
    let includedMeals: Set<MealType>
    let allergies: [String]
    let avoidFoods: [String]
    let favoriteFoods: [String]
    let maxPrepTime: Int
    let budgetOptimized: Bool
    let varietyLevel: VarietyLevel
    let cuisinePreferences: [CuisineType]
    let startDate: Date
}

struct MacroTargets {
    var protein: Double
    var carbs: Double
    var fat: Double
}

enum MealType: String, Codable, CaseIterable {
    case breakfast = "Breakfast"
    case morningSnack = "Morning Snack"
    case lunch = "Lunch"
    case afternoonSnack = "Afternoon Snack"
    case dinner = "Dinner"
}

enum DietType: String, Codable, CaseIterable {
    case balanced = "Balanced"
    case lowCarb = "Low Carb"
    case highProtein = "High Protein"
    case mediterranean = "Mediterranean"
    case vegan = "Vegan"
}

enum VarietyLevel: String, Codable, CaseIterable {
    case low = "Low - Repeat favorites"
    case medium = "Medium - Some variety"
    case high = "High - Different daily"
}

enum CuisineType: String, Codable, CaseIterable {
    case american = "American"
    case italian = "Italian"
    case mexican = "Mexican"
    case asian = "Asian"
    case mediterranean = "Mediterranean"
    case indian = "Indian"
}
