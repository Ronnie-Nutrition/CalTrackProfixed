import Foundation
import Combine
import SwiftUI

// MARK: - Enhanced Food Database Service

@MainActor
class EnhancedFoodDatabase: ObservableObject {
    static let shared = EnhancedFoodDatabase()
    
    @Published var isLoading = false
    @Published var searchResults: [EnhancedFoodItem] = []
    @Published var searchSuggestions: [String] = []
    @Published var lastSearchQuery = ""
    @Published var apiQualityScores: [String: Double] = [:]
    
    // API Services
    private let usdaService = USDAFoodDataService()
    private let openFoodFactsService = OpenFoodFactsService()
    private let edamamService = EdamamService()
    
    // Search configuration
    private let maxResultsPerAPI = 20
    private let searchTimeout: TimeInterval = 10
    private let qualityThreshold: Double = 0.6
    
    // Caching and history
    private var searchCache: [String: [EnhancedFoodItem]] = [:]
    private var popularSearches: [String] = []
    private var nutritionFactsCache: [String: DetailedNutrition] = [:]
    
    private init() {
        loadPopularSearches()
        loadAPIQualityScores()
    }
    
    // MARK: - Main Search Interface
    
    func searchFood(query: String, filters: SearchFilters? = nil) async -> [EnhancedFoodItem] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return [] }
        
        let cleanQuery = preprocessQuery(query)
        lastSearchQuery = cleanQuery
        isLoading = true
        
        defer { isLoading = false }
        
        // Check cache first
        if let cachedResults = searchCache[cleanQuery] {
            await MainActor.run {
                self.searchResults = cachedResults
            }
            return cachedResults
        }
        
        // Perform parallel search across all APIs
        async let usdaResults = searchUSDA(query: cleanQuery, filters: filters)
        async let openFoodResults = searchOpenFoodFacts(query: cleanQuery, filters: filters)
        async let edamamResults = searchEdamam(query: cleanQuery, filters: filters)
        async let localResults = searchLocalDatabase(query: cleanQuery)
        
        // Combine and rank results
        let allResults = await [usdaResults, openFoodResults, edamamResults, localResults].flatMap { $0 }
        let rankedResults = rankAndMergeResults(allResults, query: cleanQuery)
        
        // Cache results
        searchCache[cleanQuery] = rankedResults
        
        // Update popular searches
        updatePopularSearches(cleanQuery)
        
        await MainActor.run {
            self.searchResults = rankedResults
        }
        
        return rankedResults
    }
    
    // MARK: - Smart Search Suggestions
    
    func getSearchSuggestions(for query: String) -> [String] {
        let lowercaseQuery = query.lowercased()
        var suggestions: Set<String> = Set()
        
        // Add popular searches that match
        for search in popularSearches {
            if search.lowercased().contains(lowercaseQuery) {
                suggestions.insert(search)
            }
        }
        
        // Add common food categories
        let foodCategories = [
            "fruits", "vegetables", "meat", "dairy", "grains", "seafood", "snacks", "beverages",
            "chicken", "beef", "pork", "fish", "eggs", "milk", "cheese", "yogurt", "bread",
            "rice", "pasta", "beans", "nuts", "seeds", "berries", "citrus", "leafy greens"
        ]
        
        for category in foodCategories {
            if category.contains(lowercaseQuery) || lowercaseQuery.contains(category) {
                suggestions.insert(category.capitalized)
            }
        }
        
        // Add typo corrections
        let typoCorrections = getTypoCorrections(for: query)
        suggestions.formUnion(typoCorrections)
        
        return Array(suggestions).prefix(8).map { String($0) }
    }
    
    // MARK: - Detailed Nutrition Lookup
    
    func getDetailedNutrition(for foodId: String, source: FoodSource) async -> DetailedNutrition? {
        // Check cache first
        if let cached = nutritionFactsCache[foodId] {
            return cached
        }
        
        var detailedNutrition: DetailedNutrition?
        
        switch source {
        case .usda:
            detailedNutrition = await usdaService.getDetailedNutrition(foodId: foodId)
        case .openFoodFacts:
            detailedNutrition = await openFoodFactsService.getDetailedNutrition(foodId: foodId)
        case .edamam:
            detailedNutrition = await edamamService.getDetailedNutrition(foodId: foodId)
        case .local:
            detailedNutrition = getLocalDetailedNutrition(foodId: foodId)
        }
        
        // Cache the result
        if let nutrition = detailedNutrition {
            nutritionFactsCache[foodId] = nutrition
        }
        
        return detailedNutrition
    }
    
    // MARK: - Barcode Lookup with Multi-API Support
    
    func lookupBarcode(_ barcode: String) async -> EnhancedFoodItem? {
        // Try Open Food Facts first (best for barcodes)
        if let result = await openFoodFactsService.lookupBarcode(barcode) {
            return result
        }
        
        // Try USDA as backup
        if let result = await usdaService.lookupBarcode(barcode) {
            return result
        }
        
        // Finally try Edamam
        return await edamamService.lookupBarcode(barcode)
    }
    
    // MARK: - Private Search Methods
    
    private func searchUSDA(query: String, filters: SearchFilters?) async -> [EnhancedFoodItem] {
        return await usdaService.search(query: query, filters: filters, limit: maxResultsPerAPI)
    }
    
    private func searchOpenFoodFacts(query: String, filters: SearchFilters?) async -> [EnhancedFoodItem] {
        return await openFoodFactsService.search(query: query, filters: filters, limit: maxResultsPerAPI)
    }
    
    private func searchEdamam(query: String, filters: SearchFilters?) async -> [EnhancedFoodItem] {
        return await edamamService.search(query: query, filters: filters, limit: maxResultsPerAPI)
    }
    
    private func searchLocalDatabase(query: String) async -> [EnhancedFoodItem] {
        return LocalFoodDatabase.searchEnhanced(query)
    }
    
    // MARK: - Result Ranking and Merging
    
    private func rankAndMergeResults(_ results: [EnhancedFoodItem], query: String) -> [EnhancedFoodItem] {
        // Group by similar foods
        let groupedResults = Dictionary(grouping: results) { item in
            item.normalizedName
        }
        
        // Select best result from each group
        var bestResults: [EnhancedFoodItem] = []
        
        for (_, group) in groupedResults {
            let sortedGroup = group.sorted { item1, item2 in
                calculateRelevanceScore(item1, query: query) > calculateRelevanceScore(item2, query: query)
            }
            
            if let best = sortedGroup.first {
                bestResults.append(best)
            }
        }
        
        // Sort by overall relevance and quality
        return bestResults.sorted { item1, item2 in
            let score1 = calculateOverallScore(item1, query: query)
            let score2 = calculateOverallScore(item2, query: query)
            return score1 > score2
        }.prefix(50).map { $0 }
    }
    
    private func calculateRelevanceScore(_ item: EnhancedFoodItem, query: String) -> Double {
        let lowercaseQuery = query.lowercased()
        let lowercaseName = item.name.lowercased()
        
        var score: Double = 0
        
        // Exact match
        if lowercaseName == lowercaseQuery {
            score += 10
        }
        
        // Starts with query
        if lowercaseName.hasPrefix(lowercaseQuery) {
            score += 8
        }
        
        // Contains query
        if lowercaseName.contains(lowercaseQuery) {
            score += 5
        }
        
        // Word boundary matches
        let queryWords = lowercaseQuery.components(separatedBy: .whitespaces)
        let nameWords = lowercaseName.components(separatedBy: .whitespaces)
        
        for queryWord in queryWords {
            for nameWord in nameWords {
                if nameWord == queryWord {
                    score += 3
                } else if nameWord.contains(queryWord) {
                    score += 1
                }
            }
        }
        
        return score
    }
    
    private func calculateOverallScore(_ item: EnhancedFoodItem, query: String) -> Double {
        let relevanceScore = calculateRelevanceScore(item, query: query)
        let qualityScore = item.qualityScore
        let sourceScore = getSourceScore(item.source)
        
        return (relevanceScore * 0.5) + (qualityScore * 0.3) + (sourceScore * 0.2)
    }
    
    private func getSourceScore(_ source: FoodSource) -> Double {
        switch source {
        case .usda: return 1.0
        case .openFoodFacts: return 0.8
        case .edamam: return 0.7
        case .local: return 0.6
        }
    }
    
    // MARK: - Query Preprocessing
    
    private func preprocessQuery(_ query: String) -> String {
        var processed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove common prefixes
        let prefixes = ["organic", "raw", "fresh", "cooked", "boiled", "grilled", "fried"]
        for prefix in prefixes {
            if processed.lowercased().hasPrefix(prefix + " ") {
                processed = String(processed.dropFirst(prefix.count + 1))
            }
        }
        
        // Expand abbreviations
        let abbreviations = [
            "app": "apple",
            "choc": "chocolate",
            "veg": "vegetable",
            "prot": "protein"
        ]
        
        for (abbr, full) in abbreviations {
            processed = processed.replacingOccurrences(of: abbr, with: full, options: .caseInsensitive)
        }
        
        return processed
    }
    
    // MARK: - Typo Correction
    
    private func getTypoCorrections(for query: String) -> Set<String> {
        let commonTypos = [
            "bannana": "banana",
            "tomatoe": "tomato",
            "potatoe": "potato",
            "chiken": "chicken",
            "chees": "cheese",
            "bred": "bread",
            "mlik": "milk",
            "aple": "apple",
            "orang": "orange",
            "letuce": "lettuce"
        ]
        
        var corrections: Set<String> = Set()
        
        for (typo, correction) in commonTypos {
            if query.lowercased().contains(typo) {
                corrections.insert(correction)
            }
        }
        
        return corrections
    }
    
    // MARK: - Popular Searches Management
    
    private func loadPopularSearches() {
        if let data = UserDefaults.standard.data(forKey: "popularSearches"),
           let searches = try? JSONDecoder().decode([String].self, from: data) {
            popularSearches = searches
        } else {
            // Default popular searches
            popularSearches = [
                "chicken breast", "banana", "apple", "salmon", "broccoli", "rice",
                "eggs", "milk", "bread", "cheese", "yogurt", "oats", "spinach",
                "sweet potato", "quinoa", "avocado", "almonds", "ground beef"
            ]
        }
    }
    
    private func updatePopularSearches(_ query: String) {
        if !popularSearches.contains(query) {
            popularSearches.append(query)
            if popularSearches.count > 100 {
                popularSearches.removeFirst()
            }
            
            if let encoded = try? JSONEncoder().encode(popularSearches) {
                UserDefaults.standard.set(encoded, forKey: "popularSearches")
            }
        }
    }
    
    // MARK: - API Quality Scoring
    
    private func loadAPIQualityScores() {
        apiQualityScores = [
            "usda": 0.95,
            "openFoodFacts": 0.85,
            "edamam": 0.80,
            "local": 0.70
        ]
    }
    
    private func getLocalDetailedNutrition(foodId: String) -> DetailedNutrition? {
        // Convert local database to detailed nutrition
        guard let localFood = LocalFoodDatabase.foods[foodId] else { return nil }
        
        return DetailedNutrition(
            calories: localFood.calories,
            macronutrients: Macronutrients(
                protein: localFood.protein,
                carbohydrates: localFood.carbs,
                fat: localFood.fat,
                fiber: nil,
                sugar: nil
            ),
            vitamins: [:],
            minerals: [:],
            servingSize: "100g",
            servingSizeGrams: 100
        )
    }
}

