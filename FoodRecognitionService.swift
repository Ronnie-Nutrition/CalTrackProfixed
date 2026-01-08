//
//  FoodRecognitionService.swift
//  CalTrackPro
//
//  AI-powered food recognition using OpenAI Vision API
//

import Foundation
import Vision
import CoreML
import UIKit

// MARK: - OpenAI Vision Response Models
struct OpenAIVisionResponse: Codable {
    let choices: [OpenAIChoice]
}

struct OpenAIChoice: Codable {
    let message: OpenAIMessage
}

struct OpenAIMessage: Codable {
    let content: String
}

struct OpenAIFoodAnalysis: Codable {
    let foods: [DetectedFood]
}

struct DetectedFood: Codable {
    let name: String
    let confidence: Double
    let estimatedCalories: Int?
    let estimatedProtein: Double?
    let estimatedCarbs: Double?
    let estimatedFat: Double?
    let servingSize: String?
}

// MARK: - Food Recognition Result
struct FoodRecognitionResult: Identifiable {
    let id = UUID()
    let name: String
    let confidence: Float
    let calories: Int?
    let protein: Double?
    let carbs: Double?
    let fat: Double?
    let servingSize: String?
}

// MARK: - Food Recognition Error
enum FoodRecognitionError: Error, LocalizedError {
    case modelNotLoaded
    case imageProcessingFailed
    case noResultsFound
    case networkError(String)
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .modelNotLoaded:
            return "Food recognition model could not be loaded"
        case .imageProcessingFailed:
            return "Failed to process the image"
        case .noResultsFound:
            return "No food items detected in the image"
        case .networkError(let message):
            return "Network error: \(message)"
        case .invalidResponse:
            return "Invalid response from nutrition service"
        }
    }
}

// MARK: - Food Recognition Service
@MainActor
class FoodRecognitionService: ObservableObject {

    // MARK: - Published Properties
    @Published var isProcessing = false
    @Published var lastResults: [FoodRecognitionResult] = []
    @Published var errorMessage: String?

    // MARK: - Private Properties
    private var visionModel: VNCoreMLModel?
    private let nutritionService = NutritionAPIService()

    // OpenAI Configuration
    private let openAIEndpoint = "https://api.openai.com/v1/chat/completions"
    private var openAIAPIKey: String {
        // Try to get from Keychain first, then environment, then use demo key
        if let key = KeychainManager.shared.get(key: "openai_api_key"), !key.isEmpty {
            return key
        }
        return ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
    }

    private var useOpenAI: Bool {
        !openAIAPIKey.isEmpty
    }

    // MARK: - Food Vocabulary (for filtering non-food results)
    private let foodKeywords: Set<String> = [
        // Proteins
        "chicken", "beef", "pork", "fish", "salmon", "tuna", "shrimp", "lobster", "crab",
        "steak", "meat", "bacon", "sausage", "ham", "turkey", "duck", "lamb", "egg", "eggs",
        // Dairy
        "cheese", "milk", "yogurt", "butter", "cream", "ice cream",
        // Grains & Breads
        "bread", "rice", "pasta", "noodle", "cereal", "oatmeal", "pancake", "waffle",
        "toast", "bagel", "muffin", "croissant", "biscuit", "cracker", "pretzel",
        // Fruits
        "apple", "banana", "orange", "grape", "strawberry", "blueberry", "raspberry",
        "watermelon", "melon", "pineapple", "mango", "peach", "pear", "cherry", "lemon",
        "lime", "kiwi", "coconut", "avocado", "tomato", "fruit",
        // Vegetables
        "carrot", "broccoli", "spinach", "lettuce", "salad", "potato", "corn", "pea",
        "bean", "onion", "garlic", "pepper", "cucumber", "celery", "cabbage", "cauliflower",
        "asparagus", "mushroom", "vegetable", "zucchini", "squash", "eggplant",
        // Snacks & Desserts
        "cookie", "cake", "pie", "donut", "doughnut", "candy", "chocolate", "brownie",
        "cupcake", "pastry", "chips", "popcorn", "nuts", "peanut", "almond",
        // Meals
        "pizza", "burger", "hamburger", "sandwich", "taco", "burrito", "sushi", "soup",
        "salad", "stew", "curry", "casserole", "lasagna", "wrap", "hot dog", "hotdog",
        // Beverages
        "coffee", "tea", "juice", "soda", "smoothie", "shake", "wine", "beer",
        // Other foods
        "sauce", "dressing", "syrup", "honey", "jam", "jelly", "peanut butter",
        "hummus", "guacamole", "salsa", "dip", "spread", "condiment",
        "protein bar", "granola", "snack", "food", "meal", "dish", "plate"
    ]

