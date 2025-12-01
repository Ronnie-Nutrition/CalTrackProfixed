import Foundation
import Combine
import SwiftUI
import Vision
import CoreML
import Security

// MARK: - Simple Keychain Helper for OpenAI API Key
private struct OpenAIKeychain {
    private static let service = "com.caltrackpro.openai"
    private static let account = "api_key"

    static func save(_ key: String) {
        guard let data = key.data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)

        var addQuery = query
        addQuery[kSecValueData as String] = data
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    static func get() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        if SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
           let data = result as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }

    static func delete() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }

    static var hasKey: Bool {
        if let key = get(), !key.isEmpty { return true }
        if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !envKey.isEmpty { return true }
        return false
    }
}

// MARK: - Food Recognition Models

struct RecognizedFood: Identifiable, Codable {
    var id = UUID()
    let name: String
    let confidence: Double
    let boundingBox: CGRect?
    let nutritionInfo: NutritionInfo?
    let estimatedWeight: Double? // in grams
    let category: FoodCategory

    private enum CodingKeys: String, CodingKey {
        case name, confidence, boundingBox, nutritionInfo, estimatedWeight, category
    }
    
    struct NutritionInfo: Codable {
        let calories: Double
        let protein: Double
        let carbs: Double
        let fat: Double
        let fiber: Double?
        let sugar: Double?
        
        // Per 100g values
        var per100g: NutritionInfo {
            return self
        }
        
        func scaled(to weight: Double) -> NutritionInfo {
            let factor = weight / 100.0
            return NutritionInfo(
                calories: calories * factor,
                protein: protein * factor,
                carbs: carbs * factor,
                fat: fat * factor,
                fiber: fiber.map { $0 * factor },
                sugar: sugar.map { $0 * factor }
            )
        }
    }
    
    enum FoodCategory: String, CaseIterable, Codable {
        case fruits = "Fruits"
        case vegetables = "Vegetables"
        case grains = "Grains"
        case protein = "Protein"
        case dairy = "Dairy"
        case nuts = "Nuts & Seeds"
        case beverages = "Beverages"
        case sweets = "Sweets"
        case prepared = "Prepared Foods"
        case unknown = "Unknown"
        
        var icon: String {
            switch self {
            case .fruits: return "apple.logo"
            case .vegetables: return "carrot.fill"
            case .grains: return "grain.fill"
            case .protein: return "fish.fill"
            case .dairy: return "drop.fill"
            case .nuts: return "oval.fill"
            case .beverages: return "cup.and.saucer.fill"
            case .sweets: return "birthday.cake.fill"
            case .prepared: return "fork.knife"
            case .unknown: return "questionmark.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .fruits: return .red
            case .vegetables: return .green
            case .grains: return .orange
            case .protein: return .blue
            case .dairy: return .cyan
            case .nuts: return .brown
            case .beverages: return .indigo
            case .sweets: return .pink
            case .prepared: return .purple
            case .unknown: return .gray
            }
        }
    }
}

struct FoodRecognitionResult {
    let image: UIImage
    let recognizedFoods: [RecognizedFood]
    let processingTime: TimeInterval
    let confidence: Double
    
    var topResult: RecognizedFood? {
        recognizedFoods.max(by: { $0.confidence < $1.confidence })
    }
    
    var averageConfidence: Double {
        guard !recognizedFoods.isEmpty else { return 0 }
        return recognizedFoods.reduce(0) { $0 + $1.confidence } / Double(recognizedFoods.count)
    }
}

// MARK: - OpenAI Vision Response Models
private struct OpenAIVisionResponse: Codable {
    let choices: [OpenAIChoice]
}

private struct OpenAIChoice: Codable {
    let message: OpenAIMessage
}

private struct OpenAIMessage: Codable {
    let content: String
}

private struct OpenAIFoodAnalysis: Codable {
    let foods: [OpenAIDetectedFood]
}

private struct OpenAIDetectedFood: Codable {
    let name: String
    let confidence: Double
    let estimatedCalories: Int?
    let estimatedProtein: Double?
    let estimatedCarbs: Double?
    let estimatedFat: Double?
    let servingSize: String?
    let category: String?
}

// MARK: - AI Food Recognition Service

@MainActor
class AIFoodRecognitionService: ObservableObject {
    @Published var isProcessing = false
    @Published var lastResult: FoodRecognitionResult?
    @Published var error: FoodRecognitionError?

    // OpenAI Configuration
    private let openAIEndpoint = "https://api.openai.com/v1/chat/completions"

