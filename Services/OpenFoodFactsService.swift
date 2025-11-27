import Foundation

// MARK: - Open Food Facts API Service

class OpenFoodFactsService {
    private let baseURL = "https://world.openfoodfacts.org"
    private let userAgent = "CalTrackPro-iOS/1.0"
    
    // MARK: - Search Foods
    
    func search(query: String, filters: SearchFilters?, limit: Int = 50) async -> [EnhancedFoodItem] {
        guard !query.isEmpty else { return [] }
        
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        var urlString = "\(baseURL)/cgi/search.pl"
        
        var queryParams: [String] = [
            "search_terms=\(encodedQuery)",
            "search_simple=1",
            "action=process",
            "json=1",
            "page_size=\(limit)",
            "fields=product_name,brands,categories,nutriments,image_url,code,ingredients_text,allergens,labels"
        ]
        
        // Apply filters
        if let filters = filters {
            if let category = filters.category {
                queryParams.append("tagtype_0=categories")
                queryParams.append("tag_contains_0=contains")
                queryParams.append("tag_0=\(category)")
            }
            
            if let brand = filters.brand {
                queryParams.append("tagtype_1=brands")
                queryParams.append("tag_contains_1=contains")
                queryParams.append("tag_1=\(brand)")
            }
        }
        
        urlString += "?" + queryParams.joined(separator: "&")
        
        guard let url = URL(string: urlString),
              url.scheme == "https" else {
            return []
        }
        
        do {
            let response: OpenFoodFactsSearchResponse = try await performRequest(url: url)
            return convertToEnhancedFoodItems(response.products)
        } catch {
            print("Open Food Facts API Error: \(error)")
            return []
        }
    }
    
    // MARK: - Get Detailed Nutrition
    
    func getDetailedNutrition(foodId: String) async -> DetailedNutrition? {
        let url = URL(string: "\(baseURL)/api/v0/product/\(foodId).json")!
        
        do {
            let response: OpenFoodFactsProductResponse = try await performRequest(url: url)
            
            guard response.status == 1,
                  let product = response.product else {
                return nil
            }
            
            return convertToDetailedNutrition(product)
        } catch {
            print("Open Food Facts Detailed Nutrition Error: \(error)")
            return nil
        }
    }
    
    // MARK: - Barcode Lookup
    
    func lookupBarcode(_ barcode: String) async -> EnhancedFoodItem? {
        let url = URL(string: "\(baseURL)/api/v0/product/\(barcode).json")!
        
        do {
            let response: OpenFoodFactsProductResponse = try await performRequest(url: url)
            
            guard response.status == 1,
                  let product = response.product else {
                return nil
            }
            
            return convertToEnhancedFoodItem(product, barcode: barcode)
        } catch {
            print("Open Food Facts Barcode Lookup Error: \(error)")
            return nil
        }
    }
    
    // MARK: - Private Methods
    
