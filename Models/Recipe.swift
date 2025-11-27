import SwiftData
import Foundation

@Model
final class Recipe {
    var id = UUID()
    var name: String
    var recipeDescription: String
    var ingredients: [RecipeIngredient]
    var instructions: [String]
    var servings: Int
    var cookingTimeMinutes: Int
    var difficulty: Difficulty
    var category: Category
    var imageData: Data?
    var createdAt: Date
    var nutritionPerServing: NutritionInfo?
    
    enum Difficulty: String, Codable, CaseIterable {
        case easy = "easy"
        case medium = "medium"
        case hard = "hard"
    }
    
    enum Category: String, Codable, CaseIterable {
        case breakfast = "breakfast"
        case lunch = "lunch"
        case dinner = "dinner"
        case snack = "snack"
        case dessert = "dessert"
        case main = "main"
        case side = "side"
        case drink = "drink"
        case all = "all"
    }
    
    struct NutritionInfo: Codable {
        let calories: Double
        let protein: Double
        let carbs: Double
        let fat: Double
    }
    
    struct SimpleFoodItem: Codable, Identifiable {
        let id: UUID
        let name: String
        let brand: String?
        let barcode: String?
        let calories: Double
        let protein: Double
        let carbs: Double
        let fat: Double
        let servingSize: Double
        let servingUnit: String

        init(name: String, brand: String? = nil, barcode: String? = nil,
             calories: Double, protein: Double, carbs: Double, fat: Double,
             servingSize: Double, servingUnit: String) {
            self.id = UUID()
            self.name = name
            self.brand = brand
            self.barcode = barcode
            self.calories = calories
            self.protein = protein
            self.carbs = carbs
            self.fat = fat
            self.servingSize = servingSize
            self.servingUnit = servingUnit
        }
    }
    
    struct RecipeIngredient: Codable, Identifiable {
        let id = UUID()
        let foodItem: SimpleFoodItem
        var quantity: Double
        
        var calories: Double {
            (foodItem.calories * quantity) / foodItem.servingSize
        }
        
        var protein: Double {
            (foodItem.protein * quantity) / foodItem.servingSize
        }
        
        var carbs: Double {
            (foodItem.carbs * quantity) / foodItem.servingSize
        }
        
        var fat: Double {
            (foodItem.fat * quantity) / foodItem.servingSize
        }
        
        init(foodItem: SimpleFoodItem, quantity: Double) {
            self.foodItem = foodItem
            self.quantity = quantity
        }
    }
    
    init(name: String, recipeDescription: String, ingredients: [RecipeIngredient], 
         instructions: [String], servings: Int, cookingTimeMinutes: Int,
         difficulty: Difficulty, category: Category, imageData: Data? = nil,
         nutritionPerServing: NutritionInfo? = nil) {
        self.id = UUID()
        self.name = name
        self.recipeDescription = recipeDescription
        self.ingredients = ingredients
        self.instructions = instructions
        self.servings = servings
        self.cookingTimeMinutes = cookingTimeMinutes
        self.difficulty = difficulty
        self.category = category
        self.imageData = imageData
        self.createdAt = Date()
        self.nutritionPerServing = nutritionPerServing
    }
    
    var totalCalories: Double {
        ingredients.reduce(0) { $0 + $1.calories }
    }
    
    var totalProtein: Double {
        ingredients.reduce(0) { $0 + $1.protein }
    }
    
    var totalCarbs: Double {
        ingredients.reduce(0) { $0 + $1.carbs }
    }
    
    var totalFat: Double {
        ingredients.reduce(0) { $0 + $1.fat }
    }
    
    var caloriesPerServing: Double {
        totalCalories / Double(servings)
    }
    
    var proteinPerServing: Double {
        totalProtein / Double(servings)
    }
    
    var carbsPerServing: Double {
        totalCarbs / Double(servings)
    }
    
    var fatPerServing: Double {
        totalFat / Double(servings)
    }
}