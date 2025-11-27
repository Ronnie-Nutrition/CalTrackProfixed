import Foundation

// MARK: - Enhanced Edamam API Service

class EdamamService {
    private let baseURL = "https://api.edamam.com/api/food-database/v2"
    private let nutritionBaseURL = "https://api.edamam.com/api/nutrition-details"
    private var appId: String { ProcessInfo.processInfo.environment["EDAMAM_APP_ID"] ?? "" }
    private var appKey: String { ProcessInfo.processInfo.environment["EDAMAM_APP_KEY"] ?? "" }
    
    // MARK: - Search Foods
    
    func search(query: String, filters: SearchFilters?, limit: Int = 50) async -> [EnhancedFoodItem] {
        guard !query.isEmpty else { return [] }
        
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        var urlComponents = URLComponents(string: "\(baseURL)/parser")!
        
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "app_id", value: appId),
            URLQueryItem(name: "app_key", value: appKey),
            URLQueryItem(name: "ingr", value: encodedQuery),
            URLQueryItem(name: "nutrition-type", value: "cooking")
        ]
        
        // Apply category filter
        if let filters = filters, let category = filters.category {
            queryItems.append(URLQueryItem(name: "category", value: category))
        }
        
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url,
              url.scheme == "https" else {
            return []
        }
        
        do {
            let response: EdamamParserResponse = try await performRequest(url: url)
            
            // If parser response is successful, get food suggestions
            if !response.parsed.isEmpty {
                return await getFoodSuggestions(query: query, limit: limit)
            } else {
                return []
            }
        } catch {
            print("Edamam Parser API Error: \(error)")
            return []
        }
    }
    
    private func getFoodSuggestions(query: String, limit: Int) async -> [EnhancedFoodItem] {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        var urlComponents = URLComponents(string: "\(baseURL)/auto-complete")!
        
        urlComponents.queryItems = [
            URLQueryItem(name: "app_id", value: appId),
            URLQueryItem(name: "app_key", value: appKey),
            URLQueryItem(name: "q", value: encodedQuery),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        
        guard let url = urlComponents.url else { return [] }
        
        do {
            let suggestions: [String] = try await performRequest(url: url)
            
            // Convert suggestions to enhanced food items
            var enhancedItems: [EnhancedFoodItem] = []
            
            for suggestion in suggestions.prefix(limit) {
                if let item = await searchSingleFood(suggestion) {
                    enhancedItems.append(item)
                }
            }
            
            return enhancedItems
        } catch {
            print("Edamam Auto-complete API Error: \(error)")
            return []
        }
    }
    
    private func searchSingleFood(_ foodName: String) async -> EnhancedFoodItem? {
        let encodedFood = foodName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        var urlComponents = URLComponents(string: "\(baseURL)/parser")!
        
        urlComponents.queryItems = [
            URLQueryItem(name: "app_id", value: appId),
            URLQueryItem(name: "app_key", value: appKey),
            URLQueryItem(name: "ingr", value: encodedFood),
            URLQueryItem(name: "nutrition-type", value: "cooking")
        ]
        
        guard let url = urlComponents.url else { return nil }
        
        do {
            let response: EdamamParserResponse = try await performRequest(url: url)
            
            if let firstParsed = response.parsed.first {
                return convertToEnhancedFoodItem(firstParsed.food, originalQuery: foodName)
            } else if let firstHint = response.hints.first {
                return convertToEnhancedFoodItem(firstHint.food, originalQuery: foodName)
            }
            
            return nil
        } catch {
            print("Edamam Single Food Search Error: \(error)")
            return nil
        }
    }
    
    // MARK: - Get Detailed Nutrition
    
    func getDetailedNutrition(foodId: String) async -> DetailedNutrition? {
        // For Edamam, we need to use the Recipe Analysis API with ingredients
        // This is a simplified version - in production, you'd store more complete food data
        
        // Try to get nutrition analysis for a standard serving
        let ingredients = ["\(foodId) 100g"]
        
        do {
            let nutritionData = try await analyzeNutrition(ingredients: ingredients)
            return convertNutritionDataToDetailed(nutritionData)
        } catch {
            print("Edamam Detailed Nutrition Error: \(error)")
            return nil
        }
    }
    
    private func analyzeNutrition(ingredients: [String]) async throws -> EdamamNutritionResponse {
        var urlComponents = URLComponents(string: nutritionBaseURL)!
        
        urlComponents.queryItems = [
            URLQueryItem(name: "app_id", value: appId),
            URLQueryItem(name: "app_key", value: appKey)
        ]
        
        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = EdamamNutritionRequest(ingr: ingredients)
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.serverError((response as? HTTPURLResponse)?.statusCode ?? 500)
        }
        
        return try JSONDecoder().decode(EdamamNutritionResponse.self, from: data)
    }
    
    // MARK: - Barcode Lookup
    
    func lookupBarcode(_ barcode: String) async -> EnhancedFoodItem? {
        // Edamam doesn't have direct barcode lookup, so we'll search by UPC
        let results = await search(query: barcode, filters: nil, limit: 5)
        
        // Return the first result that might match the barcode
        return results.first { result in
            result.name.contains(barcode) || result.foodId.contains(barcode)
        }
    }
    
    // MARK: - Private Methods
    
    private func performRequest<T: Codable>(url: URL) async throws -> T {
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        
        // Basic security headers
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            print("Edamam JSON Decode Error: \(error)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Edamam Response: \(jsonString.prefix(500))")
            }
            throw APIError.decodingError
        }
    }
    
    private func convertToEnhancedFoodItem(_ food: EdamamFood, originalQuery: String) -> EnhancedFoodItem {
        let basicNutrition = extractBasicNutrition(from: food)
        
        return EnhancedFoodItem(
            foodId: food.foodId,
            name: food.label,
            brand: extractBrand(from: food),
            category: food.categoryLabel ?? food.category,
            source: .edamam,
            qualityScore: calculateEdamamQualityScore(food),
            basicNutrition: basicNutrition,
            hasDetailedNutrition: hasDetailedNutrientData(food),
            imageURL: food.image,
            barcode: nil, // Edamam doesn't provide barcodes
            ingredients: nil, // Not available in basic search
            allergens: nil, // Not available in basic search
            certifications: nil,
            lastUpdated: Date()
        )
    }
    
    private func extractBasicNutrition(from food: EdamamFood) -> BasicNutrition {
        let nutrients = food.nutrients
        
        return BasicNutrition(
            calories: nutrients.enerc_kcal ?? 0,
            protein: nutrients.procnt ?? 0,
            carbohydrates: nutrients.chocdf ?? 0,
            fat: nutrients.fat ?? 0,
            fiber: nutrients.fibtg,
            sugar: nutrients.sugar,
            sodium: nutrients.na,
            servingSize: "100g",
            servingSizeGrams: 100
        )
    }
    
    private func extractBrand(from food: EdamamFood) -> String? {
        // Edamam doesn't typically include brand in basic search
        // Brand might be embedded in the label
        let label = food.label.lowercased()
        let brandKeywords = ["organic", "fresh", "raw", "whole foods", "trader joe's"]
        
        for keyword in brandKeywords {
            if label.contains(keyword) {
                return keyword.capitalized
            }
        }
        
        return nil
    }
    
    private func calculateEdamamQualityScore(_ food: EdamamFood) -> Double {
        var score: Double = 0.75 // Base score for Edamam
        
        // Higher score for more complete nutrition data
        let nutrients = food.nutrients
        var nutrientCount = 0
        
        if nutrients.enerc_kcal != nil { nutrientCount += 1 }
        if nutrients.procnt != nil { nutrientCount += 1 }
        if nutrients.chocdf != nil { nutrientCount += 1 }
        if nutrients.fat != nil { nutrientCount += 1 }
        if nutrients.fibtg != nil { nutrientCount += 1 }
        if nutrients.sugar != nil { nutrientCount += 1 }
        if nutrients.na != nil { nutrientCount += 1 }
        if nutrients.ca != nil { nutrientCount += 1 }
        if nutrients.fe != nil { nutrientCount += 1 }
        
        score += Double(nutrientCount) * 0.02 // Up to 0.18 bonus
        
        // Higher score for having an image
        if food.image != nil {
            score += 0.05
        }
        
        // Higher score for specific categories
        if let category = food.category, !category.isEmpty {
            score += 0.02
        }
        
        return min(score, 1.0)
    }
    
    private func hasDetailedNutrientData(_ food: EdamamFood) -> Bool {
        let nutrients = food.nutrients
        let availableNutrients = [
            nutrients.enerc_kcal, nutrients.procnt, nutrients.chocdf, nutrients.fat,
            nutrients.fibtg, nutrients.sugar, nutrients.na, nutrients.ca, nutrients.fe,
            nutrients.k, nutrients.mg, nutrients.vitc, nutrients.vita_iu
        ].compactMap { $0 }
        
        return availableNutrients.count >= 8
    }
    
    private func convertNutritionDataToDetailed(_ nutritionData: EdamamNutritionResponse) -> DetailedNutrition {
        let totalNutrients = nutritionData.totalNutrients
        
        let macronutrients = Macronutrients(
            protein: totalNutrients.procnt?.quantity ?? 0,
            carbohydrates: totalNutrients.chocdf?.quantity ?? 0,
            fat: totalNutrients.fat?.quantity ?? 0,
            fiber: totalNutrients.fibtg?.quantity,
            sugar: totalNutrients.sugar?.quantity,
            saturatedFat: totalNutrients.fasat?.quantity,
            transFat: totalNutrients.fatrn?.quantity,
            cholesterol: totalNutrients.chole?.quantity,
            sodium: totalNutrients.na?.quantity,
            potassium: totalNutrients.k?.quantity
        )
        
        var vitamins: [String: Double] = [:]
        if let vitaminC = totalNutrients.vitc?.quantity {
            vitamins["Vitamin C"] = vitaminC
        }
        if let vitaminA = totalNutrients.vita_iu?.quantity {
            vitamins["Vitamin A"] = vitaminA
        }
        if let vitaminD = totalNutrients.vitd?.quantity {
            vitamins["Vitamin D"] = vitaminD
        }
        
        var minerals: [String: Double] = [:]
        if let calcium = totalNutrients.ca?.quantity {
            minerals["Calcium"] = calcium
        }
        if let iron = totalNutrients.fe?.quantity {
            minerals["Iron"] = iron
        }
        if let magnesium = totalNutrients.mg?.quantity {
            minerals["Magnesium"] = magnesium
        }
        
        return DetailedNutrition(
            calories: totalNutrients.enerc_kcal?.quantity ?? 0,
            macronutrients: macronutrients,
            vitamins: vitamins,
            minerals: minerals,
            servingSize: "100g",
            servingSizeGrams: 100
        )
    }
}

