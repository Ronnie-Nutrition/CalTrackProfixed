import Foundation

// MARK: - Nutrition API Service
class NutritionAPIService {
    static let shared = NutritionAPIService()
    
    // Edamam API Credentials
    private let appId = "fce081fe"
    private let appKey = "b1ce256719fa10b335802c08577cef51"
    private let baseURL = "https://api.edamam.com/api/food-database/v2"
    
    private init() {}
    
    // MARK: - Food Search
    func searchFood(query: String, completion: @escaping (Result<FoodSearchResponse, Error>) -> Void) {
        guard !query.isEmpty else {
            completion(.failure(APIError.invalidQuery))
            return
        }
        
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "\(baseURL)/parser?app_id=\(appId)&app_key=\(appKey)&ingr=\(encodedQuery)"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(APIError.noData))
                return
            }
            
            do {
                let searchResponse = try JSONDecoder().decode(FoodSearchResponse.self, from: data)
                completion(.success(searchResponse))
            } catch {
                completion(.failure(error))
            }
        }.resume()
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

// MARK: - API Models
struct FoodSearchResponse: Codable {
    let parsed: [ParsedFood]
    let hints: [FoodHint]?
}

struct ParsedFood: Codable {
    let food: FoodItem
}

struct FoodHint: Codable {
    let food: FoodItem
}

struct FoodItem: Codable {
    let foodId: String
    let label: String
    let nutrients: Nutrients
    let category: String?
    let categoryLabel: String?
    let image: String?
}

struct Nutrients: Codable {
    let ENERC_KCAL: Double?  // Calories
    let PROCNT: Double?      // Protein
    let FAT: Double?         // Fat
    let CHOCDF: Double?      // Carbs
    let FIBTG: Double?       // Fiber
    let SUGAR: Double?       // Sugar
    
    // Computed properties for easier access
    var calories: Double { ENERC_KCAL ?? 0 }
    var protein: Double { PROCNT ?? 0 }
    var fat: Double { FAT ?? 0 }
    var carbs: Double { CHOCDF ?? 0 }
    var fiber: Double { FIBTG ?? 0 }
    var sugar: Double { SUGAR ?? 0 }
}

// MARK: - API Errors
enum APIError: LocalizedError {
    case invalidQuery
    case invalidURL
    case noData
    case foodNotFound
    case unauthorized
    case rateLimitExceeded
    
    var errorDescription: String? {
        switch self {
        case .invalidQuery:
            return "Invalid search query"
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .foodNotFound:
            return "Food not found"
        case .unauthorized:
            return "Invalid API credentials"
        case .rateLimitExceeded:
            return "API rate limit exceeded"
        }
    }
}