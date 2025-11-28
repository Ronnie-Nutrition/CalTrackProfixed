import SwiftUI
import Charts
import SwiftData

struct InsightsView: View {
    @Query private var entries: [FoodEntry]
    @State private var timeRange = TimeRange.week
    @State private var selectedMetric = Metric.calories
    @EnvironmentObject var appState: AppState
    
    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case threeMonths = "3 Months"
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .threeMonths: return 90
            }
        }
    }
    
    enum Metric: String, CaseIterable {
        case calories = "Calories"
        case protein = "Protein"
        case carbs = "Carbs"
        case fat = "Fat"
        case weight = "Weight"
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Time Range Picker
                    Picker("Time Range", selection: $timeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // Progress Card
                    ProgressSummaryCard(entries: filteredEntries)
                        .padding(.horizontal)
                    
                    // Chart
                    LiquidGlassCard(cornerRadius: 16) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Trends")
                                    .font(AppFonts.headline())
                                    .foregroundColor(AppColors.primaryText)

                                Spacer()

                                Picker("Metric", selection: $selectedMetric) {
                                    ForEach(Metric.allCases, id: \.self) { metric in
                                        Text(metric.rawValue).tag(metric)
                                    }
                                }
                                .pickerStyle(.menu)
                            }

                            Chart(chartData) { item in
                                LineMark(
                                    x: .value("Date", item.date),
                                    y: .value(selectedMetric.rawValue, item.value)
                                )
                                .foregroundStyle(ThemeManager.shared.currentAccentColor)

                                AreaMark(
                                    x: .value("Date", item.date),
                                    y: .value(selectedMetric.rawValue, item.value)
                                )
                                .foregroundStyle(ThemeManager.shared.currentAccentColor.opacity(0.15))
                            }
                            .frame(height: 200)
                            .padding(.top)
                        }
                        .padding()
                    }
                    .padding(.horizontal)
                    
                    // Insights
                    InsightsSection(entries: filteredEntries)
                        .padding(.horizontal)
                    
                    // Achievements
                    AchievementsSection()
                        .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var filteredEntries: [FoodEntry] {
        let startDate = Calendar.current.date(byAdding: .day, value: -timeRange.days, to: Date())!
        return entries.filter { $0.timestamp >= startDate }
    }
    
    private var chartData: [InsightsChartDataPoint] {
        let calendar = Calendar.current
        let groupedByDay = Dictionary(grouping: filteredEntries) { entry in
            calendar.startOfDay(for: entry.timestamp)
        }
        
        return groupedByDay.map { date, entries in
            let value: Double
            switch selectedMetric {
            case .calories:
                value = entries.reduce(0) { $0 + $1.totalCalories }
            case .protein:
                value = entries.reduce(0) { $0 + $1.totalProtein }
            case .carbs:
                value = entries.reduce(0) { $0 + $1.totalCarbs }
            case .fat:
                value = entries.reduce(0) { $0 + $1.totalFat }
            case .weight:
                value = 0 // Would need weight tracking
            }
            return InsightsChartDataPoint(date: date, value: value)
        }.sorted { $0.date < $1.date }
    }
}

struct InsightsChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct ProgressSummaryCard: View {
    let entries: [FoodEntry]
    @EnvironmentObject var appState: AppState
    @ObservedObject private var themeManager = ThemeManager.shared

    private var averageCalories: Double {
        guard !entries.isEmpty else { return 0 }
        let total = entries.reduce(0) { $0 + $1.totalCalories }
        let days = Set(entries.map { Calendar.current.startOfDay(for: $0.timestamp) }).count
        return total / Double(max(days, 1))
    }

    private var daysOnTrack: Int {
        let target = appState.currentUser?.dailyCalorieTarget ?? 2000
        let groupedByDay = Dictionary(grouping: entries) { entry in
            Calendar.current.startOfDay(for: entry.timestamp)
        }

        return groupedByDay.filter { _, dayEntries in
            let total = dayEntries.reduce(0) { $0 + $1.totalCalories }
            return abs(total - target) <= target * 0.1 // Within 10% of target
        }.count
    }

    var body: some View {
        LiquidGlassCard(cornerRadius: 16) {
            VStack(spacing: 16) {
                Text("Progress Summary")
                    .font(AppFonts.headline())
                    .foregroundColor(AppColors.primaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 12) {
                    InsightsStatBox(
                        title: "Avg Daily",
                        value: "\(Int(averageCalories))",
                        unit: "cal",
                        icon: "flame.fill",
                        color: .orange
                    )

                    InsightsStatBox(
                        title: "Days on Track",
                        value: "\(daysOnTrack)",
                        unit: "days",
                        icon: "checkmark.circle.fill",
                        color: .green
                    )

                    InsightsStatBox(
                        title: "Streak",
                        value: "\(currentStreak)",
                        unit: "days",
                        icon: "flame.fill",
                        color: .red
                    )
                }
            }
            .padding()
        }
    }
    
