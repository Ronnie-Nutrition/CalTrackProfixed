import SwiftUI
import SwiftData

struct HealthIntegrationView: View {
    @StateObject private var healthManager = HealthKitManager()
    @Query private var foodEntries: [FoodEntry]
    @Environment(\.modelContext) private var modelContext
    
    @State private var showingPermissionSheet = false
    @State private var showingSyncSuccess = false
    @State private var autoSyncEnabled = true
    
    private var todayFoodEntries: [FoodEntry] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()
        
        return foodEntries.filter { entry in
            entry.timestamp >= startOfDay && entry.timestamp < endOfDay
        }
    }
    
    private var totalCaloriesToday: Double {
        todayFoodEntries.reduce(0) { $0 + $1.totalCalories }
    }
    
    private var netCalories: Double {
        totalCaloriesToday - healthManager.todayActiveCalories
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                GlassmorphismBackground(colors: [.green, .blue, .cyan])
                
                ScrollView {
                    VStack(spacing: 24) {
                        headerSection
                        
                        if healthManager.isAuthorized {
                            healthDataOverview
                            todaysBalance
                            
                            if !healthManager.todayWorkouts.isEmpty {
                                workoutsSection
                            }
                            
                            weightTrackingSection
                            syncDetailsSection
                        }
                        
                        featuresOverviewSection
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await refreshHealthData()
            }
            .alert("Sync Complete", isPresented: $showingSyncSuccess) {
                Button("OK") {}
            } message: {
                Text("Your nutrition data has been successfully synced to Apple Health.")
            }
            .alert("Error", isPresented: .constant(healthManager.syncError != nil)) {
                Button("OK") {
                    healthManager.syncError = nil
                }
            } message: {
                Text(healthManager.syncError?.localizedDescription ?? "An error occurred")
            }
            .onAppear {
                Task {
                    await healthManager.fetchTodayHealthData()
                    await healthManager.fetchWeeklyWeightTrend()
                }
            }
            .onChange(of: autoSyncEnabled) { _, enabled in
                if enabled && healthManager.isAuthorized {
                    healthManager.autoSyncIfEnabled(foodEntries)
                }
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        LiquidGlassCard {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "heart.fill")
                        .font(.title)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.red, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    VStack(alignment: .leading) {
                        Text("Apple Health")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Sync nutrition data with Health app")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    AuthStatusBadge(status: healthManager.authorizationStatus)
                }
                
                if !healthManager.isAuthorized {
                    VStack(spacing: 12) {
                        Text("Connect with Apple Health to automatically sync your nutrition data and get insights from your workouts and weight.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Connect to Health") {
                            requestHealthPermission()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.red, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .liquidPulse(color: .red, intensity: 0.3)
                    }
                } else {
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Auto-Sync")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("Sync nutrition data automatically")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: $autoSyncEnabled)
                                .tint(.red)
                        }
                        
                        if let lastSync = healthManager.lastSyncDate {
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundColor(.secondary)
                                Text("Last sync: \(lastSync, style: .relative) ago")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                        }
                        
                        Button("Sync Now") {
                            syncNutritionData()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(.green.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(8)
                    }
                }
            }
            .padding()
        }
    }
    
    private var healthDataOverview: some View {
        LiquidGlassCard {
            VStack(spacing: 16) {
                Text("Today's Health Data")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    HealthMetricCard(
                        title: "Weight",
                        value: healthManager.formatWeight(healthManager.currentWeight),
                        icon: "scalemass.fill",
                        color: .blue
                    )
                    
                    HealthMetricCard(
                        title: "Active Calories",
                        value: healthManager.formatCalories(healthManager.todayActiveCalories),
                        icon: "flame.fill",
                        color: .orange
                    )
                    
                    HealthMetricCard(
                        title: "Steps",
                        value: healthManager.formatSteps(healthManager.todaySteps),
                        icon: "shoe.2.fill",
                        color: .green
                    )
                }
            }
            .padding()
        }
    }
    
    private var todaysBalance: some View {
        LiquidGlassCard {
            VStack(spacing: 16) {
                Text("Calorie Balance")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: 20) {
                    VStack(spacing: 8) {
                        Text("Consumed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        VStack(spacing: 4) {
                            Text("\(Int(totalCaloriesToday))")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            
                            Text("calories")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    Image(systemName: "minus")
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 8) {
                        Text("Active Burned")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        VStack(spacing: 4) {
                            Text("\(Int(healthManager.todayActiveCalories))")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                            
                            Text("calories")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    Image(systemName: "equal")
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 8) {
                        Text("Net")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        VStack(spacing: 4) {
                            Text("\(Int(netCalories))")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(netCalories > 0 ? .green : .red)
                            
                            Text("calories")
                                .font(.caption)
                                .foregroundColor(netCalories > 0 ? .green : .red)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                
                if netCalories > 0 {
                    Text("You have \(Int(netCalories)) calories remaining for today")
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                        .background(.green.opacity(0.1))
                        .cornerRadius(8)
                } else if netCalories < 0 {
                    Text("You've exceeded your calorie budget by \(Int(abs(netCalories))) calories")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                        .background(.red.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding()
        }
    }
    
    private var workoutsSection: some View {
        LiquidGlassCard {
            VStack(spacing: 16) {
                HStack {
                    Text("Today's Workouts")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text("\(healthManager.todayWorkouts.count) workout\(healthManager.todayWorkouts.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 12) {
                    ForEach(healthManager.todayWorkouts) { workout in
                        WorkoutRow(workout: workout)
                    }
                }
            }
            .padding()
        }
    }
    
    private var weightTrackingSection: some View {
        LiquidGlassCard {
            VStack(spacing: 16) {
                Text("Weight Trend")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if healthManager.weeklyWeightTrend.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        Text("No weight data available")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("Add weight data in the Health app to see your trend here")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Recent Entries:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        
                        ForEach(healthManager.weeklyWeightTrend.suffix(3)) { entry in
                            HStack {
                                Text(entry.date, style: .date)
                                    .font(.caption)
                                
                                Spacer()
                                
                                Text(healthManager.formatWeight(entry.weight))
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    private var syncDetailsSection: some View {
        LiquidGlassCard {
            VStack(spacing: 16) {
                Text("Sync Details")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: 12) {
                    SyncDetailRow(
                        title: "Calories",
                        description: "Total daily energy consumed",
                        isEnabled: true
                    )
                    
                    SyncDetailRow(
                        title: "Macronutrients",
                        description: "Protein, carbs, and fat breakdown",
                        isEnabled: true
                    )
                    
                    SyncDetailRow(
                        title: "Fiber & Sugar",
                        description: "Dietary fiber and sugar intake",
                        isEnabled: true
                    )
                    
                    SyncDetailRow(
                        title: "Water",
                        description: "Daily water intake (coming soon)",
                        isEnabled: false
                    )
                }
            }
            .padding()
        }
    }
    
    private var featuresOverviewSection: some View {
        LiquidGlassCard {
            VStack(spacing: 16) {
                Text("Health Integration Features")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: 12) {
                    FeatureRow(
                        icon: "arrow.up.circle.fill",
                        title: "Nutrition Sync",
                        description: "Automatically sync your daily nutrition data to Apple Health",
                        color: .green
                    )
                    
                    FeatureRow(
                        icon: "arrow.down.circle.fill",
                        title: "Workout Integration",
                        description: "View today's workouts and burned calories from Health app",
                        color: .orange
                    )
                    
                    FeatureRow(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Weight Tracking",
                        description: "Monitor weight trends and correlate with nutrition data",
                        color: .blue
                    )
                    
                    FeatureRow(
                        icon: "brain.head.profile",
                        title: "Smart Insights",
                        description: "Get personalized recommendations based on health data",
                        color: .purple
                    )
                }
            }
            .padding()
        }
    }
    
    // MARK: - Actions
    
    private func requestHealthPermission() {
        Task {
            await healthManager.requestAuthorization()
            if healthManager.isAuthorized {
                await healthManager.fetchTodayHealthData()
                await healthManager.fetchWeeklyWeightTrend()
            }
        }
    }
    
    private func syncNutritionData() {
        Task {
            await healthManager.syncNutritionData(todayFoodEntries)
            await MainActor.run {
                showingSyncSuccess = true
            }
        }
    }
    
    private func refreshHealthData() async {
        await healthManager.fetchTodayHealthData()
        await healthManager.fetchWeeklyWeightTrend()
    }
}

// MARK: - Supporting Views

struct AuthStatusBadge: View {
    let status: HealthKitManager.AuthorizationStatus
    
    private var (text, color): (String, Color) {
        switch status {
        case .notDetermined:
            return ("Not Connected", .gray)
        case .denied:
            return ("Denied", .red)
        case .authorized:
            return ("Connected", .green)
        case .restricted:
            return ("Restricted", .orange)
        }
    }
    
    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .cornerRadius(8)
    }
}

struct HealthMetricCard: View {
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
                .font(.subheadline)
                .fontWeight(.bold)
                .lineLimit(1)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 80)
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}

struct WorkoutRow: View {
    let workout: HealthKitManager.WorkoutSummary
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: workout.icon)
                .font(.title3)
                .foregroundColor(workout.color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    Text("\(Int(workout.duration / 60)) min")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(workout.caloriesBurned)) cal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text(workout.startDate, style: .time)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct SyncDetailRow: View {
    let title: String
    let description: String
    let isEnabled: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isEnabled ? "checkmark.circle.fill" : "clock.circle.fill")
                .foregroundColor(isEnabled ? .green : .orange)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .opacity(isEnabled ? 1.0 : 0.7)
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HealthIntegrationView()
        .modelContainer(for: [FoodEntry.self])
}