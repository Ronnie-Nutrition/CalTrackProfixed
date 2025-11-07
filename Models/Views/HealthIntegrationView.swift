import SwiftUI
import HealthKit

struct HealthIntegrationView: View {
    @StateObject private var healthManager = HealthKitManager.shared
    @State private var showingPremiumUpgrade = false
    @State private var isPremiumUser = false // This would come from subscription state
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.red)
                        
                        Text("Apple Health Integration")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text("Sync your nutrition data with Apple Health and get personalized insights")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                    
                    if !isPremiumUser {
                        // Premium upgrade prompt
                        PremiumUpgradeCard {
                            showingPremiumUpgrade = true
                        }
                        .padding(.horizontal)
                    } else {
                        // Health integration content for premium users
                        VStack(spacing: 20) {
                            // Authorization status
                            HealthAuthorizationCard()
                            
                            if healthManager.isAuthorized {
                                // Health data overview
                                HealthDataOverview()
                                
                                // Sync settings
                                HealthSyncSettings()
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Health")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingPremiumUpgrade) {
                PremiumUpgradeView()
            }
            .task {
                if isPremiumUser {
                    await healthManager.loadHealthData()
                }
            }
        }
    }
}

struct PremiumUpgradeCard: View {
    let onUpgrade: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.yellow)
                
                Text("Premium Feature")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text("Upgrade to CalTrackPro Premium to unlock Apple Health integration and advanced features")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                FeatureRow(icon: "heart.fill", text: "Sync nutrition data to Apple Health", color: .red)
                FeatureRow(icon: "flame.fill", text: "Auto-adjust calorie goals based on workouts", color: .orange)
                FeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Advanced nutrition insights and trends", color: .blue)
                FeatureRow(icon: "trophy.fill", text: "Achievement tracking and goals", color: .yellow)
                FeatureRow(icon: "calendar", text: "Meal planning and recipe suggestions", color: .green)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            
            Button(action: onUpgrade) {
                HStack {
                    Image(systemName: "crown.fill")
                    Text("Upgrade to Premium - $4.99/month")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(16)
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            Text(text)
                .font(.body)
            Spacer()
        }
    }
}

struct HealthAuthorizationCard: View {
    @StateObject private var healthManager = HealthKitManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: healthManager.isAuthorized ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .foregroundColor(healthManager.isAuthorized ? .green : .orange)
                    .font(.title2)
                
                VStack(alignment: .leading) {
                    Text("Health Authorization")
                        .font(.headline)
                    Text(healthManager.isAuthorized ? "Connected to Apple Health" : "Not connected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if !healthManager.isAuthorized {
                    Button("Connect") {
                        Task {
                            await healthManager.requestAuthorization()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            
            if let error = healthManager.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.top, 8)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct HealthDataOverview: View {
    @StateObject private var healthManager = HealthKitManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Today's Health Data")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                HealthDataCard(
                    title: "Active Calories",
                    value: "\(Int(healthManager.dailyActiveCalories))",
                    unit: "cal",
                    icon: "flame.fill",
                    color: .orange
                )
                
                HealthDataCard(
                    title: "Current Weight",
                    value: healthManager.currentWeight.map { String(format: "%.1f", $0) } ?? "--",
                    unit: "lbs",
                    icon: "scalemass.fill",
                    color: .blue
                )
            }
            
            if !healthManager.recentWorkouts.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Workouts")
                        .font(.headline)
                    
                    ForEach(healthManager.recentWorkouts.prefix(3), id: \.uuid) { workout in
                        WorkoutRow(workout: workout)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct HealthDataCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            VStack(spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(title)
                .font(.caption)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(8)
    }
}

struct WorkoutRow: View {
    let workout: HKWorkout
    
    var body: some View {
        HStack {
            Image(systemName: workoutIcon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading) {
                Text(workout.workoutActivityType.displayName)
                    .font(.body)
                Text(DateFormatter.time.string(from: workout.startDate))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("\(Int(workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0)) cal")
                    .font(.caption)
                    .fontWeight(.medium)
                Text("\(Int(workout.duration / 60)) min")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var workoutIcon: String {
        switch workout.workoutActivityType {
        case .running: return "figure.run"
        case .cycling: return "figure.outdoor.cycle"
        case .swimming: return "figure.pool.swim"
        case .walking: return "figure.walk"
        case .yoga: return "figure.yoga"
        default: return "figure.strengthtraining.traditional"
        }
    }
}

struct HealthSyncSettings: View {
    @State private var autoSyncNutrition = true
    @State private var adjustCaloriesFromWorkouts = true
    @State private var syncWeight = true
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Sync Settings")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                SettingToggleRow(
                    title: "Auto-sync nutrition data",
                    description: "Automatically save food entries to Apple Health",
                    isOn: $autoSyncNutrition
                )
                
                SettingToggleRow(
                    title: "Adjust calorie goals from workouts",
                    description: "Increase daily calorie goal based on exercise",
                    isOn: $adjustCaloriesFromWorkouts
                )
                
                SettingToggleRow(
                    title: "Sync weight data",
                    description: "Use Apple Health weight for goal calculations",
                    isOn: $syncWeight
                )
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct SettingToggleRow: View {
    let title: String
    let description: String
    @Binding var isOn: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $isOn)
                    .labelsHidden()
            }
        }
    }
}

// Extensions
extension HKWorkoutActivityType {
    var displayName: String {
        switch self {
        case .running: return "Running"
        case .walking: return "Walking"
        case .cycling: return "Cycling"
        case .swimming: return "Swimming"
        case .yoga: return "Yoga"
        case .strengthTraining: return "Strength Training"
        case .functionalStrengthTraining: return "Functional Training"
        default: return "Workout"
        }
    }
}

extension DateFormatter {
    static let time: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}

#Preview {
    HealthIntegrationView()
}