    private var openAIAPIKey: String? {
        if let key = OpenAIKeychain.get(), !key.isEmpty {
            return key
        }
        if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        return nil
    }

    private var useOpenAI: Bool {
        openAIAPIKey != nil
    }

    // MARK: - Static API Key Methods
    static func setOpenAIAPIKey(_ key: String) {
        OpenAIKeychain.save(key)
    }

    static func getOpenAIAPIKey() -> String? {
        OpenAIKeychain.get()
    }

    static func hasOpenAIAPIKey() -> Bool {
        OpenAIKeychain.hasKey
    }

    static func clearOpenAIAPIKey() {
        OpenAIKeychain.delete()
    }

    enum FoodRecognitionError: LocalizedError {
        case imageProcessingFailed
        case modelNotAvailable
        case networkError(String)
        case lowConfidence
        case noFoodDetected
        case invalidResponse

        var errorDescription: String? {
            switch self {
            case .imageProcessingFailed:
                return "Failed to process the image. Please try again."
            case .modelNotAvailable:
                return "Food recognition model is not available."
            case .networkError(let message):
                return "Network error: \(message)"
            case .lowConfidence:
                return "Could not confidently identify the food. Try a clearer photo."
            case .noFoodDetected:
                return "No food items detected in the image."
            case .invalidResponse:
                return "Invalid response from AI service."
            }
        }
    }
    
    // MARK: - Main Recognition Method

    func recognizeFood(from image: UIImage) async throws -> FoodRecognitionResult {
        isProcessing = true
        error = nil

        let startTime = Date()

        defer {
            isProcessing = false
        }

        do {
            // Step 1: Preprocess image
            guard let processedImage = preprocessImage(image) else {
                throw FoodRecognitionError.imageProcessingFailed
            }

            // Step 2: Run food detection
            let detectedFoods: [RecognizedFood]

            if useOpenAI {
                print("🤖 Using OpenAI Vision API for food recognition")
                detectedFoods = try await detectFoodsWithOpenAI(in: processedImage)
            } else {
                print("📱 Using Apple Vision API for food recognition")
                detectedFoods = try await detectFoods(in: processedImage)
                print("📱 Apple Vision returned \(detectedFoods.count) foods")
            }

            // Step 3: Get nutrition information (for mock results)
            let recognizedFoods: [RecognizedFood]
            if useOpenAI {
                // OpenAI results already have nutrition estimates
                recognizedFoods = detectedFoods
            } else {
                recognizedFoods = await withTaskGroup(of: RecognizedFood?.self) { group in
                    for food in detectedFoods {
                        group.addTask {
                            return await self.enhanceWithNutrition(food)
                        }
                    }

                    var results: [RecognizedFood] = []
                    for await result in group {
                        if let food = result {
                            results.append(food)
                        }
                    }
                    return results
                }
            }

            let processingTime = Date().timeIntervalSince(startTime)
            let result = FoodRecognitionResult(
                image: image,
                recognizedFoods: recognizedFoods,
                processingTime: processingTime,
                confidence: recognizedFoods.isEmpty ? 0 : recognizedFoods.reduce(0) { $0 + $1.confidence } / Double(recognizedFoods.count)
            )

            lastResult = result
            return result

        } catch {
            self.error = error as? FoodRecognitionError ?? .imageProcessingFailed
            throw error
        }
    }

    // MARK: - OpenAI Vision Detection

    private func detectFoodsWithOpenAI(in image: UIImage) async throws -> [RecognizedFood] {
        guard let apiKey = openAIAPIKey else {
            throw FoodRecognitionError.modelNotAvailable
        }

        // Convert to base64
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw FoodRecognitionError.imageProcessingFailed
        }
        let base64Image = imageData.base64EncodedString()

