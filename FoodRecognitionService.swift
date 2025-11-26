//
//  FoodRecognitionService.swift
//  CalTrackPro
//
//  AI-powered food recognition using Vision and CoreML
//

import Foundation
import Vision
import CoreML
import UIKit

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
    
    // MARK: - Initialization
    init() {
        loadModel()
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
        
        // Filter for food-related results with decent confidence
        let foodResults = observations
            .filter { $0.confidence > 0.1 }
            .prefix(5)
            .map { observation in
                FoodRecognitionResult(
                    name: observation.identifier.capitalized,
                    confidence: observation.confidence,
                    calories: nil,
                    protein: nil,
                    carbs: nil,
                    fat: nil,
                    servingSize: nil
                )
            }
        
        if foodResults.isEmpty {
            continuation.resume(throwing: FoodRecognitionError.noResultsFound)
        } else {
            continuation.resume(returning: Array(foodResults))
        }
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
