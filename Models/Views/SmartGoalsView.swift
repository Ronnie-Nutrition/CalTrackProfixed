import SwiftUI
import SwiftData

struct SmartGoalsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var goals: [Goal]
    @Query private var achievements: [Achievement]
    @Query private var foodEntries: [FoodEntry]
    @Query private var recipes: [Recipe]
    
    @StateObject private var goalTracker = GoalTracker()
    @StateObject private var achievementManager = AchievementManager()
    
    @State private var selectedTab = 0
    @State private var showingGoalCreator = false
    @State private var showingAchievementDetail: Achievement?
    @State private var showingGoalDetail: Goal?
    @State private var animateProgress = false
    
    var activeGoals: [Goal] {
        goals.filter { $0.isActive && !$0.isCompleted }
    }
    
    var completedGoals: [Goal] {
        goals.filter { $0.isCompleted }
    }
    
    var unlockedAchievements: [Achievement] {
        achievements.filter { $0.isUnlocked }
    }
    
    var totalPoints: Int {
        achievementManager.totalPoints(from: unlockedAchievements)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                GlassmorphismBackground(colors: [.blue, .purple, .indigo])
                
                VStack(spacing: 0) {
                    // Header Section
                    LiquidGlassCard {
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "target")
                                    .font(.title)
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Smart Goals")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    Text("\(activeGoals.count) active • \(totalPoints) points earned")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Button(action: { showingGoalCreator = true }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                }
                                .liquidPulse(color: .blue, intensity: 0.3)
                            }
                            
                            // Tab Selector
                            HStack(spacing: 0) {
                                ForEach(["Goals", "Achievements"], id: \.self) { tab in
                                    let index = tab == "Goals" ? 0 : 1
                                    Button(action: {
                                        withAnimation(FluidSpring.snappy) {
                                            selectedTab = index
                                        }
                                    }) {
                                        VStack(spacing: 4) {
                                            Text(tab)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(selectedTab == index ? .primary : .secondary)
                                            
                                            Rectangle()
                                                .fill(selectedTab == index ? .blue : .clear)
                                                .frame(height: 2)
                                                .cornerRadius(1)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                        }
                        .padding()
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Content
                    TabView(selection: $selectedTab) {
                        // Goals Tab
                        goalsContent
                            .tag(0)
                        
                        // Achievements Tab
                        achievementsContent
                            .tag(1)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingGoalCreator) {
                GoalCreatorView()
            }
            .sheet(item: $showingAchievementDetail) { achievement in
                AchievementDetailView(achievement: achievement)
            }
            .sheet(item: $showingGoalDetail) { goal in
                GoalDetailView(goal: goal)
            }
            .onAppear {
                setupDefaultAchievements()
                updateGoalProgress()
                checkAchievements()
                
                withAnimation(.easeInOut(duration: 1.0)) {
                    animateProgress = true
                }
            }
        }
    }
    
    // MARK: - Goals Content
    
    private var goalsContent: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Active Goals Section
                if !activeGoals.isEmpty {
                    sectionHeader("Active Goals", icon: "target", color: .blue)
                    
                    ForEach(activeGoals.sorted(by: { $0.priority.rawValue > $1.priority.rawValue })) { goal in
                        GoalCard(goal: goal, animateProgress: animateProgress) {
                            showingGoalDetail = goal
                        }
                    }
                }
                
                // Completed Goals Section
                if !completedGoals.isEmpty {
                    sectionHeader("Completed Goals", icon: "checkmark.seal.fill", color: .green)
                    
                    ForEach(completedGoals.prefix(5)) { goal in
                        CompletedGoalCard(goal: goal) {
                            showingGoalDetail = goal
                        }
                    }
                }
                
                // Suggested Goals Section
                if activeGoals.count < 3 {
                    sectionHeader("Suggested Goals", icon: "lightbulb.fill", color: .orange)
                    
                    ForEach(suggestedGoals.prefix(3), id: \.name) { goal in
                        SuggestedGoalCard(goal: goal) {
                            addSuggestedGoal(goal)
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Achievements Content
    
    private var achievementsContent: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Achievement Stats
                LiquidGlassCard {
                    HStack(spacing: 20) {
                        StatBox(
                            title: "Total Points",
                            value: "\(totalPoints)",
                            icon: "star.fill",
                            color: .yellow
                        )
                        
                        StatBox(
                            title: "Unlocked",
                            value: "\(unlockedAchievements.count)/\(achievements.count)",
                            icon: "trophy.fill",
                            color: .orange
                        )
                        
                        StatBox(
                            title: "This Week",
                            value: "\(weeklyUnlocks)",
                            icon: "calendar.badge.checkmark",
                            color: .green
                        )
                    }
                    .padding()
                }
                .padding(.horizontal)
                
                // Recent Achievements
                if !achievementManager.recentUnlocks.isEmpty {
                    sectionHeader("Recent Unlocks", icon: "sparkles", color: .purple)
                    
                    ForEach(achievementManager.recentUnlocks) { achievement in
                        RecentAchievementCard(achievement: achievement) {
                            showingAchievementDetail = achievement
                        }
                    }
                }
                
                // Achievement Categories
                let achievementsByCategory = achievementManager.achievementsByCategory(from: achievements)
                
                ForEach(Array(achievementsByCategory.keys), id: \.self) { category in
                    if let categoryAchievements = achievementsByCategory[category] {
                        sectionHeader(category.displayName, icon: categoryIcon(for: category), color: categoryColor(for: category))
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(categoryAchievements) { achievement in
                                AchievementCard(achievement: achievement) {
                                    showingAchievementDetail = achievement
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Helper Views
    
    private func sectionHeader(_ title: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.headline)
            
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
        }
        .padding(.horizontal)
    }
    
    private var suggestedGoals: [Goal] {
        // Get user profile if available
        Goal.suggestedGoals(based: nil, recentEntries: Array(foodEntries.suffix(50)))
    }
    
    private var weeklyUnlocks: Int {
        let weekAgo = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date()
        return unlockedAchievements.filter { achievement in
            guard let unlockedAt = achievement.unlockedAt else { return false }
            return unlockedAt > weekAgo
        }.count
    }
    
    // MARK: - Helper Functions
    
    private func categoryIcon(for category: Achievement.Category) -> String {
        switch category {
        case .nutrition: return "leaf.fill"
        case .goals: return "target"
        case .consistency: return "checkmark.seal.fill"
        case .social: return "person.2.fill"
        case .learning: return "book.fill"
        case .creativity: return "paintbrush.fill"
        }
    }
    
    private func categoryColor(for category: Achievement.Category) -> Color {
        switch category {
        case .nutrition: return .green
        case .goals: return .blue
        case .consistency: return .orange
        case .social: return .purple
        case .learning: return .indigo
        case .creativity: return .pink
        }
    }
    
    private func addSuggestedGoal(_ goal: Goal) {
        modelContext.insert(goal)
        try? modelContext.save()
        
        withAnimation(FluidSpring.bouncy) {
            // Trigger UI update
        }
    }
    
    private func setupDefaultAchievements() {
        if achievements.isEmpty {
            let defaultAchievements = Achievement.createDefaultAchievements()
            for achievement in defaultAchievements {
                modelContext.insert(achievement)
            }
            try? modelContext.save()
        }
    }
    
    private func updateGoalProgress() {
        goalTracker.updateGoalProgress(for: foodEntries, goals: goals)
    }
    
    private func checkAchievements() {
        achievementManager.checkAchievements(
            goals: goals,
            foodEntries: foodEntries,
            recipes: recipes,
            achievements: achievements
        )
    }
}

// MARK: - Goal Card

struct GoalCard: View {
    let goal: Goal
    let animateProgress: Bool
    let onTap: () -> Void
    
    @State private var displayedProgress: Double = 0
    
    var body: some View {
        LiquidGlassCard {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: goal.type.icon)
                        .font(.title3)
                        .foregroundColor(priorityColor)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(goal.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(goal.goalDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(goal.timeFrame.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if goal.daysRemaining > 0 {
                            Text("\(goal.daysRemaining) days left")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                // Progress Section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(goal.formattedProgress)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text("\(Int(displayedProgress))%")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(priorityColor)
                            .contentTransition(.numericText())
                    }
                    
                    // Progress Bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(.ultraThinMaterial)
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    LinearGradient(
                                        colors: [priorityColor, priorityColor.opacity(0.7)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * (displayedProgress / 100), height: 8)
                                .animation(.easeInOut(duration: 1.0), value: displayedProgress)
                        }
                    }
                    .frame(height: 8)
                }
                
                // Streak Info
                if goal.streak > 0 {
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        
                        Text("Streak: \(goal.streak) days")
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        if goal.bestStreak > goal.streak {
                            Text("Best: \(goal.bestStreak)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding()
        }
        .onTapGesture(perform: onTap)
        .onAppear {
            if animateProgress {
                withAnimation(.easeInOut(duration: 1.5).delay(0.1)) {
                    displayedProgress = goal.progressPercentage
                }
            } else {
                displayedProgress = goal.progressPercentage
            }
        }
        .onChange(of: goal.progressPercentage) { _, newValue in
            withAnimation(.easeInOut(duration: 0.5)) {
                displayedProgress = newValue
            }
        }
    }
    
    private var priorityColor: Color {
        switch goal.priority {
        case .low: return .blue
        case .medium: return .green
        case .high: return .orange
        case .critical: return .red
        }
    }
}

// MARK: - Supporting Views

struct CompletedGoalCard: View {
    let goal: Goal
    let onTap: () -> Void
    
    var body: some View {
        LiquidGlassCard {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.green)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if let completedAt = goal.completedAt {
                        Text("Completed \(completedAt, style: .relative) ago")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if goal.bestStreak > 0 {
                    VStack(alignment: .trailing) {
                        Text("Best Streak")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(goal.bestStreak) days")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                    }
                }
            }
            .padding()
        }
        .onTapGesture(perform: onTap)
        .opacity(0.8)
    }
}

struct SuggestedGoalCard: View {
    let goal: Goal
    let onAdd: () -> Void
    
    var body: some View {
        LiquidGlassCard {
            HStack(spacing: 12) {
                Image(systemName: goal.type.icon)
                    .font(.title3)
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(goal.goalDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Button("Add", action: onAdd)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.orange)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()
        }
    }
}

struct AchievementCard: View {
    let achievement: Achievement
    let onTap: () -> Void
    
    var body: some View {
        LiquidGlassCard {
            VStack(spacing: 8) {
                Image(systemName: achievement.icon)
                    .font(.title2)
                    .foregroundColor(achievement.isUnlocked ? rarityColor : .secondary)
                
                Text(achievement.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                if achievement.isUnlocked {
                    Text("\(achievement.points) pts")
                        .font(.caption2)
                        .foregroundColor(rarityColor)
                } else {
                    Text("Locked")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .opacity(achievement.isUnlocked ? 1.0 : 0.6)
        }
        .onTapGesture(perform: onTap)
    }
    
    private var rarityColor: Color {
        switch achievement.rarity {
        case .common: return .gray
        case .uncommon: return .green
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .orange
        }
    }
}

struct RecentAchievementCard: View {
    let achievement: Achievement
    let onTap: () -> Void
    
    var body: some View {
        LiquidGlassCard {
            HStack(spacing: 12) {
                Image(systemName: achievement.icon)
                    .font(.title3)
                    .foregroundColor(.yellow)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(achievement.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("Unlocked \(achievement.unlockedAt!, style: .relative) ago")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("\(achievement.points) pts")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.yellow)
            }
            .padding()
        }
        .onTapGesture(perform: onTap)
        .liquidPulse(color: .yellow, intensity: 0.2)
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    SmartGoalsView()
        .modelContainer(for: [Goal.self, Achievement.self, FoodEntry.self, Recipe.self])
}