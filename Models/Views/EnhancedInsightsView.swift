import SwiftUI
import Charts
import SwiftData

struct EnhancedInsightsView: View {
    @Query private var entries: [FoodEntry]
    @State private var timeRange = TimeRange.week
    @State private var selectedMetric = Metric.calories
    @EnvironmentObject var appState: AppState
    @State private var animationProgress: Double = 0
    @State private var selectedDataPoint: EnhancedChartDataPoint?
    
    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case threeMonths = "3 Months"
        case year = "Year"
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .threeMonths: return 90
            case .year: return 365
            }
        }
    }
    
    enum Metric: String, CaseIterable {
        case calories = "Calories"
        case protein = "Protein"
        case carbs = "Carbs"
        case fat = "Fat"
        case fiber = "Fiber"
        case water = "Water"
        
        var color: Color {
            switch self {
            case .calories: return .orange
            case .protein: return .red
            case .carbs: return .blue
            case .fat: return .yellow
            case .fiber: return .green
            case .water: return .cyan
            }
        }
        
        var icon: String {
            switch self {
            case .calories: return "flame.fill"
            case .protein: return "figure.strengthtraining.traditional"
            case .carbs: return "leaf.fill"
            case .fat: return "drop.fill"
            case .fiber: return "chart.xyaxis.line"
            case .water: return "drop.circle.fill"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Liquid Glass Header
                    LiquidGlassCard {
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.title)
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                
                                VStack(alignment: .leading) {
                                    Text("Nutrition Insights")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    Text("Track your progress and patterns")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            
                            // Time Range Picker with Liquid Glass
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(TimeRange.allCases, id: \.self) { range in
                                        LiquidGlassButton(
                                            title: range.rawValue,
                                            icon: nil,
                                            color: timeRange == range ? .blue : .gray
                                        ) {
                                            withAnimation(FluidSpring.bouncy) {
                                                timeRange = range
                                            }
                                        }
                                        .scaleEffect(timeRange == range ? 1.05 : 1.0)
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                    .padding(.horizontal)
                    
                    // Enhanced Progress Cards with Liquid Animation
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            LiquidProgressCard(
                                title: "Daily Average",
                                value: averageCalories,
                                target: Double(appState.currentUser?.dailyCalorieTarget ?? 2000),
                                unit: "cal",
                                icon: "flame.fill",
                                color: .orange
                            )
                            
                            LiquidProgressCard(
                                title: "Protein Goal",
                                value: averageProtein,
                                target: Double(appState.currentUser?.dailyProteinTarget ?? 150),
                                unit: "g",
                                icon: "figure.strengthtraining.traditional",
                                color: .red
                            )
                            
                            LiquidProgressCard(
                                title: "Streak",
                                value: Double(currentStreak),
                                target: 7,
                                unit: "days",
                                icon: "calendar.badge.checkmark",
                                color: .green
                            )
                        }
                        .padding(.horizontal)
                    }
                    
                    // Main Chart with Liquid Glass Effect
                    LiquidGlassCard {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Label(selectedMetric.rawValue, systemImage: selectedMetric.icon)
                                    .font(.headline)
                                
                                Spacer()
                                
                                Menu {
                                    ForEach(Metric.allCases, id: \.self) { metric in
                                        Button(action: {
                                            withAnimation(FluidSpring.smooth) {
                                                selectedMetric = metric
                                            }
                                        }) {
                                            Label(metric.rawValue, systemImage: metric.icon)
                                        }
                                    }
                                } label: {
                                    Label("Change", systemImage: "arrow.up.arrow.down.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            // Enhanced Chart with Animations
                            Chart(chartData) { item in
                                // Area mark for gradient fill
                                AreaMark(
                                    x: .value("Date", item.date),
                                    y: .value(selectedMetric.rawValue, item.animatedValue)
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            selectedMetric.color.opacity(0.3),
                                            selectedMetric.color.opacity(0.05)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .interpolationMethod(.catmullRom)
                                
                                // Line mark
                                LineMark(
                                    x: .value("Date", item.date),
                                    y: .value(selectedMetric.rawValue, item.animatedValue)
                                )
                                .foregroundStyle(selectedMetric.color)
                                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                                .interpolationMethod(.catmullRom)
                                
                                // Point marks
                                PointMark(
                                    x: .value("Date", item.date),
                                    y: .value(selectedMetric.rawValue, item.animatedValue)
                                )
                                .foregroundStyle(selectedMetric.color)
                                .symbolSize(item.id == selectedDataPoint?.id ? 150 : 80)
                                
                                // Goal line
                                if let goal = getGoalValue() {
                                    RuleMark(y: .value("Goal", goal))
                                        .foregroundStyle(Color.secondary.opacity(0.5))
                                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
                                        .annotation(position: .top, alignment: .trailing) {
                                            Text("Goal: \(Int(goal))")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                                .padding(.horizontal, 4)
                                                .background(.ultraThinMaterial)
                                                .cornerRadius(4)
                                        }
                                }
                            }
                            .frame(height: 250)
                            .chartXAxis {
                                AxisMarks(values: .stride(by: .day)) { value in
                                    if value.as(Date.self) != nil {
                                        AxisGridLine()
                                        AxisValueLabel(
                                            format: .dateTime.weekday(.abbreviated),
                                            centered: true
                                        )
                                    }
                                }
                            }
                            .chartYAxis {
                                AxisMarks { value in
                                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                    AxisValueLabel()
                                }
                            }
                            .chartOverlay { proxy in
                                GeometryReader { geometry in
                                    Rectangle()
                                        .fill(Color.clear)
                                        .contentShape(Rectangle())
                                        .onTapGesture { location in
                                            _ = geometry.frame(in: .local)
                                            if let date = proxy.value(atX: location.x, as: Date.self) {
                                                if let closestPoint = chartData.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }) {
                                                    withAnimation(FluidSpring.snappy) {
                                                        selectedDataPoint = closestPoint
                                                    }
                                                }
                                            }
                                        }
                                }
                            }
                            
                            // Selected value display
                            if let selected = selectedDataPoint {
                                HStack {
                                    Text(selected.date, format: .dateTime.month().day())
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("\(Int(selected.value)) \(getUnitForMetric())")
                                        .font(.headline)
                                        .foregroundColor(selectedMetric.color)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(.ultraThinMaterial)
                                .cornerRadius(8)
                            }
                        }
                        .padding()
                    }
                    .padding(.horizontal)
                    
                    // Macro Distribution with Liquid Progress Rings
                    LiquidGlassCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Macro Distribution")
                                .font(.headline)
                            
                            HStack(spacing: 24) {
                                ForEach(macroData, id: \.name) { macro in
                                    VStack(spacing: 12) {
                                        ZStack {
                                            LiquidProgressRing(
                                                progress: macro.percentage,
                                                total: 100,
                                                color: macro.color,
                                                size: 80,
                                                lineWidth: 8
                                            )
                                            
                                            Text("\(Int(macro.percentage))%")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                        }
                                        
                                        Text(macro.name)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        Text("\(Int(macro.value))g")
                                            .font(.caption2)
                                            .fontWeight(.medium)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding()
                    }
                    .padding(.horizontal)
                    
                    // Enhanced Insights with Liquid Cards
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Personalized Insights")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(generateInsights()) { insight in
                                    LiquidInsightCard(insight: insight)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Achievements Section with Liquid Glass
                    EnhancedAchievementsSection(entries: entries)
                        .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(
                GlassmorphismBackground(colors: [.blue, .purple, .cyan])
                    .opacity(0.3)
            )
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0)) {
                animationProgress = 1.0
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredEntries: [FoodEntry] {
        let startDate = Calendar.current.date(byAdding: .day, value: -timeRange.days, to: Date())!
        return entries.filter { $0.timestamp >= startDate }
    }
    
    private var chartData: [EnhancedChartDataPoint] {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -timeRange.days, to: endDate)!
        
        var data: [EnhancedChartDataPoint] = []
        var currentDate = startDate
        
        while currentDate <= endDate {
            let dayEntries = filteredEntries.filter { calendar.isDate($0.timestamp, inSameDayAs: currentDate) }
            
            let value: Double
            switch selectedMetric {
            case .calories:
                value = dayEntries.reduce(0) { $0 + $1.totalCalories }
            case .protein:
                value = dayEntries.reduce(0) { $0 + $1.totalProtein }
            case .carbs:
                value = dayEntries.reduce(0) { $0 + $1.totalCarbs }
            case .fat:
                value = dayEntries.reduce(0) { $0 + $1.totalFat }
            case .fiber:
                value = dayEntries.reduce(0) { $0 + ($1.fiber ?? 0) }
            case .water:
                value = 0 // Placeholder for water tracking
            }
            
            data.append(EnhancedChartDataPoint(
                date: currentDate,
                value: value,
                animatedValue: value * animationProgress
            ))
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        return data
    }
    
    private var averageCalories: Double {
        guard !filteredEntries.isEmpty else { return 0 }
        let total = filteredEntries.reduce(0) { $0 + $1.totalCalories }
        let days = max(Set(filteredEntries.map { Calendar.current.startOfDay(for: $0.timestamp) }).count, 1)
        return total / Double(days)
    }
    
    private var averageProtein: Double {
        guard !filteredEntries.isEmpty else { return 0 }
        let total = filteredEntries.reduce(0) { $0 + $1.totalProtein }
        let days = max(Set(filteredEntries.map { Calendar.current.startOfDay(for: $0.timestamp) }).count, 1)
        return total / Double(days)
    }
    
    private var currentStreak: Int {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())
        
        while true {
            let hasEntry = filteredEntries.contains { calendar.isDate($0.timestamp, inSameDayAs: checkDate) }
            if hasEntry {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }
        
        return streak
    }
    
    private var macroData: [(name: String, value: Double, percentage: Double, color: Color)] {
        let totalProtein = filteredEntries.reduce(0) { $0 + $1.totalProtein }
        let totalCarbs = filteredEntries.reduce(0) { $0 + $1.totalCarbs }
        let totalFat = filteredEntries.reduce(0) { $0 + $1.totalFat }
        let totalMacros = totalProtein + totalCarbs + totalFat
        
        guard totalMacros > 0 else {
            return [
                ("Protein", 0, 0, .red),
                ("Carbs", 0, 0, .blue),
                ("Fat", 0, 0, .yellow)
            ]
        }
        
        return [
            ("Protein", totalProtein, (totalProtein / totalMacros) * 100, .red),
            ("Carbs", totalCarbs, (totalCarbs / totalMacros) * 100, .blue),
            ("Fat", totalFat, (totalFat / totalMacros) * 100, .yellow)
        ]
    }
    
    private func getGoalValue() -> Double? {
        guard let user = appState.currentUser else { return nil }
        
        switch selectedMetric {
        case .calories: return user.dailyCalorieTarget
        case .protein: return user.dailyProteinTarget
        case .carbs: return user.dailyCarbTarget
        case .fat: return user.dailyFatTarget
        case .fiber: return 25 // Default fiber goal
        case .water: return 8 // Default water goal (glasses)
        }
    }
    
    private func getUnitForMetric() -> String {
        switch selectedMetric {
        case .calories: return "cal"
        case .water: return "glasses"
        default: return "g"
        }
    }
    
    private func generateInsights() -> [EnhancedInsight] {
        var insights: [EnhancedInsight] = []
        
        // Calorie trend
        let calorieChange = calculateTrendChange(for: .calories)
        if abs(calorieChange) > 10 {
            insights.append(EnhancedInsight(
                icon: calorieChange > 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill",
                title: "Calorie Trend",
                description: "Your daily calories are \(calorieChange > 0 ? "up" : "down") \(Int(abs(calorieChange)))% this week",
                color: calorieChange > 0 ? .orange : .green,
                category: .trend
            ))
        }
        
        // Protein achievement
        if averageProtein > Double(appState.currentUser?.dailyProteinTarget ?? 150) * 0.9 {
            insights.append(EnhancedInsight(
                icon: "figure.strengthtraining.traditional",
                title: "Protein Power",
                description: "You're consistently hitting your protein goals! 💪",
                color: .red,
                category: .achievement
            ))
        }
        
        // Consistency score
        let consistencyScore = calculateConsistencyScore()
        if consistencyScore > 0.8 {
            insights.append(EnhancedInsight(
                icon: "star.circle.fill",
                title: "Consistency Champion",
                description: "Your tracking consistency is excellent at \(Int(consistencyScore * 100))%",
                color: .purple,
                category: .achievement
            ))
        }
        
        // Meal pattern
        if let favoriteTime = findFavoriteMealTime() {
            insights.append(EnhancedInsight(
                icon: "clock.fill",
                title: "Eating Pattern",
                description: "You log most meals during \(favoriteTime)",
                color: .indigo,
                category: .pattern
            ))
        }
        
        return insights
    }
    
    private func calculateTrendChange(for metric: Metric) -> Double {
        let calendar = Calendar.current
        let midPoint = calendar.date(byAdding: .day, value: -timeRange.days / 2, to: Date())!
        
        let firstHalf = filteredEntries.filter { $0.timestamp < midPoint }
        let secondHalf = filteredEntries.filter { $0.timestamp >= midPoint }
        
        guard !firstHalf.isEmpty && !secondHalf.isEmpty else { return 0 }
        
        let firstAvg: Double
        let secondAvg: Double
        
        switch metric {
        case .calories:
            firstAvg = firstHalf.reduce(0) { $0 + $1.totalCalories } / Double(firstHalf.count)
            secondAvg = secondHalf.reduce(0) { $0 + $1.totalCalories } / Double(secondHalf.count)
        case .protein:
            firstAvg = firstHalf.reduce(0) { $0 + $1.totalProtein } / Double(firstHalf.count)
            secondAvg = secondHalf.reduce(0) { $0 + $1.totalProtein } / Double(secondHalf.count)
        default:
            return 0
        }
        
        guard firstAvg > 0 else { return 0 }
        return ((secondAvg - firstAvg) / firstAvg) * 100
    }
    
    private func calculateConsistencyScore() -> Double {
        let totalDays = timeRange.days
        let daysWithEntries = Set(filteredEntries.map { Calendar.current.startOfDay(for: $0.timestamp) }).count
        return Double(daysWithEntries) / Double(totalDays)
    }
    
    private func findFavoriteMealTime() -> String? {
        let mealCounts = filteredEntries.reduce(into: [FoodEntry.MealType: Int]()) { counts, entry in
            counts[entry.mealType, default: 0] += 1
        }
        
        guard let topMeal = mealCounts.max(by: { $0.value < $1.value }) else { return nil }
        
        switch topMeal.key {
        case .breakfast: return "breakfast time 🌅"
        case .lunch: return "lunch time ☀️"
        case .dinner: return "dinner time 🌙"
        case .snack: return "snack time 🍿"
        }
    }
}

// MARK: - Supporting Views

struct LiquidProgressCard: View {
    let title: String
    let value: Double
    let target: Double
    let unit: String
    let icon: String
    let color: Color
    
    @State private var animatedValue: Double = 0
    
    private var percentage: Double {
        guard target > 0 else { return 0 }
        return min((value / target) * 100, 150)
    }
    
    var body: some View {
        LiquidGlassCard {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [color, color.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Spacer()
                    Text("\(Int(percentage))%")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("\(Int(animatedValue))")
                            .font(.title)
                            .fontWeight(.bold)
                            .contentTransition(.numericText())
                        
                        Text(unit)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("of \(Int(target))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Liquid Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(color.opacity(0.2))
                            .frame(height: 8)
                        
                        LiquidProgressIndicator(
                            progress: percentage / 100,
                            color: color,
                            height: 8
                        )
                        .frame(width: geometry.size.width)
                    }
                }
                .frame(height: 8)
            }
            .padding()
        }
        .frame(width: 180)
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animatedValue = value
            }
        }
    }
}

struct LiquidInsightCard: View {
    let insight: EnhancedInsight
    @State private var isHovered = false
    
    var body: some View {
        LiquidGlassCard {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [insight.color.opacity(0.3), insight.color.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: insight.icon)
                        .font(.title3)
                        .foregroundColor(insight.color)
                }
                .liquidPulse(color: insight.color, intensity: 0.2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(insight.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(insight.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                .frame(width: 200, alignment: .leading)
            }
            .padding()
        }
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .onHover { hovering in
            withAnimation(FluidSpring.gentle) {
                isHovered = hovering
            }
        }
    }
}

struct EnhancedAchievementsSection: View {
    let entries: [FoodEntry]
    
    var achievements: [EnhancedAchievement] {
        var results: [EnhancedAchievement] = []
        
        let daysTracked = Set(entries.map { Calendar.current.startOfDay(for: $0.timestamp) }).count
        
        // Days tracked achievements
        if daysTracked >= 7 {
            results.append(EnhancedAchievement(
                icon: "calendar.badge.checkmark",
                title: "Week Warrior",
                description: "7 days tracked",
                progress: 1.0,
                isUnlocked: true,
                color: .green,
                tier: .bronze
            ))
        }
        
        if daysTracked >= 30 {
            results.append(EnhancedAchievement(
                icon: "calendar.circle.fill",
                title: "Monthly Master",
                description: "30 days tracked",
                progress: 1.0,
                isUnlocked: true,
                color: .blue,
                tier: .silver
            ))
        }
        
        if daysTracked >= 100 {
            results.append(EnhancedAchievement(
                icon: "crown.fill",
                title: "Century Champion",
                description: "100 days tracked",
                progress: Double(daysTracked) / 100,
                isUnlocked: daysTracked >= 100,
                color: .yellow,
                tier: .gold
            ))
        }
        
        // Streak achievements
        let currentStreak = calculateCurrentStreak()
        if currentStreak >= 3 {
            results.append(EnhancedAchievement(
                icon: "flame.fill",
                title: "Fire Starter",
                description: "3 day streak",
                progress: 1.0,
                isUnlocked: true,
                color: .orange,
                tier: .bronze
            ))
        }
        
        return results
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Achievements")
                    .font(.headline)
                
                Spacer()
                
                Text("\(achievements.filter { $0.isUnlocked }.count)/\(achievements.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(achievements) { achievement in
                        EnhancedAchievementCard(achievement: achievement)
                    }
                }
            }
        }
    }
    
    private func calculateCurrentStreak() -> Int {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())
        
        while true {
            let hasEntry = entries.contains { calendar.isDate($0.timestamp, inSameDayAs: checkDate) }
            if hasEntry {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }
        
        return streak
    }
}