    // MARK: - Initialization
    init() {
        loadModel()
    }

    // MARK: - API Key Configuration
    static func setOpenAIAPIKey(_ key: String) {
        KeychainManager.shared.set(value: key, forKey: "openai_api_key")
    }

    static func getOpenAIAPIKey() -> String? {
        KeychainManager.shared.get(key: "openai_api_key")
    }

    static func hasOpenAIAPIKey() -> Bool {
        if let key = getOpenAIAPIKey(), !key.isEmpty {
            return true
        }
        if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !envKey.isEmpty {
            return true
        }
        return false
    }

    static func clearOpenAIAPIKey() {
        KeychainManager.shared.delete(key: "openai_api_key")
    }
    
    // MARK: - Model Loading
    private func loadModel() {
        // Option 1: Use Apple's built-in Vision for image classification
        // This works without a custom model for basic food detection
        
        // Option 2: Load custom CoreML model if available
        // Uncomment and replace with your model name:
        /*
        do {
            let config = MLModelConfiguration()
            config.computeUnits = .all
            let model = try FoodClassifier(configuration: config)
            visionModel = try VNCoreMLModel(for: model.model)
        } catch {
            print("Failed to load ML model: \(error)")
        }
        */
    }
    
    // MARK: - Image Recognition
    func recognizeFood(from image: UIImage) async throws -> [FoodRecognitionResult] {
        isProcessing = true
        errorMessage = nil

        defer { isProcessing = false }

        // Use OpenAI Vision if API key is available
        if useOpenAI {
            print("🤖 Using OpenAI Vision API for food recognition")
            let results = try await performOpenAIVisionRecognition(image: image)
            lastResults = results
            return results
        }

        // Fallback to Apple Vision framework
        print("📱 Using Apple Vision framework (no OpenAI API key configured)")
        guard let cgImage = image.cgImage else {
            throw FoodRecognitionError.imageProcessingFailed
        }

        // Use Vision framework for classification
        let results = try await performVisionClassification(on: cgImage)

        // Enrich results with nutrition data
        var enrichedResults: [FoodRecognitionResult] = []
        for result in results {
            if let nutritionData = try? await nutritionService.fetchNutrition(for: result.name) {
                enrichedResults.append(FoodRecognitionResult(
                    name: result.name,
                    confidence: result.confidence,
                    calories: nutritionData.calories,
                    protein: nutritionData.protein,
                    carbs: nutritionData.carbs,
                    fat: nutritionData.fat,
                    servingSize: nutritionData.servingSize
                ))
            } else {
                enrichedResults.append(result)
            }
        }

        lastResults = enrichedResults
        return enrichedResults
    }

    // MARK: - OpenAI Vision Recognition
    private func performOpenAIVisionRecognition(image: UIImage) async throws -> [FoodRecognitionResult] {
        // Resize image to reduce API costs (max 512px on longest side)
        let resizedImage = resizeImage(image, maxDimension: 512)

        // Convert to base64
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.8) else {
            throw FoodRecognitionError.imageProcessingFailed
        }
        let base64Image = imageData.base64EncodedString()

