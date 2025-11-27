import Foundation
import Combine
import HealthKit
import SwiftUI

// MARK: - HealthKit Manager

@MainActor
class HealthKitManager: ObservableObject {
    private let healthStore = HKHealthStore()
    
    @Published var isAuthorized = false
    @Published var authorizationStatus: AuthorizationStatus = .notDetermined
    @Published var lastSyncDate: Date?
    @Published var syncError: HealthKitError?
    
    // Health data properties
    @Published var currentWeight: Double?
    @Published var todayActiveCalories: Double = 0
    @Published var todaySteps: Double = 0
    @Published var todayWorkouts: [WorkoutSummary] = []
    @Published var weeklyWeightTrend: [WeightEntry] = []
    
    enum AuthorizationStatus {
        case notDetermined
        case denied
        case authorized
        case restricted
    }
    
    enum HealthKitError: LocalizedError {
        case notAvailable
        case authorizationDenied
        case syncFailed(String)
        case dataNotAvailable
        case permissionRequired
        
        var errorDescription: String? {
            switch self {
            case .notAvailable:
                return "HealthKit is not available on this device"
            case .authorizationDenied:
                return "Health app access was denied"
            case .syncFailed(let message):
                return "Sync failed: \(message)"
            case .dataNotAvailable:
                return "Health data is not available"
            case .permissionRequired:
                return "Health app permissions are required"
            }
        }
    }
    
    // MARK: - Health Data Models
    
    struct WeightEntry: Identifiable {
        let id = UUID()
        let date: Date
        let weight: Double // in kg
        let source: String
    }
    
    struct WorkoutSummary: Identifiable {
        let id = UUID()
        let type: HKWorkoutActivityType
        let duration: TimeInterval
        let caloriesBurned: Double
        let startDate: Date
        let endDate: Date
        
        var displayName: String {
            switch type {
            case .running: return "Running"
            case .cycling: return "Cycling"
            case .walking: return "Walking"
            case .swimming: return "Swimming"
            case .yoga: return "Yoga"
            case .traditionalStrengthTraining: return "Strength Training"
            case .highIntensityIntervalTraining: return "HIIT"
            case .dance: return "Dance"
            case .pilates: return "Pilates"
            default: return "Workout"
            }
        }
        
        var icon: String {
            switch type {
            case .running: return "figure.run"
            case .cycling: return "bicycle"
            case .walking: return "figure.walk"
            case .swimming: return "figure.pool.swim"
            case .yoga: return "figure.yoga"
            case .traditionalStrengthTraining: return "dumbbell.fill"
            case .highIntensityIntervalTraining: return "flame.fill"
            case .dance: return "music.note"
            case .pilates: return "figure.pilates"
            default: return "figure.mixed.cardio"
            }
        }
        
        var color: Color {
            switch type {
            case .running: return .orange
            case .cycling: return .blue
            case .walking: return .green
            case .swimming: return .cyan
            case .yoga: return .purple
            case .traditionalStrengthTraining: return .red
            case .highIntensityIntervalTraining: return .pink
            case .dance: return .yellow
            case .pilates: return .indigo
            default: return .gray
            }
        }
    }
    
    // MARK: - Initialization
    
    init() {
        checkHealthKitAvailability()
        checkAuthorizationStatus()
    }
    
    // MARK: - HealthKit Availability
    
