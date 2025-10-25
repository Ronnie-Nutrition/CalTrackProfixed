import Foundation

// This file re-exports the FoodItem from NutritionAPIService
// so it can be used throughout the app without importing the service

typealias FoodItem = NutritionAPIService.FoodItem
typealias Nutrients = NutritionAPIService.Nutrients
typealias FoodSearchResponse = NutritionAPIService.FoodSearchResponse