    private func performRequest<T: Codable>(url: URL) async throws -> T {
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
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
            print("Open Food Facts JSON Decode Error: \(error)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Open Food Facts Response: \(jsonString.prefix(500))")
            }
            throw APIError.decodingError
        }
    }
    
    private func convertToEnhancedFoodItems(_ products: [OpenFoodFactsProduct]) -> [EnhancedFoodItem] {
        return products.compactMap { product in
            convertToEnhancedFoodItem(product, barcode: product.code)
        }
    }
    
    private func convertToEnhancedFoodItem(_ product: OpenFoodFactsProduct, barcode: String?) -> EnhancedFoodItem? {
        guard let name = getProductName(product),
              let basicNutrition = extractBasicNutrition(from: product) else {
            return nil
        }
        
        return EnhancedFoodItem(
            foodId: product.code ?? UUID().uuidString,
            name: name,
            brand: extractBrand(from: product),
            category: extractCategory(from: product),
            source: .openFoodFacts,
            qualityScore: calculateOpenFoodFactsQualityScore(product),
            basicNutrition: basicNutrition,
            hasDetailedNutrition: hasDetailedNutritionData(product),
            imageURL: product.imageUrl,
            barcode: barcode,
            ingredients: extractIngredients(from: product),
            allergens: extractAllergens(from: product),
            certifications: extractCertifications(from: product),
            lastUpdated: parseDate(product.lastModifiedT) ?? Date()
        )
    }
    
    private func getProductName(_ product: OpenFoodFactsProduct) -> String? {
        return product.productName ?? product.productNameEn ?? product.genericName
    }
    
    private func extractBasicNutrition(from product: OpenFoodFactsProduct) -> BasicNutrition? {
        guard let nutriments = product.nutriments else { return nil }
        
        let calories = nutriments.energyKcal100g ?? nutriments.energy100g ?? 0
        let protein = nutriments.proteins100g ?? 0
        let carbs = nutriments.carbohydrates100g ?? 0
        let fat = nutriments.fat100g ?? 0
        let fiber = nutriments.fiber100g
        let sugar = nutriments.sugars100g
        let sodium = nutriments.sodium100g
        
        return BasicNutrition(
            calories: calories,
            protein: protein,
            carbohydrates: carbs,
            fat: fat,
            fiber: fiber,
            sugar: sugar,
            sodium: sodium,
            servingSize: determineServingSize(product),
            servingSizeGrams: determineServingSizeGrams(product)
        )
    }
    
    private func extractBrand(from product: OpenFoodFactsProduct) -> String? {
        return product.brands?.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces)
    }
    
    private func extractCategory(from product: OpenFoodFactsProduct) -> String? {
        guard let categories = product.categories else { return nil }
        
        // Get the most specific category (usually the last one)
        let categoryList = categories.components(separatedBy: ",")
        return categoryList.last?.trimmingCharacters(in: .whitespaces).capitalized
    }
    
    private func extractIngredients(from product: OpenFoodFactsProduct) -> [String]? {
        guard let ingredientsText = product.ingredientsText else { return nil }
        
        return ingredientsText
            .components(separatedBy: ",")
            .map { ingredient in
                ingredient
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: "^\\d+\\.?\\d*%?\\s*", with: "", options: .regularExpression) // Remove percentages
                    .capitalized
            }
            .filter { !$0.isEmpty }
    }
    
    private func extractAllergens(from product: OpenFoodFactsProduct) -> [String]? {
        guard let allergensText = product.allergens else { return nil }
        
        return allergensText
            .replacingOccurrences(of: "en:", with: "")
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces).capitalized }
            .filter { !$0.isEmpty }
    }
    
    private func extractCertifications(from product: OpenFoodFactsProduct) -> [String]? {
        guard let labels = product.labels else { return nil }
        
        let certificationKeywords = [
            "organic", "bio", "fair-trade", "non-gmo", "gluten-free", "vegan", "vegetarian",
            "kosher", "halal", "sustainable", "rainforest-alliance", "usda-organic"
        ]
        
        let labelList = labels.lowercased().components(separatedBy: ",")
        
        return certificationKeywords.compactMap { keyword in
            if labelList.contains(where: { $0.contains(keyword) }) {
                return keyword.capitalized
            }
            return nil
        }
    }
    
    private func calculateOpenFoodFactsQualityScore(_ product: OpenFoodFactsProduct) -> Double {
        var score: Double = 0.75 // Base score for Open Food Facts
        
        // Higher score for complete nutrition data
        if let nutriments = product.nutriments {
            var nutrientCount = 0
            
            if nutriments.energyKcal100g != nil { nutrientCount += 1 }
            if nutriments.proteins100g != nil { nutrientCount += 1 }
            if nutriments.carbohydrates100g != nil { nutrientCount += 1 }
            if nutriments.fat100g != nil { nutrientCount += 1 }
            if nutriments.fiber100g != nil { nutrientCount += 1 }
            if nutriments.sugars100g != nil { nutrientCount += 1 }
            if nutriments.sodium100g != nil { nutrientCount += 1 }
            
            score += Double(nutrientCount) * 0.02 // Up to 0.14 bonus
        }
        
        // Higher score for additional data
        if product.ingredientsText != nil { score += 0.05 }
        if product.brands != nil { score += 0.03 }
        if product.imageUrl != nil { score += 0.02 }
        if product.allergens != nil { score += 0.02 }
        
        return min(score, 1.0)
    }
    
    private func hasDetailedNutritionData(_ product: OpenFoodFactsProduct) -> Bool {
        guard let nutriments = product.nutriments else { return false }
        
        // Check if we have more than just basic nutrition
        let basicNutrients = [
            nutriments.energyKcal100g,
            nutriments.proteins100g,
            nutriments.carbohydrates100g,
            nutriments.fat100g
        ].compactMap { $0 }
        
        let totalNutrients = Mirror(reflecting: nutriments).children.count
        
        return basicNutrients.count >= 3 && totalNutrients > 10
    }
    
    private func determineServingSize(_ product: OpenFoodFactsProduct) -> String {
        if let servingSize = product.servingSize {
            return servingSize
        }
        return "100g"
    }
    
    private func determineServingSizeGrams(_ product: OpenFoodFactsProduct) -> Double {
        // Try to extract serving size in grams
        if let servingSize = product.servingSize {
            let cleanSize = servingSize.lowercased()
            
            // Extract number from serving size
            if let range = cleanSize.range(of: "\\d+", options: .regularExpression) {
                let numberString = String(cleanSize[range])
                if let number = Double(numberString) {
                    if cleanSize.contains("g") {
                        return number
                    } else if cleanSize.contains("ml") {
                        return number // Assume 1ml = 1g for liquids
                    }
                }
            }
        }
        
        return 100.0 // Default to 100g
    }
    
    private func parseDate(_ timestamp: Double?) -> Date? {
        guard let timestamp = timestamp else { return nil }
        return Date(timeIntervalSince1970: timestamp)
    }
    
    private func convertToDetailedNutrition(_ product: OpenFoodFactsProduct) -> DetailedNutrition? {
        guard let nutriments = product.nutriments,
              let basicNutrition = extractBasicNutrition(from: product) else {
            return nil
        }
        
        var vitamins: [String: Double] = [:]
        var minerals: [String: Double] = [:]
        
        // Extract vitamins
        if let vitaminC = nutriments.vitaminC100g {
            vitamins["Vitamin C"] = vitaminC
        }
        if let vitaminA = nutriments.vitaminA100g {
            vitamins["Vitamin A"] = vitaminA
        }
        
        // Extract minerals
        if let calcium = nutriments.calcium100g {
            minerals["Calcium"] = calcium
        }
        if let iron = nutriments.iron100g {
            minerals["Iron"] = iron
        }
        if let potassium = nutriments.potassium100g {
            minerals["Potassium"] = potassium
        }
        
        let macronutrients = Macronutrients(
            protein: basicNutrition.protein,
            carbohydrates: basicNutrition.carbohydrates,
            fat: basicNutrition.fat,
            fiber: basicNutrition.fiber,
            sugar: basicNutrition.sugar,
            saturatedFat: nutriments.saturatedFat100g,
            transFat: nutriments.transFat100g,
            cholesterol: nutriments.cholesterol100g,
            sodium: basicNutrition.sodium,
            potassium: nutriments.potassium100g
        )
        
        return DetailedNutrition(
            calories: basicNutrition.calories,
            macronutrients: macronutrients,
            vitamins: vitamins,
            minerals: minerals,
            servingSize: basicNutrition.servingSize,
            servingSizeGrams: basicNutrition.servingSizeGrams
        )
    }
}

