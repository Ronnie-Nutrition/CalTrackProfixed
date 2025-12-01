import Foundation
import SwiftUI
import Combine
import UserNotifications
import WidgetKit

// MARK: - Fasting Schedule Presets
enum FastingSchedule: String, CaseIterable, Codable {
    case sixteenEight = "16:8"
    case eighteenSix = "18:6"
    case twentyFour = "20:4"
    case omad = "OMAD (23:1)"
    case custom = "Custom"

    var fastingHours: Int {
        switch self {
        case .sixteenEight: return 16
        case .eighteenSix: return 18
        case .twentyFour: return 20
        case .omad: return 23
        case .custom: return 16 // Default, user can adjust
        }
    }

    var eatingHours: Int {
        return 24 - fastingHours
    }

    var description: String {
        switch self {
        case .sixteenEight: return "Fast 16 hours, eat within 8 hours"
        case .eighteenSix: return "Fast 18 hours, eat within 6 hours"
        case .twentyFour: return "Fast 20 hours, eat within 4 hours"
        case .omad: return "One meal a day - 23 hour fast"
        case .custom: return "Set your own fasting window"
        }
    }

    var icon: String {
        switch self {
        case .sixteenEight: return "clock"
        case .eighteenSix: return "clock.fill"
        case .twentyFour: return "timer"
        case .omad: return "flame.fill"
        case .custom: return "slider.horizontal.3"
        }
    }
}

// MARK: - Fasting State
enum FastingState: String, Codable {
    case fasting
    case eating
    case notStarted
}

// MARK: - Fasting Session
struct FastingSession: Codable, Identifiable {
    var id = UUID()
    let startTime: Date
    var endTime: Date?
    let targetDuration: TimeInterval
    let schedule: FastingSchedule
    var completed: Bool

    var actualDuration: TimeInterval {
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime)
    }

    var progress: Double {
        min(actualDuration / targetDuration, 1.0)
    }
}

// MARK: - Fasting Manager
@MainActor
class FastingManager: ObservableObject {
    static let shared = FastingManager()

    // MARK: - Published Properties
    @Published var currentState: FastingState = .notStarted
    @Published var selectedSchedule: FastingSchedule = .sixteenEight
    @Published var customFastingHours: Int = 16
    @Published var currentSession: FastingSession?
    @Published var fastingHistory: [FastingSession] = []
    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    @Published var totalFastsCompleted: Int = 0

    // Fasting Timer
    @Published var elapsedTime: TimeInterval = 0
    @Published var remainingTime: TimeInterval = 0

    // Eating Window Timer
    @Published var eatingWindowStartTime: Date?
    @Published var eatingWindowElapsedTime: TimeInterval = 0
    @Published var eatingWindowRemainingTime: TimeInterval = 0

    // Water intake tracking
    @Published var waterIntake: Int = 0 // glasses of water
    @Published var waterGoal: Int = 8 // default 8 glasses

    private var timer: Timer?
    private let userDefaults = UserDefaults.standard

    // MARK: - Keys
    private let stateKey = "fasting_state"
    private let scheduleKey = "fasting_schedule"
    private let customHoursKey = "fasting_custom_hours"
    private let sessionKey = "fasting_current_session"
    private let historyKey = "fasting_history"
    private let streakKey = "fasting_current_streak"
    private let longestStreakKey = "fasting_longest_streak"
    private let totalFastsKey = "fasting_total_completed"
    private let eatingWindowStartKey = "eating_window_start"
    private let waterIntakeKey = "fasting_water_intake"
    private let waterGoalKey = "fasting_water_goal"

    // MARK: - Computed Properties
    var fastingHours: Int {
        selectedSchedule == .custom ? customFastingHours : selectedSchedule.fastingHours
    }

    var eatingWindowHours: Int {
        24 - fastingHours
    }

    var targetDuration: TimeInterval {
        TimeInterval(fastingHours * 3600)
    }

    var eatingWindowDuration: TimeInterval {
        TimeInterval(eatingWindowHours * 3600)
    }

    var progress: Double {
        guard targetDuration > 0 else { return 0 }
        return min(elapsedTime / targetDuration, 1.0)
    }

    var eatingWindowProgress: Double {
        guard eatingWindowDuration > 0 else { return 0 }
        return min(eatingWindowElapsedTime / eatingWindowDuration, 1.0)
    }

    var formattedElapsedTime: String {
        formatTimeInterval(elapsedTime)
    }

