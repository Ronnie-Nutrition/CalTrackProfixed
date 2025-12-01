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
                FoodOption(name: "Scrambled Eggs (4 eggs)", brand: nil, calories: 280, protein: 24, carbs: 2, fat: 20, fiber: 0, standardServing: 200, unit: "g", estimatedCost: 3.0, preparationTime: 10, preparationNotes: "Whisk 4 eggs and cook in pan",
                    detailedInstructions: "1. Crack 4 eggs into a bowl\n2. Add splash of milk and whisk until combined\n3. Season with salt and pepper\n4. Heat butter in non-stick pan over medium-low\n5. Pour in eggs, let set for 30 seconds\n6. Gently push eggs from edge to center\n7. Continue until eggs are soft curds\n8. Remove while slightly wet (they'll continue cooking)\n9. Serve immediately, season to taste",
                    ingredients: ["4 large eggs", "2 tbsp milk or cream", "1 tbsp butter", "Salt and pepper to taste", "Optional: chives, cheese"]),
                FoodOption(name: "Egg White Omelette", brand: nil, calories: 120, protein: 26, carbs: 2, fat: 0.5, fiber: 0, standardServing: 150, unit: "g", estimatedCost: 3.5, preparationTime: 12, preparationNotes: "Use 6 egg whites with vegetables",
                    detailedInstructions: "1. Separate 6 eggs, keeping whites only\n2. Whisk egg whites with salt until frothy\n3. Heat non-stick pan over medium heat\n4. Spray with cooking spray\n5. Pour in egg whites, swirl to cover pan\n6. Add vegetables (spinach, tomatoes, mushrooms)\n7. Cook until edges set (2-3 min)\n8. Fold omelette in half\n9. Slide onto plate and serve",
                    ingredients: ["6 egg whites", "1/2 cup spinach", "1/4 cup diced tomatoes", "1/4 cup mushrooms, sliced", "Cooking spray", "Salt and pepper", "Optional: feta cheese"]),
                FoodOption(name: "Protein Pancakes", brand: nil, calories: 300, protein: 25, carbs: 30, fat: 8, fiber: 3, standardServing: 150, unit: "g", estimatedCost: 4.0, preparationTime: 15, preparationNotes: "Mix protein powder with oats and eggs",
                    detailedInstructions: "1. Blend oats into flour consistency\n2. Mix oat flour, protein powder, baking powder\n3. In separate bowl, mash banana\n4. Add egg and milk to banana\n5. Combine wet and dry ingredients\n6. Heat griddle to medium heat\n7. Pour 1/4 cup batter per pancake\n8. Cook until bubbles form, flip\n9. Cook 1-2 min more until golden\n10. Top with berries and maple syrup",
                    ingredients: ["1/2 cup rolled oats", "1 scoop vanilla protein powder", "1 ripe banana", "1 egg", "1/4 cup milk", "1/2 tsp baking powder", "Berries for topping", "Sugar-free syrup (optional)"]),
                FoodOption(name: "Cottage Cheese Bowl", brand: nil, calories: 220, protein: 28, carbs: 10, fat: 5, fiber: 2, standardServing: 250, unit: "g", estimatedCost: 3.0, preparationTime: 5, preparationNotes: "Top with berries and nuts",
                    detailedInstructions: "1. Scoop cottage cheese into bowl\n2. Wash and dry fresh berries\n3. Arrange berries on top\n4. Sprinkle with chopped almonds or walnuts\n5. Drizzle with honey if desired\n6. Add a pinch of cinnamon\n7. Optional: add chia seeds for extra fiber\n8. Serve immediately",
                    ingredients: ["1 cup low-fat cottage cheese", "1/2 cup mixed berries", "2 tbsp chopped almonds", "1 tsp honey", "Pinch of cinnamon", "1 tsp chia seeds (optional)"]),
                // Low Carb / Keto
                FoodOption(name: "Bacon & Eggs", brand: nil, calories: 350, protein: 24, carbs: 1, fat: 28, fiber: 0, standardServing: 150, unit: "g", estimatedCost: 5.0, preparationTime: 15, preparationNotes: "Fry bacon crispy, cook eggs to preference",
                    detailedInstructions: "1. Place bacon strips in cold pan\n2. Turn heat to medium\n3. Cook bacon, flipping occasionally (8-10 min)\n4. Transfer crispy bacon to paper towels\n5. Drain most bacon fat, leave 1 tbsp\n6. Crack eggs into hot pan\n7. For sunny-side up: cook 3 min undisturbed\n8. For over-easy: flip and cook 30 sec more\n9. Season eggs with salt and pepper\n10. Serve immediately with bacon",
                    ingredients: ["4 strips thick-cut bacon", "2-3 large eggs", "Salt and pepper to taste", "Optional: toast for serving"]),
                FoodOption(name: "Avocado Eggs", brand: nil, calories: 320, protein: 14, carbs: 8, fat: 26, fiber: 7, standardServing: 200, unit: "g", estimatedCost: 4.0, preparationTime: 15, preparationNotes: "Bake eggs in avocado halves",
                    detailedInstructions: "1. Preheat oven to 425°F\n2. Cut avocado in half, remove pit\n3. Scoop out some flesh to enlarge hole\n4. Place avocado halves in muffin tin (for stability)\n5. Crack one egg into each half\n6. Season with salt, pepper, paprika\n7. Bake 15-20 min until egg whites set\n8. Top with everything bagel seasoning\n9. Garnish with fresh cilantro\n10. Serve immediately",
                    ingredients: ["1 ripe avocado", "2 small eggs", "Salt and pepper", "Paprika", "Everything bagel seasoning", "Fresh cilantro for garnish"]),
                FoodOption(name: "Smoked Salmon Plate", brand: nil, calories: 280, protein: 30, carbs: 2, fat: 16, fiber: 0, standardServing: 120, unit: "g", estimatedCost: 8.0, preparationTime: 5, preparationNotes: "Serve with cream cheese and capers",
                    detailedInstructions: "1. Arrange smoked salmon slices on plate\n2. Add dollops of cream cheese\n3. Scatter capers around plate\n4. Slice red onion paper-thin\n5. Add cucumber slices if desired\n6. Garnish with fresh dill\n7. Squeeze fresh lemon juice over salmon\n8. Add freshly cracked black pepper\n9. Serve with everything bagel or crostini",
                    ingredients: ["4 oz smoked salmon", "2 tbsp cream cheese", "1 tbsp capers, drained", "Thin red onion slices", "Fresh dill", "Lemon wedge", "Black pepper", "Everything bagel (optional)"]),
                FoodOption(name: "Sausage & Cheese Scramble", brand: nil, calories: 400, protein: 28, carbs: 3, fat: 32, fiber: 0, standardServing: 180, unit: "g", estimatedCost: 5.0, preparationTime: 12, preparationNotes: "Cook sausage, add eggs and cheese",
                    detailedInstructions: "1. Remove sausage from casing\n2. Brown sausage in skillet, breaking up pieces\n3. Cook until no pink remains (5-6 min)\n4. Whisk eggs in bowl with salt and pepper\n5. Reduce heat to medium-low\n6. Pour eggs over sausage\n7. Gently stir to scramble\n8. When almost set, add shredded cheese\n9. Stir until cheese melts\n10. Serve hot, garnish with chives",
                    ingredients: ["4 oz breakfast sausage", "3 large eggs", "1/4 cup shredded cheddar cheese", "Salt and pepper to taste", "Fresh chives for garnish"]),
                // Balanced / Mediterranean
                FoodOption(name: "Greek Yogurt Parfait", brand: nil, calories: 300, protein: 20, carbs: 35, fat: 8, fiber: 4, standardServing: 250, unit: "g", estimatedCost: 4.0, preparationTime: 5, preparationNotes: "Layer yogurt with granola and honey",
                    detailedInstructions: "1. Choose a clear glass or jar for presentation\n2. Add layer of Greek yogurt (1/3 cup)\n3. Sprinkle layer of granola\n4. Add layer of mixed berries\n5. Repeat layers until jar is full\n6. Drizzle honey on top\n7. Optional: add sliced almonds\n8. Sprinkle with chia seeds\n9. Serve immediately or refrigerate up to 4 hours",
                    ingredients: ["1 cup plain Greek yogurt", "1/4 cup granola", "1/2 cup mixed berries", "1 tbsp honey", "1 tbsp sliced almonds", "1 tsp chia seeds"]),
                FoodOption(name: "Overnight Oats", brand: nil, calories: 350, protein: 12, carbs: 55, fat: 10, fiber: 8, standardServing: 250, unit: "g", estimatedCost: 2.5, preparationTime: 5, preparationNotes: "Prepare night before with milk and chia",
                    detailedInstructions: "1. Combine oats and chia seeds in jar\n2. Add milk and Greek yogurt\n3. Stir in maple syrup or honey\n4. Add vanilla extract\n5. Stir well to combine\n6. Cover and refrigerate overnight (at least 4 hours)\n7. In morning, stir oats\n8. Add desired toppings\n9. Eat cold or microwave 1-2 min\n10. Store in fridge up to 5 days",
                    ingredients: ["1/2 cup rolled oats", "1 tbsp chia seeds", "1/2 cup milk of choice", "1/4 cup Greek yogurt", "1 tbsp maple syrup", "1/2 tsp vanilla extract", "Toppings: berries, banana, nuts"]),
                FoodOption(name: "Shakshuka", brand: nil, calories: 280, protein: 16, carbs: 18, fat: 16, fiber: 4, standardServing: 250, unit: "g", estimatedCost: 4.0, preparationTime: 25, preparationNotes: "Poach eggs in spiced tomato sauce",
                    detailedInstructions: "1. Heat olive oil in oven-safe skillet\n2. Sauté onion until soft (5 min)\n3. Add garlic, cook 30 seconds\n4. Add cumin, paprika, cayenne\n5. Pour in crushed tomatoes\n6. Simmer until thickened (10 min)\n7. Make wells in sauce with spoon\n8. Crack eggs into wells\n9. Cover and cook until whites set (5-8 min)\n10. Top with feta and fresh herbs\n11. Serve with crusty bread",
                    ingredients: ["1 tbsp olive oil", "1/2 onion, diced", "3 cloves garlic, minced", "1 can crushed tomatoes", "1 tsp cumin", "1 tsp paprika", "1/4 tsp cayenne", "3-4 eggs", "Crumbled feta", "Fresh parsley", "Crusty bread"]),
                FoodOption(name: "Whole Grain Toast & Avocado", brand: nil, calories: 320, protein: 10, carbs: 35, fat: 18, fiber: 10, standardServing: 150, unit: "g", estimatedCost: 3.5, preparationTime: 8, preparationNotes: "Toast bread, top with mashed avocado and egg",
                    detailedInstructions: "1. Toast whole grain bread until golden\n2. Cut avocado in half, remove pit\n3. Scoop flesh into bowl\n4. Mash with fork, leave some chunks\n5. Add lemon juice, salt, pepper\n6. Spread avocado on toast\n7. Optional: cook egg sunny-side up\n8. Place egg on top of avocado\n9. Sprinkle with red pepper flakes\n10. Add everything bagel seasoning",
                    ingredients: ["2 slices whole grain bread", "1 ripe avocado", "1 egg (optional)", "Juice of 1/2 lemon", "Salt and pepper", "Red pepper flakes", "Everything bagel seasoning"]),
                // Vegan
                FoodOption(name: "Tofu Scramble", brand: nil, calories: 220, protein: 18, carbs: 8, fat: 14, fiber: 3, standardServing: 200, unit: "g", estimatedCost: 3.0, preparationTime: 15, preparationNotes: "Crumble firm tofu with turmeric and vegetables",
                    detailedInstructions: "1. Press tofu to remove excess water\n2. Heat oil in large skillet\n3. Crumble tofu into pan with hands\n4. Add turmeric for yellow color\n5. Add nutritional yeast for eggy flavor\n6. Season with salt, pepper, garlic powder\n7. Add diced vegetables (bell peppers, spinach)\n8. Cook until vegetables are soft (5-7 min)\n9. Squeeze lime juice over top\n10. Serve with toast or in a wrap",
                    ingredients: ["14 oz firm tofu, pressed", "1 tbsp olive oil", "1/2 tsp turmeric", "2 tbsp nutritional yeast", "1/2 cup bell peppers, diced", "1 cup spinach", "Garlic powder", "Salt and pepper", "Lime juice"]),
                FoodOption(name: "Acai Bowl", brand: nil, calories: 350, protein: 6, carbs: 60, fat: 10, fiber: 8, standardServing: 300, unit: "g", estimatedCost: 6.0, preparationTime: 10, preparationNotes: "Blend acai with banana, top with granola",
                    detailedInstructions: "1. Add frozen acai packet to blender\n2. Add frozen banana and berries\n3. Add small amount of liquid (juice or milk)\n4. Blend until thick and smooth\n5. Consistency should be like soft-serve\n6. Pour into bowl\n7. Arrange toppings in sections\n8. Add granola for crunch\n9. Drizzle with honey or nut butter\n10. Serve immediately (melts fast)",
                    ingredients: ["1 frozen acai packet (100g)", "1 frozen banana", "1/2 cup frozen berries", "1/4 cup almond milk", "1/4 cup granola", "Fresh berries for topping", "1 tbsp coconut flakes", "1 tbsp honey", "1 tbsp almond butter"]),
                FoodOption(name: "Chia Pudding", brand: nil, calories: 280, protein: 8, carbs: 32, fat: 14, fiber: 12, standardServing: 200, unit: "g", estimatedCost: 3.0, preparationTime: 5, preparationNotes: "Mix chia with almond milk overnight",
                    detailedInstructions: "1. Combine chia seeds and milk in jar\n2. Add maple syrup or honey for sweetness\n3. Add vanilla extract\n4. Stir well to prevent clumping\n5. Refrigerate at least 4 hours or overnight\n6. Stir again when set\n7. Add more milk if too thick\n8. Top with fresh fruit\n9. Add nuts or granola for crunch\n10. Can be meal-prepped for the week",
                    ingredients: ["3 tbsp chia seeds", "1 cup almond milk", "1 tbsp maple syrup", "1/2 tsp vanilla extract", "Fresh mango or berries", "Coconut flakes", "Chopped nuts"])
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
                FoodOption(name: "Grilled Ribeye Steak", brand: nil, calories: 450, protein: 42, carbs: 0, fat: 32, fiber: 0, standardServing: 200, unit: "g", estimatedCost: 15.0, preparationTime: 20, preparationNotes: "Season and grill to desired temp",
                    detailedInstructions: "1. Remove steak from fridge 30 min before cooking\n2. Pat dry with paper towels\n3. Season generously with salt and pepper on both sides\n4. Preheat grill or cast iron to high heat\n5. Sear 4-5 min per side for medium-rare (internal temp 130°F)\n6. Rest for 5 minutes before slicing\n7. Optional: Top with herb butter",
                    ingredients: ["8 oz ribeye steak", "1 tsp kosher salt", "1/2 tsp black pepper", "1 tbsp olive oil", "2 tbsp butter (optional)", "Fresh rosemary (optional)"]),
                FoodOption(name: "Baked Salmon Fillet", brand: nil, calories: 350, protein: 40, carbs: 0, fat: 20, fiber: 0, standardServing: 200, unit: "g", estimatedCost: 12.0, preparationTime: 20, preparationNotes: "Bake at 400°F for 15 minutes",
                    detailedInstructions: "1. Preheat oven to 400°F (200°C)\n2. Pat salmon dry and place on lined baking sheet\n3. Drizzle with olive oil and lemon juice\n4. Season with salt, pepper, and dill\n5. Bake for 12-15 minutes until flaky\n6. Internal temp should reach 145°F\n7. Garnish with fresh lemon wedges",
                    ingredients: ["7 oz salmon fillet", "1 tbsp olive oil", "1/2 lemon, juiced", "1/2 tsp salt", "1/4 tsp black pepper", "1 tsp dried dill", "Lemon wedges for serving"]),
                FoodOption(name: "Grilled Chicken Thighs", brand: nil, calories: 320, protein: 36, carbs: 0, fat: 18, fiber: 0, standardServing: 200, unit: "g", estimatedCost: 5.0, preparationTime: 25, preparationNotes: "Marinate and grill until cooked through",
                    detailedInstructions: "1. Combine marinade: olive oil, lemon, garlic, herbs\n2. Marinate thighs for 30 min to 4 hours\n3. Preheat grill to medium-high\n4. Remove chicken, shake off excess marinade\n5. Grill skin-side down first, 6-7 min\n6. Flip and grill 5-6 min more\n7. Internal temp should reach 165°F\n8. Rest 5 minutes before serving",
                    ingredients: ["2 bone-in chicken thighs", "2 tbsp olive oil", "2 cloves garlic, minced", "1 lemon, juiced", "1 tsp oregano", "1/2 tsp paprika", "Salt and pepper to taste"]),
                FoodOption(name: "Lean Ground Turkey", brand: nil, calories: 280, protein: 38, carbs: 0, fat: 14, fiber: 0, standardServing: 200, unit: "g", estimatedCost: 5.0, preparationTime: 15, preparationNotes: "Season and cook in skillet",
                    detailedInstructions: "1. Heat skillet over medium-high heat\n2. Add oil and let it shimmer\n3. Add turkey, breaking into crumbles\n4. Season with salt, pepper, and garlic powder\n5. Cook 8-10 min, stirring occasionally\n6. Ensure no pink remains\n7. Use in tacos, bowls, or as burger patties",
                    ingredients: ["7 oz lean ground turkey (93%)", "1 tsp olive oil", "1/2 tsp garlic powder", "1/2 tsp onion powder", "Salt and pepper to taste", "Optional: taco seasoning"]),
                FoodOption(name: "Shrimp Stir-Fry", brand: nil, calories: 300, protein: 35, carbs: 15, fat: 12, fiber: 3, standardServing: 300, unit: "g", estimatedCost: 10.0, preparationTime: 15, preparationNotes: "Sauté shrimp with vegetables",
                    detailedInstructions: "1. Prep all ingredients before starting\n2. Heat wok or large skillet over high heat\n3. Add 1 tbsp oil, swirl to coat\n4. Add shrimp, cook 2 min per side until pink\n5. Remove shrimp, set aside\n6. Add more oil, stir-fry vegetables 3-4 min\n7. Return shrimp to pan\n8. Add sauce, toss to combine\n9. Serve immediately over rice or noodles",
                    ingredients: ["8 oz large shrimp, peeled and deveined", "1 cup broccoli florets", "1 bell pepper, sliced", "1/2 cup snap peas", "3 cloves garlic, minced", "1 tbsp ginger, minced", "2 tbsp soy sauce", "1 tbsp sesame oil", "1 tsp cornstarch", "2 tbsp vegetable oil"]),
                // Low Carb
                FoodOption(name: "Pork Chops", brand: nil, calories: 350, protein: 32, carbs: 0, fat: 24, fiber: 0, standardServing: 180, unit: "g", estimatedCost: 6.0, preparationTime: 20, preparationNotes: "Pan sear or grill until 145°F",
                    detailedInstructions: "1. Bring chops to room temperature (15 min)\n2. Pat dry and season both sides generously\n3. Heat cast iron skillet over medium-high\n4. Add oil, wait until smoking\n5. Sear chops 4-5 min per side\n6. Add butter, garlic, and thyme in last minute\n7. Baste with melted butter\n8. Rest 5 min before serving\n9. Internal temp should be 145°F",
                    ingredients: ["2 bone-in pork chops (1-inch thick)", "1 tsp salt", "1/2 tsp black pepper", "1 tbsp olive oil", "2 tbsp butter", "3 garlic cloves, smashed", "Fresh thyme sprigs"]),
                FoodOption(name: "Baked Cod with Butter", brand: nil, calories: 280, protein: 35, carbs: 0, fat: 14, fiber: 0, standardServing: 200, unit: "g", estimatedCost: 8.0, preparationTime: 18, preparationNotes: "Bake with lemon and herbs",
                    detailedInstructions: "1. Preheat oven to 400°F\n2. Place cod in baking dish\n3. Season with salt, pepper, and herbs\n4. Top each fillet with butter pats\n5. Squeeze lemon juice over fish\n6. Bake 12-15 min until flaky\n7. Fish should be opaque throughout\n8. Garnish with fresh parsley",
                    ingredients: ["7 oz cod fillet", "2 tbsp butter", "1/2 lemon, juiced", "1/4 tsp paprika", "1 tsp dried parsley", "Salt and pepper to taste", "Fresh parsley for garnish"]),
                FoodOption(name: "Lamb Chops", brand: nil, calories: 400, protein: 30, carbs: 0, fat: 32, fiber: 0, standardServing: 180, unit: "g", estimatedCost: 14.0, preparationTime: 15, preparationNotes: "Grill with rosemary and garlic",
                    detailedInstructions: "1. Bring lamb to room temperature\n2. Rub with olive oil, garlic, and rosemary\n3. Season with salt and pepper\n4. Heat grill or pan to high heat\n5. Sear 3-4 min per side for medium-rare\n6. Let rest 5 minutes\n7. Internal temp: 145°F medium-rare\n8. Serve with mint sauce if desired",
                    ingredients: ["4 lamb rib chops", "2 tbsp olive oil", "4 cloves garlic, minced", "2 tbsp fresh rosemary, chopped", "1 tsp salt", "1/2 tsp black pepper", "Mint sauce (optional)"]),
                FoodOption(name: "Chicken Wings", brand: nil, calories: 380, protein: 28, carbs: 2, fat: 28, fiber: 0, standardServing: 200, unit: "g", estimatedCost: 6.0, preparationTime: 35, preparationNotes: "Bake at 425°F until crispy",
                    detailedInstructions: "1. Pat wings very dry with paper towels\n2. Toss with baking powder and seasonings\n3. Arrange on wire rack over baking sheet\n4. Bake at 425°F for 20 min\n5. Flip wings, bake 20 min more\n6. Wings should be golden and crispy\n7. Toss in sauce of choice\n8. Serve with ranch or blue cheese",
                    ingredients: ["1 lb chicken wings", "1 tbsp baking powder", "1 tsp garlic powder", "1 tsp paprika", "1/2 tsp salt", "1/4 cup hot sauce (optional)", "2 tbsp butter, melted (for sauce)"]),
                // Mediterranean
                FoodOption(name: "Grilled Sea Bass", brand: nil, calories: 280, protein: 36, carbs: 0, fat: 14, fiber: 0, standardServing: 200, unit: "g", estimatedCost: 14.0, preparationTime: 15, preparationNotes: "Grill with olive oil and lemon",
                    detailedInstructions: "1. Score fish skin with diagonal cuts\n2. Rub with olive oil inside and out\n3. Season with salt, pepper, and herbs\n4. Stuff cavity with lemon and herbs\n5. Grill over medium heat 5-6 min per side\n6. Fish is done when flesh is opaque\n7. Drizzle with fresh lemon juice\n8. Serve with Mediterranean salad",
                    ingredients: ["7 oz sea bass fillet", "2 tbsp extra virgin olive oil", "1 lemon, sliced", "Fresh oregano", "Fresh thyme", "2 garlic cloves", "Sea salt and pepper"]),
                FoodOption(name: "Chicken Souvlaki", brand: nil, calories: 350, protein: 35, carbs: 15, fat: 16, fiber: 2, standardServing: 250, unit: "g", estimatedCost: 7.0, preparationTime: 25, preparationNotes: "Marinated chicken skewers with tzatziki",
                    detailedInstructions: "1. Cut chicken into 1-inch cubes\n2. Make marinade: olive oil, lemon, oregano, garlic\n3. Marinate chicken 2 hours minimum\n4. Thread onto soaked wooden skewers\n5. Grill over high heat, turning every 3 min\n6. Total cook time: 12-15 min\n7. Serve with tzatziki and pita\n8. Garnish with fresh parsley",
                    ingredients: ["8 oz chicken breast, cubed", "3 tbsp olive oil", "2 tbsp lemon juice", "1 tsp dried oregano", "3 cloves garlic, minced", "Tzatziki sauce", "Pita bread", "Red onion, sliced"]),
                FoodOption(name: "Stuffed Bell Peppers", brand: nil, calories: 320, protein: 22, carbs: 28, fat: 14, fiber: 5, standardServing: 300, unit: "g", estimatedCost: 5.0, preparationTime: 45, preparationNotes: "Fill with ground meat and rice",
                    detailedInstructions: "1. Preheat oven to 375°F\n2. Cut tops off peppers, remove seeds\n3. Brown ground beef with onions and garlic\n4. Mix meat with cooked rice and tomato sauce\n5. Season with Italian herbs\n6. Stuff peppers with mixture\n7. Top with cheese if desired\n8. Bake 35-40 min until peppers tender\n9. Let cool slightly before serving",
                    ingredients: ["2 large bell peppers", "6 oz lean ground beef", "1/2 cup cooked rice", "1/2 cup tomato sauce", "1/4 cup onion, diced", "2 cloves garlic, minced", "1/4 cup mozzarella cheese", "Italian seasoning"]),
                FoodOption(name: "Baked Chicken Breast", brand: nil, calories: 280, protein: 42, carbs: 2, fat: 10, fiber: 0, standardServing: 200, unit: "g", estimatedCost: 5.0, preparationTime: 30, preparationNotes: "Season and bake at 400°F",
                    detailedInstructions: "1. Preheat oven to 400°F\n2. Pound chicken to even thickness\n3. Brush with olive oil\n4. Season both sides generously\n5. Place in baking dish\n6. Bake 22-25 min until juices run clear\n7. Internal temp should reach 165°F\n8. Rest 5 min before slicing\n9. Slice against the grain",
                    ingredients: ["7 oz boneless chicken breast", "1 tbsp olive oil", "1 tsp paprika", "1/2 tsp garlic powder", "1/2 tsp onion powder", "1/4 tsp cayenne (optional)", "Salt and pepper to taste"]),
                // Vegan
                FoodOption(name: "Chickpea Curry", brand: nil, calories: 350, protein: 14, carbs: 48, fat: 12, fiber: 12, standardServing: 350, unit: "g", estimatedCost: 4.0, preparationTime: 30, preparationNotes: "Simmer chickpeas in coconut curry sauce",
                    detailedInstructions: "1. Sauté onion until soft (5 min)\n2. Add garlic, ginger, curry spices\n3. Cook until fragrant (1 min)\n4. Add tomatoes, coconut milk\n5. Stir in drained chickpeas\n6. Simmer 15-20 min until thickened\n7. Add spinach in last 2 min\n8. Season with salt to taste\n9. Serve over basmati rice with naan",
                    ingredients: ["1 can chickpeas, drained", "1 can coconut milk", "1 can diced tomatoes", "1 onion, diced", "3 cloves garlic", "1 tbsp ginger", "2 tbsp curry powder", "1 tsp garam masala", "Fresh spinach", "Basmati rice for serving"]),
                FoodOption(name: "Tofu Stir-Fry", brand: nil, calories: 300, protein: 20, carbs: 25, fat: 14, fiber: 5, standardServing: 350, unit: "g", estimatedCost: 5.0, preparationTime: 20, preparationNotes: "Crispy tofu with vegetables and sauce",
                    detailedInstructions: "1. Press tofu 15 min, cut into cubes\n2. Toss tofu in cornstarch\n3. Pan-fry tofu until golden (8 min)\n4. Remove tofu, set aside\n5. Stir-fry vegetables in same pan\n6. Make sauce: soy sauce, sesame oil, garlic\n7. Return tofu to pan with sauce\n8. Toss until coated\n9. Serve over rice or noodles",
                    ingredients: ["14 oz extra-firm tofu", "2 tbsp cornstarch", "3 tbsp vegetable oil", "2 cups mixed vegetables", "3 tbsp soy sauce", "1 tbsp sesame oil", "2 cloves garlic, minced", "1 tsp ginger", "Green onions for garnish"]),
                FoodOption(name: "Black Bean Burgers", brand: nil, calories: 280, protein: 12, carbs: 40, fat: 10, fiber: 10, standardServing: 200, unit: "g", estimatedCost: 4.0, preparationTime: 25, preparationNotes: "Homemade patties with black beans",
                    detailedInstructions: "1. Mash black beans, leaving some chunks\n2. Sauté onion and garlic\n3. Mix beans with breadcrumbs and egg\n4. Add spices and sautéed veggies\n5. Form into patties\n6. Chill 15 min (firms them up)\n7. Pan-fry or grill 4-5 min per side\n8. Serve on bun with toppings\n9. Add avocado, tomato, lettuce",
                    ingredients: ["1 can black beans, drained", "1/3 cup breadcrumbs", "1 egg (or flax egg)", "1/4 cup onion, diced", "2 cloves garlic, minced", "1 tsp cumin", "1/2 tsp smoked paprika", "Salt and pepper", "Burger buns and toppings"]),
                FoodOption(name: "Vegetable Pasta", brand: nil, calories: 380, protein: 12, carbs: 60, fat: 12, fiber: 8, standardServing: 350, unit: "g", estimatedCost: 4.0, preparationTime: 20, preparationNotes: "Pasta with roasted vegetables and olive oil",
                    detailedInstructions: "1. Cook pasta according to package\n2. Reserve 1 cup pasta water before draining\n3. Roast vegetables at 425°F (20 min)\n4. Sauté garlic in olive oil\n5. Toss pasta with garlic oil\n6. Add roasted vegetables\n7. Use pasta water to loosen sauce\n8. Season with salt, pepper, red pepper flakes\n9. Top with parmesan and fresh basil",
                    ingredients: ["6 oz pasta (penne or rigatoni)", "2 cups mixed vegetables (zucchini, cherry tomatoes, bell peppers)", "3 tbsp olive oil", "4 cloves garlic, sliced", "Red pepper flakes", "Fresh basil", "Parmesan cheese", "Salt and pepper"]),
                // Sides (for variety)
                FoodOption(name: "Steamed Asparagus", brand: nil, calories: 40, protein: 4, carbs: 8, fat: 0.4, fiber: 4, standardServing: 150, unit: "g", estimatedCost: 3.0, preparationTime: 8, preparationNotes: "Steam until tender-crisp",
                    detailedInstructions: "1. Trim woody ends of asparagus\n2. Bring 1 inch water to boil in pot\n3. Place asparagus in steamer basket\n4. Cover and steam 3-5 min\n5. Asparagus should be bright green\n6. Remove immediately to stop cooking\n7. Drizzle with olive oil and lemon\n8. Season with salt and pepper",
                    ingredients: ["1 bunch asparagus", "1 tbsp olive oil", "1/2 lemon, juiced", "Salt and pepper to taste"]),
                FoodOption(name: "Roasted Brussels Sprouts", brand: nil, calories: 80, protein: 4, carbs: 14, fat: 2, fiber: 6, standardServing: 150, unit: "g", estimatedCost: 3.0, preparationTime: 25, preparationNotes: "Roast at 400°F with olive oil",
                    detailedInstructions: "1. Preheat oven to 400°F\n2. Trim and halve Brussels sprouts\n3. Toss with olive oil, salt, pepper\n4. Spread cut-side down on baking sheet\n5. Roast 20-25 min until crispy\n6. Shake pan halfway through\n7. Optional: drizzle with balsamic\n8. Serve immediately while crispy",
                    ingredients: ["1 lb Brussels sprouts", "2 tbsp olive oil", "1/2 tsp salt", "1/4 tsp black pepper", "2 tbsp balsamic glaze (optional)"]),
                FoodOption(name: "Cauliflower Mash", brand: nil, calories: 100, protein: 4, carbs: 12, fat: 4, fiber: 4, standardServing: 200, unit: "g", estimatedCost: 2.5, preparationTime: 15, preparationNotes: "Steam and mash with butter",
                    detailedInstructions: "1. Cut cauliflower into florets\n2. Steam or boil until very tender (10 min)\n3. Drain well (important for texture)\n4. Add butter and garlic\n5. Mash or blend until smooth\n6. Season with salt and pepper\n7. Add milk for creamier texture\n8. Garnish with chives",
                    ingredients: ["1 medium cauliflower head", "2 tbsp butter", "2 cloves garlic, minced", "2 tbsp milk or cream", "Salt and pepper to taste", "Fresh chives for garnish"]),
                FoodOption(name: "Sweet Potato", brand: nil, calories: 180, protein: 4, carbs: 40, fat: 0.2, fiber: 6, standardServing: 200, unit: "g", estimatedCost: 1.5, preparationTime: 45, preparationNotes: "Bake at 400°F until soft",
                    detailedInstructions: "1. Preheat oven to 400°F\n2. Scrub sweet potato clean\n3. Pierce several times with fork\n4. Place on foil-lined baking sheet\n5. Bake 45-60 min until soft\n6. Test doneness with fork\n7. Cut open and fluff with fork\n8. Top with butter, cinnamon, or savory toppings",
                    ingredients: ["1 medium sweet potato", "1 tbsp butter", "Pinch of cinnamon (optional)", "Salt to taste", "Optional: brown sugar, pecans, or savory toppings"])
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
                    preparationNotes: option.preparationNotes,
                    detailedInstructions: option.detailedInstructions,
                    ingredients: option.ingredients
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
        let mainIngredients = foods.map { $0.name.lowercased() }

        // Generate context-aware suggestions based on meal type and ingredients
        switch mealType {
        case .breakfast:
            if mainIngredients.contains(where: { $0.contains("egg") }) {
                if mainIngredients.contains(where: { $0.contains("bacon") || $0.contains("sausage") }) {
                    suggestions.append(RecipeSuggestion(
                        name: "Classic American Breakfast",
                        description: "Cook protein first, use the rendered fat to fry eggs. Serve everything hot together with toast on the side. Add hot sauce or ketchup to taste.",
                        estimatedTime: 15
                    ))
                } else if mainIngredients.contains(where: { $0.contains("avocado") || $0.contains("toast") }) {
                    suggestions.append(RecipeSuggestion(
                        name: "Avocado Toast Stack",
                        description: "Toast bread until golden, mash avocado with salt and lime. Layer avocado on toast, top with fried or poached egg. Finish with red pepper flakes and everything seasoning.",
                        estimatedTime: 10
                    ))
                } else {
                    suggestions.append(RecipeSuggestion(
                        name: "Protein-Packed Breakfast Plate",
                        description: "Cook eggs to your preference (scrambled, fried, or omelette). Pair with any sides for a balanced meal. Season well with herbs and spices.",
                        estimatedTime: 12
                    ))
                }
            }
            if mainIngredients.contains(where: { $0.contains("oat") || $0.contains("yogurt") || $0.contains("parfait") }) {
                suggestions.append(RecipeSuggestion(
                    name: "Power Bowl Assembly",
                    description: "Layer base ingredient in bowl. Add fresh or frozen berries, drizzle with honey. Top with nuts, seeds, and a sprinkle of cinnamon for extra flavor.",
                    estimatedTime: 5
                ))
            }
            if mainIngredients.contains(where: { $0.contains("pancake") || $0.contains("waffle") }) {
                suggestions.append(RecipeSuggestion(
                    name: "Fluffy Stack Method",
                    description: "Heat griddle to medium (350°F). Pour batter, wait for bubbles to form before flipping. Stack 3-4 high, top with butter, fresh fruit, and warm maple syrup.",
                    estimatedTime: 15
                ))
            }

        case .lunch:
            if mainIngredients.contains(where: { $0.contains("salad") || $0.contains("greens") }) {
                suggestions.append(RecipeSuggestion(
                    name: "Build-Your-Own Salad",
                    description: "Start with greens as base. Add protein in center, arrange toppings around edges. Drizzle dressing just before eating. Toss gently to combine all flavors.",
                    estimatedTime: 10
                ))
            }
            if mainIngredients.contains(where: { $0.contains("chicken") || $0.contains("turkey") }) {
                suggestions.append(RecipeSuggestion(
                    name: "Protein Bowl Assembly",
                    description: "Slice grilled protein against the grain. Arrange over base (rice, greens, or grains). Add vegetables and sauce. For meal prep, keep dressing separate until serving.",
                    estimatedTime: 15
                ))
            }
            if mainIngredients.contains(where: { $0.contains("wrap") || $0.contains("taco") || $0.contains("tortilla") }) {
                suggestions.append(RecipeSuggestion(
                    name: "Perfect Wrap Technique",
                    description: "Warm tortilla for pliability. Layer fillings in center, leaving edges clear. Fold bottom up, then sides in, and roll tightly. Cut diagonally for presentation.",
                    estimatedTime: 8
                ))
            }
            if mainIngredients.contains(where: { $0.contains("soup") }) {
                suggestions.append(RecipeSuggestion(
                    name: "Soup & Sides Combo",
                    description: "Heat soup thoroughly, stirring occasionally. Serve in warm bowl. Pair with crusty bread or crackers. Add fresh herbs and a drizzle of olive oil before serving.",
                    estimatedTime: 10
                ))
            }

        case .dinner:
            if mainIngredients.contains(where: { $0.contains("steak") || $0.contains("beef") }) {
                suggestions.append(RecipeSuggestion(
                    name: "Steakhouse-Style Dinner",
                    description: "Let meat rest at room temperature 30 min before cooking. Sear on high heat for crust, finish to desired doneness. Rest 5 min before slicing. Serve with roasted vegetables.",
                    estimatedTime: 25
                ))
            }
            if mainIngredients.contains(where: { $0.contains("salmon") || $0.contains("fish") || $0.contains("cod") || $0.contains("sea bass") }) {
                suggestions.append(RecipeSuggestion(
                    name: "Mediterranean Fish Dinner",
                    description: "Pat fish dry for crispy skin. Season well, cook skin-side down first. Pair with lemon, olive oil, and fresh herbs. Serve over vegetables or with a light salad.",
                    estimatedTime: 20
                ))
            }
            if mainIngredients.contains(where: { $0.contains("chicken") }) {
                suggestions.append(RecipeSuggestion(
                    name: "One-Pan Chicken Dinner",
                    description: "Arrange chicken and vegetables in single pan. Season everything together. Roast at 400°F until chicken reaches 165°F. Let rest 5 min for juicy results.",
                    estimatedTime: 35
                ))
            }
            if mainIngredients.contains(where: { $0.contains("shrimp") || $0.contains("stir-fry") }) {
                suggestions.append(RecipeSuggestion(
                    name: "Quick Stir-Fry Method",
                    description: "Prep all ingredients before heating wok. Cook protein first, set aside. Stir-fry vegetables quickly on high heat. Return protein, add sauce, toss to combine. Serve immediately.",
                    estimatedTime: 15
                ))
            }
            if mainIngredients.contains(where: { $0.contains("pasta") || $0.contains("spaghetti") }) {
                suggestions.append(RecipeSuggestion(
                    name: "Perfect Pasta Technique",
                    description: "Salt water generously, cook pasta al dente. Reserve pasta water before draining. Toss pasta with sauce and splash of pasta water. Finish with fresh herbs and cheese.",
                    estimatedTime: 20
                ))
            }
            if mainIngredients.contains(where: { $0.contains("curry") || $0.contains("indian") }) {
                suggestions.append(RecipeSuggestion(
                    name: "Curry Night Setup",
                    description: "Toast spices in dry pan for aroma. Build sauce layer by layer. Simmer until flavors meld. Serve over basmati rice with naan bread and cooling yogurt on side.",
                    estimatedTime: 30
                ))
            }

        case .morningSnack, .afternoonSnack:
            if mainIngredients.contains(where: { $0.contains("protein") || $0.contains("shake") }) {
                suggestions.append(RecipeSuggestion(
                    name: "Perfect Protein Shake",
                    description: "Add liquid first, then protein powder. Blend until smooth with no lumps. Add ice for thickness. For extra nutrition, blend in banana or nut butter.",
                    estimatedTime: 3
                ))
            }
            if mainIngredients.contains(where: { $0.contains("nut") || $0.contains("fruit") || $0.contains("apple") }) {
                suggestions.append(RecipeSuggestion(
                    name: "Grab-and-Go Snack Prep",
                    description: "Pre-portion snacks into containers for the week. Keep nuts and dried fruit separate to maintain crunch. Pair with fresh fruit for balanced energy.",
                    estimatedTime: 5
                ))
            }
            if mainIngredients.contains(where: { $0.contains("hummus") || $0.contains("veggie") || $0.contains("celery") }) {
                suggestions.append(RecipeSuggestion(
                    name: "Veggie Snack Plate",
                    description: "Arrange colorful vegetables around dip. Cut vegetables into uniform sticks for easy dipping. Chill plate before serving for maximum crunch.",
                    estimatedTime: 5
                ))
            }
        }

        // Add meal-prep tip if we have multiple components
        if foods.count >= 2 {
            suggestions.append(RecipeSuggestion(
                name: "Meal Prep Tip",
                description: "These components can be prepped ahead. Store protein and vegetables separately. Assemble just before eating for best texture. Most items keep 3-4 days refrigerated.",
                estimatedTime: 5
            ))
        }

        // If no specific suggestions matched, add a general one
        if suggestions.isEmpty {
            suggestions.append(RecipeSuggestion(
                name: "Simple Plating",
                description: "Prepare each component following the instructions above. Arrange on plate with protein as centerpiece. Add sides around the edges. Season to taste and enjoy!",
                estimatedTime: 5
            ))
        }

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
    let detailedInstructions: String?
    let ingredients: [String]?

    init(id: UUID = UUID(), name: String, brand: String?, quantity: Double, unit: String, calories: Double, protein: Double, carbs: Double, fat: Double, fiber: Double, preparationNotes: String?, estimatedPrepTime: Int? = 10, detailedInstructions: String? = nil, ingredients: [String]? = nil) {
        self.id = id
        self.name = name
        self.brand = brand
        self.quantity = quantity
        self.unit = unit
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.fiber = fiber
        self.preparationNotes = preparationNotes
        self.estimatedPrepTime = estimatedPrepTime
        self.detailedInstructions = detailedInstructions
        self.ingredients = ingredients
    }
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
    let detailedInstructions: String?
    let ingredients: [String]?

    init(name: String, brand: String?, calories: Double, protein: Double, carbs: Double, fat: Double, fiber: Double, standardServing: Double, unit: String, estimatedCost: Double, preparationTime: Int, preparationNotes: String?, detailedInstructions: String? = nil, ingredients: [String]? = nil) {
        self.name = name
        self.brand = brand
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.fiber = fiber
        self.standardServing = standardServing
        self.unit = unit
        self.estimatedCost = estimatedCost
        self.preparationTime = preparationTime
        self.preparationNotes = preparationNotes
        self.detailedInstructions = detailedInstructions
        self.ingredients = ingredients
    }
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