    private func checkHealthKitAvailability() {
        guard HKHealthStore.isHealthDataAvailable() else {
            syncError = .notAvailable
            return
        }
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            await MainActor.run {
                syncError = .notAvailable
                authorizationStatus = .denied
            }
            return
        }
        
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .height)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.workoutType(),
            HKObjectType.quantityType(forIdentifier: .basalEnergyBurned)!
        ]
        
        let typesToWrite: Set<HKSampleType> = [
            HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed)!,
            HKObjectType.quantityType(forIdentifier: .dietaryProtein)!,
            HKObjectType.quantityType(forIdentifier: .dietaryCarbohydrates)!,
            HKObjectType.quantityType(forIdentifier: .dietaryFatTotal)!,
            HKObjectType.quantityType(forIdentifier: .dietaryFiber)!,
            HKObjectType.quantityType(forIdentifier: .dietarySugar)!,
            HKObjectType.quantityType(forIdentifier: .dietaryWater)!
        ]
        
        do {
            try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)
            await MainActor.run {
                checkAuthorizationStatus()
            }
        } catch {
            await MainActor.run {
                syncError = .authorizationDenied
                authorizationStatus = .denied
            }
        }
    }
    
    private func checkAuthorizationStatus() {
        guard HKHealthStore.isHealthDataAvailable() else {
            authorizationStatus = .denied
            return
        }
        
        let sampleType = HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed)!
        let status = healthStore.authorizationStatus(for: sampleType)
        
        switch status {
        case .notDetermined:
            authorizationStatus = .notDetermined
            isAuthorized = false
        case .sharingDenied:
            authorizationStatus = .denied
            isAuthorized = false
        case .sharingAuthorized:
            authorizationStatus = .authorized
            isAuthorized = true
        @unknown default:
            authorizationStatus = .denied
            isAuthorized = false
        }
    }
    
    // MARK: - Sync Nutrition Data to Health
    
    func syncNutritionData(_ foodEntries: [FoodEntry], for date: Date = Date()) async {
        guard isAuthorized else {
            syncError = .permissionRequired
            return
        }
        
        // Filter entries for the specified date
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date
        
        let dayEntries = foodEntries.filter { entry in
            entry.timestamp >= startOfDay && entry.timestamp < endOfDay
        }
        
        guard !dayEntries.isEmpty else { return }
        
        // Calculate totals
        let totalCalories = dayEntries.reduce(0) { $0 + $1.totalCalories }
        let totalProtein = dayEntries.reduce(0) { $0 + $1.totalProtein }
        let totalCarbs = dayEntries.reduce(0) { $0 + $1.totalCarbs }
        let totalFat = dayEntries.reduce(0) { $0 + $1.totalFat }
        let totalFiber = dayEntries.compactMap(\.fiber).reduce(0, +)
        let totalSugar = dayEntries.compactMap(\.sugar).reduce(0, +)
        
        // Create health samples
        let samples = createNutritionSamples(
            calories: totalCalories,
            protein: totalProtein,
            carbs: totalCarbs,
            fat: totalFat,
            fiber: totalFiber,
            sugar: totalSugar,
            date: date
        )
        
        do {
            try await healthStore.save(samples)
            await MainActor.run {
                lastSyncDate = Date()
                syncError = nil
            }
        } catch {
            await MainActor.run {
                syncError = .syncFailed(error.localizedDescription)
            }
        }
    }
    
    private func createNutritionSamples(
        calories: Double,
        protein: Double,
        carbs: Double,
        fat: Double,
        fiber: Double,
        sugar: Double,
        date: Date
    ) -> [HKQuantitySample] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date
        
        var samples: [HKQuantitySample] = []
        
        // Calories
        if let caloriesType = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed) {
            let caloriesQuantity = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: calories)
            let caloriesSample = HKQuantitySample(
                type: caloriesType,
                quantity: caloriesQuantity,
                start: startOfDay,
                end: endOfDay
            )
            samples.append(caloriesSample)
        }
        
        // Protein
        if let proteinType = HKQuantityType.quantityType(forIdentifier: .dietaryProtein) {
            let proteinQuantity = HKQuantity(unit: HKUnit.gram(), doubleValue: protein)
            let proteinSample = HKQuantitySample(
                type: proteinType,
                quantity: proteinQuantity,
                start: startOfDay,
                end: endOfDay
            )
            samples.append(proteinSample)
        }
        
        // Carbohydrates
        if let carbsType = HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates) {
            let carbsQuantity = HKQuantity(unit: HKUnit.gram(), doubleValue: carbs)
            let carbsSample = HKQuantitySample(
                type: carbsType,
                quantity: carbsQuantity,
                start: startOfDay,
                end: endOfDay
            )
            samples.append(carbsSample)
        }
        
        // Fat
        if let fatType = HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal) {
            let fatQuantity = HKQuantity(unit: HKUnit.gram(), doubleValue: fat)
            let fatSample = HKQuantitySample(
                type: fatType,
                quantity: fatQuantity,
                start: startOfDay,
                end: endOfDay
            )
            samples.append(fatSample)
        }
        
        // Fiber
        if fiber > 0, let fiberType = HKQuantityType.quantityType(forIdentifier: .dietaryFiber) {
            let fiberQuantity = HKQuantity(unit: HKUnit.gram(), doubleValue: fiber)
            let fiberSample = HKQuantitySample(
                type: fiberType,
                quantity: fiberQuantity,
                start: startOfDay,
                end: endOfDay
            )
            samples.append(fiberSample)
        }
        
        // Sugar
        if sugar > 0, let sugarType = HKQuantityType.quantityType(forIdentifier: .dietarySugar) {
            let sugarQuantity = HKQuantity(unit: HKUnit.gram(), doubleValue: sugar)
            let sugarSample = HKQuantitySample(
                type: sugarType,
                quantity: sugarQuantity,
                start: startOfDay,
                end: endOfDay
            )
            samples.append(sugarSample)
        }
        
        return samples
    }
    
    // MARK: - Read Health Data
    
    func fetchTodayHealthData() async {
        guard isAuthorized else { return }
        
        async let weight = fetchCurrentWeight()
        async let activeCalories = fetchTodayActiveCalories()
        async let steps = fetchTodaySteps()
        async let workouts = fetchTodayWorkouts()
        
        let results = await (weight, activeCalories, steps, workouts)
        
        await MainActor.run {
            currentWeight = results.0
            todayActiveCalories = results.1
            todaySteps = results.2
            todayWorkouts = results.3
        }
    }
    
    private func fetchCurrentWeight() async -> Double? {
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return nil }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(
            sampleType: weightType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [sortDescriptor]
        ) { _, samples, _ in
            if let sample = samples?.first as? HKQuantitySample {
                let weightInKg = sample.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
                Task { @MainActor in
                    self.currentWeight = weightInKg
                }
            }
        }
        
        healthStore.execute(query)
        
        // Return current weight from the published property after a brief delay
        try? await Task.sleep(nanoseconds: 500_000_000)
        return currentWeight
    }
    
    private func fetchTodayActiveCalories() async -> Double {
        guard let activeCaloriesType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return 0 }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: activeCaloriesType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, _ in
                let calories = result?.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie()) ?? 0
                continuation.resume(returning: calories)
            }
            
            healthStore.execute(query)
        }
    }
    
    private func fetchTodaySteps() async -> Double {
        guard let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return 0 }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepsType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, _ in
                let steps = result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                continuation.resume(returning: steps)
            }
            
            healthStore.execute(query)
        }
    }
    
    private func fetchTodayWorkouts() async -> [WorkoutSummary] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: HKObjectType.workoutType(),
                predicate: predicate,
                limit: 20,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, _ in
                let workouts = samples?.compactMap { sample -> WorkoutSummary? in
                    guard let workout = sample as? HKWorkout else { return nil }
                    
                    let caloriesBurned = workout.totalEnergyBurned?.doubleValue(for: HKUnit.kilocalorie()) ?? 0
                    
                    return WorkoutSummary(
                        type: workout.workoutActivityType,
                        duration: workout.duration,
                        caloriesBurned: caloriesBurned,
                        startDate: workout.startDate,
                        endDate: workout.endDate
                    )
                } ?? []
                
                continuation.resume(returning: workouts)
            }
            
            healthStore.execute(query)
        }
    }
    
    func fetchWeeklyWeightTrend() async {
        guard isAuthorized else { return }
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return }
        
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .weekOfYear, value: -4, to: endDate) ?? endDate
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)
        
        let query = HKSampleQuery(
            sampleType: weightType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [sortDescriptor]
        ) { _, samples, _ in
            let weightEntries = samples?.compactMap { sample -> WeightEntry? in
                guard let weightSample = sample as? HKQuantitySample else { return nil }
                let weightInKg = weightSample.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
                return WeightEntry(
                    date: weightSample.endDate,
                    weight: weightInKg,
                    source: weightSample.sourceRevision.source.name
                )
            } ?? []
            
            Task { @MainActor in
                self.weeklyWeightTrend = weightEntries
            }
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Auto-sync for Food Entries
    
    func autoSyncIfEnabled(_ foodEntries: [FoodEntry]) {
        guard isAuthorized else { return }
        
        Task {
            await syncNutritionData(foodEntries)
        }
    }
    
    // MARK: - Utility Methods
    
    func formatWeight(_ weight: Double?) -> String {
        guard let weight = weight else { return "Not Available" }
        
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 1
        
        // Convert to user's preferred unit (assume kg for now)
        return "\(formatter.string(from: NSNumber(value: weight)) ?? "0") kg"
    }
    
    func formatCalories(_ calories: Double) -> String {
        "\(Int(calories))"
    }
    
    func formatSteps(_ steps: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: Int(steps))) ?? "0"
    }
}