import Foundation
// Note: API models are defined in Models/NutritionAPIModels.swift

// MARK: - Local Food Database
struct LocalFoodDatabase {
    static let foods: [String: (calories: Double, protein: Double, carbs: Double, fat: Double)] = [
        // Fruits
        "strawberry": (32, 0.7, 7.7, 0.3),
        "strawberries": (32, 0.7, 7.7, 0.3),
        "apple": (52, 0.3, 14, 0.2),
        "banana": (89, 1.1, 23, 0.3),
        "orange": (47, 0.9, 12, 0.1),
        
        // Proteins
        "chicken": (239, 27, 0, 14),
        "chicken breast": (165, 31, 0, 3.6),
        "beef": (250, 26, 0, 15),
        "salmon": (208, 20, 0, 13),
        "eggs": (155, 13, 1.1, 11),
        
        // Vegetables
        "broccoli": (34, 2.8, 7, 0.4),
        "carrot": (41, 0.9, 10, 0.2),
        "spinach": (23, 2.9, 3.6, 0.4),
        
        // Common foods
        "rice": (130, 2.7, 28, 0.3),
        "bread": (265, 9, 49, 3.2),
        "milk": (61, 3.2, 4.8, 3.3),
        "cheese": (402, 25, 1.3, 33),
        
        // Herbalife products (example)
        "herbalife shake": (220, 17, 21, 9),
        "herbalife": (220, 17, 21, 9),
        "protein shake": (200, 20, 10, 5)
    ]
    
    static func searchLocal(_ query: String) -> [FoodItem] {
        let searchTerm = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        return foods.compactMap { (name, nutrition) in
            if name.contains(searchTerm) || searchTerm.contains(name) {
                return FoodItem(
                    foodId: UUID().uuidString,
                    label: name.capitalized,
                    categoryLabel: "Local Database",
                    nutrients: FoodNutrients(
                        calories: nutrition.calories,
                        protein: nutrition.protein,
                        carbs: nutrition.carbs,
                        fat: nutrition.fat
                    )
                )
            }
            return nil
        }
    }
}

// MARK: - Nutrition API Service
class NutritionAPIService {
    static let shared = NutritionAPIService()
    
    // Edamam API Credentials - Now loaded securely from Keychain
    private var appId: String { 
        SecureAPIConfig.edamamAppId
    }
    private var appKey: String { 
        SecureAPIConfig.edamamAppKey
    }
    private let baseURL = "https://api.edamam.com/api/food-database/v2"
    
    private init() {}
    
