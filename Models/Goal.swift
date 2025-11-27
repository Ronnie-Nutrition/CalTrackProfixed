import SwiftData
import Combine
import Foundation

@Model
final class Goal {
    var id = UUID()
    var name: String
    var goalDescription: String
    var type: GoalType
    var target: Double
    var currentProgress: Double
    var unit: String
    var timeFrame: TimeFrame
    var startDate: Date
    var endDate: Date
    var isActive: Bool
    var isCompleted: Bool
    var createdAt: Date
    var completedAt: Date?
    var streak: Int
    var bestStreak: Int
    var priority: Priority
    
    enum GoalType: String, Codable, CaseIterable {
        case calorieTarget = "calories"
        case proteinTarget = "protein"
        case carbTarget = "carbs"
        case fatTarget = "fat"
        case weightLoss = "weight_loss"
        case weightGain = "weight_gain"
        case waterIntake = "water"
        case exerciseMinutes = "exercise"
        case stepsDaily = "steps"
        case mealPrep = "meal_prep"
        case recipesCreated = "recipes"
        case consecutiveDays = "streak"
        
        var displayName: String {
            switch self {
            case .calorieTarget: return "Calorie Target"
            case .proteinTarget: return "Protein Goal"
            case .carbTarget: return "Carb Goal"
            case .fatTarget: return "Fat Goal"
            case .weightLoss: return "Weight Loss"
            case .weightGain: return "Weight Gain"
            case .waterIntake: return "Water Intake"
            case .exerciseMinutes: return "Exercise Minutes"
            case .stepsDaily: return "Daily Steps"
            case .mealPrep: return "Meal Prep"
            case .recipesCreated: return "Recipe Creation"
            case .consecutiveDays: return "Consistency Streak"
            }
        }
        
        var icon: String {
            switch self {
            case .calorieTarget: return "flame.fill"
            case .proteinTarget: return "leaf.fill"
            case .carbTarget: return "grain.fill"
            case .fatTarget: return "drop.fill"
            case .weightLoss: return "scale.mass.fill"
            case .weightGain: return "plus.square.fill"
            case .waterIntake: return "drop.circle.fill"
            case .exerciseMinutes: return "figure.run"
            case .stepsDaily: return "shoe.2.fill"
            case .mealPrep: return "calendar.badge.plus"
            case .recipesCreated: return "book.fill"
            case .consecutiveDays: return "checkmark.seal.fill"
            }
        }
    }
    
    enum TimeFrame: String, Codable, CaseIterable {
        case daily = "daily"
        case weekly = "weekly"
        case monthly = "monthly"
        case quarterly = "quarterly"
        case yearly = "yearly"
        case custom = "custom"
        
        var displayName: String {
            switch self {
            case .daily: return "Daily"
            case .weekly: return "Weekly"
            case .monthly: return "Monthly"
            case .quarterly: return "Quarterly"
            case .yearly: return "Yearly"
            case .custom: return "Custom"
            }
        }
    }
    
    enum Priority: String, Codable, CaseIterable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        case critical = "critical"
        
