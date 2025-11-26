//
//  HealthKitService.swift
//  CalTrackPro
//
//  Apple Health integration for nutrition and fitness data sync
//

import Foundation
import HealthKit

// MARK: - HealthKit Error
enum HealthKitError: Error, LocalizedError {
    case notAvailable
    case authorizationDenied
    case dataNotAvailable
    case saveFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device"
        case .authorizationDenied:
            return "HealthKit access was denied"
        case .dataNotAvailable:
            return "Health data not available"
        case .saveFailed(let message):
            return "Failed to save health data: \(message)"
        }
    }
}

// MARK: - Daily Nutrition Summary
struct DailyNutritionSummary {
    let date: Date
    var calories: Double = 0
    var protein: Double = 0
    var carbs: Double = 0
    var fat: Double = 0
    var fiber: Double = 0
    var sugar: Double = 0
    var water: Double = 0 // in mL
    var activeCalories: Double = 0
    var steps: Int = 0
}

// MARK: - HealthKit Service
@MainActor
class HealthKitService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isAuthorized = false
    @Published var todaySummary = DailyNutritionSummary(date: Date())
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let healthStore = HKHealthStore()
    
    // Data types we want to read
    private let readTypes: Set<HKObjectType> = [
        HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)!,
        HKQuantityType.quantityType(forIdentifier: .dietaryProtein)!,
        HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates)!,
        HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal)!,
        HKQuantityType.quantityType(forIdentifier: .dietaryFiber)!,
        HKQuantityType.quantityType(forIdentifier: .dietarySugar)!,
        HKQuantityType.quantityType(forIdentifier: .dietaryWater)!,
        HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKQuantityType.quantityType(forIdentifier: .stepCount)!,
        HKQuantityType.quantityType(forIdentifier: .bodyMass)!,
    ]
    
    // Data types we want to write
    private let writeTypes: Set<HKSampleType> = [
        HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)!,
        HKQuantityType.quantityType(forIdentifier: .dietaryProtein)!,
        HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates)!,
        HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal)!,
        HKQuantityType.quantityType(forIdentifier: .dietaryFiber)!,
        HKQuantityType.quantityType(forIdentifier: .dietarySugar)!,
        HKQuantityType.quantityType(forIdentifier: .dietaryWater)!,
    ]
    
    // MARK: - Initialization
    init() {
        Task {
            await checkAuthorizationStatus()
        }
    }
    
    // MARK: - Authorization
    var isHealthKitAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }
    
    func requestAuthorization() async throws {
        guard isHealthKitAvailable else {
            throw HealthKitError.notAvailable
        }
        
        try await healthStore.requestAuthorization(toShare: writeTypes, read: readTypes)
        await checkAuthorizationStatus()
    }
    
    private func checkAuthorizationStatus() async {
        guard isHealthKitAvailable else {
            isAuthorized = false
            return
        }
        
        // Check if we have at least read access to calories
        let calorieType = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)!
        let status = healthStore.authorizationStatus(for: calorieType)
        
        isAuthorized = status == .sharingAuthorized
    }
    
    // MARK: - Save Food Entry to HealthKit
    func saveFoodEntry(
        calories: Double,
        protein: Double,
        carbs: Double,
        fat: Double,
        fiber: Double? = nil,
        sugar: Double? = nil,
        date: Date = Date()
    ) async throws {
        
        var samples: [HKQuantitySample] = []
        
        // Calories
        if calories > 0 {
            let calorieType = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)!
            let calorieQuantity = HKQuantity(unit: .kilocalorie(), doubleValue: calories)
            let calorieSample = HKQuantitySample(type: calorieType, quantity: calorieQuantity, start: date, end: date)
            samples.append(calorieSample)
        }
        
        // Protein
        if protein > 0 {
            let proteinType = HKQuantityType.quantityType(forIdentifier: .dietaryProtein)!
            let proteinQuantity = HKQuantity(unit: .gram(), doubleValue: protein)
            let proteinSample = HKQuantitySample(type: proteinType, quantity: proteinQuantity, start: date, end: date)
            samples.append(proteinSample)
        }
        
        // Carbs
        if carbs > 0 {
            let carbType = HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates)!
            let carbQuantity = HKQuantity(unit: .gram(), doubleValue: carbs)
            let carbSample = HKQuantitySample(type: carbType, quantity: carbQuantity, start: date, end: date)
            samples.append(carbSample)
        }
        
        // Fat
        if fat > 0 {
            let fatType = HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal)!
            let fatQuantity = HKQuantity(unit: .gram(), doubleValue: fat)
            let fatSample = HKQuantitySample(type: fatType, quantity: fatQuantity, start: date, end: date)
            samples.append(fatSample)
        }
        
        // Fiber (optional)
        if let fiber = fiber, fiber > 0 {
            let fiberType = HKQuantityType.quantityType(forIdentifier: .dietaryFiber)!
            let fiberQuantity = HKQuantity(unit: .gram(), doubleValue: fiber)
            let fiberSample = HKQuantitySample(type: fiberType, quantity: fiberQuantity, start: date, end: date)
            samples.append(fiberSample)
        }
        
        // Sugar (optional)
        if let sugar = sugar, sugar > 0 {
            let sugarType = HKQuantityType.quantityType(forIdentifier: .dietarySugar)!
            let sugarQuantity = HKQuantity(unit: .gram(), doubleValue: sugar)
            let sugarSample = HKQuantitySample(type: sugarType, quantity: sugarQuantity, start: date, end: date)
            samples.append(sugarSample)
        }
        
        // Save all samples
        do {
            try await healthStore.save(samples)
            // Refresh today's summary after saving
            await fetchTodaySummary()
        } catch {
            throw HealthKitError.saveFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Save Water Intake
    func saveWaterIntake(milliliters: Double, date: Date = Date()) async throws {
        let waterType = HKQuantityType.quantityType(forIdentifier: .dietaryWater)!
        let waterQuantity = HKQuantity(unit: .literUnit(with: .milli), doubleValue: milliliters)
        let waterSample = HKQuantitySample(type: waterType, quantity: waterQuantity, start: date, end: date)
        
        try await healthStore.save(waterSample)
        await fetchTodaySummary()
    }
    
    // MARK: - Fetch Today's Summary
    func fetchTodaySummary() async {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        var summary = DailyNutritionSummary(date: now)
        
        // Fetch each type
        summary.calories = await fetchSum(for: .dietaryEnergyConsumed, unit: .kilocalorie(), start: startOfDay, end: endOfDay)
        summary.protein = await fetchSum(for: .dietaryProtein, unit: .gram(), start: startOfDay, end: endOfDay)
        summary.carbs = await fetchSum(for: .dietaryCarbohydrates, unit: .gram(), start: startOfDay, end: endOfDay)
        summary.fat = await fetchSum(for: .dietaryFatTotal, unit: .gram(), start: startOfDay, end: endOfDay)
        summary.fiber = await fetchSum(for: .dietaryFiber, unit: .gram(), start: startOfDay, end: endOfDay)
        summary.sugar = await fetchSum(for: .dietarySugar, unit: .gram(), start: startOfDay, end: endOfDay)
        summary.water = await fetchSum(for: .dietaryWater, unit: .literUnit(with: .milli), start: startOfDay, end: endOfDay)
        summary.activeCalories = await fetchSum(for: .activeEnergyBurned, unit: .kilocalorie(), start: startOfDay, end: endOfDay)
        summary.steps = Int(await fetchSum(for: .stepCount, unit: .count(), start: startOfDay, end: endOfDay))
        
        todaySummary = summary
    }
    
    // MARK: - Fetch Historical Data
    func fetchWeeklySummary() async -> [DailyNutritionSummary] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var summaries: [DailyNutritionSummary] = []
        
        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: date)!
            
            var summary = DailyNutritionSummary(date: date)
            summary.calories = await fetchSum(for: .dietaryEnergyConsumed, unit: .kilocalorie(), start: date, end: endOfDay)
            summary.protein = await fetchSum(for: .dietaryProtein, unit: .gram(), start: date, end: endOfDay)
            summary.carbs = await fetchSum(for: .dietaryCarbohydrates, unit: .gram(), start: date, end: endOfDay)
            summary.fat = await fetchSum(for: .dietaryFatTotal, unit: .gram(), start: date, end: endOfDay)
            
            summaries.append(summary)
        }
        
        return summaries.reversed()
    }
    
    // MARK: - Helper: Fetch Sum for Type
    private func fetchSum(
        for identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        start: Date,
        end: Date
    ) async -> Double {
        
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else {
            return 0
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                let value = result?.sumQuantity()?.doubleValue(for: unit) ?? 0
                continuation.resume(returning: value)
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - Get Current Weight
    func getCurrentWeight() async -> Double? {
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            return nil
        }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: weightType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let weight = sample.quantity.doubleValue(for: .pound())
                continuation.resume(returning: weight)
            }
            
            healthStore.execute(query)
        }
    }
}
