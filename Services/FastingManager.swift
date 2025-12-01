import Foundation
import SwiftUI
import Combine
import UserNotifications

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

    // Timer
    @Published var elapsedTime: TimeInterval = 0
    @Published var remainingTime: TimeInterval = 0

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

    // MARK: - Computed Properties
    var fastingHours: Int {
        selectedSchedule == .custom ? customFastingHours : selectedSchedule.fastingHours
    }

    var targetDuration: TimeInterval {
        TimeInterval(fastingHours * 3600)
    }

    var progress: Double {
        guard targetDuration > 0 else { return 0 }
        return min(elapsedTime / targetDuration, 1.0)
    }

    var formattedElapsedTime: String {
        formatTimeInterval(elapsedTime)
    }

    var formattedRemainingTime: String {
        formatTimeInterval(max(0, remainingTime))
    }

    var estimatedEndTime: Date? {
        guard let session = currentSession else { return nil }
        return session.startTime.addingTimeInterval(targetDuration)
    }

    // MARK: - Initialization
    private init() {
        loadState()
        if currentState == .fasting {
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

        startTimer()
        saveState()
        scheduleNotification()
    }

    func stopFasting() {
        timer?.invalidate()
        timer = nil

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

        saveState()
        cancelNotifications()
    }

    func resetFasting() {
        timer?.invalidate()
        timer = nil
        currentSession = nil
        currentState = .notStarted
        elapsedTime = 0
        remainingTime = 0
        saveState()
        cancelNotifications()
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
        guard let session = currentSession else { return }

        elapsedTime = Date().timeIntervalSince(session.startTime)
        remainingTime = max(0, targetDuration - elapsedTime)

        // Auto-complete when target reached
        if progress >= 1.0 && currentState == .fasting {
            // Optionally auto-stop or just notify
            // For now, we let it continue (some people fast longer)
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
    private func scheduleNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Fasting Complete!"
        content.body = "Congratulations! You've completed your \(selectedSchedule.rawValue) fast."
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

    private func cancelNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["fasting_complete"]
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

        if let session = currentSession,
           let encoded = try? JSONEncoder().encode(session) {
            userDefaults.set(encoded, forKey: sessionKey)
        } else {
            userDefaults.removeObject(forKey: sessionKey)
        }

        if let encoded = try? JSONEncoder().encode(fastingHistory) {
            userDefaults.set(encoded, forKey: historyKey)
        }
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
