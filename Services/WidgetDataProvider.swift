import Foundation
import WidgetKit
import SwiftData

/// Service to share data between main app and widgets via App Groups
class WidgetDataProvider {
    static let shared = WidgetDataProvider()

    private let appGroupIdentifier = "group.easyaiflows.com.CalTrackProFixed"
    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }

    private init() {}

    // MARK: - Sync from Database

    /// Syncs today's nutrition data from SwiftData to the widget
    func syncFromDatabase(modelContext: ModelContext, calorieGoal: Int = 2000, proteinGoal: Int = 150, carbsGoal: Int = 250, fatGoal: Int = 65) {
        // Query today's food entries
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? Date()

        let descriptor = FetchDescriptor<FoodEntry>(
            predicate: #Predicate<FoodEntry> { entry in
                entry.timestamp >= startOfToday && entry.timestamp < endOfToday
            }
        )

        do {
            let todayEntries = try modelContext.fetch(descriptor)

            // Calculate totals
            let totalCalories = todayEntries.reduce(0) { $0 + $1.totalCalories }
            let totalProtein = todayEntries.reduce(0) { $0 + $1.totalProtein }
            let totalCarbs = todayEntries.reduce(0) { $0 + $1.totalCarbs }
            let totalFat = todayEntries.reduce(0) { $0 + $1.totalFat }

            // Update shared UserDefaults
            updateNutritionData(
                calories: Int(totalCalories),
                calorieGoal: calorieGoal,
                protein: Int(totalProtein),
                proteinGoal: proteinGoal,
                carbs: Int(totalCarbs),
                carbsGoal: carbsGoal,
                fat: Int(totalFat),
                fatGoal: fatGoal
            )
        } catch {
            print("WidgetDataProvider: Error fetching food entries: \(error)")
        }
    }

    // MARK: - Calorie Data

    func updateCalorieData(consumed: Int, goal: Int) {
        sharedDefaults?.set(consumed, forKey: "todayCalories")
        sharedDefaults?.set(goal, forKey: "calorieGoal")
        reloadWidgets()
    }

    func updateNutritionData(
        calories: Int,
        calorieGoal: Int,
        protein: Int,
        proteinGoal: Int,
        carbs: Int,
        carbsGoal: Int,
        fat: Int,
        fatGoal: Int
    ) {
        sharedDefaults?.set(calories, forKey: "todayCalories")
        sharedDefaults?.set(calorieGoal, forKey: "calorieGoal")
        sharedDefaults?.set(protein, forKey: "todayProtein")
        sharedDefaults?.set(proteinGoal, forKey: "proteinGoal")
        sharedDefaults?.set(carbs, forKey: "todayCarbs")
        sharedDefaults?.set(carbsGoal, forKey: "carbsGoal")
        sharedDefaults?.set(fat, forKey: "todayFat")
        sharedDefaults?.set(fatGoal, forKey: "fatGoal")
        reloadWidgets()
    }

    // MARK: - Fasting Data

    func updateFastingData(
        state: String,
        startTime: Date?,
        targetHours: Int
    ) {
        sharedDefaults?.set(state, forKey: "fastingState")
        if let startTime = startTime {
            sharedDefaults?.set(startTime.timeIntervalSince1970, forKey: "fastingStartTime")
        } else {
            sharedDefaults?.removeObject(forKey: "fastingStartTime")
        }
        sharedDefaults?.set(targetHours, forKey: "fastingTargetHours")
        reloadWidgets()
    }

    func startFasting(targetHours: Int) {
        sharedDefaults?.set("fasting", forKey: "fastingState")
        sharedDefaults?.set(Date().timeIntervalSince1970, forKey: "fastingStartTime")
        sharedDefaults?.set(targetHours, forKey: "fastingTargetHours")
        reloadWidgets()
    }

    func stopFasting() {
        sharedDefaults?.set("eating", forKey: "fastingState")
        sharedDefaults?.removeObject(forKey: "fastingStartTime")
        reloadWidgets()
    }

    func resetFasting() {
        sharedDefaults?.set("not_started", forKey: "fastingState")
        sharedDefaults?.removeObject(forKey: "fastingStartTime")
        reloadWidgets()
    }

    // MARK: - Widget Reload

    func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }

    func reloadCalorieWidget() {
        WidgetCenter.shared.reloadTimelines(ofKind: "CalorieProgressWidget")
    }

    func reloadFastingWidget() {
        WidgetCenter.shared.reloadTimelines(ofKind: "FastingTimerWidget")
    }

    func reloadNutritionWidget() {
        WidgetCenter.shared.reloadTimelines(ofKind: "NutritionSummaryWidget")
    }

    // MARK: - Daily Reset

    func resetDailyData() {
        sharedDefaults?.set(0, forKey: "todayCalories")
        sharedDefaults?.set(0, forKey: "todayProtein")
        sharedDefaults?.set(0, forKey: "todayCarbs")
        sharedDefaults?.set(0, forKey: "todayFat")
        reloadWidgets()
    }

    // MARK: - Goals Setup

    func setNutritionGoals(
        calorieGoal: Int,
        proteinGoal: Int,
        carbsGoal: Int,
        fatGoal: Int
    ) {
        sharedDefaults?.set(calorieGoal, forKey: "calorieGoal")
        sharedDefaults?.set(proteinGoal, forKey: "proteinGoal")
        sharedDefaults?.set(carbsGoal, forKey: "carbsGoal")
        sharedDefaults?.set(fatGoal, forKey: "fatGoal")
        reloadWidgets()
    }
}
