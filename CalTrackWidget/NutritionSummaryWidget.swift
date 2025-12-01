import WidgetKit
import SwiftUI

// MARK: - Nutrition Summary Widget

struct NutritionEntry: TimelineEntry {
    let date: Date
    let calories: Int
    let calorieGoal: Int
    let protein: Int
    let proteinGoal: Int
    let carbs: Int
    let carbsGoal: Int
    let fat: Int
    let fatGoal: Int
}

struct NutritionSummaryProvider: TimelineProvider {
    func placeholder(in context: Context) -> NutritionEntry {
        NutritionEntry(
            date: Date(),
            calories: 1450,
            calorieGoal: 2000,
            protein: 85,
            proteinGoal: 120,
            carbs: 150,
            carbsGoal: 200,
            fat: 50,
            fatGoal: 65
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (NutritionEntry) -> Void) {
        let entry = loadNutritionData()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NutritionEntry>) -> Void) {
        let entry = loadNutritionData()
        // Update every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadNutritionData() -> NutritionEntry {
        let userDefaults = UserDefaults(suiteName: "group.easyaiflows.com.CalTrackProFixed")

        return NutritionEntry(
            date: Date(),
            calories: userDefaults?.integer(forKey: "todayCalories") ?? 0,
            calorieGoal: userDefaults?.integer(forKey: "calorieGoal") ?? 2000,
            protein: userDefaults?.integer(forKey: "todayProtein") ?? 0,
            proteinGoal: userDefaults?.integer(forKey: "proteinGoal") ?? 120,
            carbs: userDefaults?.integer(forKey: "todayCarbs") ?? 0,
            carbsGoal: userDefaults?.integer(forKey: "carbsGoal") ?? 200,
            fat: userDefaults?.integer(forKey: "todayFat") ?? 0,
            fatGoal: userDefaults?.integer(forKey: "fatGoal") ?? 65
        )
    }
}

struct NutritionSummaryWidgetEntryView: View {
    var entry: NutritionEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemMedium:
            mediumView
        case .systemLarge:
            largeView
        default:
            mediumView
        }
    }

    private var mediumView: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Today's Nutrition")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(entry.calories)/\(entry.calorieGoal) cal")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
            }

            HStack(spacing: 16) {
                macroColumn(
                    name: "Protein",
                    value: entry.protein,
                    goal: entry.proteinGoal,
                    unit: "g",
                    color: .red
                )

                macroColumn(
                    name: "Carbs",
                    value: entry.carbs,
                    goal: entry.carbsGoal,
                    unit: "g",
                    color: .blue
                )

                macroColumn(
                    name: "Fat",
                    value: entry.fat,
                    goal: entry.fatGoal,
                    unit: "g",
                    color: .yellow
                )
            }
        }
        .padding()
    }

    private var largeView: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("Today's Nutrition")
                        .font(.system(size: 18, weight: .bold))
                    Text(entry.date, style: .date)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                Spacer()
            }

            // Calorie Ring
            HStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 12)

                    Circle()
                        .trim(from: 0, to: min(Double(entry.calories) / Double(entry.calorieGoal), 1.0))
                        .stroke(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 2) {
                        Text("\(entry.calories)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                        Text("/ \(entry.calorieGoal)")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 100, height: 100)

                VStack(alignment: .leading, spacing: 8) {
                    let remaining = max(0, entry.calorieGoal - entry.calories)
                    Text("\(remaining) cal remaining")
                        .font(.system(size: 16, weight: .semibold))

                    let percentage = entry.calorieGoal > 0 ? Int((Double(entry.calories) / Double(entry.calorieGoal)) * 100) : 0
                    Text("\(percentage)% of daily goal")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            // Macros
            HStack(spacing: 24) {
                macroRow(
                    name: "Protein",
                    value: entry.protein,
                    goal: entry.proteinGoal,
                    unit: "g",
                    color: .red
                )

                macroRow(
                    name: "Carbs",
                    value: entry.carbs,
                    goal: entry.carbsGoal,
                    unit: "g",
                    color: .blue
                )

                macroRow(
                    name: "Fat",
                    value: entry.fat,
                    goal: entry.fatGoal,
                    unit: "g",
                    color: .yellow
                )
            }
        }
        .padding()
    }

    private func macroColumn(name: String, value: Int, goal: Int, unit: String, color: Color) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                    .frame(width: 50, height: 50)

                Circle()
                    .trim(from: 0, to: goal > 0 ? min(Double(value) / Double(goal), 1.0) : 0)
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))

                Text("\(value)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
            }

            Text(name)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
        }
    }

    private func macroRow(name: String, value: Int, goal: Int, unit: String, color: Color) -> some View {
        VStack(spacing: 8) {
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text(name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }

            Text("\(value)\(unit)")
                .font(.system(size: 18, weight: .bold, design: .rounded))

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: geometry.size.width * (goal > 0 ? min(Double(value) / Double(goal), 1.0) : 0), height: 6)
                }
            }
            .frame(height: 6)

            Text("\(goal)\(unit) goal")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct NutritionSummaryWidget: Widget {
    let kind: String = "NutritionSummaryWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NutritionSummaryProvider()) { entry in
            NutritionSummaryWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient(
                        colors: [Color.green.opacity(0.3), Color.teal.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
        }
        .configurationDisplayName("Nutrition Summary")
        .description("View your daily macros and nutrition progress.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

#Preview(as: .systemLarge) {
    NutritionSummaryWidget()
} timeline: {
    NutritionEntry(
        date: Date(),
        calories: 1450,
        calorieGoal: 2000,
        protein: 85,
        proteinGoal: 120,
        carbs: 150,
        carbsGoal: 200,
        fat: 50,
        fatGoal: 65
    )
}
