import SwiftData
import Foundation

@Model
final class FoodEntry {
    var id = UUID()
    var name: String
    var brand: String?
    var barcode: String?
    var imageData: Data?
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var fiber: Double?
    var sugar: Double?
    var sodium: Double?
    var servingSize: Double
    var servingUnit: String
    var quantity: Double
    var mealType: MealType
    var timestamp: Date
    var userID: String?
    
    enum MealType: String, Codable, CaseIterable {
        case breakfast = "Breakfast"
        case lunch = "Lunch"
        case dinner = "Dinner"
        case snack = "Snack"
    }
    
    init(name: String, calories: Double, protein: Double, carbs: Double, fat: Double,
         servingSize: Double, servingUnit: String, quantity: Double,
         mealType: MealType, timestamp: Date = Date()) {
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.servingSize = servingSize
        self.servingUnit = servingUnit
        self.quantity = quantity
        self.mealType = mealType
        self.timestamp = timestamp
    }
    
    var totalCalories: Double {
        return (calories / servingSize) * quantity
    }
    
    var totalProtein: Double {
        return (protein / servingSize) * quantity
    }
    
    var totalCarbs: Double {
        return (carbs / servingSize) * quantity
    }
    
    var totalFat: Double {
        return (fat / servingSize) * quantity
    }
}