import Foundation
// Note: API models are defined in Models/NutritionAPIModels.swift

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
        
        // Use Open Food Facts API as fallback (free, no API key required)
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://world.openfoodfacts.org/cgi/search.pl?search_terms=\(encodedQuery)&search_simple=1&action=process&json=1&page_size=20"
        
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async {
                completion(.failure(APIError.invalidURL))
            }
            return
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    let nsError = error as NSError
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
                
                switch httpResponse.statusCode {
                case 200:
                    guard let data = data else {
                        completion(.failure(APIError.noData))
                        return
                    }
                    
                    do {
                        // Try to parse as Open Food Facts response first
                        if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let products = jsonObject["products"] as? [[String: Any]] {
                            let searchResponse = self.convertOpenFoodFactsToEdamam(products: products)
                            completion(.success(searchResponse))
                        } else {
                            // Fallback to original Edamam format
                            let searchResponse = try JSONDecoder().decode(FoodSearchResponse.self, from: data)
                            completion(.success(searchResponse))
                        }
                    } catch {
                        print("JSON Decoding error: \(error)")
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