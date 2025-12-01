import SwiftUI

struct FastingView: View {
    @StateObject private var fastingManager = FastingManager.shared
    @State private var showingSchedulePicker = false
    @State private var showingHistory = false
    @State private var animateRing = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Stats Cards
                    statsSection

                    // Main Timer
                    timerSection

                    // Schedule Selector
                    scheduleSection

                    // Action Button
                    actionButton

                    // Quick Stats
                    quickStatsSection
                }
                .padding()
            }
            .background(AppColors.primaryBackground)
            .navigationTitle("Fasting")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingHistory = true }) {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                }
            }
            .sheet(isPresented: $showingHistory) {
                FastingHistoryView()
            }
        }
    }

    // MARK: - Stats Section
    private var statsSection: some View {
        HStack(spacing: 12) {
            FastingStatCard(
                title: "Current Streak",
                value: "\(fastingManager.currentStreak)",
                icon: "flame.fill",
                color: .orange
            )

            FastingStatCard(
                title: "Total Fasts",
                value: "\(fastingManager.totalFastsCompleted)",
                icon: "checkmark.circle.fill",
                color: .green
            )

            FastingStatCard(
                title: "This Week",
                value: "\(fastingManager.thisWeekFasts)",
                icon: "calendar",
                color: .blue
            )
        }
    }

    // MARK: - Timer Section
    private var timerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.gray.opacity(0.2), .gray.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 20
                    )
                    .frame(width: 250, height: 250)

                // Progress ring
                Circle()
                    .trim(from: 0, to: fastingManager.progress)
                    .stroke(
                        LinearGradient(
                            colors: progressColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 250, height: 250)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: fastingManager.progress)

                // Inner content
                VStack(spacing: 8) {
                    // State indicator
                    HStack(spacing: 6) {
                        Circle()
                            .fill(stateColor)
                            .frame(width: 10, height: 10)
                        Text(stateText)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }

                    // Main time display
                    Text(fastingManager.formattedElapsedTime)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .monospacedDigit()

                    // Progress percentage
                    Text("\(Int(fastingManager.progress * 100))%")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(progressColors.first ?? .blue)

                    // Target info
                    if fastingManager.currentState == .fasting {
                        Text("of \(fastingManager.fastingHours)h goal")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 20)

            // Time details
            if fastingManager.currentState == .fasting {
                HStack(spacing: 40) {
                    VStack {
                        Text("Remaining")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(fastingManager.formattedRemainingTime)
                            .font(.headline)
                            .monospacedDigit()
                    }

                    if let endTime = fastingManager.estimatedEndTime {
                        VStack {
                            Text("Goal Time")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(endTime, style: .time)
                                .font(.headline)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
        )
    }

    // MARK: - Schedule Section
    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Fasting Schedule")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(FastingSchedule.allCases, id: \.self) { schedule in
                        ScheduleButton(
                            schedule: schedule,
                            isSelected: fastingManager.selectedSchedule == schedule,
                            isDisabled: fastingManager.currentState == .fasting
                        ) {
                            withAnimation {
                                fastingManager.selectedSchedule = schedule
                            }
                        }
                    }
                }
            }

            // Custom hours slider
            if fastingManager.selectedSchedule == .custom {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Fast Duration")
                            .font(.subheadline)
                        Spacer()
                        Text("\(fastingManager.customFastingHours) hours")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }

                    Slider(
                        value: Binding(
                            get: { Double(fastingManager.customFastingHours) },
                            set: { fastingManager.customFastingHours = Int($0) }
                        ),
                        in: 12...23,
                        step: 1
                    )
                    .tint(.blue)
                    .disabled(fastingManager.currentState == .fasting)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppColors.secondaryBackground)
                )
            }
        }
    }

    // MARK: - Action Button
    private var actionButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                if fastingManager.currentState == .fasting {
                    fastingManager.stopFasting()
                } else {
                    fastingManager.startFasting()
                }
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: actionButtonIcon)
                    .font(.title2)
                Text(actionButtonText)
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: actionButtonColors,
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: actionButtonColors.first?.opacity(0.4) ?? .clear, radius: 10, y: 5)
        }
    }

    // MARK: - Quick Stats Section
    private var quickStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Progress")
                .font(.headline)

            HStack(spacing: 16) {
                ProgressStatCard(
                    title: "Longest Streak",
                    value: "\(fastingManager.longestStreak) days",
                    icon: "trophy.fill",
                    color: .yellow
                )

                ProgressStatCard(
                    title: "Success Rate",
                    value: "\(Int(fastingManager.completionRate * 100))%",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .green
                )
            }
        }
    }

    // MARK: - Computed Properties
    private var stateText: String {
        switch fastingManager.currentState {
        case .fasting: return "FASTING"
        case .eating: return "EATING WINDOW"
        case .notStarted: return "NOT STARTED"
        }
    }

    private var stateColor: Color {
        switch fastingManager.currentState {
        case .fasting: return .green
        case .eating: return .orange
        case .notStarted: return .gray
        }
    }

    private var progressColors: [Color] {
        let progress = fastingManager.progress
        if progress < 0.5 {
            return [.blue, .cyan]
        } else if progress < 0.75 {
            return [.cyan, .green]
        } else if progress < 1.0 {
            return [.green, .yellow]
        } else {
            return [.yellow, .orange]
        }
    }

    private var actionButtonText: String {
        fastingManager.currentState == .fasting ? "End Fast" : "Start Fasting"
    }

    private var actionButtonIcon: String {
        fastingManager.currentState == .fasting ? "stop.fill" : "play.fill"
    }

    private var actionButtonColors: [Color] {
        fastingManager.currentState == .fasting ? [.red, .orange] : [.green, .mint]
    }
}

// MARK: - Supporting Views
struct FastingStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
        )
    }
}

struct ScheduleButton: View {
    let schedule: FastingSchedule
    let isSelected: Bool
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: schedule.icon)
                    .font(.title3)
                Text(schedule.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color.blue : Color.clear)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(.regularMaterial)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .disabled(isDisabled)
        .opacity(isDisabled && !isSelected ? 0.5 : 1.0)
    }
}

struct ProgressStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.2))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.regularMaterial)
        )
    }
}

// MARK: - History View
struct FastingHistoryView: View {
    @StateObject private var fastingManager = FastingManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if fastingManager.fastingHistory.isEmpty {
                    ContentUnavailableView(
                        "No Fasting History",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("Your completed fasts will appear here")
                    )
                } else {
                    ForEach(fastingManager.fastingHistory) { session in
                        HistoryRow(session: session)
                    }
                }
            }
            .navigationTitle("Fasting History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct HistoryRow: View {
    let session: FastingSession

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.schedule.rawValue)
                    .font(.headline)
                Text(session.startTime, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(formatDuration(session.actualDuration))
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 4) {
                    Image(systemName: session.completed ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(session.completed ? .green : .red)
                    Text(session.completed ? "Completed" : "Ended Early")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
}

#Preview {
    FastingView()
}
