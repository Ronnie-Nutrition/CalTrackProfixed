import SwiftData
import Foundation

@Model
final class Ingredient {
    var id = UUID()
    var name: String
    var amount: Double
    var unit: String
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    
    init(name: String, amount: Double, unit: String,
         calories: Double, protein: Double, carbs: Double, fat: Double) {
        self.id = UUID()
        self.name = name
        self.amount = amount
        self.unit = unit
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
    }
}

@Model
final class Recipe {
    var id = UUID()
    var name: String
    @Relationship(deleteRule: .cascade) var ingredients: [Ingredient]
    var instructions: String
    var servings: Int
    var prepTime: Int // minutes
    var cookTime: Int // minutes
    var imageData: Data?
    var createdAt: Date
    var isFavorite: Bool
    
    init(name: String, ingredients: [Ingredient], instructions: String,
         servings: Int, prepTime: Int, cookTime: Int) {
        self.name = name
        self.ingredients = ingredients
        self.instructions = instructions
        self.servings = servings
        self.prepTime = prepTime
        self.cookTime = cookTime
        self.createdAt = Date()
        self.isFavorite = false
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