    // MARK: - Food Search
    func searchFood(query: String, completion: @escaping (Result<FoodSearchResponse, Error>) -> Void) {
        guard !query.isEmpty else {
            DispatchQueue.main.async {
                completion(.failure(APIError.invalidQuery))
            }
            return
        }
        
        // Check network connectivity
        if !NetworkMonitor.shared.isConnected {
            // Offline mode - use cached data
            searchOffline(query: query, completion: completion)
            return
        }
        
        // First try local database
        let localResults = LocalFoodDatabase.searchLocal(query)
        if !localResults.isEmpty {
            let parsedItems = localResults.map { ParsedFoodItem(food: $0) }
            let response = FoodSearchResponse(text: query, parsed: parsedItems, hints: nil)
            DispatchQueue.main.async {
                completion(.success(response))
            }
            return
        }
        
        // Fallback to Open Food Facts API - use US/English endpoint with language filters
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://us.openfoodfacts.org/cgi/search.pl?search_terms=\(encodedQuery)&search_simple=1&action=process&json=1&page_size=50&lc=en&cc=us&tagtype_0=countries&tag_contains_0=contains&tag_0=united-states"
        
        guard let url = URL(string: urlString),
              SecurityConfig.isSecureURL(url) else {
            DispatchQueue.main.async {
                completion(.failure(APIError.invalidURL))
            }
            return
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        // Add security headers
        for (header, value) in SecurityConfig.securityHeaders {
            request.setValue(value, forHTTPHeaderField: header)
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    let nsError = error as NSError
                    
                    // Log error to Crashlytics
                    CrashlyticsManager.shared.recordError(error, additionalInfo: [
                        "api_endpoint": "food_search",
                        "query": query,
                        "error_code": nsError.code
                    ])
                    
                    if nsError.code == NSURLErrorTimedOut {
                        completion(.failure(APIError.timeout))
                    } else if nsError.code == NSURLErrorNotConnectedToInternet {
                        completion(.failure(APIError.noInternetConnection))
                    } else {
                        completion(.failure(error))
                    }
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(APIError.invalidResponse))
                    return
                }
                
                // Log API response
                CrashlyticsManager.shared.logAPIRequest(
                    endpoint: "food_search",
                    method: "GET",
                    statusCode: httpResponse.statusCode
                )
                
                switch httpResponse.statusCode {
                case 200:
                    guard let data = data else {
                        completion(.failure(APIError.noData))
                        return
                    }
                    
                    do {
                        // Parse Open Food Facts response
                        if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let products = jsonObject["products"] as? [[String: Any]] {
                            let searchResponse = self.convertOpenFoodFactsToEdamam(products: products)
                            
                            // Log successful search
                            CrashlyticsManager.shared.logFoodSearch(
                                query: query,
                                resultCount: searchResponse.hints?.count ?? 0
                            )
                            
                            // Cache results for offline use
                            if let hints = searchResponse.hints {
                                let foodItems = hints.map { $0.food }
                                OfflineDataCache.shared.cacheSearchResults(query: query, results: foodItems)
                            }
                            
                            completion(.success(searchResponse))
                        } else {
                            // If no products found
                            let emptyResponse = FoodSearchResponse(text: "", parsed: [], hints: nil)
                            completion(.success(emptyResponse))
                        }
                    } catch {
                        print("JSON Decoding error: \(error)")
                        // For debugging, print the response
                        if let responseString = String(data: data, encoding: .utf8) {
                            print("Response: \(responseString.prefix(500))")
                        }
                        completion(.failure(APIError.decodingError))
                    }
                    
                case 401:
                    completion(.failure(APIError.unauthorized))
                case 429:
                    completion(.failure(APIError.rateLimitExceeded))
                case 400...499:
                    completion(.failure(APIError.clientError(httpResponse.statusCode)))
                case 500...599:
                    completion(.failure(APIError.serverError(httpResponse.statusCode)))
                default:
                    completion(.failure(APIError.unexpectedStatusCode(httpResponse.statusCode)))
                }
            }
        }.resume()
    }
    
    // MARK: - Open Food Facts Converter
    private func convertOpenFoodFactsToEdamam(products: [[String: Any]]) -> FoodSearchResponse {
        let foods = products.compactMap { product -> FoodItem? in
            // Prefer English name, then fall back to generic name
            let englishName = product["product_name_en"] as? String
            let genericName = product["product_name"] as? String

            // Use English name if available and not empty, otherwise use generic
            var name = englishName?.isEmpty == false ? englishName! : (genericName ?? "")

            // Skip if no name or name appears to be non-English
            guard !name.isEmpty else { return nil }

            // Filter out non-English entries (check for common non-ASCII characters)
            if !isLikelyEnglish(name) {
                return nil
            }

            // Clean up the name - remove excessive brand info
            name = cleanProductName(name)

            let nutrients = product["nutriments"] as? [String: Any] ?? [:]
            let calories = nutrients["energy-kcal_100g"] as? Double ?? 0
            let protein = nutrients["proteins_100g"] as? Double ?? 0
            let carbs = nutrients["carbohydrates_100g"] as? Double ?? 0
            let fat = nutrients["fat_100g"] as? Double ?? 0

            // Skip products with no nutrition data
            if calories == 0 && protein == 0 && carbs == 0 && fat == 0 {
                return nil
            }

            let foodNutrients = FoodNutrients(
                calories: calories,
                protein: protein,
                carbs: carbs,
                fat: fat
            )

            // Get brand for display
            let brand = product["brands"] as? String
            let displayName = brand != nil && !brand!.isEmpty ? "\(name) (\(brand!))" : name

            return FoodItem(
                foodId: product["_id"] as? String ?? product["code"] as? String ?? UUID().uuidString,
                label: displayName,
                categoryLabel: brand,
                nutrients: foodNutrients
            )
        }

        let parsedItems = foods.map { food in
            ParsedFoodItem(food: food)
        }

        return FoodSearchResponse(
            text: "",
            parsed: parsedItems,
            hints: nil
        )
    }

    /// Check if text is likely English (filters out foreign language entries)
    private func isLikelyEnglish(_ text: String) -> Bool {
        // Check for common non-English/accented characters
        let nonEnglishChars = CharacterSet(charactersIn: "éèêëàâäôöùûüçñœæøåíìîïóòõúýÿžšđ")
        if text.lowercased().unicodeScalars.contains(where: { nonEnglishChars.contains($0) }) {
            return false
        }

        // Check for non-Latin scripts (Cyrillic, Chinese, Japanese, Korean, Arabic, Hebrew, etc.)
        for scalar in text.unicodeScalars {
            let value = scalar.value
            // Allow ASCII (0-127) and extended Latin (128-591)
            if value > 591 {
                return false
            }
        }

        return true
    }

    /// Clean up product name for better display
    private func cleanProductName(_ name: String) -> String {
        var cleaned = name

        // Remove common suffixes that add clutter
        let suffixesToRemove = [", ", " - ", " / "]
        for suffix in suffixesToRemove {
            if let range = cleaned.range(of: suffix) {
                // Only truncate if the suffix is in the latter half of the string
                let distance = cleaned.distance(from: cleaned.startIndex, to: range.lowerBound)
                if distance > cleaned.count / 2 {
                    cleaned = String(cleaned[..<range.lowerBound])
                }
            }
        }

        // Capitalize first letter of each word
        cleaned = cleaned.capitalized

        return cleaned.trimmingCharacters(in: .whitespaces)
    }
    
    // MARK: - Barcode Lookup
    func lookupBarcode(_ barcode: String, completion: @escaping (Result<FoodItem, Error>) -> Void) {
        let cleanBarcode = barcode.trimmingCharacters(in: .whitespacesAndNewlines)

        // Validate barcode is numeric (real barcodes don't contain letters)
        let numericOnly = cleanBarcode.filter { $0.isNumber }
        guard numericOnly.count >= 8 && numericOnly == cleanBarcode else {
            print("❌ Invalid barcode format: '\(barcode)' - must be 8+ digits, no letters")
            print("💡 This appears to be a SKU code, not a barcode. Try scanning the barcode lines.")
            DispatchQueue.main.async {
                completion(.failure(APIError.invalidBarcode(barcode)))
            }
            return
        }

        // Generate all possible barcode formats to try
        let barcodesToTry = generateBarcodeVariants(numericOnly)
        print("🔍 Barcode lookup: \(numericOnly)")
        print("📝 Will try \(barcodesToTry.count) variants: \(barcodesToTry)")

        // Try Open Food Facts first, then UPC Database as fallback
        tryOpenFoodFactsLookup(barcodes: barcodesToTry, index: 0) { [weak self] result in
            switch result {
            case .success(let foodItem):
                completion(.success(foodItem))
            case .failure:
                // Fallback to UPC Database
                print("🔄 Open Food Facts failed, trying UPC Database...")
                self?.tryUPCDatabaseLookup(barcode: numericOnly, completion: completion)
            }
        }
    }

    /// Generate all possible barcode format variants (UPC-A, EAN-13, etc.)
    private func generateBarcodeVariants(_ barcode: String) -> [String] {
        var variants: [String] = []
        let cleanBarcode = barcode.trimmingCharacters(in: .whitespacesAndNewlines)

        // Add original barcode
        variants.append(cleanBarcode)

        // Pad to 12 digits (UPC-A format)
        if cleanBarcode.count < 12 {
            let upcA = String(repeating: "0", count: 12 - cleanBarcode.count) + cleanBarcode
            if !variants.contains(upcA) {
                variants.append(upcA)
            }
        }

        // Pad to 13 digits (EAN-13 format)
        if cleanBarcode.count < 13 {
            let ean13 = String(repeating: "0", count: 13 - cleanBarcode.count) + cleanBarcode
            if !variants.contains(ean13) {
                variants.append(ean13)
            }
        }

        // Try with single leading zero
        let withZero = "0" + cleanBarcode
        if !variants.contains(withZero) && withZero.count <= 14 {
            variants.append(withZero)
        }

        // Try removing leading zeros if present
        let withoutLeadingZeros = cleanBarcode.drop(while: { $0 == "0" })
        if !withoutLeadingZeros.isEmpty {
            let trimmed = String(withoutLeadingZeros)
            if !variants.contains(trimmed) {
                variants.append(trimmed)
            }
        }

        return variants
    }

    /// Recursively try each barcode variant on Open Food Facts until one succeeds
    private func tryOpenFoodFactsLookup(barcodes: [String], index: Int, completion: @escaping (Result<FoodItem, Error>) -> Void) {
        guard index < barcodes.count else {
            print("❌ All barcode variants exhausted, product not found")
            DispatchQueue.main.async {
                completion(.failure(APIError.foodNotFound))
            }
            return
        }

        let barcode = barcodes[index]
        let urlString = "https://world.openfoodfacts.org/api/v0/product/\(barcode).json"
        print("🔄 Trying variant \(index + 1)/\(barcodes.count): \(barcode)")

        guard let url = URL(string: urlString) else {
            // Try next variant
            tryOpenFoodFactsLookup(barcodes: barcodes, index: index + 1, completion: completion)
            return
        }

        var request = URLRequest(url: url)
        request.setValue("CalTrackPro-iOS/1.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("⚠️ Network error for \(barcode): \(error.localizedDescription)")
                // Try next variant on error
                self?.tryOpenFoodFactsLookup(barcodes: barcodes, index: index + 1, completion: completion)
                return
            }

            guard let data = data else {
                // Try next variant
                self?.tryOpenFoodFactsLookup(barcodes: barcodes, index: index + 1, completion: completion)
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let status = json["status"] as? Int {

                    if status == 1, let product = json["product"] as? [String: Any] {
                        let productName = product["product_name"] as? String ?? "Unknown Product"
                        let brands = product["brands"] as? String
                        let nutriments = product["nutriments"] as? [String: Any] ?? [:]

                        print("✅ Found with barcode \(barcode): \(productName)")

                        let calories = nutriments["energy-kcal_100g"] as? Double ?? nutriments["energy-kcal"] as? Double ?? 0
                        let protein = nutriments["proteins_100g"] as? Double ?? nutriments["proteins"] as? Double ?? 0
                        let fat = nutriments["fat_100g"] as? Double ?? nutriments["fat"] as? Double ?? 0
                        let carbs = nutriments["carbohydrates_100g"] as? Double ?? nutriments["carbohydrates"] as? Double ?? 0
                        let fiber = nutriments["fiber_100g"] as? Double ?? nutriments["fiber"] as? Double

                        let displayName = brands != nil ? "\(productName) (\(brands!))" : productName

                        let foodItem = FoodItem(
                            foodId: barcode,
                            label: displayName,
                            nutrients: Nutrients(
                                ENERC_KCAL: calories,
                                PROCNT: protein,
                                FAT: fat,
                                CHOCDF: carbs,
                                FIBTG: fiber
                            ),
                            category: product["categories"] as? String,
                            categoryLabel: brands,
                            image: product["image_url"] as? String
                        )

                        DispatchQueue.main.async {
                            completion(.success(foodItem))
                        }
                        return
                    } else {
                        print("⚠️ Not found with \(barcode), trying next variant...")
                        // Try next variant
                        self?.tryOpenFoodFactsLookup(barcodes: barcodes, index: index + 1, completion: completion)
                    }
                } else {
                    // Try next variant
                    self?.tryOpenFoodFactsLookup(barcodes: barcodes, index: index + 1, completion: completion)
                }
            } catch {
                // Try next variant
                self?.tryOpenFoodFactsLookup(barcodes: barcodes, index: index + 1, completion: completion)
            }
        }.resume()
    }

    /// Fallback lookup using UPC Database API (free tier: 100/day)
    private func tryUPCDatabaseLookup(barcode: String, completion: @escaping (Result<FoodItem, Error>) -> Void) {
        let urlString = "https://api.upcitemdb.com/prod/trial/lookup?upc=\(barcode)"
        print("🔄 Trying UPC Database: \(barcode)")

        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async {
                completion(.failure(APIError.foodNotFound))
            }
            return
        }

        var request = URLRequest(url: url)
        request.setValue("CalTrackPro-iOS/1.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ UPC Database error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(APIError.foodNotFound))
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(APIError.foodNotFound))
                }
                return
            }

            // Debug response
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📦 UPC Database response: \(String(jsonString.prefix(500)))")
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let items = json["items"] as? [[String: Any]],
                   let firstItem = items.first {

                    let title = firstItem["title"] as? String ?? "Unknown Product"
                    let brand = firstItem["brand"] as? String

                    print("✅ UPC Database found: \(title)")

                    // UPC Database doesn't have nutrition, so we create with placeholder
                    let displayName = brand != nil ? "\(title) (\(brand!))" : title

                    let foodItem = FoodItem(
                        foodId: barcode,
                        label: displayName,
                        nutrients: Nutrients(
                            ENERC_KCAL: 0, // No nutrition data from UPC Database
                            PROCNT: 0,
                            FAT: 0,
                            CHOCDF: 0,
                            FIBTG: nil
                        ),
                        category: firstItem["category"] as? String,
                        categoryLabel: brand,
                        image: (firstItem["images"] as? [String])?.first
                    )

                    DispatchQueue.main.async {
                        completion(.success(foodItem))
                    }
                } else {
                    print("❌ Product not found in UPC Database")
                    DispatchQueue.main.async {
                        completion(.failure(APIError.foodNotFound))
                    }
                }
            } catch {
                print("❌ UPC Database JSON error: \(error)")
                DispatchQueue.main.async {
                    completion(.failure(APIError.foodNotFound))
                }
            }
        }.resume()
    }
    
    // MARK: - Offline Search
    private func searchOffline(query: String, completion: @escaping (Result<FoodSearchResponse, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            // Try cached search results first
            if let cachedResults = OfflineDataCache.shared.getCachedSearchResults(for: query) {
                let parsedItems = cachedResults.map { ParsedFoodItem(food: $0) }
                let response = FoodSearchResponse(text: query, parsed: parsedItems, hints: nil)
                
                DispatchQueue.main.async {
                    completion(.success(response))
                }
                return
            }
            
            // Try local database
            let localResults = LocalFoodDatabase.searchLocal(query)
            
            // Try recent foods
            let recentResults = OfflineDataCache.shared.getRecentFoods(matching: query)
            
            // Combine results
            var allResults = localResults + recentResults
            allResults = Array(Set(allResults)) // Remove duplicates based on foodId
            
            if !allResults.isEmpty {
                let parsedItems = allResults.map { ParsedFoodItem(food: $0) }
                let response = FoodSearchResponse(text: query, parsed: parsedItems, hints: nil)
                
                DispatchQueue.main.async {
                    completion(.success(response))
                }
            } else {
                DispatchQueue.main.async {
                    completion(.failure(APIError.noInternetConnection))
                }
            }
        }
    }
}

