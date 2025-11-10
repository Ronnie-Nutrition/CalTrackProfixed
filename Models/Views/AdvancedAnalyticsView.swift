import SwiftUI
import SwiftData
import Charts

struct AdvancedAnalyticsView: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @Query private var foodEntries: [FoodEntry]
    @State private var selectedTimeRange: AnalyticsTimeRange = .month
    @State private var selectedMetric: AnalyticsMetric = .calories
    @State private var showUpgrade = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                GlassmorphismBackground(colors: [.purple, .blue, .indigo])
                
                if subscriptionManager.hasAccessTo(.advancedAnalytics) {
                    analyticsContent
                } else {
                    premiumRequiredView
                }
            }
            .navigationTitle("Advanced Analytics")
            .navigationBarTitleDisplayMode(.inline)
        }
        .premiumFeature(.advancedAnalytics)
    }
    
    // MARK: - Analytics Content
    
    private var analyticsContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                timeRangeSelector
                metricsOverview
                detailedCharts
                nutritionTrends
                insightsSection
                exportSection
            }
            .padding()
        }
    }
    
    private var timeRangeSelector: some View {
        LiquidGlassCard {
            VStack(spacing: 12) {
                Text("Analysis Period")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                HStack(spacing: 8) {
                    ForEach(AnalyticsTimeRange.allCases, id: \.self) { range in
                        TimeRangeButton(
                            range: range,
                            isSelected: selectedTimeRange == range
                        ) {
                            selectedTimeRange = range
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    private var metricsOverview: some View {
        LiquidGlassCard {
            VStack(spacing: 16) {
                Text("Key Metrics")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    MetricCard(
                        title: "Avg Daily Calories",
                        value: calculateAverageCalories(),
                        unit: "cal",
                        trend: .up,
                        color: .red
                    )
                    
                    MetricCard(
                        title: "Protein Goal",
                        value: calculateProteinGoalCompletion(),
                        unit: "%",
                        trend: .up,
                        color: .blue
                    )
                    
                    MetricCard(
                        title: "Logging Streak",
                        value: Double(calculateLoggingStreak()),
                        unit: "days",
                        trend: .stable,
                        color: .green
                    )
                    
                    MetricCard(
                        title: "Macro Balance",
                        value: calculateMacroBalance(),
                        unit: "%",
                        trend: .up,
                        color: .orange
                    )
                }
            }
            .padding()
        }
    }
    
    private var detailedCharts: some View {
        VStack(spacing: 16) {
            // Calories Trend Chart
            LiquidGlassCard {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Calories Trend")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Picker("Metric", selection: $selectedMetric) {
                            ForEach(AnalyticsMetric.allCases, id: \.self) { metric in
                                Text(metric.displayName).tag(metric)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    
                    Chart(getChartData()) { dataPoint in
                        LineMark(
                            x: .value("Date", dataPoint.date),
                            y: .value("Value", dataPoint.value)
                        )
                        .foregroundStyle(selectedMetric.color)
                        .symbol(Circle())
                        
                        AreaMark(
                            x: .value("Date", dataPoint.date),
                            y: .value("Value", dataPoint.value)
                        )
                        .foregroundStyle(selectedMetric.color.opacity(0.1))
                    }
                    .frame(height: 200)
                    .chartBackground { chartProxy in
                        Rectangle()
                            .fill(.clear)
                    }
                }
                .padding()
            }
            
            // Macronutrient Distribution
            LiquidGlassCard {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Macronutrient Distribution")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Chart(getMacroData()) { macro in
                        SectorMark(
                            angle: .value("Percentage", macro.percentage),
                            innerRadius: .ratio(0.5),
                            angularInset: 2
                        )
                        .foregroundStyle(macro.color)
                        .cornerRadius(4)
                    }
                    .frame(height: 200)
                    .chartBackground { chartProxy in
                        Rectangle()
                            .fill(.clear)
                    }
                    
                    HStack(spacing: 20) {
                        ForEach(getMacroData()) { macro in
                            LegendItem(
                                color: macro.color,
                                label: macro.name,
                                value: "\(Int(macro.percentage))%"
                            )
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    private var nutritionTrends: some View {
        LiquidGlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Nutrition Trends")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                VStack(spacing: 12) {
                    NutrientTrendRow(
                        nutrient: "Vitamin C",
                        currentValue: 85,
                        targetValue: 100,
                        unit: "mg",
                        trend: .up
                    )
                    
                    NutrientTrendRow(
                        nutrient: "Iron",
                        currentValue: 12,
                        targetValue: 18,
                        unit: "mg",
                        trend: .down
                    )
                    
                    NutrientTrendRow(
                        nutrient: "Fiber",
                        currentValue: 28,
                        targetValue: 35,
                        unit: "g",
                        trend: .up
                    )
                    
                    NutrientTrendRow(
                        nutrient: "Calcium",
                        currentValue: 950,
                        targetValue: 1000,
                        unit: "mg",
                        trend: .stable
                    )
                }
            }
            .padding()
        }
    }
    
    private var insightsSection: some View {
        LiquidGlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .font(.title2)
                        .foregroundColor(.purple)
                    
                    Text("AI Insights")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                VStack(spacing: 12) {
                    InsightCard(
                        type: .positive,
                        title: "Great Protein Intake!",
                        description: "You've consistently met your protein goals this week. Keep it up!"
                    )
                    
                    InsightCard(
                        type: .suggestion,
                        title: "Increase Fiber Intake",
                        description: "Consider adding more vegetables and whole grains to reach your fiber goals."
                    )
                    
                    InsightCard(
                        type: .warning,
                        title: "Sodium Watch",
                        description: "Your sodium intake has been high lately. Try reducing processed foods."
                    )
                }
            }
            .padding()
        }
    }
    
    private var exportSection: some View {
        LiquidGlassCard {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    Text("Export Data")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                }
                
                HStack(spacing: 12) {
                    ExportButton(
                        title: "PDF Report",
                        icon: "doc.text",
                        action: exportPDF
                    )
                    
                    ExportButton(
                        title: "CSV Data",
                        icon: "tablecells",
                        action: exportCSV
                    )
                    
                    ExportButton(
                        title: "Share",
                        icon: "square.and.arrow.up",
                        action: shareData
                    )
                }
            }
            .padding()
        }
    }
    
    // MARK: - Premium Required View
    
    private var premiumRequiredView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 12) {
                Text("Advanced Analytics Premium")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Get detailed insights into your nutrition patterns with advanced charts, AI-powered recommendations, and comprehensive reports.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            VStack(spacing: 16) {
                PremiumFeatureHighlight(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Detailed Charts & Trends",
                    description: "Visualize your nutrition data over time"
                )
                
                PremiumFeatureHighlight(
                    icon: "brain.head.profile",
                    title: "AI-Powered Insights",
                    description: "Get personalized recommendations"
                )
                
                PremiumFeatureHighlight(
                    icon: "waveform.path.ecg",
                    title: "Nutrient Tracking",
                    description: "Monitor vitamins and minerals"
                )
                
                PremiumFeatureHighlight(
                    icon: "square.and.arrow.up",
                    title: "Export Reports",
                    description: "Download PDF reports and CSV data"
                )
            }
            
            Button(action: {
                showUpgrade = true
            }) {
                HStack {
                    Image(systemName: "crown.fill")
                        .font(.title2)
                    
                    Text("Upgrade to Premium")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [.purple, .pink],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            .liquidPulse(color: .purple, intensity: 0.3)
            .padding(.horizontal)
            
            Spacer()
        }
        .sheet(isPresented: $showUpgrade) {
            PremiumUpgradeView(sourceFeature: .advancedAnalytics)
        }
    }
    
    // MARK: - Data Calculations
    
    private func calculateAverageCalories() -> Double {
        let entries = getEntriesForTimeRange()
        guard !entries.isEmpty else { return 0 }
        
        let totalCalories = entries.reduce(0) { $0 + $1.totalCalories }
        let uniqueDays = Set(entries.map { Calendar.current.startOfDay(for: $0.timestamp) }).count
        
        return uniqueDays > 0 ? totalCalories / Double(uniqueDays) : 0
    }
    
    private func calculateProteinGoalCompletion() -> Double {
        let entries = getEntriesForTimeRange()
        let dailyProteinGoal = 150.0 // This should come from user profile
        
        let daysWithGoalMet = entries
            .reduce(into: [Date: Double]()) { result, entry in
                let day = Calendar.current.startOfDay(for: entry.timestamp)
                result[day, default: 0] += entry.totalProtein
            }
            .filter { $0.value >= dailyProteinGoal }
            .count
        
        let totalDays = Set(entries.map { Calendar.current.startOfDay(for: $0.timestamp) }).count
        
        return totalDays > 0 ? (Double(daysWithGoalMet) / Double(totalDays)) * 100 : 0
    }
    
    private func calculateLoggingStreak() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var streak = 0
        var currentDate = today
        
        while true {
            let hasEntry = foodEntries.contains { entry in
                calendar.isDate(entry.timestamp, inSameDayAs: currentDate)
            }
            
            if hasEntry {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else {
                break
            }
        }
        
        return streak
    }
    
    private func calculateMacroBalance() -> Double {
        let entries = getEntriesForTimeRange()
        guard !entries.isEmpty else { return 0 }
        
        let totalCalories = entries.reduce(0) { $0 + $1.totalCalories }
        let proteinCalories = entries.reduce(0) { $0 + ($1.totalProtein * 4) }
        let carbCalories = entries.reduce(0) { $0 + ($1.totalCarbs * 4) }
        let fatCalories = entries.reduce(0) { $0 + ($1.totalFat * 9) }
        
        guard totalCalories > 0 else { return 0 }
        
        let proteinPercent = (proteinCalories / totalCalories) * 100
        let carbPercent = (carbCalories / totalCalories) * 100
        let fatPercent = (fatCalories / totalCalories) * 100
        
        // Calculate how close we are to ideal ratios (30% protein, 40% carbs, 30% fat)
        let proteinScore = max(0, 100 - abs(proteinPercent - 30) * 2)
        let carbScore = max(0, 100 - abs(carbPercent - 40) * 2)
        let fatScore = max(0, 100 - abs(fatPercent - 30) * 2)
        
        return (proteinScore + carbScore + fatScore) / 3
    }
    
    private func getEntriesForTimeRange() -> [FoodEntry] {
        let calendar = Calendar.current
        let now = Date()
        
        let startDate: Date
        switch selectedTimeRange {
        case .week:
            startDate = calendar.date(byAdding: .weekOfYear, value: -1, to: now) ?? now
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .threeMonths:
            startDate = calendar.date(byAdding: .month, value: -3, to: now) ?? now
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        }
        
        return foodEntries.filter { $0.timestamp >= startDate }
    }
    
    private func getChartData() -> [ChartDataPoint] {
        let entries = getEntriesForTimeRange()
        
        let dailyData = Dictionary(grouping: entries) { entry in
            Calendar.current.startOfDay(for: entry.timestamp)
        }
        
        return dailyData.map { date, entries in
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
            }
            
            return ChartDataPoint(date: date, value: value)
        }
        .sorted { $0.date < $1.date }
    }
    
    private func getMacroData() -> [MacroData] {
        let entries = getEntriesForTimeRange()
        guard !entries.isEmpty else { return [] }
        
        let totalProtein = entries.reduce(0) { $0 + $1.totalProtein }
        let totalCarbs = entries.reduce(0) { $0 + $1.totalCarbs }
        let totalFat = entries.reduce(0) { $0 + $1.totalFat }
        
        let total = totalProtein + totalCarbs + totalFat
        guard total > 0 else { return [] }
        
        return [
            MacroData(name: "Protein", percentage: (totalProtein / total) * 100, color: .blue),
            MacroData(name: "Carbs", percentage: (totalCarbs / total) * 100, color: .orange),
            MacroData(name: "Fat", percentage: (totalFat / total) * 100, color: .yellow)
        ]
    }
    
    // MARK: - Export Actions
    
    private func exportPDF() {
        // Implementation for PDF export
    }
    
    private func exportCSV() {
        // Implementation for CSV export
    }
    
    private func shareData() {
        // Implementation for sharing
    }
}