    var formattedRemainingTime: String {
        formatTimeInterval(max(0, remainingTime))
    }

    var formattedEatingWindowRemaining: String {
        formatTimeInterval(max(0, eatingWindowRemainingTime))
    }

    var estimatedEndTime: Date? {
        guard let session = currentSession else { return nil }
        return session.startTime.addingTimeInterval(targetDuration)
    }

    var eatingWindowEndTime: Date? {
        guard let startTime = eatingWindowStartTime else { return nil }
        return startTime.addingTimeInterval(eatingWindowDuration)
    }

    // Fasting benefits based on elapsed time
    var currentFastingBenefit: FastingBenefit? {
        FastingBenefit.allBenefits.last { elapsedTime >= $0.hoursRequired * 3600 }
    }

    var nextFastingBenefit: FastingBenefit? {
        FastingBenefit.allBenefits.first { elapsedTime < $0.hoursRequired * 3600 }
    }

    var timeToNextBenefit: TimeInterval? {
        guard let next = nextFastingBenefit else { return nil }
        return (next.hoursRequired * 3600) - elapsedTime
    }

    // MARK: - Initialization
    private init() {
        loadState()
        if currentState == .fasting || currentState == .eating {
            startTimer()
        }
    }

    // MARK: - Actions
    func startFasting() {
        let session = FastingSession(
            startTime: Date(),
            endTime: nil,
            targetDuration: targetDuration,
            schedule: selectedSchedule,
            completed: false
        )

        currentSession = session
        currentState = .fasting
        elapsedTime = 0
        remainingTime = targetDuration
        waterIntake = 0 // Reset water intake for new fast
        eatingWindowStartTime = nil
        eatingWindowElapsedTime = 0
        eatingWindowRemainingTime = 0

        startTimer()
        saveState()
        scheduleFastingNotification()
        scheduleWaterReminders()
    }

    func stopFasting() {
        if var session = currentSession {
            session.endTime = Date()
            session.completed = session.progress >= 1.0

            // Add to history
            fastingHistory.insert(session, at: 0)

            // Update stats
            if session.completed {
                totalFastsCompleted += 1
                updateStreak(completed: true)
            } else {
                updateStreak(completed: false)
            }

            // Keep only last 30 days of history
            if fastingHistory.count > 30 {
                fastingHistory = Array(fastingHistory.prefix(30))
            }
        }

        currentSession = nil
        currentState = .eating
        elapsedTime = 0
        remainingTime = 0

        // Start eating window tracking
        eatingWindowStartTime = Date()
        eatingWindowElapsedTime = 0
        eatingWindowRemainingTime = eatingWindowDuration

        saveState()
        cancelFastingNotifications()
        scheduleEatingWindowNotifications()

        // Keep timer running for eating window
        startTimer()
    }

    func endEatingWindow() {
        // Transition from eating to ready for next fast
        currentState = .notStarted
        eatingWindowStartTime = nil
        eatingWindowElapsedTime = 0
        eatingWindowRemainingTime = 0

        timer?.invalidate()
        timer = nil

        saveState()
        cancelEatingWindowNotifications()
    }

    func resetFasting() {
        timer?.invalidate()
        timer = nil
        currentSession = nil
        currentState = .notStarted
        elapsedTime = 0
        remainingTime = 0
        eatingWindowStartTime = nil
        eatingWindowElapsedTime = 0
        eatingWindowRemainingTime = 0
        waterIntake = 0
        saveState()
        cancelFastingNotifications()
        cancelEatingWindowNotifications()
    }

    // MARK: - Water Tracking
    func addWater() {
        waterIntake += 1
        saveState()
    }

    func removeWater() {
        if waterIntake > 0 {
            waterIntake -= 1
            saveState()
        }
    }

