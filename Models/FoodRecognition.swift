import Foundation
import SwiftUI
import Vision
import CoreML

// MARK: - Food Recognition Models

struct RecognizedFood: Identifiable, Codable {
    let id = UUID()
    let name: String
    let confidence: Double
    let boundingBox: CGRect?
    let nutritionInfo: NutritionInfo?
    let estimatedWeight: Double? // in grams
    let category: FoodCategory
    
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

// MARK: - AI Food Recognition Service

@MainActor
class AIFoodRecognitionService: ObservableObject {
    @Published var isProcessing = false
    @Published var lastResult: FoodRecognitionResult?
    @Published var error: FoodRecognitionError?
    
    enum FoodRecognitionError: LocalizedError {
        case imageProcessingFailed
        case modelNotAvailable
        case networkError
        case lowConfidence
        case noFoodDetected
        
        var errorDescription: String? {
            switch self {
            case .imageProcessingFailed:
                return "Failed to process the image. Please try again."
            case .modelNotAvailable:
                return "Food recognition model is not available."
            case .networkError:
                return "Network error. Please check your connection."
            case .lowConfidence:
                return "Could not confidently identify the food. Try a clearer photo."
            case .noFoodDetected:
                return "No food items detected in the image."
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
            let detectedFoods = try await detectFoods(in: processedImage)
            
            // Step 3: Get nutrition information
            let recognizedFoods = await withTaskGroup(of: RecognizedFood?.self) { group in
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
    
    // MARK: - Food Detection (Mock Implementation)
    
    private func detectFoods(in image: UIImage) async throws -> [RecognizedFood] {
        // Simulate processing delay
        try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        
        // Mock food detection results
        // In a real implementation, this would use Vision/CoreML or cloud APIs
        let mockResults = generateMockFoodDetection()
        
        guard !mockResults.isEmpty else {
            throw FoodRecognitionError.noFoodDetected
        }
        
        return mockResults
    }
    
    // MARK: - Nutrition Enhancement
    
    private func enhanceWithNutrition(_ food: RecognizedFood) async -> RecognizedFood {
        // Mock nutrition lookup
        // In a real implementation, this would query nutrition databases
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
    
    // MARK: - Mock Data Generation
    
    private func generateMockFoodDetection() -> [RecognizedFood] {
        let mockFoods = [
            ("Apple", 0.95, RecognizedFood.FoodCategory.fruits, 150.0),
            ("Banana", 0.88, RecognizedFood.FoodCategory.fruits, 120.0),
            ("Chicken Breast", 0.92, RecognizedFood.FoodCategory.protein, 200.0),
            ("Broccoli", 0.87, RecognizedFood.FoodCategory.vegetables, 100.0),
            ("Brown Rice", 0.83, RecognizedFood.FoodCategory.grains, 150.0),
            ("Salmon", 0.90, RecognizedFood.FoodCategory.protein, 150.0),
            ("Greek Yogurt", 0.85, RecognizedFood.FoodCategory.dairy, 170.0),
            ("Almonds", 0.89, RecognizedFood.FoodCategory.nuts, 30.0),
            ("Mixed Salad", 0.79, RecognizedFood.FoodCategory.vegetables, 80.0)
        ]
        
        // Randomly select 1-3 foods for detection
        let numberOfFoods = Int.random(in: 1...3)
        let selectedFoods = mockFoods.shuffled().prefix(numberOfFoods)
        
        return selectedFoods.enumerated().map { index, food in
            let (name, baseConfidence, category, weight) = food
            let confidence = baseConfidence + Double.random(in: -0.1...0.1)
            
            return RecognizedFood(
                name: name,
                confidence: max(0.6, min(0.99, confidence)),
                boundingBox: generateRandomBoundingBox(index: index),
                nutritionInfo: nil, // Will be filled by enhanceWithNutrition
                estimatedWeight: weight + Double.random(in: -20...20),
                category: category
            )
        }
    }
    
    private func generateRandomBoundingBox(index: Int) -> CGRect {
        let x = Double.random(in: 0.1...0.6)
        let y = Double.random(in: 0.1...0.6)
        let width = Double.random(in: 0.2...0.4)
        let height = Double.random(in: 0.2...0.4)
        
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    private func generateNutritionInfo(for foodName: String) -> RecognizedFood.NutritionInfo {
        // Mock nutrition data per 100g
        let nutritionDatabase: [String: RecognizedFood.NutritionInfo] = [
            "Apple": RecognizedFood.NutritionInfo(calories: 52, protein: 0.3, carbs: 14, fat: 0.2, fiber: 2.4, sugar: 10),
            "Banana": RecognizedFood.NutritionInfo(calories: 89, protein: 1.1, carbs: 23, fat: 0.3, fiber: 2.6, sugar: 12),
            "Chicken Breast": RecognizedFood.NutritionInfo(calories: 165, protein: 31, carbs: 0, fat: 3.6, fiber: 0, sugar: 0),
            "Broccoli": RecognizedFood.NutritionInfo(calories: 34, protein: 2.8, carbs: 7, fat: 0.4, fiber: 2.6, sugar: 1.5),
            "Brown Rice": RecognizedFood.NutritionInfo(calories: 111, protein: 2.6, carbs: 23, fat: 0.9, fiber: 1.8, sugar: 0.4),
            "Salmon": RecognizedFood.NutritionInfo(calories: 208, protein: 20, carbs: 0, fat: 13, fiber: 0, sugar: 0),
            "Greek Yogurt": RecognizedFood.NutritionInfo(calories: 97, protein: 10, carbs: 4, fat: 5, fiber: 0, sugar: 4),
            "Almonds": RecognizedFood.NutritionInfo(calories: 579, protein: 21, carbs: 22, fat: 50, fiber: 12, sugar: 4),
            "Mixed Salad": RecognizedFood.NutritionInfo(calories: 20, protein: 1.5, carbs: 4, fat: 0.2, fiber: 2, sugar: 2)
        ]
        
        return nutritionDatabase[foodName] ?? RecognizedFood.NutritionInfo(
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
        let nutrition = nutritionInfo?.scaled(to: weight) ?? NutritionInfo(calories: 100, protein: 5, carbs: 15, fat: 2)
        
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