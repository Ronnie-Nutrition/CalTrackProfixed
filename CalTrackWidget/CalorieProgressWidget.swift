import WidgetKit
import SwiftUI

// MARK: - Calorie Progress Widget

struct CalorieEntry: TimelineEntry {
    let date: Date
    let consumed: Int
    let goal: Int
    let remaining: Int
    let progress: Double
}

struct CalorieProgressProvider: TimelineProvider {
    func placeholder(in context: Context) -> CalorieEntry {
        CalorieEntry(date: Date(), consumed: 1200, goal: 2000, remaining: 800, progress: 0.6)
    }

    func getSnapshot(in context: Context, completion: @escaping (CalorieEntry) -> Void) {
        let entry = loadCalorieData()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CalorieEntry>) -> Void) {
        let entry = loadCalorieData()
        // Update every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadCalorieData() -> CalorieEntry {
        let userDefaults = UserDefaults(suiteName: "group.easyaiflows.com.CalTrackProFixed")
        let consumed = userDefaults?.integer(forKey: "todayCalories") ?? 0
        let goal = userDefaults?.integer(forKey: "calorieGoal") ?? 2000
        let remaining = max(0, goal - consumed)
        let progress = goal > 0 ? min(Double(consumed) / Double(goal), 1.0) : 0

        return CalorieEntry(
            date: Date(),
            consumed: consumed,
            goal: goal,
            remaining: remaining,
            progress: progress
        )
    }
}

struct CalorieProgressWidgetEntryView: View {
    var entry: CalorieEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        default:
            smallView
        }
    }

    private var smallView: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(LinearGradient(
                    colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))

            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 8)

                    Circle()
                        .trim(from: 0, to: entry.progress)
                        .stroke(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 2) {
                        Text("\(entry.consumed)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        Text("cal")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 80, height: 80)

                Text("\(entry.remaining) left")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }

    private var mediumView: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(LinearGradient(
                    colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))

            HStack(spacing: 20) {
                // Progress Ring
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 10)

                    Circle()
                        .trim(from: 0, to: entry.progress)
                        .stroke(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 2) {
                        Text("\(Int(entry.progress * 100))%")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                }
                .frame(width: 90, height: 90)

                // Stats
                VStack(alignment: .leading, spacing: 8) {
                    Text("Calories Today")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)

                    HStack {
                        VStack(alignment: .leading) {
                            Text("\(entry.consumed)")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                            Text("consumed")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing) {
                            Text("\(entry.remaining)")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.green)
                            Text("remaining")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }

                    Text("Goal: \(entry.goal) cal")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
    }
}

struct CalorieProgressWidget: Widget {
    let kind: String = "CalorieProgressWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CalorieProgressProvider()) { entry in
            CalorieProgressWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Calorie Progress")
        .description("Track your daily calorie intake at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    CalorieProgressWidget()
} timeline: {
    CalorieEntry(date: Date(), consumed: 1200, goal: 2000, remaining: 800, progress: 0.6)
}