// MARK: - Edamam Data Models

struct EdamamParserResponse: Codable {
    let text: String
    let parsed: [EdamamParsedItem]
    let hints: [EdamamHint]
}

struct EdamamParsedItem: Codable {
    let food: EdamamFood
}

struct EdamamHint: Codable {
    let food: EdamamFood
    let measures: [EdamamMeasure]
}

struct EdamamFood: Codable {
    let foodId: String
    let label: String
    let knownAs: String?
    let nutrients: EdamamNutrients
    let category: String?
    let categoryLabel: String?
    let image: String?
    let brand: String?
    let servingsPerContainer: Double?
}

struct EdamamMeasure: Codable {
    let uri: String
    let label: String
    let weight: Double
}

struct EdamamNutrients: Codable {
    let enerc_kcal: Double? // Energy (calories)
    let procnt: Double?     // Protein
    let chocdf: Double?     // Carbohydrates
    let fat: Double?        // Fat
    let fibtg: Double?      // Fiber
    let sugar: Double?      // Sugar
    let na: Double?         // Sodium
    let ca: Double?         // Calcium
    let fe: Double?         // Iron
    let k: Double?          // Potassium
    let mg: Double?         // Magnesium
    let vitc: Double?       // Vitamin C
    let vita_iu: Double?    // Vitamin A
}

