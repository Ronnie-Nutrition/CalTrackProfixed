import SwiftUI
import HealthKit

struct HealthIntegrationView: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var isHealthKitAuthorized = false
    @State private var showingUpgrade = false
    @State private var syncEnabled = false
    @State private var lastSyncDate: Date?

    var body: some View {
        NavigationStack {
            ZStack {
                GlassmorphismBackground(colors: [.red, .pink, .purple])

                ScrollView {
                    VStack(spacing: 24) {
                        headerSection

                        if !subscriptionManager.isPremiumUser {
                            premiumRequiredCard
                        } else {
                            healthPermissionsSection
                            if isHealthKitAuthorized {
                                syncSettingsSection
                                syncStatusSection
                            }
                        }

                        featuresSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Apple Health")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingUpgrade) {
                PremiumUpgradeView(sourceFeature: .advancedAnalytics)
            }
            .onAppear {
                checkHealthKitAuthorization()
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.red, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "heart.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
            }

            VStack(spacing: 8) {
                Text("Apple Health Integration")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Sync your nutrition data with Apple Health to get a complete picture of your wellness")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Premium Required Card

    private var premiumRequiredCard: some View {
        LiquidGlassCard {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "crown.fill")
                        .font(.title2)
                        .foregroundColor(.yellow)

                    Text("Premium Feature")
                        .font(.headline)
                        .fontWeight(.semibold)

                    Spacer()
                }

                Text("Apple Health integration is a premium feature. Upgrade to sync your nutrition data automatically.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Button(action: { showingUpgrade = true }) {
                    HStack {
                        Image(systemName: "crown.fill")
                        Text("Upgrade to Premium")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(colors: [.purple, .pink], startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(12)
                }
            }
            .padding()
        }
    }

    // MARK: - Health Permissions Section

    private var healthPermissionsSection: some View {
        LiquidGlassCard {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: isHealthKitAuthorized ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(isHealthKitAuthorized ? .green : .orange)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(isHealthKitAuthorized ? "Connected" : "Not Connected")
                            .font(.headline)
                            .fontWeight(.semibold)

                        Text(isHealthKitAuthorized ? "CalTrackPro can access Apple Health" : "Grant access to sync nutrition data")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }

                if !isHealthKitAuthorized {
                    Button(action: requestHealthKitAuthorization) {
                        HStack {
                            Image(systemName: "heart.fill")
                            Text("Connect to Health")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(12)
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Sync Settings Section

    private var syncSettingsSection: some View {
        LiquidGlassCard {
            VStack(spacing: 16) {
                HStack {
                    Text("Sync Settings")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                }

                Toggle(isOn: $syncEnabled) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            Text("Auto-Sync")
                                .font(.subheadline)
                            Text("Automatically sync when logging food")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: .green))

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Data Types")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    HealthDataTypeRow(icon: "flame.fill", title: "Calories", color: .orange)
                    HealthDataTypeRow(icon: "p.circle.fill", title: "Protein", color: .red)
                    HealthDataTypeRow(icon: "c.circle.fill", title: "Carbohydrates", color: .yellow)
                    HealthDataTypeRow(icon: "f.circle.fill", title: "Fat", color: .blue)
                }
            }
            .padding()
        }
    }

    // MARK: - Sync Status Section

    private var syncStatusSection: some View {
        LiquidGlassCard {
            VStack(spacing: 16) {
                HStack {
                    Text("Sync Status")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                }

                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.secondary)

                    if let lastSync = lastSyncDate {
                        Text("Last sync: \(lastSync, style: .relative) ago")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Never synced")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button("Sync Now") {
                        performSync()
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
            }
            .padding()
        }
    }

    // MARK: - Features Section

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What Gets Synced")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal)

            VStack(spacing: 8) {
                HealthFeatureRow(icon: "flame.fill", title: "Calorie Intake", description: "Track daily energy consumption", color: .orange)
                HealthFeatureRow(icon: "dumbbell.fill", title: "Macronutrients", description: "Protein, carbs, and fat intake", color: .blue)
                HealthFeatureRow(icon: "chart.line.uptrend.xyaxis", title: "Nutrition Trends", description: "View data in Apple Health app", color: .green)
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Actions

    private func checkHealthKitAuthorization() {
        // Check if Health data is available
        if HKHealthStore.isHealthDataAvailable() {
            // In a real implementation, check actual authorization status
            isHealthKitAuthorized = UserDefaults.standard.bool(forKey: "healthKitAuthorized")
            syncEnabled = UserDefaults.standard.bool(forKey: "healthSyncEnabled")
            lastSyncDate = UserDefaults.standard.object(forKey: "lastHealthSync") as? Date
        }
    }

    private func requestHealthKitAuthorization() {
        // In a real implementation, this would request HealthKit authorization
        // For now, simulate successful authorization
        isHealthKitAuthorized = true
        UserDefaults.standard.set(true, forKey: "healthKitAuthorized")
    }

    private func performSync() {
        // In a real implementation, sync data to HealthKit
        lastSyncDate = Date()
        UserDefaults.standard.set(lastSyncDate, forKey: "lastHealthSync")
    }
}

// MARK: - Supporting Views

struct HealthDataTypeRow: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)

            Text(title)
                .font(.subheadline)

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        }
        .padding(.vertical, 4)
    }
}

struct HealthFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        LiquidGlassRow(cornerRadius: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 40, height: 40)

                    Image(systemName: icon)
                        .foregroundColor(color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    HealthIntegrationView()
}