        // Create request
        guard let url = URL(string: openAIEndpoint) else {
            throw FoodRecognitionError.networkError("Invalid URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(openAIAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Create the prompt for food analysis - Enhanced for better accuracy
        let prompt = """
        You are an expert nutritionist analyzing a food image. Carefully examine this image and identify ALL individual food items visible.

        IMPORTANT GUIDELINES:
        - Identify each distinct food item separately (e.g., on a tray, identify each item: "grilled chicken breast", "steamed broccoli", "white rice" - NOT "food tray")
        - Be very specific with food names (e.g., "grilled salmon fillet" not "fish", "Caesar salad with croutons" not "salad")
        - Estimate the VISIBLE portion size based on what you see in the image, not a typical serving
        - Use visual cues like plate size, utensils, or hands for scale reference
        - Consider cooking method when identifying (grilled vs fried, steamed vs roasted)
        - For mixed dishes, identify the main components

        For each food item provide:
        1. Specific food name (include preparation method if visible)
        2. Confidence level (0.0 to 1.0) - be honest if uncertain
        3. Estimated calories for the VISIBLE portion
        4. Estimated protein in grams for the VISIBLE portion
        5. Estimated carbs in grams for the VISIBLE portion
        6. Estimated fat in grams for the VISIBLE portion
        7. Estimated serving size based on what's VISIBLE (e.g., "approximately 150g" or "1 cup")

        Respond ONLY with valid JSON in this exact format (no markdown, no explanation):
        {"foods": [{"name": "food name", "confidence": 0.95, "estimatedCalories": 150, "estimatedProtein": 5.0, "estimatedCarbs": 20.0, "estimatedFat": 6.0, "servingSize": "approximately 150g"}]}

        If no food is detected, respond with: {"foods": []}
        """

        let requestBody: [String: Any] = [
            "model": "gpt-4o",
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": prompt
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64Image)",
                                "detail": "high"  // Use high detail for better food recognition accuracy
                            ]
                        ]
                    ]
                ]
            ],
            "max_tokens": 1000  // Increased for multiple food items on trays/plates
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        // Make the request
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw FoodRecognitionError.networkError("Invalid response")
        }

        if httpResponse.statusCode != 200 {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ OpenAI API Error: \(errorString)")
            }
            throw FoodRecognitionError.networkError("API returned status \(httpResponse.statusCode)")
        }

        // Parse the response
        let openAIResponse = try JSONDecoder().decode(OpenAIVisionResponse.self, from: data)

        guard let content = openAIResponse.choices.first?.message.content else {
            throw FoodRecognitionError.noResultsFound
        }

        print("📝 OpenAI Response: \(content)")

        // Parse the JSON content from the response
        // Clean up the response in case it has markdown formatting
        var cleanedContent = content
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonData = cleanedContent.data(using: .utf8) else {
            throw FoodRecognitionError.invalidResponse
        }

        let foodAnalysis = try JSONDecoder().decode(OpenAIFoodAnalysis.self, from: jsonData)

        if foodAnalysis.foods.isEmpty {
            throw FoodRecognitionError.noResultsFound
        }

        // Convert to FoodRecognitionResult
        var results: [FoodRecognitionResult] = []
        for food in foodAnalysis.foods {
            // Try to get more accurate nutrition from our nutrition API
            var calories = food.estimatedCalories
            var protein = food.estimatedProtein
            var carbs = food.estimatedCarbs
            var fat = food.estimatedFat
            var servingSize = food.servingSize

            if let nutritionData = try? await nutritionService.fetchNutrition(for: food.name) {
                calories = nutritionData.calories
                protein = nutritionData.protein
                carbs = nutritionData.carbs
                fat = nutritionData.fat
                servingSize = nutritionData.servingSize
            }

            results.append(FoodRecognitionResult(
                name: food.name,
                confidence: Float(food.confidence),
                calories: calories,
                protein: protein,
                carbs: carbs,
                fat: fat,
                servingSize: servingSize
            ))

            print("✅ Detected: \(food.name) (\(Int(food.confidence * 100))% confidence)")
        }

        return results
    }

    // MARK: - Image Resizing Helper
    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let ratio = max(size.width, size.height) / maxDimension

        if ratio <= 1 {
            return image
        }

        let newSize = CGSize(width: size.width / ratio, height: size.height / ratio)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()

        return resizedImage
    }
    
    // MARK: - Vision Classification
    private func performVisionClassification(on image: CGImage) async throws -> [FoodRecognitionResult] {
        return try await withCheckedThrowingContinuation { continuation in
            
            // Create classification request
            let request: VNImageBasedRequest
            
            if let model = visionModel {
                // Use custom model if available
                request = VNCoreMLRequest(model: model) { request, error in
                    self.handleClassificationResults(request: request, error: error, continuation: continuation)
                }
            } else {
                // Fallback to built-in classifier
                request = VNClassifyImageRequest { request, error in
                    self.handleClassificationResults(request: request, error: error, continuation: continuation)
                }
            }
            
            // Configure request
            request.imageCropAndScaleOption = .centerCrop
            
            // Perform request
            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: FoodRecognitionError.imageProcessingFailed)
            }
        }
    }
    
    private func handleClassificationResults(
        request: VNRequest,
        error: Error?,
        continuation: CheckedContinuation<[FoodRecognitionResult], Error>
    ) {
        if let error = error {
            continuation.resume(throwing: error)
            return
        }

        guard let observations = request.results as? [VNClassificationObservation] else {
            continuation.resume(throwing: FoodRecognitionError.noResultsFound)
            return
        }

        // Filter for food-related results only
        let foodResults = observations
            .filter { observation in
                let identifier = observation.identifier.lowercased()
                // Check if any food keyword is contained in the identifier
                return observation.confidence > 0.05 && foodKeywords.contains(where: { keyword in
                    identifier.contains(keyword) || keyword.contains(identifier)
                })
            }
            .prefix(5)
            .map { observation in
                // Clean up the identifier for display
                let cleanName = cleanFoodName(observation.identifier)
                return FoodRecognitionResult(
                    name: cleanName,
                    confidence: observation.confidence,
                    calories: nil,
                    protein: nil,
                    carbs: nil,
                    fat: nil,
                    servingSize: nil
                )
            }

        if foodResults.isEmpty {
            // If no food detected, provide helpful feedback
            print("⚠️ No food items detected. Top classifications were:")
            for obs in observations.prefix(5) {
                print("   - \(obs.identifier): \(Int(obs.confidence * 100))%")
            }
            continuation.resume(throwing: FoodRecognitionError.noResultsFound)
        } else {
            print("✅ Food items detected:")
            for result in foodResults {
                print("   - \(result.name): \(Int(result.confidence * 100))%")
            }
            continuation.resume(returning: Array(foodResults))
        }
    }

    /// Clean up Vision identifier for display
    private func cleanFoodName(_ identifier: String) -> String {
        // Vision returns identifiers like "chocolate_chip_cookie" or "granny_smith"
        return identifier
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .capitalized
    }
    
    // MARK: - Portion Size Estimation (using depth data if available)
    func estimatePortionSize(from image: UIImage, depthData: Data? = nil) -> String {
        // Basic estimation based on image analysis
        // In production, integrate with depth camera data for accurate sizing
        
        guard let cgImage = image.cgImage else { return "1 serving" }
        
        let width = cgImage.width
        let height = cgImage.height
        let aspectRatio = Double(width) / Double(height)
        
        // Simple heuristic - improve with ML model
        if aspectRatio > 1.5 {
            return "Large plate"
        } else if aspectRatio > 1.0 {
            return "Medium plate"
        } else {
            return "Small bowl"
        }
    }
}

