import Foundation

// Import API models to ensure types are available
// Types: FoodSearchResponse, FoodItem, ParsedFood, FoodHint, Nutrients

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
                    nutrients: Nutrients(
                        ENERC_KCAL: nutrition.calories,
                        PROCNT: nutrition.protein,
                        FAT: nutrition.fat,
                        CHOCDF: nutrition.carbs,
                        FIBTG: nil,
                        SUGAR: nil
                    ),
                    category: nil,
                    categoryLabel: "Local Database",
                    image: nil
                )
            }
            return nil
        }
    }
}

// MARK: - Nutrition API Service
class NutritionAPIService {
    static let shared = NutritionAPIService()
    
    // Edamam API Credentials - Now loaded securely
    private var appId: String { APIConfig.edamamAppId }
    private var appKey: String { APIConfig.edamamAppKey }
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
        
        // Always use local database - no API needed!
        let localResults = LocalFoodDatabase.searchLocal(query)
        let parsedItems = localResults.map { ParsedFood(food: $0) }
        let response = FoodSearchResponse(parsed: parsedItems, hints: nil)
        
        DispatchQueue.main.async {
            completion(.success(response))
        }
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
            return "Error processing server response"
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