import SwiftData
import Foundation

@Model
final class Achievement {
    var id = UUID()
    var name: String
    var achievementDescription: String
    var type: AchievementType
    var category: Category
    var requirement: Double
    var isUnlocked: Bool
    var unlockedAt: Date?
    var icon: String
    var rarity: Rarity
    var points: Int
    var createdAt: Date
    
    enum AchievementType: String, Codable, CaseIterable {
        case goalCompletion = "goal_completion"
        case streak = "streak"
        case totalLogged = "total_logged"
        case perfectDay = "perfect_day"
        case recipeCreation = "recipe_creation"
        case consistency = "consistency"
        case milestone = "milestone"
        case discovery = "discovery"
        
        var displayName: String {
            switch self {
            case .goalCompletion: return "Goal Master"
            case .streak: return "Streak Champion"
            case .totalLogged: return "Tracking Pro"
            case .perfectDay: return "Perfect Day"
            case .recipeCreation: return "Chef"
            case .consistency: return "Consistent Tracker"
            case .milestone: return "Milestone"
            case .discovery: return "Explorer"
            }
        }
    }
    
    enum Category: String, Codable, CaseIterable {
        case nutrition = "nutrition"
        case goals = "goals"
        case consistency = "consistency"
        case social = "social"
        case learning = "learning"
        case creativity = "creativity"
        
        var displayName: String {
            switch self {
            case .nutrition: return "Nutrition"
            case .goals: return "Goals"
            case .consistency: return "Consistency"
            case .social: return "Social"
            case .learning: return "Learning"
            case .creativity: return "Creativity"
            }
        }
        
        var color: String {
            switch self {
            case .nutrition: return "green"
            case .goals: return "blue"
            case .consistency: return "orange"
            case .social: return "purple"
            case .learning: return "indigo"
            case .creativity: return "pink"
            }
        }
    }
    
    enum Rarity: String, Codable, CaseIterable {
        case common = "common"
        case uncommon = "uncommon"
        case rare = "rare"
        case epic = "epic"
        case legendary = "legendary"
        
        var displayName: String {
            switch self {
            case .common: return "Common"
            case .uncommon: return "Uncommon"
            case .rare: return "Rare"
            case .epic: return "Epic"
            case .legendary: return "Legendary"
            }
        }
        
        var color: String {
            switch self {
            case .common: return "gray"
            case .uncommon: return "green"
            case .rare: return "blue"
            case .epic: return "purple"
            case .legendary: return "orange"
            }
        }
        
        var points: Int {
            switch self {
            case .common: return 10
            case .uncommon: return 25
            case .rare: return 50
            case .epic: return 100
            case .legendary: return 250
            }
        }
    }
    
    init(name: String, achievementDescription: String, type: AchievementType, 
         category: Category, requirement: Double, icon: String, rarity: Rarity) {
        self.name = name
        self.achievementDescription = achievementDescription
        self.type = type
        self.category = category
        self.requirement = requirement
        self.isUnlocked = false
        self.unlockedAt = nil
        self.icon = icon
        self.rarity = rarity
        self.points = rarity.points
        self.createdAt = Date()
    }
    
    func unlock() {
        isUnlocked = true
        unlockedAt = Date()
    }
    
    // MARK: - Predefined Achievements
    
    static func createDefaultAchievements() -> [Achievement] {
        return [
            // Streak Achievements
            Achievement(
                name: "Getting Started",
                achievementDescription: "Log food for 3 consecutive days",
                type: .streak,
                category: .consistency,
                requirement: 3,
                icon: "calendar.badge.checkmark",
                rarity: .common
            ),
            
            Achievement(
                name: "Week Warrior",
                achievementDescription: "Log food for 7 consecutive days",
                type: .streak,
                category: .consistency,
                requirement: 7,
                icon: "flame.fill",
                rarity: .uncommon
            ),
            
            Achievement(
                name: "Month Master",
                achievementDescription: "Log food for 30 consecutive days",
                type: .streak,
                category: .consistency,
                requirement: 30,
                icon: "crown.fill",
                rarity: .rare
            ),
            
            Achievement(
                name: "Unstoppable",
                achievementDescription: "Log food for 100 consecutive days",
                type: .streak,
                category: .consistency,
                requirement: 100,
                icon: "bolt.fill",
                rarity: .legendary
            ),
            
            // Goal Completion Achievements
            Achievement(
                name: "First Goal",
                achievementDescription: "Complete your first goal",
                type: .goalCompletion,
                category: .goals,
                requirement: 1,
                icon: "target",
                rarity: .common
            ),
            
            Achievement(
                name: "Goal Getter",
                achievementDescription: "Complete 5 goals",
                type: .goalCompletion,
                category: .goals,
                requirement: 5,
                icon: "checkmark.seal.fill",
                rarity: .uncommon
            ),
            
            Achievement(
                name: "Achievement Hunter",
                achievementDescription: "Complete 20 goals",
                type: .goalCompletion,
                category: .goals,
                requirement: 20,
                icon: "star.circle.fill",
                rarity: .epic
            ),
            
            // Recipe Creation Achievements
            Achievement(
                name: "Recipe Rookie",
                achievementDescription: "Create your first recipe",
                type: .recipeCreation,
                category: .creativity,
                requirement: 1,
                icon: "book.fill",
                rarity: .common
            ),
            
            Achievement(
                name: "Home Chef",
                achievementDescription: "Create 5 recipes",
                type: .recipeCreation,
                category: .creativity,
                requirement: 5,
                icon: "chef.hat.fill",
                rarity: .uncommon
            ),
            
            Achievement(
                name: "Recipe Master",
                achievementDescription: "Create 25 recipes",
                type: .recipeCreation,
                category: .creativity,
                requirement: 25,
                icon: "crown.fill",
                rarity: .epic
            ),
            
            // Perfect Day Achievements
            Achievement(
                name: "Balanced Day",
                achievementDescription: "Hit all macro targets in one day",
                type: .perfectDay,
                category: .nutrition,
                requirement: 1,
                icon: "scale.3d",
                rarity: .uncommon
            ),
            
            Achievement(
                name: "Perfect Week",
                achievementDescription: "Hit all targets for 7 consecutive days",
                type: .perfectDay,
                category: .nutrition,
                requirement: 7,
                icon: "checkmark.diamond.fill",
                rarity: .rare
            ),
            
            // Total Logged Achievements
            Achievement(
                name: "Hundred Club",
                achievementDescription: "Log 100 food items",
                type: .totalLogged,
                category: .consistency,
                requirement: 100,
                icon: "number.circle.fill",
                rarity: .uncommon
            ),
            
            Achievement(
                name: "Thousand Strong",
                achievementDescription: "Log 1000 food items",
                type: .totalLogged,
                category: .consistency,
                requirement: 1000,
                icon: "infinity.circle.fill",
                rarity: .epic
            ),
            
            // Discovery Achievements
            Achievement(
                name: "Food Explorer",
                achievementDescription: "Try 50 different foods",
                type: .discovery,
                category: .learning,
                requirement: 50,
                icon: "globe.americas.fill",
                rarity: .rare
            ),
            
            Achievement(
                name: "Variety Seeker",
                achievementDescription: "Try 100 different foods",
                type: .discovery,
                category: .learning,
                requirement: 100,
                icon: "sparkles",
                rarity: .epic
            )
        ]
    }
}