// MARK: - Nutrition API Service
class NutritionAPIService {
    
    struct NutritionData {
        let calories: Int
        let protein: Double
        let carbs: Double
        let fat: Double
        let servingSize: String
    }
    
    // USDA FoodData Central API
    private let baseURL = "https://api.nal.usda.gov/fdc/v1"
    private let apiKey: String
    
    init() {
        // Load API key from config
        self.apiKey = ProcessInfo.processInfo.environment["USDA_API_KEY"] ?? "DEMO_KEY"
    }
    
    func fetchNutrition(for foodName: String) async throws -> NutritionData {
        let query = foodName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? foodName
        let urlString = "\(baseURL)/foods/search?query=\(query)&pageSize=1&api_key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            throw FoodRecognitionError.networkError("Invalid URL")
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw FoodRecognitionError.networkError("Request failed")
        }
        
        // Parse USDA response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let foods = json["foods"] as? [[String: Any]],
              let firstFood = foods.first,
              let nutrients = firstFood["foodNutrients"] as? [[String: Any]] else {
            throw FoodRecognitionError.invalidResponse
        }
        
        var calories = 0
        var protein = 0.0
        var carbs = 0.0
        var fat = 0.0
        
        for nutrient in nutrients {
            guard let name = nutrient["nutrientName"] as? String,
                  let value = nutrient["value"] as? Double else { continue }
            
            switch name {
            case "Energy":
                calories = Int(value)
            case "Protein":
                protein = value
            case "Carbohydrate, by difference":
                carbs = value
            case "Total lipid (fat)":
                fat = value
            default:
                break
            }
        }
        
        let servingSize = (firstFood["servingSize"] as? Double).map { "\(Int($0))g" } ?? "100g"
        
        return NutritionData(
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            servingSize: servingSize
        )
    }
}

// MARK: - Barcode Lookup Extension
extension NutritionAPIService {
    
    func fetchNutritionByBarcode(_ barcode: String) async throws -> NutritionData {
        // Open Food Facts API for barcode lookup
        let urlString = "https://world.openfoodfacts.org/api/v0/product/\(barcode).json"
        
        guard let url = URL(string: urlString) else {
            throw FoodRecognitionError.networkError("Invalid URL")
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw FoodRecognitionError.networkError("Product not found")
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let product = json["product"] as? [String: Any],
              let nutriments = product["nutriments"] as? [String: Any] else {
            throw FoodRecognitionError.invalidResponse
        }
        
        let calories = (nutriments["energy-kcal_100g"] as? Double).map { Int($0) } ?? 0
        let protein = nutriments["proteins_100g"] as? Double ?? 0
        let carbs = nutriments["carbohydrates_100g"] as? Double ?? 0
        let fat = nutriments["fat_100g"] as? Double ?? 0
        let servingSize = (product["serving_size"] as? String) ?? "100g"
        
        return NutritionData(
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            servingSize: servingSize
        )
    }
}
