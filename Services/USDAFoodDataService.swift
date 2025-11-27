import Foundation

// MARK: - USDA FoodData Central API Service

class USDAFoodDataService {
    private let baseURL = "https://api.nal.usda.gov/fdc/v1"
    private let apiKey: String
    
    init() {
        // Load API key from environment or use demo key
        self.apiKey = ProcessInfo.processInfo.environment["USDA_API_KEY"] ?? "DEMO_KEY"
    }
    
    // MARK: - Search Foods
    
    func search(query: String, filters: SearchFilters?, limit: Int = 50) async -> [EnhancedFoodItem] {
        guard !query.isEmpty else { return [] }
        
        let searchRequest = USDASearchRequest(
            query: query,
            dataType: filters?.source == .usda ? ["Foundation", "SR Legacy"] : nil,
            pageSize: limit,
            pageNumber: 1,
            sortBy: "dataType.keyword",
            sortOrder: "asc"
        )
        
        guard let url = buildSearchURL(request: searchRequest) else {
            return []
        }
        
        do {
            let response: USDASearchResponse = try await performRequest(url: url)
            return convertToEnhancedFoodItems(response.foods)
        } catch {
            print("USDA API Error: \(error)")
            return []
        }
    }
    
    // MARK: - Get Detailed Nutrition
    
    func getDetailedNutrition(foodId: String) async -> DetailedNutrition? {
        let url = URL(string: "\(baseURL)/food/\(foodId)")!
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "X-Api-Key")
        
        do {
            let foodDetails: USDAFoodDetails = try await performRequest(url: url)
            return convertToDetailedNutrition(foodDetails)
        } catch {
            print("USDA Detailed Nutrition Error: \(error)")
            return nil
        }
    }
    
    // MARK: - Barcode Lookup
    
    func lookupBarcode(_ barcode: String) async -> EnhancedFoodItem? {
        // USDA doesn't have direct barcode lookup, so we'll search by UPC
        let results = await search(query: barcode, filters: nil, limit: 5)
        
        // Return the first result that might match the barcode
        return results.first { result in
            result.barcode == barcode || result.name.contains(barcode)
        }
    }
    
    // MARK: - Private Methods
    
    private func buildSearchURL(request: USDASearchRequest) -> URL? {
        var components = URLComponents(string: "\(baseURL)/foods/search")!
        
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "query", value: request.query),
            URLQueryItem(name: "pageSize", value: String(request.pageSize)),
            URLQueryItem(name: "pageNumber", value: String(request.pageNumber)),
            URLQueryItem(name: "api_key", value: apiKey)
        ]
        
        if let dataType = request.dataType {
            for type in dataType {
                queryItems.append(URLQueryItem(name: "dataType", value: type))
            }
        }
        
        if let sortBy = request.sortBy {
            queryItems.append(URLQueryItem(name: "sortBy", value: sortBy))
        }
        
        if let sortOrder = request.sortOrder {
            queryItems.append(URLQueryItem(name: "sortOrder", value: sortOrder))
        }
        
        components.queryItems = queryItems
        return components.url
    }
    
    private func performRequest<T: Codable>(url: URL) async throws -> T {
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "X-Api-Key")
        request.timeoutInterval = 15
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.serverError((response as? HTTPURLResponse)?.statusCode ?? 500)
        }
        
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            print("USDA JSON Decode Error: \(error)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("USDA Response: \(jsonString.prefix(500))")
            }
            throw APIError.decodingError
        }
    }
    
    private func convertToEnhancedFoodItems(_ foods: [USDAFood]) -> [EnhancedFoodItem] {
        return foods.compactMap { food in
            guard let basicNutrition = extractBasicNutrition(from: food) else {
                return nil
            }
            
            return EnhancedFoodItem(
                foodId: String(food.fdcId),
                name: food.description,
                brand: extractBrand(from: food),
                category: food.foodCategory?.description,
                source: .usda,
                qualityScore: calculateUSDAQualityScore(food),
                basicNutrition: basicNutrition,
                hasDetailedNutrition: food.foodNutrients?.count ?? 0 > 10,
                imageURL: nil, // USDA doesn't provide images
                barcode: extractBarcode(from: food),
                ingredients: extractIngredients(from: food),
                allergens: nil, // USDA doesn't provide allergen info
                certifications: nil,
                lastUpdated: parseDate(food.publicationDate) ?? Date()
            )
        }
    }
    
    private func extractBasicNutrition(from food: USDAFood) -> BasicNutrition? {
        guard let nutrients = food.foodNutrients else { return nil }
        
        var calories: Double = 0
        var protein: Double = 0
        var carbs: Double = 0
        var fat: Double = 0
        var fiber: Double?
        var sugar: Double?
        var sodium: Double?
        
        for nutrient in nutrients {
            switch nutrient.nutrientId {
            case 1008: // Energy (calories)
                calories = nutrient.value ?? 0
            case 1003: // Protein
                protein = nutrient.value ?? 0
            case 1005: // Total carbs
                carbs = nutrient.value ?? 0
            case 1004: // Total fat
                fat = nutrient.value ?? 0
            case 1079: // Fiber
                fiber = nutrient.value
            case 2000: // Total sugars
                sugar = nutrient.value
            case 1093: // Sodium
                sodium = nutrient.value
            default:
                break
            }
        }
        
        return BasicNutrition(
            calories: calories,
            protein: protein,
            carbohydrates: carbs,
            fat: fat,
            fiber: fiber,
            sugar: sugar,
            sodium: sodium,
            servingSize: "100g",
            servingSizeGrams: 100
        )
    }
    
    private func extractBrand(from food: USDAFood) -> String? {
        return food.brandOwner ?? food.brandName
    }
    
    private func extractBarcode(from food: USDAFood) -> String? {
        return food.gtinUpc
    }
    
    private func extractIngredients(from food: USDAFood) -> [String]? {
        guard let ingredientsString = food.ingredients else { return nil }
        
        return ingredientsString
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces).capitalized }
            .filter { !$0.isEmpty }
    }
    
    private func calculateUSDAQualityScore(_ food: USDAFood) -> Double {
        var score: Double = 0.8 // Base score for USDA
        
        // Higher score for more detailed nutrition data
        let nutrientCount = food.foodNutrients?.count ?? 0
        if nutrientCount > 20 {
            score += 0.15
        } else if nutrientCount > 10 {
            score += 0.1
        }
        
        // Higher score for branded foods (more specific)
        if food.brandOwner != nil || food.brandName != nil {
            score += 0.05
        }
        
        // Higher score for ingredients list
        if food.ingredients != nil {
            score += 0.05
        }
        
        return min(score, 1.0)
    }
    
    private func parseDate(_ dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: dateString)
    }
    
    private func convertToDetailedNutrition(_ foodDetails: USDAFoodDetails) -> DetailedNutrition? {
        guard let nutrients = foodDetails.foodNutrients else { return nil }
        
        var calories: Double = 0
        var macros = Macronutrients(protein: 0, carbohydrates: 0, fat: 0, fiber: nil, sugar: nil)
        var vitamins: [String: Double] = [:]
        var minerals: [String: Double] = [:]
        
        for nutrient in nutrients {
            let value = nutrient.amount ?? 0
            
            switch nutrient.nutrient.id {
            case 1008: calories = value
            case 1003: macros = Macronutrients(protein: value, carbohydrates: macros.carbohydrates, fat: macros.fat, fiber: macros.fiber, sugar: macros.sugar)
            case 1005: macros = Macronutrients(protein: macros.protein, carbohydrates: value, fat: macros.fat, fiber: macros.fiber, sugar: macros.sugar)
            case 1004: macros = Macronutrients(protein: macros.protein, carbohydrates: macros.carbohydrates, fat: value, fiber: macros.fiber, sugar: macros.sugar)
            case 1079: macros = Macronutrients(protein: macros.protein, carbohydrates: macros.carbohydrates, fat: macros.fat, fiber: value, sugar: macros.sugar)
            case 2000: macros = Macronutrients(protein: macros.protein, carbohydrates: macros.carbohydrates, fat: macros.fat, fiber: macros.fiber, sugar: value)
            case 1162: vitamins["Vitamin C"] = value
            case 1087: vitamins["Vitamin A"] = value
            case 1114: vitamins["Vitamin D"] = value
            case 1124: vitamins["Vitamin E"] = value
            case 1185: vitamins["Vitamin K"] = value
            case 1089: minerals["Iron"] = value
            case 1087: minerals["Calcium"] = value
            case 1095: minerals["Zinc"] = value
            case 1089: minerals["Magnesium"] = value
            default: break
            }
        }
        
        return DetailedNutrition(
            calories: calories,
            macronutrients: macros,
            vitamins: vitamins,
            minerals: minerals,
            servingSize: "100g",
            servingSizeGrams: 100
        )
    }
}

