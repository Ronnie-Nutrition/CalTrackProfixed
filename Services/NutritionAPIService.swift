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
        
        // Fallback to Open Food Facts API
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://world.openfoodfacts.org/cgi/search.pl?search_terms=\(encodedQuery)&search_simple=1&action=process&json=1&page_size=20"
        
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
            guard let name = product["product_name_en"] as? String ?? product["product_name"] as? String,
                  !name.isEmpty else { return nil }
            
            let nutrients = product["nutriments"] as? [String: Any] ?? [:]
            let calories = nutrients["energy-kcal_100g"] as? Double ?? 0
            let protein = nutrients["proteins_100g"] as? Double ?? 0
            let carbs = nutrients["carbohydrates_100g"] as? Double ?? 0
            let fat = nutrients["fat_100g"] as? Double ?? 0
            
            let foodNutrients = FoodNutrients(
                calories: calories,
                protein: protein,
                carbs: carbs,
                fat: fat
            )
            
            return FoodItem(
                foodId: product["id"] as? String ?? UUID().uuidString,
                label: name,
                categoryLabel: product["categories"] as? String,
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
    
    // MARK: - Barcode Lookup
    func lookupBarcode(_ barcode: String, completion: @escaping (Result<FoodItem, Error>) -> Void) {
        // For now, we'll use the search API
        // Upgrade to Nutritionix or Spoonacular for better barcode support
        searchFood(query: barcode) { result in
            switch result {
            case .success(let response):
                if let firstFood = response.parsed.first?.food {
                    completion(.success(firstFood))
                } else {
                    completion(.failure(APIError.foodNotFound))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
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
