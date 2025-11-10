import SwiftUI
import SwiftData

struct GoalDetailView: View {
    let goal: Goal
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var showingDeleteAlert = false
    @State private var showingEditView = false
    @State private var progressHistory: [ProgressEntry] = []
    
    struct ProgressEntry {
        let date: Date
        let value: Double
        let percentage: Double
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                GlassmorphismBackground(colors: [.blue, .purple, .indigo])
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Hero Section
                        LiquidGlassCard {
                            VStack(spacing: 16) {
                                // Header
                                HStack {
                                    Image(systemName: goal.type.icon)
                                        .font(.largeTitle)
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [priorityColor, priorityColor.opacity(0.7)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 4) {
                                        StatusBadge(goal: goal)
                                        
                                        Text(goal.timeFrame.displayName)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(goal.name)
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    if !goal.goalDescription.isEmpty {
                                        Text(goal.goalDescription)
                                            .font(.body)
                                            .foregroundColor(.secondary)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }
                                
                                // Progress Circle
                                ZStack {
                                    Circle()
                                        .stroke(.ultraThinMaterial, lineWidth: 8)
                                        .frame(width: 120, height: 120)
                                    
                                    Circle()
                                        .trim(from: 0, to: goal.progressPercentage / 100)
                                        .stroke(
                                            LinearGradient(
                                                colors: [priorityColor, priorityColor.opacity(0.6)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                                        )
                                        .frame(width: 120, height: 120)
                                        .rotationEffect(.degrees(-90))
                                    
                                    VStack(spacing: 4) {
                                        Text("\(Int(goal.progressPercentage))%")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(priorityColor)
                                        
                                        Text("Complete")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .liquidPulse(color: priorityColor, intensity: goal.isCompleted ? 0.5 : 0.2)
                            }
                            .padding()
                        }
                        
                        // Stats Section
                        LiquidGlassCard {
                            VStack(spacing: 16) {
                                Text("Statistics")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 16) {
                                    StatCard(
                                        title: "Current Progress",
                                        value: goal.formattedProgress,
                                        icon: "chart.line.uptrend.xyaxis",
                                        color: .blue
                                    )
                                    
                                    StatCard(
                                        title: "Target",
                                        value: "\(Int(goal.target)) \(goal.unit)",
                                        icon: "target",
                                        color: .green
                                    )
                                    
                                    StatCard(
                                        title: "Current Streak",
                                        value: "\(goal.streak) days",
                                        icon: "flame.fill",
                                        color: .orange
                                    )
                                    
                                    StatCard(
                                        title: "Best Streak",
                                        value: "\(goal.bestStreak) days",
                                        icon: "trophy.fill",
                                        color: .yellow
                                    )
                                    
                                    StatCard(
                                        title: "Days Remaining",
                                        value: goal.isCompleted ? "Complete" : "\(goal.daysRemaining)",
                                        icon: "calendar",
                                        color: goal.isOverdue ? .red : .purple
                                    )
                                    
                                    StatCard(
                                        title: "Priority",
                                        value: goal.priority.rawValue.capitalized,
                                        icon: "exclamationmark.triangle.fill",
                                        color: priorityColor
                                    )
                                }
                            }
                            .padding()
                        }
                        
                        // Timeline Section
                        LiquidGlassCard {
                            VStack(spacing: 16) {
                                HStack {
                                    Text("Timeline")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    
                                    Spacer()
                                    
                                    Button("View History") {
                                        // Show detailed history
                                    }
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                }
                                
                                VStack(spacing: 12) {
                                    TimelineItem(
                                        title: "Goal Created",
                                        date: goal.createdAt,
                                        icon: "plus.circle.fill",
                                        color: .blue,
                                        isCompleted: true
                                    )
                                    
                                    TimelineItem(
                                        title: "Target Date",
                                        date: goal.endDate,
                                        icon: "flag.fill",
                                        color: goal.isOverdue ? .red : .green,
                                        isCompleted: false
                                    )
                                    
                                    if goal.isCompleted, let completedAt = goal.completedAt {
                                        TimelineItem(
                                            title: "Goal Completed",
                                            date: completedAt,
                                            icon: "checkmark.circle.fill",
                                            color: .green,
                                            isCompleted: true
                                        )
                                    }
                                }
                            }
                            .padding()
                        }
                        
                        // Actions Section
                        VStack(spacing: 12) {
                            if !goal.isCompleted {
                                Button("Edit Goal") {
                                    showingEditView = true
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.blue)
                                .foregroundColor(.white)
                                .cornerRadius(16)
                                .shadow(color: .blue.opacity(0.3), radius: 10)
                                
                                Button("Mark as Completed") {
                                    markGoalCompleted()
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.green.opacity(0.2))
                                .foregroundColor(.green)
                                .cornerRadius(16)
                            }
                            
                            Button("Delete Goal") {
                                showingDeleteAlert = true
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.red.opacity(0.1))
                            .foregroundColor(.red)
                            .cornerRadius(16)
                        }
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edit") {
                        showingEditView = true
                    }
                    .foregroundColor(.blue)
                }
            }
            .alert("Delete Goal", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteGoal()
                }
            } message: {
                Text("Are you sure you want to delete this goal? This action cannot be undone.")
            }
            .sheet(isPresented: $showingEditView) {
                GoalEditView(goal: goal)
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
    
    private func markGoalCompleted() {
        withAnimation(FluidSpring.bouncy) {
            goal.markAsCompleted()
            try? modelContext.save()
        }
    }
    
    private func deleteGoal() {
        modelContext.delete(goal)
        try? modelContext.save()
        dismiss()
    }
}

struct StatusBadge: View {
    let goal: Goal
    
    var body: some View {
        Text(statusText)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(statusColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.2))
            .cornerRadius(8)
    }
    
    private var statusText: String {
        if goal.isCompleted {
            return "Completed"
        } else if goal.isOverdue {
            return "Overdue"
        } else if goal.progressPercentage >= 75 {
            return "Almost There"
        } else if goal.progressPercentage >= 50 {
            return "In Progress"
        } else {
            return "Started"
        }
    }
    
    private var statusColor: Color {
        if goal.isCompleted {
            return .green
        } else if goal.isOverdue {
            return .red
        } else if goal.progressPercentage >= 75 {
            return .orange
        } else {
            return .blue
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .lineLimit(1)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, minHeight: 80)
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}

struct TimelineItem: View {
    let title: String
    let date: Date
    let icon: String
    let color: Color
    let isCompleted: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.green)
            } else {
                Circle()
                    .stroke(color.opacity(0.5), lineWidth: 2)
                    .frame(width: 20, height: 20)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Goal Edit View

struct GoalEditView: View {
    let goal: Goal
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var goalName: String
    @State private var goalDescription: String
    @State private var targetValue: Double
    @State private var selectedPriority: Goal.Priority
    @State private var endDate: Date
    
    init(goal: Goal) {
        self.goal = goal
        _goalName = State(initialValue: goal.name)
        _goalDescription = State(initialValue: goal.goalDescription)
        _targetValue = State(initialValue: goal.target)
        _selectedPriority = State(initialValue: goal.priority)
        _endDate = State(initialValue: goal.endDate)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                GlassmorphismBackground(colors: [.blue, .purple, .indigo])
                
                ScrollView {
                    VStack(spacing: 24) {
                        LiquidGlassCard {
                            VStack(spacing: 16) {
                                Text("Edit Goal")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                CustomTextField(
                                    title: "Goal Name",
                                    text: $goalName,
                                    placeholder: "Enter goal name"
                                )
                                
                                CustomTextField(
                                    title: "Description",
                                    text: $goalDescription,
                                    placeholder: "Describe your goal"
                                )
                                
                                HStack(spacing: 16) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Target")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        
                                        HStack {
                                            TextField("Target", value: $targetValue, format: .number)
                                                .textFieldStyle(.roundedBorder)
                                                .keyboardType(.decimalPad)
                                            
                                            Text(goal.unit)
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Priority")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        
                                        Picker("Priority", selection: $selectedPriority) {
                                            ForEach(Goal.Priority.allCases, id: \.self) { priority in
                                                Text(priority.rawValue.capitalized).tag(priority)
                                            }
                                        }
                                        .pickerStyle(.menu)
                                        .background(.ultraThinMaterial)
                                        .cornerRadius(8)
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("End Date")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    DatePicker(
                                        "End Date",
                                        selection: $endDate,
                                        in: Date()...,
                                        displayedComponents: .date
                                    )
                                    .labelsHidden()
                                    .background(.ultraThinMaterial)
                                    .cornerRadius(8)
                                }
                            }
                            .padding()
                        }
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                }
            }
        }
    }
    
    private func saveChanges() {
        goal.name = goalName
        goal.goalDescription = goalDescription
        goal.target = targetValue
        goal.priority = selectedPriority
        goal.endDate = endDate
        
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    let goal = Goal(
        name: "Daily Calorie Goal",
        goalDescription: "Maintain a healthy daily calorie intake",
        type: .calorieTarget,
        target: 2000,
        unit: "cal",
        timeFrame: .daily,
        endDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    )
    
    return GoalDetailView(goal: goal)
        .modelContainer(for: [Goal.self])
}