    // MARK: - Timer
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateTimer()
            }
        }
    }

    private func updateTimer() {
        if currentState == .fasting {
            guard let session = currentSession else { return }

            elapsedTime = Date().timeIntervalSince(session.startTime)
            remainingTime = max(0, targetDuration - elapsedTime)

            // Auto-complete when target reached - keep running but user is notified
        } else if currentState == .eating {
            guard let startTime = eatingWindowStartTime else { return }

            eatingWindowElapsedTime = Date().timeIntervalSince(startTime)
            eatingWindowRemainingTime = max(0, eatingWindowDuration - eatingWindowElapsedTime)

            // Check if eating window has ended
            if eatingWindowProgress >= 1.0 {
                // Eating window complete - could auto-transition or notify
            }
        }
    }

    // MARK: - Streaks
    private func updateStreak(completed: Bool) {
        if completed {
            // Check if last fast was within 48 hours (allowing for some flexibility)
            if let lastFast = fastingHistory.dropFirst().first,
               let lastEnd = lastFast.endTime,
               Date().timeIntervalSince(lastEnd) < 48 * 3600 {
                currentStreak += 1
            } else {
                currentStreak = 1
            }

            longestStreak = max(longestStreak, currentStreak)
        } else {
            currentStreak = 0
        }
    }

    // MARK: - Notifications
    private func scheduleFastingNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Fasting Complete! 🎉"
        content.body = "Congratulations! You've completed your \(selectedSchedule.rawValue) fast. You can now start your eating window."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: targetDuration,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "fasting_complete",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    private func scheduleWaterReminders() {
        // Schedule water reminders every 2 hours during fasting
        let intervals: [TimeInterval] = [7200, 14400, 21600, 28800] // 2, 4, 6, 8 hours

        for (index, interval) in intervals.enumerated() {
            guard interval < targetDuration else { continue }

            let content = UNMutableNotificationContent()
            content.title = "Stay Hydrated 💧"
            content.body = "Remember to drink water during your fast. You've been fasting for \(Int(interval / 3600)) hours."
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: interval,
                repeats: false
            )

            let request = UNNotificationRequest(
                identifier: "water_reminder_\(index)",
                content: content,
                trigger: trigger
            )

            UNUserNotificationCenter.current().add(request)
        }
    }

    private func scheduleEatingWindowNotifications() {
        // Notify when eating window is almost over (1 hour before)
        let oneHourBefore = eatingWindowDuration - 3600
        if oneHourBefore > 0 {
            let content = UNMutableNotificationContent()
            content.title = "Eating Window Closing Soon ⏰"
            content.body = "Your eating window ends in 1 hour. Finish eating soon to maintain your fasting schedule."
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: oneHourBefore,
                repeats: false
            )

            let request = UNNotificationRequest(
                identifier: "eating_window_warning",
                content: content,
                trigger: trigger
            )

            UNUserNotificationCenter.current().add(request)
        }

        // Notify when eating window ends
        let content = UNMutableNotificationContent()
        content.title = "Eating Window Closed 🍽️"
        content.body = "Your \(eatingWindowHours)-hour eating window has ended. Ready to start your next fast?"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: eatingWindowDuration,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "eating_window_end",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    private func cancelFastingNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["fasting_complete", "water_reminder_0", "water_reminder_1", "water_reminder_2", "water_reminder_3"]
        )
    }

    private func cancelEatingWindowNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["eating_window_warning", "eating_window_end"]
        )
    }

    // MARK: - Persistence
    private func saveState() {
        userDefaults.set(currentState.rawValue, forKey: stateKey)
        userDefaults.set(selectedSchedule.rawValue, forKey: scheduleKey)
        userDefaults.set(customFastingHours, forKey: customHoursKey)
        userDefaults.set(currentStreak, forKey: streakKey)
        userDefaults.set(longestStreak, forKey: longestStreakKey)
        userDefaults.set(totalFastsCompleted, forKey: totalFastsKey)
        userDefaults.set(waterIntake, forKey: waterIntakeKey)
        userDefaults.set(waterGoal, forKey: waterGoalKey)

        if let session = currentSession,
           let encoded = try? JSONEncoder().encode(session) {
            userDefaults.set(encoded, forKey: sessionKey)
        } else {
            userDefaults.removeObject(forKey: sessionKey)
        }

        if let encoded = try? JSONEncoder().encode(fastingHistory) {
            userDefaults.set(encoded, forKey: historyKey)
        }

        // Save eating window start time
        if let eatingStart = eatingWindowStartTime {
            userDefaults.set(eatingStart, forKey: eatingWindowStartKey)
        } else {
            userDefaults.removeObject(forKey: eatingWindowStartKey)
        }

        // Sync with widget
        syncWidgetData()
    }

    private func syncWidgetData() {
        WidgetDataProvider.shared.updateFastingData(
            state: currentState.rawValue,
            startTime: currentSession?.startTime,
            targetHours: fastingHours
        )
    }

    private func loadState() {
        if let stateString = userDefaults.string(forKey: stateKey),
           let state = FastingState(rawValue: stateString) {
            currentState = state
        }

        if let scheduleString = userDefaults.string(forKey: scheduleKey),
           let schedule = FastingSchedule(rawValue: scheduleString) {
            selectedSchedule = schedule
        }

        customFastingHours = userDefaults.integer(forKey: customHoursKey)
        if customFastingHours == 0 { customFastingHours = 16 }

        currentStreak = userDefaults.integer(forKey: streakKey)
        longestStreak = userDefaults.integer(forKey: longestStreakKey)
        totalFastsCompleted = userDefaults.integer(forKey: totalFastsKey)
        waterIntake = userDefaults.integer(forKey: waterIntakeKey)
        waterGoal = userDefaults.integer(forKey: waterGoalKey)
        if waterGoal == 0 { waterGoal = 8 }

        if let sessionData = userDefaults.data(forKey: sessionKey),
           let session = try? JSONDecoder().decode(FastingSession.self, from: sessionData) {
            currentSession = session
            elapsedTime = Date().timeIntervalSince(session.startTime)
            remainingTime = max(0, session.targetDuration - elapsedTime)
        }

        if let historyData = userDefaults.data(forKey: historyKey),
           let history = try? JSONDecoder().decode([FastingSession].self, from: historyData) {
            fastingHistory = history
        }

        // Load eating window state
        if let eatingStart = userDefaults.object(forKey: eatingWindowStartKey) as? Date {
            eatingWindowStartTime = eatingStart
            eatingWindowElapsedTime = Date().timeIntervalSince(eatingStart)
            eatingWindowRemainingTime = max(0, eatingWindowDuration - eatingWindowElapsedTime)

            // If eating window has expired while app was closed, reset to notStarted
            if eatingWindowElapsedTime >= eatingWindowDuration && currentState == .eating {
                currentState = .notStarted
                eatingWindowStartTime = nil
                eatingWindowElapsedTime = 0
                eatingWindowRemainingTime = 0
            }
        }
    }

    // MARK: - Helpers
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    // MARK: - Statistics
    var averageFastDuration: TimeInterval {
        guard !fastingHistory.isEmpty else { return 0 }
        let total = fastingHistory.reduce(0) { $0 + $1.actualDuration }
        return total / Double(fastingHistory.count)
    }

    var completionRate: Double {
        guard !fastingHistory.isEmpty else { return 0 }
        let completed = fastingHistory.filter { $0.completed }.count
        return Double(completed) / Double(fastingHistory.count)
    }

    var thisWeekFasts: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return fastingHistory.filter { $0.startTime >= weekAgo }.count
    }
}