        // Create request
        guard let url = URL(string: openAIEndpoint) else {
            throw FoodRecognitionError.networkError("Invalid URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Create the prompt for food analysis
        let prompt = """
        Analyze this image and identify all food items visible. For each food item, provide:
        1. The food name (be specific, e.g., "chocolate chip cookie" not just "cookie")
        2. Your confidence level (0.0 to 1.0)
        3. Estimated calories per serving
        4. Estimated protein in grams
        5. Estimated carbs in grams
        6. Estimated fat in grams
        7. Typical serving size
        8. Food category (one of: Fruits, Vegetables, Grains, Protein, Dairy, Nuts & Seeds, Beverages, Sweets, Prepared Foods, Unknown)

        Respond ONLY with valid JSON in this exact format (no markdown, no explanation):
        {"foods": [{"name": "food name", "confidence": 0.95, "estimatedCalories": 150, "estimatedProtein": 5.0, "estimatedCarbs": 20.0, "estimatedFat": 6.0, "servingSize": "1 cookie (30g)", "category": "Sweets"}]}

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
                                "detail": "low"
                            ]
                        ]
                    ]
                ]
            ],
            "max_tokens": 500
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
            throw FoodRecognitionError.noFoodDetected
        }

        print("📝 OpenAI Response: \(content)")

        // Clean up the response in case it has markdown formatting
        let cleanedContent = content
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonData = cleanedContent.data(using: .utf8) else {
            throw FoodRecognitionError.invalidResponse
        }

        let foodAnalysis = try JSONDecoder().decode(OpenAIFoodAnalysis.self, from: jsonData)

        if foodAnalysis.foods.isEmpty {
            throw FoodRecognitionError.noFoodDetected
        }

        // Convert to RecognizedFood
        return foodAnalysis.foods.map { food in
            let category = RecognizedFood.FoodCategory(rawValue: food.category ?? "Unknown") ?? .unknown

            let nutrition = RecognizedFood.NutritionInfo(
                calories: Double(food.estimatedCalories ?? 100),
                protein: food.estimatedProtein ?? 5.0,
                carbs: food.estimatedCarbs ?? 15.0,
                fat: food.estimatedFat ?? 2.0,
                fiber: nil,
                sugar: nil
            )

            print("✅ Detected: \(food.name) (\(Int(food.confidence * 100))% confidence)")

            return RecognizedFood(
                name: food.name,
                confidence: food.confidence,
                boundingBox: nil,
                nutritionInfo: nutrition,
                estimatedWeight: 100, // Default serving
                category: category
            )
        }
    }
    
    // MARK: - Image Preprocessing
    
    private func preprocessImage(_ image: UIImage) -> UIImage? {
        // Resize image for optimal processing
        let targetSize = CGSize(width: 512, height: 512)
        
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: targetSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage
    }
    
    // MARK: - Food Detection using Apple Vision

    private func detectFoods(in image: UIImage) async throws -> [RecognizedFood] {
        guard let cgImage = image.cgImage else {
            throw FoodRecognitionError.imageProcessingFailed
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNClassifyImageRequest { request, error in
                if error != nil {
                    continuation.resume(throwing: FoodRecognitionError.imageProcessingFailed)
                    return
                }

                guard let observations = request.results as? [VNClassificationObservation] else {
                    continuation.resume(throwing: FoodRecognitionError.noFoodDetected)
                    return
                }

                // Log all top classifications for debugging
                print("🔍 Vision classifications:")
                for obs in observations.prefix(10) {
                    print("   - \(obs.identifier): \(Int(obs.confidence * 100))%")
                }

                // Filter for food-related classifications (lowered threshold to 0.01)
                var foodResults = observations
                    .filter { observation in
                        let identifier = observation.identifier.lowercased()
                        return observation.confidence > 0.01 && self.isFoodRelated(identifier)
                    }
                    .prefix(5)
                    .map { observation -> RecognizedFood in
                        let cleanName = self.cleanFoodName(observation.identifier)
                        let category = self.categorizeFood(cleanName)
                        let nutrition = self.generateNutritionInfo(for: cleanName)

                        return RecognizedFood(
                            name: cleanName,
                            confidence: Double(observation.confidence),
                            boundingBox: nil,
                            nutritionInfo: nutrition,
                            estimatedWeight: 100.0,
                            category: category
                        )
                    }

                // If no food detected but we have high-confidence results, try to use them anyway
                if foodResults.isEmpty {
                    // Check if there are any color-based hints (red = berries, orange = citrus, etc.)
                    let colorHints = observations.prefix(10).compactMap { obs -> RecognizedFood? in
                        let id = obs.identifier.lowercased()
                        if id.contains("red") && obs.confidence > 0.1 {
                            return RecognizedFood(
                                name: "Strawberries",
                                confidence: Double(obs.confidence) * 0.8,
                                boundingBox: nil,
                                nutritionInfo: self.generateNutritionInfo(for: "strawberry"),
                                estimatedWeight: 100.0,
                                category: .fruits
                            )
                        } else if id.contains("green") && obs.confidence > 0.1 {
                            return RecognizedFood(
                                name: "Salad Greens",
                                confidence: Double(obs.confidence) * 0.8,
                                boundingBox: nil,
                                nutritionInfo: self.generateNutritionInfo(for: "salad"),
                                estimatedWeight: 100.0,
                                category: .vegetables
                            )
                        } else if id.contains("yellow") && obs.confidence > 0.1 {
                            return RecognizedFood(
                                name: "Banana",
                                confidence: Double(obs.confidence) * 0.8,
                                boundingBox: nil,
                                nutritionInfo: self.generateNutritionInfo(for: "banana"),
                                estimatedWeight: 100.0,
                                category: .fruits
                            )
                        }
                        return nil
                    }
                    foodResults = Array(colorHints.prefix(3))
                }

                if foodResults.isEmpty {
                    print("⚠️ No food items detected - using fallback")
                    // Always return something so user can manually adjust
                    let fallbackFood = RecognizedFood(
                        name: "Detected Food",
                        confidence: 0.5,
                        boundingBox: nil,
                        nutritionInfo: RecognizedFood.NutritionInfo(
                            calories: 100, protein: 5, carbs: 15, fat: 3, fiber: 2, sugar: 5
                        ),
                        estimatedWeight: 100.0,
                        category: .prepared
                    )
                    continuation.resume(returning: [fallbackFood])
                } else {
                    print("✅ Food items detected:")
                    for result in foodResults {
                        print("   - \(result.name): \(Int(result.confidence * 100))%")
                    }
                    continuation.resume(returning: Array(foodResults))
                }
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: FoodRecognitionError.imageProcessingFailed)
            }
        }
    }

    // MARK: - Food Detection Helpers

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
        "lime", "kiwi", "coconut", "avocado", "tomato", "fruit", "pomegranate", "fig",
        // Vegetables
        "carrot", "broccoli", "spinach", "lettuce", "salad", "potato", "corn", "pea",
        "bean", "onion", "garlic", "pepper", "cucumber", "celery", "cabbage", "cauliflower",
        "asparagus", "mushroom", "vegetable", "zucchini", "squash", "eggplant", "artichoke",
        // Snacks & Desserts
        "cookie", "cake", "pie", "donut", "doughnut", "candy", "chocolate", "brownie",
        "cupcake", "pastry", "chips", "popcorn", "nuts", "peanut", "almond", "pretzel",
        // Meals
        "pizza", "burger", "hamburger", "sandwich", "taco", "burrito", "sushi", "soup",
        "salad", "stew", "curry", "casserole", "lasagna", "wrap", "hot dog", "hotdog",
        // Beverages
        "coffee", "tea", "juice", "soda", "smoothie", "shake", "wine", "beer", "espresso",
        // Other foods
        "sauce", "dressing", "syrup", "honey", "jam", "jelly", "peanut butter",
        "hummus", "guacamole", "salsa", "dip", "spread", "condiment",
        "protein bar", "granola", "snack", "food", "meal", "dish", "plate",
        "french fries", "fries", "nachos", "quesadilla", "enchilada",
        // Generic Vision labels that indicate food
        "berry", "berries", "produce", "citrus", "tropical", "leafy", "greens",
        "baked", "grilled", "fried", "roasted", "cooked", "raw", "fresh",
        "edible", "ingredient", "groceries", "grocery", "prepared", "homemade",
        "dessert", "breakfast", "lunch", "dinner", "appetizer", "entree",
        "bowl", "tray", "container", "package", "wrapped"
    ]

    // Map generic Vision labels to specific food items for better results
    private let genericToFoodMap: [String: String] = [
        "berry": "Mixed Berries",
        "berries": "Mixed Berries",
        "produce": "Fresh Produce",
        "citrus": "Orange",
        "tropical": "Tropical Fruit",
        "leafy": "Salad Greens",
        "greens": "Mixed Greens",
        "baked": "Baked Goods",
        "grilled": "Grilled Food",
        "fried": "Fried Food",
        "roasted": "Roasted Food",
        "cooked": "Cooked Meal",
        "raw": "Fresh Food",
        "fresh": "Fresh Produce",
        "edible": "Food Item",
        "ingredient": "Ingredient",
        "groceries": "Groceries",
        "grocery": "Groceries",
        "prepared": "Prepared Meal",
        "homemade": "Homemade Food",
        "dessert": "Dessert",
        "breakfast": "Breakfast",
        "lunch": "Lunch",
        "dinner": "Dinner",
        "appetizer": "Appetizer",
        "entree": "Main Course",
        "bowl": "Food Bowl",
        "tray": "Food Tray",
        "container": "Packaged Food",
        "package": "Packaged Food",
        "wrapped": "Wrapped Food"
    ]

    private func isFoodRelated(_ identifier: String) -> Bool {
        let lowercased = identifier.lowercased()
        return foodKeywords.contains(where: { keyword in
            lowercased.contains(keyword) || keyword.contains(lowercased)
        })
    }

    private func cleanFoodName(_ identifier: String) -> String {
        let cleaned = identifier
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .lowercased()

        // Check if this is a generic Vision label we can map to a better name
        for (generic, specific) in genericToFoodMap {
            if cleaned.contains(generic) {
                return specific
            }
        }

        return cleaned.capitalized
    }

    private func categorizeFood(_ name: String) -> RecognizedFood.FoodCategory {
        let lowercased = name.lowercased()

        let fruitKeywords = ["apple", "banana", "orange", "grape", "strawberry", "blueberry", "raspberry", "watermelon", "melon", "pineapple", "mango", "peach", "pear", "cherry", "lemon", "lime", "kiwi", "pomegranate", "fig", "fruit"]
        let vegetableKeywords = ["carrot", "broccoli", "spinach", "lettuce", "salad", "potato", "corn", "pea", "bean", "onion", "garlic", "pepper", "cucumber", "celery", "cabbage", "cauliflower", "asparagus", "mushroom", "vegetable", "zucchini", "squash", "eggplant", "artichoke"]
        let proteinKeywords = ["chicken", "beef", "pork", "fish", "salmon", "tuna", "shrimp", "lobster", "crab", "steak", "meat", "bacon", "sausage", "ham", "turkey", "duck", "lamb", "egg"]
        let dairyKeywords = ["cheese", "milk", "yogurt", "butter", "cream"]
        let grainKeywords = ["bread", "rice", "pasta", "noodle", "cereal", "oatmeal", "pancake", "waffle", "toast", "bagel", "muffin", "croissant", "biscuit", "cracker"]
        let sweetKeywords = ["cookie", "cake", "pie", "donut", "candy", "chocolate", "brownie", "cupcake", "pastry", "ice cream"]
        let nutKeywords = ["nuts", "peanut", "almond", "walnut", "cashew"]
        let beverageKeywords = ["coffee", "tea", "juice", "soda", "smoothie", "shake", "wine", "beer", "espresso"]

        if fruitKeywords.contains(where: { lowercased.contains($0) }) { return .fruits }
        if vegetableKeywords.contains(where: { lowercased.contains($0) }) { return .vegetables }
        if proteinKeywords.contains(where: { lowercased.contains($0) }) { return .protein }
        if dairyKeywords.contains(where: { lowercased.contains($0) }) { return .dairy }
        if grainKeywords.contains(where: { lowercased.contains($0) }) { return .grains }
        if sweetKeywords.contains(where: { lowercased.contains($0) }) { return .sweets }
        if nutKeywords.contains(where: { lowercased.contains($0) }) { return .nuts }
        if beverageKeywords.contains(where: { lowercased.contains($0) }) { return .beverages }

        return .prepared
    }
    
    // MARK: - Nutrition Enhancement

    private func enhanceWithNutrition(_ food: RecognizedFood) async -> RecognizedFood {
        let nutrition = generateNutritionInfo(for: food.name)

        return RecognizedFood(
            name: food.name,
            confidence: food.confidence,
            boundingBox: food.boundingBox,
            nutritionInfo: nutrition,
            estimatedWeight: food.estimatedWeight,
            category: food.category
        )
    }

    // MARK: - Nutrition Database

    private func generateNutritionInfo(for foodName: String) -> RecognizedFood.NutritionInfo {
        // Nutrition data per 100g - comprehensive database
        let nutritionDatabase: [String: RecognizedFood.NutritionInfo] = [
            // Fruits
            "apple": RecognizedFood.NutritionInfo(calories: 52, protein: 0.3, carbs: 14, fat: 0.2, fiber: 2.4, sugar: 10),
            "banana": RecognizedFood.NutritionInfo(calories: 89, protein: 1.1, carbs: 23, fat: 0.3, fiber: 2.6, sugar: 12),
            "orange": RecognizedFood.NutritionInfo(calories: 47, protein: 0.9, carbs: 12, fat: 0.1, fiber: 2.4, sugar: 9),
            "strawberry": RecognizedFood.NutritionInfo(calories: 32, protein: 0.7, carbs: 8, fat: 0.3, fiber: 2.0, sugar: 5),
            "strawberries": RecognizedFood.NutritionInfo(calories: 32, protein: 0.7, carbs: 8, fat: 0.3, fiber: 2.0, sugar: 5),
            "mixed berries": RecognizedFood.NutritionInfo(calories: 45, protein: 0.8, carbs: 10, fat: 0.3, fiber: 3.0, sugar: 6),
            "grapes": RecognizedFood.NutritionInfo(calories: 69, protein: 0.7, carbs: 18, fat: 0.2, fiber: 0.9, sugar: 15),
            "watermelon": RecognizedFood.NutritionInfo(calories: 30, protein: 0.6, carbs: 8, fat: 0.2, fiber: 0.4, sugar: 6),
            "mango": RecognizedFood.NutritionInfo(calories: 60, protein: 0.8, carbs: 15, fat: 0.4, fiber: 1.6, sugar: 14),
            "pineapple": RecognizedFood.NutritionInfo(calories: 50, protein: 0.5, carbs: 13, fat: 0.1, fiber: 1.4, sugar: 10),
            "blueberry": RecognizedFood.NutritionInfo(calories: 57, protein: 0.7, carbs: 14, fat: 0.3, fiber: 2.4, sugar: 10),
            "avocado": RecognizedFood.NutritionInfo(calories: 160, protein: 2, carbs: 9, fat: 15, fiber: 7, sugar: 0.7),

            // Vegetables
            "broccoli": RecognizedFood.NutritionInfo(calories: 34, protein: 2.8, carbs: 7, fat: 0.4, fiber: 2.6, sugar: 1.5),
            "carrot": RecognizedFood.NutritionInfo(calories: 41, protein: 0.9, carbs: 10, fat: 0.2, fiber: 2.8, sugar: 5),
            "spinach": RecognizedFood.NutritionInfo(calories: 23, protein: 2.9, carbs: 3.6, fat: 0.4, fiber: 2.2, sugar: 0.4),
            "lettuce": RecognizedFood.NutritionInfo(calories: 15, protein: 1.4, carbs: 2.9, fat: 0.2, fiber: 1.3, sugar: 0.8),
            "tomato": RecognizedFood.NutritionInfo(calories: 18, protein: 0.9, carbs: 3.9, fat: 0.2, fiber: 1.2, sugar: 2.6),
            "potato": RecognizedFood.NutritionInfo(calories: 77, protein: 2, carbs: 17, fat: 0.1, fiber: 2.2, sugar: 0.8),
            "corn": RecognizedFood.NutritionInfo(calories: 86, protein: 3.2, carbs: 19, fat: 1.2, fiber: 2.7, sugar: 3.2),
            "cucumber": RecognizedFood.NutritionInfo(calories: 16, protein: 0.7, carbs: 3.6, fat: 0.1, fiber: 0.5, sugar: 1.7),
            "pepper": RecognizedFood.NutritionInfo(calories: 31, protein: 1, carbs: 6, fat: 0.3, fiber: 2.1, sugar: 4.2),
            "mushroom": RecognizedFood.NutritionInfo(calories: 22, protein: 3.1, carbs: 3.3, fat: 0.3, fiber: 1, sugar: 2),

            // Proteins
            "chicken": RecognizedFood.NutritionInfo(calories: 165, protein: 31, carbs: 0, fat: 3.6, fiber: 0, sugar: 0),
            "chicken breast": RecognizedFood.NutritionInfo(calories: 165, protein: 31, carbs: 0, fat: 3.6, fiber: 0, sugar: 0),
            "beef": RecognizedFood.NutritionInfo(calories: 250, protein: 26, carbs: 0, fat: 15, fiber: 0, sugar: 0),
            "steak": RecognizedFood.NutritionInfo(calories: 271, protein: 26, carbs: 0, fat: 18, fiber: 0, sugar: 0),
            "salmon": RecognizedFood.NutritionInfo(calories: 208, protein: 20, carbs: 0, fat: 13, fiber: 0, sugar: 0),
            "tuna": RecognizedFood.NutritionInfo(calories: 144, protein: 23, carbs: 0, fat: 5, fiber: 0, sugar: 0),
            "shrimp": RecognizedFood.NutritionInfo(calories: 99, protein: 24, carbs: 0.2, fat: 0.3, fiber: 0, sugar: 0),
            "egg": RecognizedFood.NutritionInfo(calories: 155, protein: 13, carbs: 1.1, fat: 11, fiber: 0, sugar: 1.1),
            "eggs": RecognizedFood.NutritionInfo(calories: 155, protein: 13, carbs: 1.1, fat: 11, fiber: 0, sugar: 1.1),
            "pork": RecognizedFood.NutritionInfo(calories: 242, protein: 27, carbs: 0, fat: 14, fiber: 0, sugar: 0),
            "turkey": RecognizedFood.NutritionInfo(calories: 189, protein: 29, carbs: 0, fat: 7, fiber: 0, sugar: 0),
            "bacon": RecognizedFood.NutritionInfo(calories: 541, protein: 37, carbs: 1.4, fat: 42, fiber: 0, sugar: 0),

            // Dairy
            "cheese": RecognizedFood.NutritionInfo(calories: 402, protein: 25, carbs: 1.3, fat: 33, fiber: 0, sugar: 0.5),
            "milk": RecognizedFood.NutritionInfo(calories: 61, protein: 3.2, carbs: 4.8, fat: 3.3, fiber: 0, sugar: 5),
            "yogurt": RecognizedFood.NutritionInfo(calories: 59, protein: 10, carbs: 3.6, fat: 0.4, fiber: 0, sugar: 3.2),
            "greek yogurt": RecognizedFood.NutritionInfo(calories: 97, protein: 10, carbs: 4, fat: 5, fiber: 0, sugar: 4),
            "butter": RecognizedFood.NutritionInfo(calories: 717, protein: 0.9, carbs: 0.1, fat: 81, fiber: 0, sugar: 0.1),
            "ice cream": RecognizedFood.NutritionInfo(calories: 207, protein: 3.5, carbs: 24, fat: 11, fiber: 0.7, sugar: 21),

            // Grains
            "rice": RecognizedFood.NutritionInfo(calories: 130, protein: 2.7, carbs: 28, fat: 0.3, fiber: 0.4, sugar: 0),
            "brown rice": RecognizedFood.NutritionInfo(calories: 111, protein: 2.6, carbs: 23, fat: 0.9, fiber: 1.8, sugar: 0.4),
            "bread": RecognizedFood.NutritionInfo(calories: 265, protein: 9, carbs: 49, fat: 3.2, fiber: 2.7, sugar: 5),
            "pasta": RecognizedFood.NutritionInfo(calories: 131, protein: 5, carbs: 25, fat: 1.1, fiber: 1.8, sugar: 0.6),
            "oatmeal": RecognizedFood.NutritionInfo(calories: 68, protein: 2.4, carbs: 12, fat: 1.4, fiber: 1.7, sugar: 0.5),
            "cereal": RecognizedFood.NutritionInfo(calories: 379, protein: 7, carbs: 84, fat: 1.6, fiber: 5.3, sugar: 18),
            "pancake": RecognizedFood.NutritionInfo(calories: 227, protein: 6, carbs: 28, fat: 10, fiber: 1, sugar: 6),
            "waffle": RecognizedFood.NutritionInfo(calories: 291, protein: 8, carbs: 33, fat: 14, fiber: 1.5, sugar: 4),

            // Prepared foods
            "pizza": RecognizedFood.NutritionInfo(calories: 266, protein: 11, carbs: 33, fat: 10, fiber: 2.3, sugar: 3.6),
            "burger": RecognizedFood.NutritionInfo(calories: 295, protein: 17, carbs: 24, fat: 14, fiber: 1.3, sugar: 5),
            "hamburger": RecognizedFood.NutritionInfo(calories: 295, protein: 17, carbs: 24, fat: 14, fiber: 1.3, sugar: 5),
            "sandwich": RecognizedFood.NutritionInfo(calories: 250, protein: 12, carbs: 28, fat: 10, fiber: 2, sugar: 4),
            "hot dog": RecognizedFood.NutritionInfo(calories: 290, protein: 11, carbs: 24, fat: 17, fiber: 0.8, sugar: 4),
            "taco": RecognizedFood.NutritionInfo(calories: 210, protein: 9, carbs: 21, fat: 10, fiber: 2.5, sugar: 2),
            "burrito": RecognizedFood.NutritionInfo(calories: 206, protein: 8, carbs: 26, fat: 8, fiber: 2.5, sugar: 1.5),
            "sushi": RecognizedFood.NutritionInfo(calories: 145, protein: 6, carbs: 22, fat: 4, fiber: 0.3, sugar: 3),
            "salad": RecognizedFood.NutritionInfo(calories: 20, protein: 1.5, carbs: 4, fat: 0.2, fiber: 2, sugar: 2),
            "french fries": RecognizedFood.NutritionInfo(calories: 312, protein: 3.4, carbs: 41, fat: 15, fiber: 3.8, sugar: 0.3),
            "soup": RecognizedFood.NutritionInfo(calories: 50, protein: 2, carbs: 8, fat: 1, fiber: 1, sugar: 2),

            // Snacks & Desserts
            "cookie": RecognizedFood.NutritionInfo(calories: 488, protein: 5, carbs: 64, fat: 24, fiber: 2.4, sugar: 32),
            "cake": RecognizedFood.NutritionInfo(calories: 371, protein: 4.5, carbs: 52, fat: 16, fiber: 1.1, sugar: 35),
            "chocolate": RecognizedFood.NutritionInfo(calories: 546, protein: 5, carbs: 60, fat: 31, fiber: 7, sugar: 48),
            "donut": RecognizedFood.NutritionInfo(calories: 452, protein: 5, carbs: 51, fat: 25, fiber: 1.7, sugar: 21),
            "chips": RecognizedFood.NutritionInfo(calories: 536, protein: 7, carbs: 53, fat: 35, fiber: 4.4, sugar: 0.5),
            "popcorn": RecognizedFood.NutritionInfo(calories: 387, protein: 13, carbs: 78, fat: 4.5, fiber: 15, sugar: 0.9),
            "pie": RecognizedFood.NutritionInfo(calories: 237, protein: 2, carbs: 34, fat: 11, fiber: 1.2, sugar: 15),

            // Nuts
            "almonds": RecognizedFood.NutritionInfo(calories: 579, protein: 21, carbs: 22, fat: 50, fiber: 12, sugar: 4),
            "peanut": RecognizedFood.NutritionInfo(calories: 567, protein: 26, carbs: 16, fat: 49, fiber: 9, sugar: 4),
            "nuts": RecognizedFood.NutritionInfo(calories: 607, protein: 20, carbs: 21, fat: 54, fiber: 7, sugar: 4),

            // Beverages
            "coffee": RecognizedFood.NutritionInfo(calories: 2, protein: 0.3, carbs: 0, fat: 0, fiber: 0, sugar: 0),
            "tea": RecognizedFood.NutritionInfo(calories: 1, protein: 0, carbs: 0.3, fat: 0, fiber: 0, sugar: 0),
            "juice": RecognizedFood.NutritionInfo(calories: 45, protein: 0.7, carbs: 10, fat: 0.2, fiber: 0.2, sugar: 9),
            "soda": RecognizedFood.NutritionInfo(calories: 41, protein: 0, carbs: 10, fat: 0, fiber: 0, sugar: 10),
            "smoothie": RecognizedFood.NutritionInfo(calories: 70, protein: 2, carbs: 14, fat: 0.5, fiber: 1.5, sugar: 11)
        ]

        // Look up in database (case-insensitive)
        let lowercasedName = foodName.lowercased()
        for (key, value) in nutritionDatabase {
            if lowercasedName.contains(key) || key.contains(lowercasedName) {
                return value
            }
        }

        // Default nutrition if not found
        return RecognizedFood.NutritionInfo(
            calories: 100, protein: 5, carbs: 15, fat: 2, fiber: 2, sugar: 5
        )
    }
    
    // MARK: - Utility Methods
    
    func clearResults() {
        lastResult = nil
        error = nil
    }
    
    func retryLastImage() async throws -> FoodRecognitionResult? {
        guard let lastImage = lastResult?.image else { return nil }
        return try await recognizeFood(from: lastImage)
    }
}

// MARK: - Food Recognition Extensions

extension RecognizedFood {
    func toFoodEntry(mealType: FoodEntry.MealType = .lunch, quantity: Double? = nil) -> FoodEntry {
        let weight = quantity ?? estimatedWeight ?? 100.0
        let nutrition = nutritionInfo?.scaled(to: weight) ?? NutritionInfo(calories: 100, protein: 5, carbs: 15, fat: 2, fiber: nil, sugar: nil)
        
        return FoodEntry(
            name: name,
            calories: nutrition.calories,
            protein: nutrition.protein,
            carbs: nutrition.carbs,
            fat: nutrition.fat,
            servingSize: weight,
            servingUnit: "g",
            quantity: 1.0,
            mealType: mealType
        )
    }
}

// MARK: - Camera Permissions

class CameraPermissionManager: ObservableObject {
    @Published var permissionStatus: PermissionStatus = .notDetermined
    
    enum PermissionStatus {
        case notDetermined
        case denied
        case authorized
        case restricted
    }
    
    func requestCameraPermission() async {
        let status = await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .video) { granted in
                continuation.resume(returning: granted)
            }
        }
        
        await MainActor.run {
            permissionStatus = status ? .authorized : .denied
        }
    }
    
    func checkCameraPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .notDetermined:
            permissionStatus = .notDetermined
        case .denied:
            permissionStatus = .denied
        case .authorized:
            permissionStatus = .authorized
        case .restricted:
            permissionStatus = .restricted
        @unknown default:
            permissionStatus = .denied
        }
    }
}

import AVFoundation