import SwiftUI

struct FastingView: View {
    @StateObject private var fastingManager = FastingManager.shared
    @State private var showingSchedulePicker = false
    @State private var showingHistory = false
    @State private var showingCalendar = false
    @State private var animateRing = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Stats Cards
                    statsSection

                    // Main Timer (shows fasting or eating window)
                    if fastingManager.currentState == .eating {
                        eatingWindowSection
                    } else {
                        timerSection
                    }

                    // Water Tracking (during fasting)
                    if fastingManager.currentState == .fasting {
                        waterTrackingSection
                    }

                    // Fasting Benefits Timeline (during fasting)
                    if fastingManager.currentState == .fasting {
                        benefitsTimelineSection
                    }

                    // Schedule Selector
                    if fastingManager.currentState != .fasting {
                        scheduleSection
                    }

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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingCalendar = true }) {
                        Image(systemName: "calendar")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingHistory = true }) {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                }
            }
            .sheet(isPresented: $showingHistory) {
                FastingHistoryView()
            }
            .sheet(isPresented: $showingCalendar) {
                FastingCalendarView()
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

    // MARK: - Eating Window Section
    private var eatingWindowSection: some View {
        VStack(spacing: 16) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.orange.opacity(0.2), .yellow.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 20
                    )
                    .frame(width: 250, height: 250)

                // Progress ring (filling up as eating window used)
                Circle()
                    .trim(from: 0, to: fastingManager.eatingWindowProgress)
                    .stroke(
                        LinearGradient(
                            colors: [.orange, .yellow],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 250, height: 250)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: fastingManager.eatingWindowProgress)

                // Inner content
                VStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 10, height: 10)
                        Text("EATING WINDOW")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }

                    Text(fastingManager.formattedEatingWindowRemaining)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .monospacedDigit()

                    Text("remaining")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("\(fastingManager.eatingWindowHours)h window")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            .padding(.vertical, 20)

            // Eating window details
            HStack(spacing: 40) {
                if let endTime = fastingManager.eatingWindowEndTime {
                    VStack {
                        Text("Closes At")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(endTime, style: .time)
                            .font(.headline)
                            .foregroundColor(.orange)
                    }
                }

                VStack {
                    Text("Time Elapsed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatTimeInterval(fastingManager.eatingWindowElapsedTime))
                        .font(.headline)
                        .monospacedDigit()
                }
            }

            // Suggestion text
            Text("Finish eating before the window closes to stay on schedule")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
        )
    }

    // MARK: - Water Tracking Section
    private var waterTrackingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "drop.fill")
                    .foregroundColor(.blue)
                Text("Hydration")
                    .font(.headline)
                Spacer()
                Text("\(fastingManager.waterIntake)/\(fastingManager.waterGoal) glasses")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Water glasses visualization
            HStack(spacing: 8) {
                ForEach(0..<fastingManager.waterGoal, id: \.self) { index in
                    Image(systemName: index < fastingManager.waterIntake ? "drop.fill" : "drop")
                        .font(.title2)
                        .foregroundColor(index < fastingManager.waterIntake ? .blue : .gray.opacity(0.3))
                        .onTapGesture {
                            if index < fastingManager.waterIntake {
                                // Tapping filled glass removes it
                                for _ in 0..<(fastingManager.waterIntake - index) {
                                    fastingManager.removeWater()
                                }
                            } else {
                                // Tapping empty glass fills up to it
                                for _ in 0..<(index + 1 - fastingManager.waterIntake) {
                                    fastingManager.addWater()
                                }
                            }
                        }
                }
            }
            .frame(maxWidth: .infinity)

            // Quick add buttons
            HStack(spacing: 12) {
                Button(action: { fastingManager.addWater() }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add Glass")
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .cornerRadius(10)
                }

                if fastingManager.waterIntake > 0 {
                    Button(action: { fastingManager.removeWater() }) {
                        HStack {
                            Image(systemName: "minus")
                            Text("Remove")
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.blue.opacity(0.15))
                        .cornerRadius(10)
                    }
                }

                Spacer()
            }

            Text("Stay hydrated! Water, black coffee, and plain tea are OK during fasting.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
        )
    }

    // MARK: - Benefits Timeline Section
    private var benefitsTimelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
                Text("Fasting Benefits")
                    .font(.headline)
            }

            // Current benefit
            if let current = fastingManager.currentFastingBenefit {
                HStack(spacing: 12) {
                    Image(systemName: current.icon)
                        .font(.title2)
                        .foregroundColor(colorFromString(current.color))
                        .frame(width: 40, height: 40)
                        .background(colorFromString(current.color).opacity(0.2))
                        .cornerRadius(10)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Current: \(current.title)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text(current.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colorFromString(current.color).opacity(0.1))
                )
            }

            // Next benefit
            if let next = fastingManager.nextFastingBenefit,
               let timeToNext = fastingManager.timeToNextBenefit {
                HStack(spacing: 12) {
                    Image(systemName: next.icon)
                        .font(.title3)
                        .foregroundColor(.gray)
                        .frame(width: 36, height: 36)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)

                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text("Next: \(next.title)")
                                .font(.caption)
                                .fontWeight(.medium)
                            Spacer()
                            Text("in \(formatTimeInterval(timeToNext))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Text(next.description)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            }

            // Timeline progress
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(FastingBenefit.allBenefits) { benefit in
                        VStack(spacing: 4) {
                            Circle()
                                .fill(fastingManager.elapsedTime >= benefit.hoursRequired * 3600 ? colorFromString(benefit.color) : Color.gray.opacity(0.3))
                                .frame(width: 12, height: 12)
                            Text("\(Int(benefit.hoursRequired))h")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        if benefit.hoursRequired < 24 {
                            Rectangle()
                                .fill(fastingManager.elapsedTime >= benefit.hoursRequired * 3600 ? colorFromString(benefit.color).opacity(0.5) : Color.gray.opacity(0.2))
                                .frame(width: 20, height: 2)
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
        )
    }

    // Helper function to convert color string to Color
    private func colorFromString(_ colorName: String) -> Color {
        switch colorName {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "yellow": return .yellow
        case "purple": return .purple
        case "cyan": return .cyan
        case "red": return .red
        case "mint": return .mint
        default: return .gray
        }
    }

    // Helper function to format time interval
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
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
        VStack(spacing: 12) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    if fastingManager.currentState == .fasting {
                        fastingManager.stopFasting()
                    } else if fastingManager.currentState == .eating {
                        fastingManager.startFasting()
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

            // Secondary action for eating window
            if fastingManager.currentState == .eating {
                Button(action: {
                    withAnimation {
                        fastingManager.endEatingWindow()
                    }
                }) {
                    Text("End Eating Window Early")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
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
        switch fastingManager.currentState {
        case .fasting: return "End Fast"
        case .eating: return "Start Next Fast"
        case .notStarted: return "Start Fasting"
        }
    }

    private var actionButtonIcon: String {
        switch fastingManager.currentState {
        case .fasting: return "stop.fill"
        case .eating: return "play.fill"
        case .notStarted: return "play.fill"
        }
    }

    private var actionButtonColors: [Color] {
        switch fastingManager.currentState {
        case .fasting: return [.red, .orange]
        case .eating: return [.green, .mint]
        case .notStarted: return [.green, .mint]
        }
    }
}

// MARK: - Calendar View
struct FastingCalendarView: View {
    @StateObject private var fastingManager = FastingManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMonth = Date()

    private var calendar: Calendar { Calendar.current }

    private var monthDays: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: selectedMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start),
              let monthLastWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.end - 1) else {
            return []
        }

        let dateInterval = DateInterval(start: monthFirstWeek.start, end: monthLastWeek.end)
        return calendar.generateDates(for: dateInterval, matching: DateComponents(hour: 0, minute: 0, second: 0))
    }

    private func fastsForDate(_ date: Date) -> [FastingSession] {
        fastingManager.fastingHistory.filter { session in
            calendar.isDate(session.startTime, inSameDayAs: date)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Month navigation
                HStack {
                    Button(action: { changeMonth(-1) }) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                    }

                    Spacer()

                    Text(selectedMonth, format: .dateTime.month(.wide).year())
                        .font(.title3)
                        .fontWeight(.semibold)

                    Spacer()

                    Button(action: { changeMonth(1) }) {
                        Image(systemName: "chevron.right")
                            .font(.title3)
                    }
                }
                .padding(.horizontal)

                // Day headers
                HStack {
                    ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                        Text(day)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }

                // Calendar grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                    ForEach(monthDays, id: \.self) { date in
                        CalendarDayCell(
                            date: date,
                            isCurrentMonth: calendar.isDate(date, equalTo: selectedMonth, toGranularity: .month),
                            fasts: fastsForDate(date)
                        )
                    }
                }

                // Legend
                HStack(spacing: 20) {
                    HStack(spacing: 4) {
                        Circle().fill(Color.green).frame(width: 8, height: 8)
                        Text("Completed").font(.caption).foregroundColor(.secondary)
                    }
                    HStack(spacing: 4) {
                        Circle().fill(Color.orange).frame(width: 8, height: 8)
                        Text("Partial").font(.caption).foregroundColor(.secondary)
                    }
                }
                .padding(.top)

                // Stats for selected month
                VStack(alignment: .leading, spacing: 8) {
                    Text("This Month")
                        .font(.headline)

                    let monthFasts = fastingManager.fastingHistory.filter { session in
                        calendar.isDate(session.startTime, equalTo: selectedMonth, toGranularity: .month)
                    }

                    HStack(spacing: 20) {
                        VStack {
                            Text("\(monthFasts.count)")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Fasts")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        VStack {
                            Text("\(monthFasts.filter { $0.completed }.count)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                            Text("Completed")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        VStack {
                            let totalHours = monthFasts.reduce(0.0) { $0 + $1.actualDuration } / 3600
                            Text("\(Int(totalHours))")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Hours")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.regularMaterial)
                )

                Spacer()
            }
            .padding()
            .navigationTitle("Fasting Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func changeMonth(_ value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: selectedMonth) {
            selectedMonth = newMonth
        }
    }
}

struct CalendarDayCell: View {
    let date: Date
    let isCurrentMonth: Bool
    let fasts: [FastingSession]

    private var calendar: Calendar { Calendar.current }

    var body: some View {
        VStack(spacing: 2) {
            Text("\(calendar.component(.day, from: date))")
                .font(.subheadline)
                .fontWeight(calendar.isDateInToday(date) ? .bold : .regular)
                .foregroundColor(isCurrentMonth ? .primary : .secondary.opacity(0.5))

            if !fasts.isEmpty {
                HStack(spacing: 2) {
                    ForEach(fasts.prefix(3)) { fast in
                        Circle()
                            .fill(fast.completed ? Color.green : Color.orange)
                            .frame(width: 6, height: 6)
                    }
                }
            }
        }
        .frame(height: 44)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(calendar.isDateInToday(date) ? Color.blue.opacity(0.15) : Color.clear)
        )
    }
}

// Extension to generate dates
extension Calendar {
    func generateDates(for dateInterval: DateInterval, matching components: DateComponents) -> [Date] {
        var dates = [dateInterval.start]

        enumerateDates(
            startingAfter: dateInterval.start,
            matching: components,
            matchingPolicy: .nextTime
        ) { date, _, stop in
            guard let date = date else { return }

            if date < dateInterval.end {
                dates.append(date)
            } else {
                stop = true
            }
        }

        return dates
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