// MARK: - USDA Data Models

struct USDASearchRequest {
    let query: String
    let dataType: [String]?
    let pageSize: Int
    let pageNumber: Int
    let sortBy: String?
    let sortOrder: String?
}

struct USDASearchResponse: Codable {
    let totalHits: Int
    let currentPage: Int
    let totalPages: Int
    let foods: [USDAFood]
}

struct USDAFood: Codable {
    let fdcId: Int
    let description: String
    let dataType: String?
    let gtinUpc: String?
    let publishedDate: String?
    let brandOwner: String?
    let brandName: String?
    let ingredients: String?
    let publicationDate: String?
    let foodCategory: USDAFoodCategory?
    let foodNutrients: [USDAFoodNutrient]?
    let servingSize: Double?
    let servingSizeUnit: String?
    let householdServingFullText: String?
}

struct USDAFoodCategory: Codable {
    let id: Int
    let code: String
    let description: String
}

struct USDAFoodNutrient: Codable {
    let nutrientId: Int
    let nutrientName: String?
    let nutrientNumber: String?
    let unitName: String?
    let value: Double?
    let rank: Int?
    let indentLevel: Int?
    let foodNutrientId: Int?
}

struct USDAFoodDetails: Codable {
    let fdcId: Int
    let description: String
    let dataType: String
    let foodNutrients: [USDADetailedNutrient]?
    let ingredients: String?
    let brandOwner: String?
    let brandName: String?
    let servingSize: Double?
    let servingSizeUnit: String?
}

struct USDADetailedNutrient: Codable {
    let type: String
    let nutrient: USDANutrient
    let amount: Double?
}

struct USDANutrient: Codable {
    let id: Int
    let number: String
    let name: String
    let rank: Int?
    let unitName: String
}

// MARK: - USDA API Key Configuration
// Using DEMO_KEY by default - replace with your USDA API key in production
private let usdaAPIKeyDefault: String = {
    if let envKey = ProcessInfo.processInfo.environment["USDA_API_KEY"], !envKey.isEmpty {
        return envKey
    }
    return "DEMO_KEY"
}()