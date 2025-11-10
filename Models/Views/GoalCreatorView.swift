import SwiftUI
import SwiftData

struct GoalCreatorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var goalName = ""
    @State private var goalDescription = ""
    @State private var selectedType = Goal.GoalType.calorieTarget
    @State private var targetValue: Double = 2000
    @State private var unit = "cal"
    @State private var selectedTimeFrame = Goal.TimeFrame.daily
    @State private var selectedPriority = Goal.Priority.medium
    @State private var endDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    @State private var customEndDate = false
    
    private let goalTypeUnits: [Goal.GoalType: String] = [
        .calorieTarget: "cal",
        .proteinTarget: "g",
        .carbTarget: "g",
        .fatTarget: "g",
        .weightLoss: "lbs",
        .weightGain: "lbs",
        .waterIntake: "glasses",
        .exerciseMinutes: "min",
        .stepsDaily: "steps",
        .mealPrep: "meals",
        .recipesCreated: "recipes",
        .consecutiveDays: "days"
    ]
    
    private let goalTypeTargets: [Goal.GoalType: Double] = [
        .calorieTarget: 2000,
        .proteinTarget: 150,
        .carbTarget: 250,
        .fatTarget: 65,
        .weightLoss: 10,
        .weightGain: 10,
        .waterIntake: 8,
        .exerciseMinutes: 30,
        .stepsDaily: 10000,
        .mealPrep: 5,
        .recipesCreated: 3,
        .consecutiveDays: 7
    ]
    
    var isValidGoal: Bool {
        !goalName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        targetValue > 0
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                GlassmorphismBackground(colors: [.blue, .purple, .indigo])
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
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
                                    
                                    VStack(alignment: .leading) {
                                        Text("Create Goal")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                        Text("Set a new personal goal")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                }
                                
                                // Goal Type Selection
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Goal Type")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    
                                    LazyVGrid(columns: [
                                        GridItem(.flexible()),
                                        GridItem(.flexible())
                                    ], spacing: 12) {
                                        ForEach(Goal.GoalType.allCases, id: \.self) { type in
                                            GoalTypeCard(
                                                type: type,
                                                isSelected: selectedType == type
                                            ) {
                                                withAnimation(FluidSpring.snappy) {
                                                    selectedType = type
                                                    updateDefaultsForType(type)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .padding()
                        }
                        
                        // Goal Details
                        LiquidGlassCard {
                            VStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Goal Details")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    CustomTextField(
                                        title: "Goal Name",
                                        text: $goalName,
                                        placeholder: selectedType.displayName
                                    )
                                    
                                    CustomTextField(
                                        title: "Description",
                                        text: $goalDescription,
                                        placeholder: "Describe what you want to achieve..."
                                    )
                                }
                                
                                Divider()
                                    .background(.ultraThinMaterial)
                                
                                // Target and Time Frame
                                VStack(spacing: 16) {
                                    HStack(spacing: 16) {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Target")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                            
                                            HStack {
                                                TextField("0", value: $targetValue, format: .number)
                                                    .textFieldStyle(.roundedBorder)
                                                    .keyboardType(.decimalPad)
                                                
                                                Text(unit)
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                                    .frame(minWidth: 40, alignment: .leading)
                                            }
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Time Frame")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                            
                                            Picker("Time Frame", selection: $selectedTimeFrame) {
                                                ForEach(Goal.TimeFrame.allCases, id: \.self) { timeFrame in
                                                    Text(timeFrame.displayName).tag(timeFrame)
                                                }
                                            }
                                            .pickerStyle(.menu)
                                            .background(.ultraThinMaterial)
                                            .cornerRadius(8)
                                        }
                                    }
                                    
                                    HStack(spacing: 16) {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Priority")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                            
                                            Picker("Priority", selection: $selectedPriority) {
                                                ForEach(Goal.Priority.allCases, id: \.self) { priority in
                                                    Text(priority.rawValue.capitalized).tag(priority)
                                                }
                                            }
                                            .pickerStyle(.segmented)
                                        }
                                    }
                                    
                                    // End Date
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
                            }
                            .padding()
                        }
                        
                        // Preview Card
                        LiquidGlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Preview")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                GoalPreviewCard(
                                    type: selectedType,
                                    name: goalName.isEmpty ? selectedType.displayName : goalName,
                                    description: goalDescription,
                                    target: targetValue,
                                    unit: unit,
                                    timeFrame: selectedTimeFrame,
                                    priority: selectedPriority,
                                    endDate: endDate
                                )
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
                    Button("Create") {
                        createGoal()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                    .disabled(!isValidGoal)
                }
            }
        }
    }
    
    private func updateDefaultsForType(_ type: Goal.GoalType) {
        unit = goalTypeUnits[type] ?? "units"
        targetValue = goalTypeTargets[type] ?? 100
        
        // Set appropriate end date based on type
        switch type.displayName {
        case "Daily Steps", "Daily Calorie Target", "Water Intake":
            endDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
        case "Weight Loss", "Weight Gain":
            endDate = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
        default:
            endDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
        }
    }
    
    private func createGoal() {
        let goal = Goal(
            name: goalName.isEmpty ? selectedType.displayName : goalName,
            goalDescription: goalDescription.isEmpty ? "Achieve your \(selectedType.displayName.lowercased()) goal" : goalDescription,
            type: selectedType,
            target: targetValue,
            unit: unit,
            timeFrame: selectedTimeFrame,
            endDate: endDate,
            priority: selectedPriority
        )
        
        modelContext.insert(goal)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error creating goal: \(error)")
        }
    }
}

struct GoalTypeCard: View {
    let type: Goal.GoalType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(type.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, minHeight: 80)
            .padding(.vertical, 8)
            .background(
                isSelected ? 
                LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing) :
                LinearGradient(colors: [.clear], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? .clear : .secondary.opacity(0.3),
                        lineWidth: 1
                    )
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct GoalPreviewCard: View {
    let type: Goal.GoalType
    let name: String
    let description: String
    let target: Double
    let unit: String
    let timeFrame: Goal.TimeFrame
    let priority: Goal.Priority
    let endDate: Date
    
    private var priorityColor: Color {
        switch priority {
        case .low: return .blue
        case .medium: return .green
        case .high: return .orange
        case .critical: return .red
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: type.icon)
                    .font(.title3)
                    .foregroundColor(priorityColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    
                    if !description.isEmpty {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(timeFrame.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(priority.rawValue.capitalized)
                        .font(.caption2)
                        .foregroundColor(priorityColor)
                }
            }
            
            // Target and Progress
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Target: \(Int(target)) \(unit)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("Due: \(endDate, style: .date)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Preview progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.ultraThinMaterial)
                            .frame(height: 6)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(priorityColor.opacity(0.3))
                            .frame(width: geometry.size.width * 0.3, height: 6)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}

struct CustomTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
        }
    }
}

#Preview {
    GoalCreatorView()
        .modelContainer(for: [Goal.self])
}