// MARK: - Supporting Views and Data Models

struct TimeRangeButton: View {
    let range: AnalyticsTimeRange
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(range.displayName)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .blue)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? .blue : .blue.opacity(0.1))
                .cornerRadius(20)
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: Double
    let unit: String
    let trend: TrendDirection
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Image(systemName: trend.icon)
                    .font(.caption)
                    .foregroundColor(trend.color)
            }
            
            HStack(alignment: .lastTextBaseline) {
                Text("\(value, specifier: "%.0f")")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}

struct NutrientTrendRow: View {
    let nutrient: String
    let currentValue: Double
    let targetValue: Double
    let unit: String
    let trend: TrendDirection
    
    private var percentage: Double {
        (currentValue / targetValue) * 100
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(nutrient)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: trend.icon)
                        .font(.caption)
                        .foregroundColor(trend.color)
                    
                    Text("\(currentValue, specifier: "%.0f")/\(targetValue, specifier: "%.0f") \(unit)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            ProgressView(value: min(percentage, 100), total: 100)
                .progressViewStyle(LinearProgressViewStyle())
                .tint(percentage >= 100 ? .green : .blue)
        }
    }
}

struct InsightCard: View {
    let type: InsightType
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .font(.title2)
                .foregroundColor(type.color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding()
        .background(type.color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct ExportButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(value)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Data Models

enum AnalyticsTimeRange: CaseIterable {
    case week, month, threeMonths, year
    
    var displayName: String {
        switch self {
        case .week: return "Week"
        case .month: return "Month"
        case .threeMonths: return "3 Months"
        case .year: return "Year"
        }
    }
}

enum AnalyticsMetric: CaseIterable {
    case calories, protein, carbs, fat
    
    var displayName: String {
        switch self {
        case .calories: return "Calories"
        case .protein: return "Protein"
        case .carbs: return "Carbs"
        case .fat: return "Fat"
        }
    }
    
    var color: Color {
        switch self {
        case .calories: return .red
        case .protein: return .blue
        case .carbs: return .orange
        case .fat: return .yellow
        }
    }
}

enum TrendDirection {
    case up, down, stable
    
    var icon: String {
        switch self {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .stable: return "minus"
        }
    }
    
    var color: Color {
        switch self {
        case .up: return .green
        case .down: return .red
        case .stable: return .gray
        }
    }
}

enum InsightType {
    case positive, suggestion, warning
    
    var icon: String {
        switch self {
        case .positive: return "checkmark.circle.fill"
        case .suggestion: return "lightbulb.fill"
        case .warning: return "exclamationmark.triangle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .positive: return .green
        case .suggestion: return .blue
        case .warning: return .orange
        }
    }
}

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct MacroData: Identifiable {
    let id = UUID()
    let name: String
    let percentage: Double
    let color: Color
}

#Preview {
    AdvancedAnalyticsView()
        .modelContainer(for: [FoodEntry.self])
}