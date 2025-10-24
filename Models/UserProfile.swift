import SwiftData
import Foundation

@Model
final class UserProfile {
    var id = UUID()
    var name: String
    var email: String
    var age: Int
    var gender: Gender
    var height: Double // in cm
    var weight: Double // in kg
    var activityLevel: ActivityLevel
    var goal: Goal
    var dailyCalorieTarget: Double
    var dailyProteinTarget: Double
    var dailyCarbTarget: Double
    var dailyFatTarget: Double
    var createdAt: Date
    var updatedAt: Date
    
    enum Gender: String, Codable, CaseIterable {
        case male = "Male"
        case female = "Female"
        case other = "Other"
    }
    
    enum ActivityLevel: String, Codable, CaseIterable {
        case sedentary = "Sedentary"
        case lightlyActive = "Lightly Active"
        case moderatelyActive = "Moderately Active"
        case veryActive = "Very Active"
        case extraActive = "Extra Active"
        
        var multiplier: Double {
            switch self {
            case .sedentary: return 1.2
            case .lightlyActive: return 1.375
            case .moderatelyActive: return 1.55
            case .veryActive: return 1.725
            case .extraActive: return 1.9
            }
        }
    }
    
    enum Goal: String, Codable, CaseIterable {
        case loseWeight = "Lose Weight"
        case maintainWeight = "Maintain Weight"
        case gainWeight = "Gain Weight"
        case buildMuscle = "Build Muscle"
        
        var calorieAdjustment: Double {
            switch self {
            case .loseWeight: return -500
            case .maintainWeight: return 0
            case .gainWeight: return 500
            case .buildMuscle: return 300
            }
        }
    }
    
    init(name: String, email: String, age: Int, gender: Gender,
         height: Double, weight: Double, activityLevel: ActivityLevel, goal: Goal) {
        self.name = name
        self.email = email
        self.age = age
        self.gender = gender
        self.height = height
        self.weight = weight
        self.activityLevel = activityLevel
        self.goal = goal
        self.createdAt = Date()
        self.updatedAt = Date()
        
        // Calculate initial targets
        let bmr = calculateBMR()
        self.dailyCalorieTarget = (bmr * activityLevel.multiplier) + goal.calorieAdjustment
        
        // Set macro targets based on goal
        switch goal {
        case .buildMuscle:
            self.dailyProteinTarget = weight * 2.2 // 2.2g per kg for muscle building
            self.dailyFatTarget = dailyCalorieTarget * 0.25 / 9 // 25% from fat
            self.dailyCarbTarget = (dailyCalorieTarget - (dailyProteinTarget * 4) - (dailyFatTarget * 9)) / 4
        default:
            self.dailyProteinTarget = weight * 1.6 // 1.6g per kg
            self.dailyFatTarget = dailyCalorieTarget * 0.3 / 9 // 30% from fat
            self.dailyCarbTarget = (dailyCalorieTarget - (dailyProteinTarget * 4) - (dailyFatTarget * 9)) / 4
        }
    }
    
    private func calculateBMR() -> Double {
        if gender == .male {
            return 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * Double(age))
        } else {
            return 447.593 + (9.247 * weight) + (3.098 * height) - (4.330 * Double(age))
        }
    }
}