        var color: String {
            switch self {
            case .low: return "blue"
            case .medium: return "green"
            case .high: return "orange"
            case .critical: return "red"
            }
        }
    }
    
    init(name: String, goalDescription: String, type: GoalType, target: Double, 
         unit: String, timeFrame: TimeFrame, startDate: Date = Date(), 
         endDate: Date, priority: Priority = .medium) {
        self.name = name
        self.goalDescription = goalDescription
        self.type = type
        self.target = target
        self.currentProgress = 0.0
        self.unit = unit
        self.timeFrame = timeFrame
        self.startDate = startDate
        self.endDate = endDate
        self.isActive = true
        self.isCompleted = false
        self.createdAt = Date()
        self.completedAt = nil
        self.streak = 0
        self.bestStreak = 0
        self.priority = priority
    }
    
    // MARK: - Computed Properties
    
    var progressPercentage: Double {
        guard target > 0 else { return 0 }
        return min((currentProgress / target) * 100, 100)
    }
    
    var isOverdue: Bool {
        return !isCompleted && Date() > endDate
    }
    
    var daysRemaining: Int {
        let calendar = Calendar.current
        let today = Date()
        if today > endDate { return 0 }
        return calendar.dateComponents([.day], from: today, to: endDate).day ?? 0
    }
    
    var formattedProgress: String {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 1
        let progressStr = formatter.string(from: NSNumber(value: currentProgress)) ?? "0"
        let targetStr = formatter.string(from: NSNumber(value: target)) ?? "0"
        return "\(progressStr) / \(targetStr) \(unit)"
    }
    
    // MARK: - Goal Management
    
    func updateProgress(_ newProgress: Double) {
        currentProgress = newProgress
        
        // Check if goal is completed
        if currentProgress >= target && !isCompleted {
            markAsCompleted()
        }
    }
    
    func markAsCompleted() {
        isCompleted = true
        completedAt = Date()
        
        // Update best streak if current streak is better
        if streak > bestStreak {
            bestStreak = streak
        }
    }
    
    func resetProgress() {
        currentProgress = 0.0
        isCompleted = false
        completedAt = nil
    }
    
    func incrementStreak() {
        streak += 1
        if streak > bestStreak {
            bestStreak = streak
        }
    }
    
    func resetStreak() {
        streak = 0
    }
    
    // MARK: - Smart Suggestions
    
    static func suggestedGoals(based userProfile: UserProfile?, recentEntries: [FoodEntry]) -> [Goal] {
        var suggestions: [Goal] = []
        
        // Default calorie goal based on profile
        if let profile = userProfile {
            let calorieGoal = Goal(
                name: "Daily Calorie Target",
                goalDescription: "Maintain your daily calorie goal for optimal health",
                type: .calorieTarget,
                target: profile.calorieGoal,
                unit: "cal",
                timeFrame: .daily,
                endDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date(),
                priority: .high
            )
            suggestions.append(calorieGoal)
        }
        
        // Protein goal (25-30% of calories)
        let proteinGoal = Goal(
            name: "Daily Protein Goal",
            goalDescription: "Meet your protein needs for muscle health",
            type: .proteinTarget,
            target: 100, // Default 100g
            unit: "g",
            timeFrame: .daily,
            endDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date(),
            priority: .medium
        )
        suggestions.append(proteinGoal)
        
        // Water intake goal
        let waterGoal = Goal(
            name: "Hydration Goal",
            goalDescription: "Stay hydrated throughout the day",
            type: .waterIntake,
            target: 8,
            unit: "glasses",
            timeFrame: .daily,
            endDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date(),
            priority: .medium
        )
        suggestions.append(waterGoal)
        
        // Consistency streak goal
        let streakGoal = Goal(
            name: "Tracking Streak",
            goalDescription: "Log your meals consistently",
            type: .consecutiveDays,
            target: 7,
            unit: "days",
            timeFrame: .weekly,
            endDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date(),
            priority: .high
        )
        suggestions.append(streakGoal)
        
        return suggestions
    }
}

// MARK: - Goal Progress Tracking

class GoalTracker: ObservableObject {
    @Published var activeGoals: [Goal] = []
    
    func updateGoalProgress(for entries: [FoodEntry], goals: [Goal]) {
        let today = Calendar.current.startOfDay(for: Date())
        let todaysEntries = entries.filter { 
            Calendar.current.isDate($0.timestamp, inSameDayAs: today)
        }
        
        for goal in goals.filter({ $0.isActive && !$0.isCompleted }) {
            updateIndividualGoal(goal, with: todaysEntries)
        }
    }
    
    private func updateIndividualGoal(_ goal: Goal, with entries: [FoodEntry]) {
        var progress: Double = 0
        
        switch goal.type {
        case .calorieTarget:
            progress = entries.reduce(0) { $0 + $1.totalCalories }
        case .proteinTarget:
            progress = entries.reduce(0) { $0 + $1.totalProtein }
        case .carbTarget:
            progress = entries.reduce(0) { $0 + $1.totalCarbs }
        case .fatTarget:
            progress = entries.reduce(0) { $0 + $1.totalFat }
        case .consecutiveDays:
            // This would be calculated differently based on logging history
            progress = goal.streak > 0 ? Double(goal.streak) : 0
        default:
            // Other goal types would need different tracking mechanisms
            break
        }
        
        goal.updateProgress(progress)
    }
}