// MARK: - Achievement Manager

class AchievementManager: ObservableObject {
    @Published var unlockedAchievements: [Achievement] = []
    @Published var recentUnlocks: [Achievement] = []
    
    func checkAchievements(
        goals: [Goal],
        foodEntries: [FoodEntry],
        recipes: [Recipe],
        achievements: [Achievement]
    ) {
        for achievement in achievements.filter({ !$0.isUnlocked }) {
            if shouldUnlockAchievement(achievement, goals: goals, foodEntries: foodEntries, recipes: recipes) {
                unlockAchievement(achievement)
            }
        }
    }
    
    private func shouldUnlockAchievement(
        _ achievement: Achievement,
        goals: [Goal],
        foodEntries: [FoodEntry],
        recipes: [Recipe]
    ) -> Bool {
        switch achievement.type {
        case .goalCompletion:
            let completedGoals = goals.filter { $0.isCompleted }
            return Double(completedGoals.count) >= achievement.requirement
            
        case .streak:
            // Calculate current streak from food entries
            let streak = calculateCurrentStreak(from: foodEntries)
            return Double(streak) >= achievement.requirement
            
        case .totalLogged:
            return Double(foodEntries.count) >= achievement.requirement
            
        case .recipeCreation:
            return Double(recipes.count) >= achievement.requirement
            
        case .perfectDay:
            return checkPerfectDays(foodEntries: foodEntries, targetDays: Int(achievement.requirement))
            
        case .discovery:
            let uniqueFoods = Set(foodEntries.map { $0.name })
            return Double(uniqueFoods.count) >= achievement.requirement
            
        case .consistency:
            let consistentDays = calculateConsistentDays(from: foodEntries)
            return Double(consistentDays) >= achievement.requirement
            
        case .milestone:
            // Custom milestone logic would go here
            return false
        }
    }
    
    private func unlockAchievement(_ achievement: Achievement) {
        achievement.unlock()
        unlockedAchievements.append(achievement)
        recentUnlocks.append(achievement)
        
        // Keep only recent unlocks from last 24 hours
        let dayAgo = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        recentUnlocks = recentUnlocks.filter { $0.unlockedAt ?? Date() > dayAgo }
    }
    
    private func calculateCurrentStreak(from entries: [FoodEntry]) -> Int {
        guard !entries.isEmpty else { return 0 }
        
        let sortedEntries = entries.sorted { $0.timestamp > $1.timestamp }
        let calendar = Calendar.current
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())
        
        for entry in sortedEntries {
            let entryDate = calendar.startOfDay(for: entry.timestamp)
            
            if calendar.isDate(entryDate, inSameDayAs: currentDate) {
                if streak == 0 || calendar.isDate(entryDate, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: currentDate)!) {
                    streak += 1
                    currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
                } else {
                    break
                }
            }
        }
        
        return streak
    }
    
    private func checkPerfectDays(foodEntries: [FoodEntry], targetDays: Int) -> Int {
        // This would need access to user's daily targets
        // For now, return 0 as placeholder
        return 0
    }
    
    private func calculateConsistentDays(from entries: [FoodEntry]) -> Int {
        let calendar = Calendar.current
        let daysWithEntries = Set(entries.map { calendar.startOfDay(for: $0.timestamp) })
        return daysWithEntries.count
    }
    
    func totalPoints(from achievements: [Achievement]) -> Int {
        return achievements.filter { $0.isUnlocked }.reduce(0) { $0 + $1.points }
    }
    
    func achievementsByCategory(from achievements: [Achievement]) -> [Achievement.Category: [Achievement]] {
        return Dictionary(grouping: achievements) { $0.category }
    }
}