    private var currentStreak: Int {
        let sortedDays = Set(entries.map { Calendar.current.startOfDay(for: $0.timestamp) })
            .sorted(by: >)
        
        var streak = 0
        let calendar = Calendar.current
        var checkDate = Date()
        
        for day in sortedDays {
            if calendar.isDate(day, inSameDayAs: checkDate) {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }
        
        return streak
    }
}

struct InsightsStatBox: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color

    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) private var colorScheme

    private var backgroundOpacity: Double {
        themeManager.isDarkMode || colorScheme == .dark ? 0.15 : 0.1
    }

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(
                    LinearGradient(
                        colors: [color, themeManager.currentAccentColor.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: color.opacity(0.3), radius: 2)

            Text(value)
                .font(AppFonts.title2(weight: .bold))
                .foregroundColor(AppColors.primaryText)

            Text(title)
                .font(AppFonts.caption())
                .foregroundColor(AppColors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.thinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(color.opacity(0.2), lineWidth: 0.5)
                )
        )
    }
}

struct InsightsSection: View {
    let entries: [FoodEntry]
    @ObservedObject private var themeManager = ThemeManager.shared

    private var insights: [Insight] {
        var results: [Insight] = []

        // Most consumed foods
        let foodCounts = entries.reduce(into: [String: Int]()) { counts, entry in
            counts[entry.name, default: 0] += 1
        }
        if let topFood = foodCounts.max(by: { $0.value < $1.value }) {
            results.append(Insight(
                icon: "star.fill",
                title: "Favorite Food",
                description: "You've had \(topFood.key) \(topFood.value) times",
                color: .yellow
            ))
        }

        // Protein intake
        let avgProtein = entries.isEmpty ? 0 : entries.reduce(0) { $0 + $1.totalProtein } / Double(entries.count)
        if avgProtein > 30 {
            results.append(Insight(
                icon: "figure.strengthtraining.traditional",
                title: "Protein Champion",
                description: "Averaging \(Int(avgProtein))g protein per meal",
                color: .red
            ))
        }

        return results
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Insights")
                .font(AppFonts.headline())
                .foregroundColor(AppColors.primaryText)

            ForEach(insights) { insight in
                LiquidGlassRow(cornerRadius: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: insight.icon)
                            .font(.title3)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [insight.color, themeManager.currentAccentColor],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40, height: 40)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(insight.color.opacity(0.15))
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(insight.title)
                                .font(AppFonts.subheadline(weight: .semibold))
                                .foregroundColor(AppColors.primaryText)
                            Text(insight.description)
                                .font(AppFonts.caption())
                                .foregroundColor(AppColors.secondaryText)
                        }

                        Spacer()
                    }
                    .padding()
                }
            }
        }
    }
}

struct Insight: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let color: Color
}

struct AchievementsSection: View {
    let achievements = [
        InsightsAchievement(icon: "trophy.fill", title: "First Week", description: "Logged meals for 7 days", isUnlocked: true, color: .yellow),
        InsightsAchievement(icon: "flame.fill", title: "10 Day Streak", description: "Keep the momentum going!", isUnlocked: false, color: .orange),
        InsightsAchievement(icon: "target", title: "Goal Crusher", description: "Hit your calorie goal 5 days in a row", isUnlocked: false, color: .green)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Achievements")
                .font(AppFonts.headline())
                .foregroundColor(AppColors.primaryText)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(achievements) { achievement in
                        InsightsAchievementCard(achievement: achievement)
                    }
                }
            }
        }
    }
}

struct InsightsAchievement: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let isUnlocked: Bool
    let color: Color
}

struct InsightsAchievementCard: View {
    let achievement: InsightsAchievement
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        LiquidGlassCard(cornerRadius: 14) {
            VStack(spacing: 8) {
                Image(systemName: achievement.icon)
                    .font(.title)
                    .foregroundStyle(
                        achievement.isUnlocked ?
                            LinearGradient(
                                colors: [achievement.color, themeManager.currentAccentColor],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [.gray.opacity(0.5), .gray.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .shadow(color: achievement.isUnlocked ? achievement.color.opacity(0.4) : .clear, radius: 3)

                Text(achievement.title)
                    .font(AppFonts.caption(weight: .semibold))
                    .foregroundColor(achievement.isUnlocked ? AppColors.primaryText : AppColors.tertiaryText)
                    .multilineTextAlignment(.center)

                Text(achievement.description)
                    .font(.system(size: 10))
                    .foregroundColor(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 100, height: 120)
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
        }
        .opacity(achievement.isUnlocked ? 1.0 : 0.6)
    }
}