// MARK: - Enhanced Food Item

struct EnhancedFoodItem: Identifiable, Codable, Hashable {
    var id = UUID()
    let foodId: String
    let name: String
    let brand: String?
    let category: String?
    let source: FoodSource
    let qualityScore: Double
    let basicNutrition: BasicNutrition
    let hasDetailedNutrition: Bool
    let imageURL: String?
    let barcode: String?
    let ingredients: [String]?
    let allergens: [String]?
    let certifications: [String]?
    let lastUpdated: Date

    private enum CodingKeys: String, CodingKey {
        case foodId, name, brand, category, source, qualityScore
        case basicNutrition, hasDetailedNutrition, imageURL, barcode
        case ingredients, allergens, certifications, lastUpdated
    }

    var normalizedName: String {
        name.lowercased()
            .replacingOccurrences(of: "[^a-z0-9\\s]", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var displayName: String {
        if let brand = brand {
            return "\(name) (\(brand))"
        }
        return name
    }
}

// MARK: - Basic Nutrition

struct BasicNutrition: Codable, Hashable {
    let calories: Double
    let protein: Double
    let carbohydrates: Double
    let fat: Double
    let fiber: Double?
    let sugar: Double?
    let sodium: Double?
    let servingSize: String
    let servingSizeGrams: Double
}

// MARK: - Detailed Nutrition

struct DetailedNutrition: Codable {
    let calories: Double
    let macronutrients: Macronutrients
    let vitamins: [String: Double]
    let minerals: [String: Double]
    let servingSize: String
    let servingSizeGrams: Double
}

struct Macronutrients: Codable {
    let protein: Double
    let carbohydrates: Double
    let fat: Double
    let fiber: Double?
    let sugar: Double?
    let saturatedFat: Double?
    let transFat: Double?
    let cholesterol: Double?
    let sodium: Double?
    let potassium: Double?

    init(protein: Double, carbohydrates: Double, fat: Double, fiber: Double? = nil, sugar: Double? = nil, saturatedFat: Double? = nil, transFat: Double? = nil, cholesterol: Double? = nil, sodium: Double? = nil, potassium: Double? = nil) {
        self.protein = protein
        self.carbohydrates = carbohydrates
        self.fat = fat
        self.fiber = fiber
        self.sugar = sugar
        self.saturatedFat = saturatedFat
        self.transFat = transFat
        self.cholesterol = cholesterol
        self.sodium = sodium
        self.potassium = potassium
    }
}

// MARK: - Food Source

enum FoodSource: String, CaseIterable, Codable {
    case usda = "USDA"
    case openFoodFacts = "Open Food Facts"
    case edamam = "Edamam"
    case local = "Local Database"
    
    var color: Color {
        switch self {
        case .usda: return .blue
        case .openFoodFacts: return .green
        case .edamam: return .orange
        case .local: return .purple
        }
    }
    
    var icon: String {
        switch self {
        case .usda: return "building.columns.fill"
        case .openFoodFacts: return "globe.americas.fill"
        case .edamam: return "leaf.fill"
        case .local: return "house.fill"
        }
    }
}

// MARK: - Search Filters

struct SearchFilters: Codable {
    var category: String?
    var brand: String?
    var minCalories: Double?
    var maxCalories: Double?
    var minProtein: Double?
    var maxProtein: Double?
    var allergenFree: [String]?
    var certifications: [String]?
    var hasNutritionFacts: Bool?
    var source: FoodSource?

    init(
        category: String? = nil,
        brand: String? = nil,
        minCalories: Double? = nil,
        maxCalories: Double? = nil,
        minProtein: Double? = nil,
        maxProtein: Double? = nil,
        allergenFree: [String]? = nil,
        certifications: [String]? = nil,
        hasNutritionFacts: Bool? = nil,
        source: FoodSource? = nil
    ) {
        self.category = category
        self.brand = brand
        self.minCalories = minCalories
        self.maxCalories = maxCalories
        self.minProtein = minProtein
        self.maxProtein = maxProtein
        self.allergenFree = allergenFree
        self.certifications = certifications
        self.hasNutritionFacts = hasNutritionFacts
        self.source = source
    }
}

// MARK: - Local Database Extension

extension LocalFoodDatabase {
    static func searchEnhanced(_ query: String) -> [EnhancedFoodItem] {
        let localResults = searchLocal(query)
        
        return localResults.map { foodItem in
            EnhancedFoodItem(
                foodId: foodItem.foodId,
                name: foodItem.label,
                brand: nil,
                category: foodItem.categoryLabel,
                source: .local,
                qualityScore: 0.7,
                basicNutrition: BasicNutrition(
                    calories: foodItem.nutrients.calories,
                    protein: foodItem.nutrients.protein,
                    carbohydrates: foodItem.nutrients.carbs,
                    fat: foodItem.nutrients.fat,
                    fiber: nil,
                    sugar: nil,
                    sodium: nil,
                    servingSize: "100g",
                    servingSizeGrams: 100
                ),
                hasDetailedNutrition: false,
                imageURL: nil,
                barcode: nil,
                ingredients: nil,
                allergens: nil,
                certifications: nil,
                lastUpdated: Date()
            )
        }
    }
}