// MARK: - API Models are defined in Models/NutritionAPIModels.swift

// MARK: - API Errors
enum APIError: LocalizedError {
    case invalidQuery
    case invalidURL
    case noData
    case foodNotFound
    case invalidBarcode(String)
    case unauthorized
    case rateLimitExceeded
    case timeout
    case noInternetConnection
    case invalidResponse
    case decodingError
    case clientError(Int)
    case serverError(Int)
    case unexpectedStatusCode(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidQuery:
            return "Please enter a valid search query"
        case .invalidURL:
            return "Invalid URL configuration"
        case .noData:
            return "No data received from server"
        case .foodNotFound:
            return "Food item not found"
        case .invalidBarcode(let code):
            return "Invalid barcode: '\(code)'. Barcodes must be numbers only. This looks like a SKU code - try scanning the actual barcode lines."
        case .unauthorized:
            return "Invalid API credentials. Please check your configuration."
        case .rateLimitExceeded:
            return "Too many requests. Please try again later."
        case .timeout:
            return "Request timed out. Please check your connection."
        case .noInternetConnection:
            return "No internet connection. Please check your network."
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError:
            return "No foods found. Try a different search term."
        case .clientError(let code):
            return "Request error (Code: \(code))"
        case .serverError(let code):
            return "Server error (Code: \(code)). Please try again later."
        case .unexpectedStatusCode(let code):
            return "Unexpected error (Code: \(code))"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .noInternetConnection:
            return "Connect to Wi-Fi or cellular data and try again."
        case .timeout:
            return "Try again with a better connection."
        case .unauthorized:
            return "Contact support if this persists."
        case .rateLimitExceeded:
            return "Wait a few minutes before searching again."
        case .invalidBarcode:
            return "Point your camera at the black and white barcode lines, not the SKU text."
        case .foodNotFound:
            return "Try searching for the product by name instead."
        default:
            return nil
        }
    }
}

// Make FoodItem Hashable for Set operations
extension FoodItem: Hashable {
    static func == (lhs: FoodItem, rhs: FoodItem) -> Bool {
        lhs.foodId == rhs.foodId
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(foodId)
    }
}
