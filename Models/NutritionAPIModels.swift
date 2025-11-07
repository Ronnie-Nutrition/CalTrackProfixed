import Foundation

// MARK: - API Response Models
// These models are used for API responses and should not be confused with SwiftData models

public struct FoodSearchResponse: Codable {
    public let parsed: [ParsedFood]
    public let hints: [FoodHint]?
    
    public init(parsed: [ParsedFood], hints: [FoodHint]? = nil) {
        self.parsed = parsed
        self.hints = hints
    }
}

public struct ParsedFood: Codable {
    public let food: FoodItem
    
    public init(food: FoodItem) {
        self.food = food
    }
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
    
    public init(foodId: String, label: String, nutrients: Nutrients, category: String? = nil, categoryLabel: String? = nil, image: String? = nil) {
        self.foodId = foodId
        self.label = label
        self.nutrients = nutrients
        self.category = category
        self.categoryLabel = categoryLabel
        self.image = image
    }
}

public struct Nutrients: Codable, Equatable {
    public let ENERC_KCAL: Double?  // Calories
    public let PROCNT: Double?      // Protein
    public let FAT: Double?         // Fat
    public let CHOCDF: Double?      // Carbs
    public let FIBTG: Double?       // Fiber
    public let SUGAR: Double?       // Sugar
    
    public init(ENERC_KCAL: Double?, PROCNT: Double?, FAT: Double?, CHOCDF: Double?, FIBTG: Double? = nil, SUGAR: Double? = nil) {
        self.ENERC_KCAL = ENERC_KCAL
        self.PROCNT = PROCNT
        self.FAT = FAT
        self.CHOCDF = CHOCDF
        self.FIBTG = FIBTG
        self.SUGAR = SUGAR
    }
    
    // Computed properties for easier access
    public var calories: Double { ENERC_KCAL ?? 0 }
    public var protein: Double { PROCNT ?? 0 }
    public var fat: Double { FAT ?? 0 }
    public var carbs: Double { CHOCDF ?? 0 }
    public var fiber: Double { FIBTG ?? 0 }
    public var sugar: Double { SUGAR ?? 0 }
}