struct EnhancedAchievementCard: View {
    let achievement: EnhancedAchievement
    @State private var isAnimating = false
    
    var body: some View {
        LiquidGlassCard {
            VStack(spacing: 12) {
                ZStack {
                    // Progress ring
                    LiquidProgressRing(
                        progress: achievement.progress,
                        total: 1.0,
                        color: achievement.color,
                        size: 80,
                        lineWidth: 6
                    )
                    .opacity(achievement.isUnlocked ? 1.0 : 0.3)
                    
                    // Icon
                    Image(systemName: achievement.icon)
                        .font(.title)
                        .foregroundStyle(
                            achievement.isUnlocked ?
                            LinearGradient(
                                colors: achievement.tierGradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) : LinearGradient(
                                colors: [.gray],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                }
                
                VStack(spacing: 4) {
                    Text(achievement.title)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                    
                    Text(achievement.description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Tier indicator
                HStack(spacing: 2) {
                    ForEach(0..<achievement.tier.stars, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.system(size: 8))
                            .foregroundColor(achievement.isUnlocked ? achievement.color : .gray)
                    }
                }
            }
            .padding()
            .frame(width: 120, height: 160)
            .overlay(
                achievement.isUnlocked ? nil :
                RoundedRectangle(cornerRadius: 20)
                    .fill(.black.opacity(0.3))
            )
        }
        .onAppear {
            if achievement.isUnlocked {
                withAnimation(
                    FluidSpring.bouncy
                        .repeatForever(autoreverses: true)
                        .delay(Double.random(in: 0...1))
                ) {
                    isAnimating = true
                }
            }
        }
    }
}

// MARK: - Models

struct EnhancedChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    var animatedValue: Double
}

struct EnhancedInsight: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let color: Color
    let category: InsightCategory
    
    enum InsightCategory {
        case trend, achievement, pattern, suggestion
    }
}

struct EnhancedAchievement: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let progress: Double
    let isUnlocked: Bool
    let color: Color
    let tier: AchievementTier
    
    enum AchievementTier {
        case bronze, silver, gold, platinum
        
        var stars: Int {
            switch self {
            case .bronze: return 1
            case .silver: return 2
            case .gold: return 3
            case .platinum: return 4
            }
        }
    }
    
    var tierGradient: [Color] {
        switch tier {
        case .bronze: return [Color(red: 0.8, green: 0.5, blue: 0.2), Color(red: 0.6, green: 0.4, blue: 0.1)]
        case .silver: return [.gray, .white]
        case .gold: return [.yellow, .orange]
        case .platinum: return [.purple, .pink]
        }
    }
}

// Extension to fix the ChartDataPoint name conflict
extension EnhancedInsightsView {
    struct EnhancedChartDataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let value: Double
        var animatedValue: Double
        
        init(date: Date, value: Double, animatedValue: Double) {
            self.date = date
            self.value = value
            self.animatedValue = animatedValue
        }
    }
}
