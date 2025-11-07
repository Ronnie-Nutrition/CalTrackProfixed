import Foundation
import HealthKit
import SwiftUI

@MainActor
class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    
    @Published var isHealthKitAvailable = false
    @Published var isAuthorized = false
    @Published var authorizationStatus: HKAuthorizationStatus = .notDetermined
    @Published var recentWorkouts: [HKWorkout] = []
    @Published var currentWeight: Double?
    @Published var dailyActiveCalories: Double = 0
    @Published var errorMessage: String?
    
    private let healthStore = HKHealthStore()
    
    // Health data types we want to read
    private let readTypes: Set<HKObjectType> = [
        HKObjectType.workoutType(),
        HKObjectType.quantityType(forIdentifier: .bodyMass)!,
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKObjectType.quantityType(forIdentifier: .basalEnergyBurned)!,
        HKObjectType.quantityType(forIdentifier: .height)!
    ]
    
    // Health data types we want to write
    private let writeTypes: Set<HKSampleType> = [
        HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed)!,
        HKObjectType.quantityType(forIdentifier: .dietaryProtein)!,
        HKObjectType.quantityType(forIdentifier: .dietaryCarbohydrates)!,
        HKObjectType.quantityType(forIdentifier: .dietaryFatTotal)!,
        HKObjectType.quantityType(forIdentifier: .dietaryFiber)!,
        HKObjectType.quantityType(forIdentifier: .dietaryCalcium)!,
        HKObjectType.quantityType(forIdentifier: .dietaryIron)!,
        HKObjectType.quantityType(forIdentifier: .dietaryVitaminC)!
    ]
    
    private init() {
        isHealthKitAvailable = HKHealthStore.isHealthDataAvailable()
        
        if isHealthKitAvailable {
            checkAuthorizationStatus()
        }
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() async {
        guard isHealthKitAvailable else {
            await MainActor.run {
                errorMessage = "HealthKit is not available on this device"
            }
            return
        }
        
        do {
            try await healthStore.requestAuthorization(toShare: writeTypes, read: readTypes)
            await checkAuthorizationStatus()
            
            if isAuthorized {
                await loadHealthData()
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to request HealthKit authorization: \(error.localizedDescription)"
            }
        }
    }
    
    private func checkAuthorizationStatus() async {
        await MainActor.run {
            // Check if we can write nutrition data
            let caloriesType = HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed)!
            authorizationStatus = healthStore.authorizationStatus(for: caloriesType)
            isAuthorized = authorizationStatus == .sharingAuthorized
        }
    }
    
    // MARK: - Write Nutrition Data
    
    func saveFoodEntry(_ foodEntry: FoodEntry) async {
        guard isAuthorized else { return }
        
        let samples = createNutritionSamples(from: foodEntry)
        
        do {
            try await healthStore.save(samples)
            print("✅ Saved nutrition data to Health app")
        } catch {
            await MainActor.run {
                errorMessage = "Failed to save nutrition data: \(error.localizedDescription)"
            }
        }
    }
    
    private func createNutritionSamples(from foodEntry: FoodEntry) -> [HKQuantitySample] {
        var samples: [HKQuantitySample] = []
        let now = Date()
        
        // Calories
        if let caloriesType = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed) {
            let caloriesQuantity = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: foodEntry.calories)
            let caloriesSample = HKQuantitySample(
                type: caloriesType,
                quantity: caloriesQuantity,
                start: now,
                end: now,
                metadata: [HKMetadataKeyFoodType: foodEntry.name]
            )
            samples.append(caloriesSample)
        }
        
        // Protein
        if let proteinType = HKQuantityType.quantityType(forIdentifier: .dietaryProtein) {
            let proteinQuantity = HKQuantity(unit: HKUnit.gram(), doubleValue: foodEntry.protein)
            let proteinSample = HKQuantitySample(
                type: proteinType,
                quantity: proteinQuantity,
                start: now,
                end: now,
                metadata: [HKMetadataKeyFoodType: foodEntry.name]
            )
            samples.append(proteinSample)
        }
        
        // Carbohydrates
        if let carbsType = HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates) {
            let carbsQuantity = HKQuantity(unit: HKUnit.gram(), doubleValue: foodEntry.carbs)
            let carbsSample = HKQuantitySample(
                type: carbsType,
                quantity: carbsQuantity,
                start: now,
                end: now,
                metadata: [HKMetadataKeyFoodType: foodEntry.name]
            )
            samples.append(carbsSample)
        }
        
        // Fat
        if let fatType = HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal) {
            let fatQuantity = HKQuantity(unit: HKUnit.gram(), doubleValue: foodEntry.fat)
            let fatSample = HKQuantitySample(
                type: fatType,
                quantity: fatQuantity,
                start: now,
                end: now,
                metadata: [HKMetadataKeyFoodType: foodEntry.name]
            )
            samples.append(fatSample)
        }
        
        return samples
    }
    
    // MARK: - Read Health Data
    
    func loadHealthData() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadRecentWorkouts() }
            group.addTask { await self.loadCurrentWeight() }
            group.addTask { await self.loadDailyActiveCalories() }
        }
    }
    
    private func loadRecentWorkouts() async {
        guard let workoutType = HKObjectType.workoutType() as? HKSampleType else { return }
        
        let predicate = HKQuery.predicateForSamples(
            withStart: Calendar.current.date(byAdding: .day, value: -7, to: Date()),
            end: Date(),
            options: .strictStartDate
        )
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: predicate,
                limit: 10,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                Task { @MainActor in
                    if let workouts = samples as? [HKWorkout] {
                        self.recentWorkouts = workouts
                    }
                    continuation.resume()
                }
            }
            
            healthStore.execute(query)
        }
    }
    
    private func loadCurrentWeight() async {
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return }
        
        let predicate = HKQuery.predicateForSamples(
            withStart: Calendar.current.date(byAdding: .month, value: -1, to: Date()),
            end: Date(),
            options: .strictEndDate
        )
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: weightType,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                Task { @MainActor in
                    if let sample = samples?.first as? HKQuantitySample {
                        self.currentWeight = sample.quantity.doubleValue(for: HKUnit.pound())
                    }
                    continuation.resume()
                }
            }
            
            healthStore.execute(query)
        }
    }
    
    private func loadDailyActiveCalories() async {
        guard let activeCaloriesType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: activeCaloriesType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                Task { @MainActor in
                    if let sum = result?.sumQuantity() {
                        self.dailyActiveCalories = sum.doubleValue(for: HKUnit.kilocalorie())
                    }
                    continuation.resume()
                }
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - Calorie Adjustment
    
    func getAdjustedCalorieGoal(baseGoal: Double) -> Double {
        // Adjust calorie goal based on active calories burned
        let adjustment = dailyActiveCalories * 0.5 // Add 50% of active calories
        return baseGoal + adjustment
    }
    
    // MARK: - Background Updates
    
    func enableBackgroundDelivery() async {
        guard isAuthorized else { return }
        
        let types = [
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.workoutType()
        ]
        
        for type in types {
            do {
                try await healthStore.enableBackgroundDelivery(
                    for: type,
                    frequency: .immediate
                ) { [weak self] in
                    Task {
                        await self?.loadHealthData()
                    }
                }
            } catch {
                print("Failed to enable background delivery for \(type): \(error)")
            }
        }
    }
}