// MARK: - Nutrition Analysis Models

struct EdamamNutritionRequest: Codable {
    let ingr: [String]
}

struct EdamamNutritionResponse: Codable {
    let uri: String
    let calories: Int
    let totalWeight: Double
    let totalNutrients: EdamamTotalNutrients
    let totalDaily: EdamamTotalNutrients
}

struct EdamamTotalNutrients: Codable {
    let enerc_kcal: EdamamNutrient?
    let procnt: EdamamNutrient?
    let chocdf: EdamamNutrient?
    let fat: EdamamNutrient?
    let fibtg: EdamamNutrient?
    let sugar: EdamamNutrient?
    let fasat: EdamamNutrient? // Saturated fat
    let fatrn: EdamamNutrient? // Trans fat
    let chole: EdamamNutrient? // Cholesterol
    let na: EdamamNutrient?    // Sodium
    let k: EdamamNutrient?     // Potassium
    let ca: EdamamNutrient?    // Calcium
    let fe: EdamamNutrient?    // Iron
    let mg: EdamamNutrient?    // Magnesium
    let vitc: EdamamNutrient?  // Vitamin C
    let vita_iu: EdamamNutrient? // Vitamin A
    let vitd: EdamamNutrient?  // Vitamin D
    
    private enum CodingKeys: String, CodingKey {
        case enerc_kcal = "ENERC_KCAL"
        case procnt = "PROCNT"
        case chocdf = "CHOCDF"
        case fat = "FAT"
        case fibtg = "FIBTG"
        case sugar = "SUGAR"
        case fasat = "FASAT"
        case fatrn = "FATRN"
        case chole = "CHOLE"
        case na = "NA"
        case k = "K"
        case ca = "CA"
        case fe = "FE"
        case mg = "MG"
        case vitc = "VITC"
        case vita_iu = "VITA_IU"
        case vitd = "VITD"
    }
}

struct EdamamNutrient: Codable {
    let label: String
    let quantity: Double
    let unit: String
}