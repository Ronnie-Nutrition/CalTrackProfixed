import WidgetKit
import SwiftUI

// MARK: - Fasting Timer Widget

enum FastingWidgetState: String {
    case notStarted = "not_started"
    case fasting = "fasting"
    case eating = "eating"
}

struct FastingEntry: TimelineEntry {
    let date: Date
    let state: FastingWidgetState
    let elapsedHours: Int
    let elapsedMinutes: Int
    let targetHours: Int
    let progress: Double
    let currentBenefit: String?
}

struct FastingTimerProvider: TimelineProvider {
    func placeholder(in context: Context) -> FastingEntry {
        FastingEntry(
            date: Date(),
            state: .fasting,
            elapsedHours: 12,
            elapsedMinutes: 30,
            targetHours: 16,
            progress: 0.78,
            currentBenefit: "Fat Burning"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (FastingEntry) -> Void) {
        let entry = loadFastingData()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FastingEntry>) -> Void) {
        let entry = loadFastingData()
        // Update every minute for accurate timer
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 1, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadFastingData() -> FastingEntry {
        let userDefaults = UserDefaults(suiteName: "group.easyaiflows.com.CalTrackProFixed")

        let stateString = userDefaults?.string(forKey: "fastingState") ?? "not_started"
        let state = FastingWidgetState(rawValue: stateString) ?? .notStarted
        let targetHours = userDefaults?.integer(forKey: "fastingTargetHours") ?? 16

        var elapsedHours = 0
        var elapsedMinutes = 0
        var progress: Double = 0
        var currentBenefit: String?

        if state == .fasting, let startTimeInterval = userDefaults?.double(forKey: "fastingStartTime"), startTimeInterval > 0 {
            let startTime = Date(timeIntervalSince1970: startTimeInterval)
            let elapsed = Date().timeIntervalSince(startTime)
            elapsedHours = Int(elapsed) / 3600
            elapsedMinutes = (Int(elapsed) % 3600) / 60

            let targetSeconds = Double(targetHours * 3600)
            progress = min(elapsed / targetSeconds, 1.0)

            // Determine current benefit
            let totalHours = elapsed / 3600
            if totalHours >= 16 {
                currentBenefit = "Autophagy Active"
            } else if totalHours >= 12 {
                currentBenefit = "Fat Burning"
            } else if totalHours >= 8 {
                currentBenefit = "Glucose Depleted"
            } else if totalHours >= 4 {
                currentBenefit = "Insulin Dropping"
            } else {
                currentBenefit = "Digestion Complete"
            }
        }

        return FastingEntry(
            date: Date(),
            state: state,
            elapsedHours: elapsedHours,
            elapsedMinutes: elapsedMinutes,
            targetHours: targetHours,
            progress: progress,
            currentBenefit: currentBenefit
        )
    }
}

struct FastingTimerWidgetEntryView: View {
    var entry: FastingEntry
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
        VStack(spacing: 8) {
            if entry.state == .fasting {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 8)

                    Circle()
                        .trim(from: 0, to: entry.progress)
                        .stroke(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 0) {
                        Text("\(entry.elapsedHours):\(String(format: "%02d", entry.elapsedMinutes))")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                }
                .frame(width: 80, height: 80)

                if let benefit = entry.currentBenefit {
                    Text(benefit)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.orange)
                        .lineLimit(1)
                }
            } else if entry.state == .eating {
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.green)

                Text("Eating Window")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.primary)

                Text("Open")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.green)
            } else {
                Image(systemName: "clock.circle")
                    .font(.system(size: 40))
                    .foregroundColor(.gray)

                Text("Ready to Fast")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }

    private var mediumView: some View {
        HStack(spacing: 20) {
            if entry.state == .fasting {
                // Progress Ring
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 10)

                    Circle()
                        .trim(from: 0, to: entry.progress)
                        .stroke(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 0) {
                        Text("\(entry.elapsedHours)h")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                        Text("\(entry.elapsedMinutes)m")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 90, height: 90)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("Fasting")
                            .font(.system(size: 16, weight: .bold))
                    }

                    if let benefit = entry.currentBenefit {
                        Text(benefit)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.orange)
                    }

                    Text("Target: \(entry.targetHours) hours")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                    // Progress Bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 8)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                                .frame(width: geometry.size.width * entry.progress, height: 8)
                        }
                    }
                    .frame(height: 8)
                }
            } else if entry.state == .eating {
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.green)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Eating Window")
                        .font(.system(size: 18, weight: .bold))

                    Text("Your eating window is open")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)

                    Text("Tap to start fasting")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.green)
                }
            } else {
                Image(systemName: "clock.circle")
                    .font(.system(size: 50))
                    .foregroundColor(.gray)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Ready to Fast")
                        .font(.system(size: 18, weight: .bold))

                    Text("Tap to start your fast")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)

                    Text("\(entry.targetHours):\(24 - entry.targetHours) protocol")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
    }
}

struct FastingTimerWidget: Widget {
    let kind: String = "FastingTimerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FastingTimerProvider()) { entry in
            FastingTimerWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient(
                        colors: [Color.orange.opacity(0.3), Color.red.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
        }
        .configurationDisplayName("Fasting Timer")
        .description("Track your intermittent fasting progress.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemMedium) {
    FastingTimerWidget()
} timeline: {
    FastingEntry(
        date: Date(),
        state: .fasting,
        elapsedHours: 12,
        elapsedMinutes: 30,
        targetHours: 16,
        progress: 0.78,
        currentBenefit: "Fat Burning"
    )
}
