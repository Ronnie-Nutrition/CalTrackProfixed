import Foundation

// MARK: - API Response Models
// These models are used for API responses and should not be confused with SwiftData models

public struct FoodSearchResponse: Codable {
    public let parsed: [ParsedFood]
    public let hints: [FoodHint]?
}

public struct ParsedFood: Codable {
    public let food: FoodItem
}

public struct FoodHint: Codable {
    public let food: FoodItem
}

public struct FoodItem: Codable, Equatable {
    public let foodId: String
    public let label: String
    public let nutrients: Nutrients
    public let category: String?
    public let categoryLabel: String?
    public let image: String?
}

public struct Nutrients: Codable, Equatable {
    public let ENERC_KCAL: Double?  // Calories
    public let PROCNT: Double?      // Protein
    public let FAT: Double?         // Fat
    public let CHOCDF: Double?      // Carbs
    public let FIBTG: Double?       // Fiber
    public let SUGAR: Double?       // Sugar
    
    // Computed properties for easier access
    public var calories: Double { ENERC_KCAL ?? 0 }
    public var protein: Double { PROCNT ?? 0 }
    public var fat: Double { FAT ?? 0 }
    public var carbs: Double { CHOCDF ?? 0 }
    public var fiber: Double { FIBTG ?? 0 }
    public var sugar: Double { SUGAR ?? 0 }
}