// MARK: - Open Food Facts Data Models

struct OpenFoodFactsSearchResponse: Codable {
    let count: Int
    let page: Int
    let pageCount: Int
    let pageSize: Int
    let products: [OpenFoodFactsProduct]
    let skip: Int
}

struct OpenFoodFactsProductResponse: Codable {
    let code: String
    let product: OpenFoodFactsProduct?
    let status: Int
    let statusVerbose: String
}

struct OpenFoodFactsProduct: Codable {
    let code: String?
    let productName: String?
    let productNameEn: String?
    let genericName: String?
    let brands: String?
    let categories: String?
    let ingredientsText: String?
    let allergens: String?
    let labels: String?
    let imageUrl: String?
    let servingSize: String?
    let nutriments: OpenFoodFactsNutriments?
    let lastModifiedT: Double?
    
    private enum CodingKeys: String, CodingKey {
        case code
        case productName = "product_name"
        case productNameEn = "product_name_en"
        case genericName = "generic_name"
        case brands
        case categories
        case ingredientsText = "ingredients_text"
        case allergens
        case labels
        case imageUrl = "image_url"
        case servingSize = "serving_size"
        case nutriments
        case lastModifiedT = "last_modified_t"
    }
}

struct OpenFoodFactsNutriments: Codable {
    let energy100g: Double?
    let energyKcal100g: Double?
    let proteins100g: Double?
    let carbohydrates100g: Double?
    let fat100g: Double?
    let saturatedFat100g: Double?
    let transFat100g: Double?
    let cholesterol100g: Double?
    let fiber100g: Double?
    let sugars100g: Double?
    let sodium100g: Double?
    let potassium100g: Double?
    let calcium100g: Double?
    let iron100g: Double?
    let vitaminA100g: Double?
    let vitaminC100g: Double?
    
    private enum CodingKeys: String, CodingKey {
        case energy100g = "energy_100g"
        case energyKcal100g = "energy-kcal_100g"
        case proteins100g = "proteins_100g"
        case carbohydrates100g = "carbohydrates_100g"
        case fat100g = "fat_100g"
        case saturatedFat100g = "saturated-fat_100g"
        case transFat100g = "trans-fat_100g"
        case cholesterol100g = "cholesterol_100g"
        case fiber100g = "fiber_100g"
        case sugars100g = "sugars_100g"
        case sodium100g = "sodium_100g"
        case potassium100g = "potassium_100g"
        case calcium100g = "calcium_100g"
        case iron100g = "iron_100g"
        case vitaminA100g = "vitamin-a_100g"
        case vitaminC100g = "vitamin-c_100g"
    }
}