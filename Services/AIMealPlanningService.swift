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

    // Comprehensive built-in food database with diet-specific options
    private func getBuiltInFoods(for mealType: MealType) -> [FoodOption] {
        switch mealType {
        case .breakfast:
            return [
                // High Protein / Muscle Building
                FoodOption(name: "Scrambled Eggs (4 eggs)", brand: nil, calories: 280, protein: 24, carbs: 2, fat: 20, fiber: 0, standardServing: 200, unit: "g", estimatedCost: 3.0, preparationTime: 10, preparationNotes: "Whisk 4 eggs and cook in pan"),
                FoodOption(name: "Egg White Omelette", brand: nil, calories: 120, protein: 26, carbs: 2, fat: 0.5, fiber: 0, standardServing: 150, unit: "g", estimatedCost: 3.5, preparationTime: 12, preparationNotes: "Use 6 egg whites with vegetables"),
                FoodOption(name: "Protein Pancakes", brand: nil, calories: 300, protein: 25, carbs: 30, fat: 8, fiber: 3, standardServing: 150, unit: "g", estimatedCost: 4.0, preparationTime: 15, preparationNotes: "Mix protein powder with oats and eggs"),
                FoodOption(name: "Cottage Cheese Bowl", brand: nil, calories: 220, protein: 28, carbs: 10, fat: 5, fiber: 2, standardServing: 250, unit: "g", estimatedCost: 3.0, preparationTime: 5, preparationNotes: "Top with berries and nuts"),
                // Low Carb / Keto
                FoodOption(name: "Bacon & Eggs", brand: nil, calories: 350, protein: 24, carbs: 1, fat: 28, fiber: 0, standardServing: 150, unit: "g", estimatedCost: 5.0, preparationTime: 15, preparationNotes: "Fry bacon crispy, cook eggs to preference"),
                FoodOption(name: "Avocado Eggs", brand: nil, calories: 320, protein: 14, carbs: 8, fat: 26, fiber: 7, standardServing: 200, unit: "g", estimatedCost: 4.0, preparationTime: 15, preparationNotes: "Bake eggs in avocado halves"),
                FoodOption(name: "Smoked Salmon Plate", brand: nil, calories: 280, protein: 30, carbs: 2, fat: 16, fiber: 0, standardServing: 120, unit: "g", estimatedCost: 8.0, preparationTime: 5, preparationNotes: "Serve with cream cheese and capers"),
                FoodOption(name: "Sausage & Cheese Scramble", brand: nil, calories: 400, protein: 28, carbs: 3, fat: 32, fiber: 0, standardServing: 180, unit: "g", estimatedCost: 5.0, preparationTime: 12, preparationNotes: "Cook sausage, add eggs and cheese"),
                // Balanced / Mediterranean
                FoodOption(name: "Greek Yogurt Parfait", brand: nil, calories: 300, protein: 20, carbs: 35, fat: 8, fiber: 4, standardServing: 250, unit: "g", estimatedCost: 4.0, preparationTime: 5, preparationNotes: "Layer yogurt with granola and honey"),
                FoodOption(name: "Overnight Oats", brand: nil, calories: 350, protein: 12, carbs: 55, fat: 10, fiber: 8, standardServing: 250, unit: "g", estimatedCost: 2.5, preparationTime: 5, preparationNotes: "Prepare night before with milk and chia"),
                FoodOption(name: "Shakshuka", brand: nil, calories: 280, protein: 16, carbs: 18, fat: 16, fiber: 4, standardServing: 250, unit: "g", estimatedCost: 4.0, preparationTime: 25, preparationNotes: "Poach eggs in spiced tomato sauce"),
                FoodOption(name: "Whole Grain Toast & Avocado", brand: nil, calories: 320, protein: 10, carbs: 35, fat: 18, fiber: 10, standardServing: 150, unit: "g", estimatedCost: 3.5, preparationTime: 8, preparationNotes: "Toast bread, top with mashed avocado and egg"),
                // Vegan
                FoodOption(name: "Tofu Scramble", brand: nil, calories: 220, protein: 18, carbs: 8, fat: 14, fiber: 3, standardServing: 200, unit: "g", estimatedCost: 3.0, preparationTime: 15, preparationNotes: "Crumble firm tofu with turmeric and vegetables"),
                FoodOption(name: "Acai Bowl", brand: nil, calories: 350, protein: 6, carbs: 60, fat: 10, fiber: 8, standardServing: 300, unit: "g", estimatedCost: 6.0, preparationTime: 10, preparationNotes: "Blend acai with banana, top with granola"),
                FoodOption(name: "Chia Pudding", brand: nil, calories: 280, protein: 8, carbs: 32, fat: 14, fiber: 12, standardServing: 200, unit: "g", estimatedCost: 3.0, preparationTime: 5, preparationNotes: "Mix chia with almond milk overnight")
            ]
        case .morningSnack, .afternoonSnack:
            return [
                // High Protein
                FoodOption(name: "Protein Shake", brand: nil, calories: 200, protein: 30, carbs: 8, fat: 4, fiber: 1, standardServing: 350, unit: "ml", estimatedCost: 3.0, preparationTime: 2, preparationNotes: "Blend protein powder with water or milk"),
                FoodOption(name: "Greek Yogurt Cup", brand: nil, calories: 130, protein: 18, carbs: 8, fat: 2, fiber: 0, standardServing: 170, unit: "g", estimatedCost: 2.0, preparationTime: 0, preparationNotes: "Ready to eat"),
                FoodOption(name: "Turkey Roll-Ups", brand: nil, calories: 150, protein: 18, carbs: 4, fat: 7, fiber: 1, standardServing: 100, unit: "g", estimatedCost: 4.0, preparationTime: 5, preparationNotes: "Roll turkey slices with cheese and mustard"),
                FoodOption(name: "Hard Boiled Eggs", brand: nil, calories: 140, protein: 12, carbs: 1, fat: 10, fiber: 0, standardServing: 100, unit: "g", estimatedCost: 1.5, preparationTime: 15, preparationNotes: "Boil eggs for 10 minutes"),
                // Low Carb
                FoodOption(name: "Cheese & Pepperoni", brand: nil, calories: 200, protein: 14, carbs: 2, fat: 16, fiber: 0, standardServing: 60, unit: "g", estimatedCost: 3.0, preparationTime: 0, preparationNotes: "Ready to eat"),
                FoodOption(name: "Celery with Almond Butter", brand: nil, calories: 180, protein: 6, carbs: 8, fat: 15, fiber: 3, standardServing: 100, unit: "g", estimatedCost: 2.5, preparationTime: 2, preparationNotes: "Spread almond butter on celery sticks"),
                FoodOption(name: "Beef Jerky", brand: nil, calories: 120, protein: 20, carbs: 4, fat: 2, fiber: 0, standardServing: 40, unit: "g", estimatedCost: 4.0, preparationTime: 0, preparationNotes: "Ready to eat"),
                FoodOption(name: "Pork Rinds", brand: nil, calories: 160, protein: 18, carbs: 0, fat: 10, fiber: 0, standardServing: 30, unit: "g", estimatedCost: 2.0, preparationTime: 0, preparationNotes: "Ready to eat"),
                // Balanced
                FoodOption(name: "Trail Mix", brand: nil, calories: 200, protein: 6, carbs: 18, fat: 14, fiber: 3, standardServing: 40, unit: "g", estimatedCost: 2.5, preparationTime: 0, preparationNotes: "Ready to eat"),
                FoodOption(name: "Apple with Peanut Butter", brand: nil, calories: 250, protein: 7, carbs: 30, fat: 14, fiber: 5, standardServing: 150, unit: "g", estimatedCost: 2.0, preparationTime: 2, preparationNotes: "Slice apple and dip in peanut butter"),
                FoodOption(name: "Hummus & Veggies", brand: nil, calories: 180, protein: 6, carbs: 20, fat: 10, fiber: 6, standardServing: 150, unit: "g", estimatedCost: 3.0, preparationTime: 5, preparationNotes: "Serve hummus with carrots and cucumber"),
                FoodOption(name: "Rice Cakes with Cream Cheese", brand: nil, calories: 150, protein: 4, carbs: 22, fat: 6, fiber: 1, standardServing: 60, unit: "g", estimatedCost: 2.0, preparationTime: 2, preparationNotes: "Spread cream cheese on rice cakes"),
                // Vegan
                FoodOption(name: "Edamame", brand: nil, calories: 120, protein: 11, carbs: 9, fat: 5, fiber: 4, standardServing: 100, unit: "g", estimatedCost: 2.0, preparationTime: 5, preparationNotes: "Steam and sprinkle with sea salt"),
                FoodOption(name: "Mixed Nuts", brand: nil, calories: 180, protein: 5, carbs: 8, fat: 16, fiber: 2, standardServing: 30, unit: "g", estimatedCost: 2.5, preparationTime: 0, preparationNotes: "Ready to eat"),
                FoodOption(name: "Energy Bites", brand: nil, calories: 150, protein: 4, carbs: 18, fat: 8, fiber: 3, standardServing: 40, unit: "g", estimatedCost: 2.0, preparationTime: 15, preparationNotes: "Roll oats, dates, and nut butter")
            ]
        case .lunch:
            return [
                // High Protein / Muscle Building
                FoodOption(name: "Grilled Chicken Salad", brand: nil, calories: 350, protein: 40, carbs: 12, fat: 16, fiber: 4, standardServing: 300, unit: "g", estimatedCost: 6.0, preparationTime: 20, preparationNotes: "Grill chicken, serve over mixed greens"),
                FoodOption(name: "Tuna Steak", brand: nil, calories: 280, protein: 45, carbs: 0, fat: 10, fiber: 0, standardServing: 170, unit: "g", estimatedCost: 10.0, preparationTime: 12, preparationNotes: "Sear tuna 2 min per side"),
                FoodOption(name: "Turkey Meatballs", brand: nil, calories: 320, protein: 35, carbs: 8, fat: 16, fiber: 1, standardServing: 200, unit: "g", estimatedCost: 5.0, preparationTime: 25, preparationNotes: "Bake at 400°F for 20 minutes"),
                FoodOption(name: "Chicken & Rice Bowl", brand: nil, calories: 450, protein: 38, carbs: 45, fat: 12, fiber: 3, standardServing: 350, unit: "g", estimatedCost: 5.0, preparationTime: 30, preparationNotes: "Layer rice with grilled chicken and veggies"),
                // Low Carb
                FoodOption(name: "Cobb Salad", brand: nil, calories: 380, protein: 28, carbs: 10, fat: 28, fiber: 4, standardServing: 300, unit: "g", estimatedCost: 7.0, preparationTime: 15, preparationNotes: "Layer greens with chicken, bacon, egg, avocado"),
                FoodOption(name: "Lettuce Wrap Tacos", brand: nil, calories: 320, protein: 28, carbs: 8, fat: 20, fiber: 3, standardServing: 250, unit: "g", estimatedCost: 6.0, preparationTime: 15, preparationNotes: "Use lettuce leaves as taco shells"),
                FoodOption(name: "Bunless Burger", brand: nil, calories: 400, protein: 32, carbs: 5, fat: 30, fiber: 2, standardServing: 200, unit: "g", estimatedCost: 7.0, preparationTime: 15, preparationNotes: "Serve burger patty on lettuce with toppings"),
                FoodOption(name: "Chicken Caesar (no croutons)", brand: nil, calories: 350, protein: 35, carbs: 6, fat: 22, fiber: 3, standardServing: 280, unit: "g", estimatedCost: 6.0, preparationTime: 15, preparationNotes: "Classic caesar with grilled chicken"),
                // Mediterranean / Balanced
                FoodOption(name: "Mediterranean Bowl", brand: nil, calories: 420, protein: 22, carbs: 45, fat: 18, fiber: 8, standardServing: 350, unit: "g", estimatedCost: 6.0, preparationTime: 20, preparationNotes: "Falafel, hummus, tabbouleh, pita"),
                FoodOption(name: "Greek Salad with Chicken", brand: nil, calories: 380, protein: 30, carbs: 15, fat: 24, fiber: 4, standardServing: 300, unit: "g", estimatedCost: 7.0, preparationTime: 15, preparationNotes: "Cucumbers, tomatoes, feta, olives, chicken"),
                FoodOption(name: "Quinoa Power Bowl", brand: nil, calories: 400, protein: 18, carbs: 50, fat: 16, fiber: 8, standardServing: 350, unit: "g", estimatedCost: 5.0, preparationTime: 25, preparationNotes: "Quinoa with roasted vegetables and tahini"),
                FoodOption(name: "Salmon Poke Bowl", brand: nil, calories: 450, protein: 28, carbs: 45, fat: 18, fiber: 5, standardServing: 350, unit: "g", estimatedCost: 12.0, preparationTime: 15, preparationNotes: "Rice bowl with raw salmon and toppings"),
                // Vegan
                FoodOption(name: "Buddha Bowl", brand: nil, calories: 380, protein: 15, carbs: 55, fat: 14, fiber: 12, standardServing: 400, unit: "g", estimatedCost: 5.0, preparationTime: 25, preparationNotes: "Grains, roasted veggies, chickpeas, tahini"),
                FoodOption(name: "Black Bean Tacos", brand: nil, calories: 350, protein: 14, carbs: 50, fat: 12, fiber: 12, standardServing: 250, unit: "g", estimatedCost: 4.0, preparationTime: 15, preparationNotes: "Corn tortillas with seasoned black beans"),
                FoodOption(name: "Lentil Soup", brand: nil, calories: 280, protein: 18, carbs: 40, fat: 6, fiber: 15, standardServing: 350, unit: "ml", estimatedCost: 3.0, preparationTime: 35, preparationNotes: "Hearty soup with lentils and vegetables")
            ]
        case .dinner:
            return [
                // High Protein / Muscle Building
                FoodOption(name: "Grilled Ribeye Steak", brand: nil, calories: 450, protein: 42, carbs: 0, fat: 32, fiber: 0, standardServing: 200, unit: "g", estimatedCost: 15.0, preparationTime: 20, preparationNotes: "Season and grill to desired temp"),
                FoodOption(name: "Baked Salmon Fillet", brand: nil, calories: 350, protein: 40, carbs: 0, fat: 20, fiber: 0, standardServing: 200, unit: "g", estimatedCost: 12.0, preparationTime: 20, preparationNotes: "Bake at 400°F for 15 minutes"),
                FoodOption(name: "Grilled Chicken Thighs", brand: nil, calories: 320, protein: 36, carbs: 0, fat: 18, fiber: 0, standardServing: 200, unit: "g", estimatedCost: 5.0, preparationTime: 25, preparationNotes: "Marinate and grill until cooked through"),
                FoodOption(name: "Lean Ground Turkey", brand: nil, calories: 280, protein: 38, carbs: 0, fat: 14, fiber: 0, standardServing: 200, unit: "g", estimatedCost: 5.0, preparationTime: 15, preparationNotes: "Season and cook in skillet"),
                FoodOption(name: "Shrimp Stir-Fry", brand: nil, calories: 300, protein: 35, carbs: 15, fat: 12, fiber: 3, standardServing: 300, unit: "g", estimatedCost: 10.0, preparationTime: 15, preparationNotes: "Sauté shrimp with vegetables"),
                // Low Carb
                FoodOption(name: "Pork Chops", brand: nil, calories: 350, protein: 32, carbs: 0, fat: 24, fiber: 0, standardServing: 180, unit: "g", estimatedCost: 6.0, preparationTime: 20, preparationNotes: "Pan sear or grill until 145°F"),
                FoodOption(name: "Baked Cod with Butter", brand: nil, calories: 280, protein: 35, carbs: 0, fat: 14, fiber: 0, standardServing: 200, unit: "g", estimatedCost: 8.0, preparationTime: 18, preparationNotes: "Bake with lemon and herbs"),
                FoodOption(name: "Lamb Chops", brand: nil, calories: 400, protein: 30, carbs: 0, fat: 32, fiber: 0, standardServing: 180, unit: "g", estimatedCost: 14.0, preparationTime: 15, preparationNotes: "Grill with rosemary and garlic"),
                FoodOption(name: "Chicken Wings", brand: nil, calories: 380, protein: 28, carbs: 2, fat: 28, fiber: 0, standardServing: 200, unit: "g", estimatedCost: 6.0, preparationTime: 35, preparationNotes: "Bake at 425°F until crispy"),
                // Mediterranean
                FoodOption(name: "Grilled Sea Bass", brand: nil, calories: 280, protein: 36, carbs: 0, fat: 14, fiber: 0, standardServing: 200, unit: "g", estimatedCost: 14.0, preparationTime: 15, preparationNotes: "Grill with olive oil and lemon"),
                FoodOption(name: "Chicken Souvlaki", brand: nil, calories: 350, protein: 35, carbs: 15, fat: 16, fiber: 2, standardServing: 250, unit: "g", estimatedCost: 7.0, preparationTime: 25, preparationNotes: "Marinated chicken skewers with tzatziki"),
                FoodOption(name: "Stuffed Bell Peppers", brand: nil, calories: 320, protein: 22, carbs: 28, fat: 14, fiber: 5, standardServing: 300, unit: "g", estimatedCost: 5.0, preparationTime: 45, preparationNotes: "Fill with ground meat and rice"),
                FoodOption(name: "Baked Chicken Breast", brand: nil, calories: 280, protein: 42, carbs: 2, fat: 10, fiber: 0, standardServing: 200, unit: "g", estimatedCost: 5.0, preparationTime: 30, preparationNotes: "Season and bake at 400°F"),
                // Vegan
                FoodOption(name: "Chickpea Curry", brand: nil, calories: 350, protein: 14, carbs: 48, fat: 12, fiber: 12, standardServing: 350, unit: "g", estimatedCost: 4.0, preparationTime: 30, preparationNotes: "Simmer chickpeas in coconut curry sauce"),
                FoodOption(name: "Tofu Stir-Fry", brand: nil, calories: 300, protein: 20, carbs: 25, fat: 14, fiber: 5, standardServing: 350, unit: "g", estimatedCost: 5.0, preparationTime: 20, preparationNotes: "Crispy tofu with vegetables and sauce"),
                FoodOption(name: "Black Bean Burgers", brand: nil, calories: 280, protein: 12, carbs: 40, fat: 10, fiber: 10, standardServing: 200, unit: "g", estimatedCost: 4.0, preparationTime: 25, preparationNotes: "Homemade patties with black beans"),
                FoodOption(name: "Vegetable Pasta", brand: nil, calories: 380, protein: 12, carbs: 60, fat: 12, fiber: 8, standardServing: 350, unit: "g", estimatedCost: 4.0, preparationTime: 20, preparationNotes: "Pasta with roasted vegetables and olive oil"),
                // Sides (for variety)
                FoodOption(name: "Steamed Asparagus", brand: nil, calories: 40, protein: 4, carbs: 8, fat: 0.4, fiber: 4, standardServing: 150, unit: "g", estimatedCost: 3.0, preparationTime: 8, preparationNotes: "Steam until tender-crisp"),
                FoodOption(name: "Roasted Brussels Sprouts", brand: nil, calories: 80, protein: 4, carbs: 14, fat: 2, fiber: 6, standardServing: 150, unit: "g", estimatedCost: 3.0, preparationTime: 25, preparationNotes: "Roast at 400°F with olive oil"),
                FoodOption(name: "Cauliflower Mash", brand: nil, calories: 100, protein: 4, carbs: 12, fat: 4, fiber: 4, standardServing: 200, unit: "g", estimatedCost: 2.5, preparationTime: 15, preparationNotes: "Steam and mash with butter"),
                FoodOption(name: "Sweet Potato", brand: nil, calories: 180, protein: 4, carbs: 40, fat: 0.2, fiber: 6, standardServing: 200, unit: "g", estimatedCost: 1.5, preparationTime: 45, preparationNotes: "Bake at 400°F until soft")
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

        // Use built-in foods for instant generation (no API delays)
        var allOptions = getBuiltInFoods(for: mealType)

        // Add user's favorite foods if appropriate
        if let cachedFavorites = getCachedFavoriteFoods() {
            let appropriateFavorites = cachedFavorites.filter { food in
                isFoodAppropriateForMeal(food, mealType: mealType)
            }
            allOptions.append(contentsOf: appropriateFavorites)
        }

        // Filter based on dietary preferences
        switch preferences.dietType {
        case .vegan:
            // Remove all animal products
            let animalProducts = ["Bacon", "Eggs", "Chicken", "Beef", "Fish", "Salmon", "Tuna", "Steak", "Turkey", "Cheese", "Yogurt", "Cottage", "Cream", "Pork", "Shrimp", "Lamb", "Cod", "Jerky", "Pepperoni"]
            allOptions = allOptions.filter { food in
                !animalProducts.contains { food.name.contains($0) }
            }
        case .lowCarb:
            // Prioritize low-carb options (carbs < 15g per serving)
            allOptions = allOptions.filter { food in
                food.carbs < 20 // More lenient for variety
            }
        case .highProtein:
            // Prioritize high-protein options (protein > 20g per serving)
            allOptions = allOptions.filter { food in
                food.protein >= 15 // Include moderate protein options too
            }
        case .mediterranean:
            // Prioritize Mediterranean foods, exclude processed meats
            let processed = ["Bacon", "Sausage", "Pepperoni", "Jerky", "Pork Rinds", "Hot Dog"]
            allOptions = allOptions.filter { food in
                !processed.contains { food.name.contains($0) }
            }
        case .balanced:
            // Keep all options for balanced diet
            break
        }

        // Shuffle to add variety between days
        allOptions.shuffle()

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