// MARK: - Fasting Benefits Timeline
struct FastingBenefit: Identifiable {
    let id = UUID()
    let hoursRequired: Double
    let title: String
    let description: String
    let icon: String
    let color: String

    static let allBenefits: [FastingBenefit] = [
        FastingBenefit(
            hoursRequired: 0,
            title: "Fast Started",
            description: "Your body begins transitioning from fed to fasting state.",
            icon: "play.circle.fill",
            color: "blue"
        ),
        FastingBenefit(
            hoursRequired: 4,
            title: "Insulin Drops",
            description: "Blood sugar stabilizes and insulin levels begin to decrease.",
            icon: "arrow.down.circle.fill",
            color: "green"
        ),
        FastingBenefit(
            hoursRequired: 8,
            title: "Glucose Used",
            description: "Your body has used most of its glucose stores.",
            icon: "flame.fill",
            color: "orange"
        ),
        FastingBenefit(
            hoursRequired: 12,
            title: "Fat Burning Begins",
            description: "Body enters ketosis - burning fat for energy instead of glucose.",
            icon: "bolt.fill",
            color: "yellow"
        ),
        FastingBenefit(
            hoursRequired: 14,
            title: "Growth Hormone Rises",
            description: "Human growth hormone levels increase, supporting muscle preservation.",
            icon: "arrow.up.circle.fill",
            color: "purple"
        ),
        FastingBenefit(
            hoursRequired: 16,
            title: "Autophagy Begins",
            description: "Cellular cleanup process starts - removing damaged cells and proteins.",
            icon: "sparkles",
            color: "cyan"
        ),
        FastingBenefit(
            hoursRequired: 18,
            title: "Deep Ketosis",
            description: "Maximum fat burning state. Body is efficiently using fat for fuel.",
            icon: "flame.circle.fill",
            color: "red"
        ),
        FastingBenefit(
            hoursRequired: 24,
            title: "Cell Regeneration",
            description: "Enhanced autophagy promotes cellular repair and regeneration.",
            icon: "arrow.triangle.2.circlepath",
            color: "mint"
        )
    ]
}
