import SwiftUI
import SwiftData

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @Query private var profiles: [UserProfile]
    @State private var isEditing = false
    @State private var showingSettings = false
    
    private var currentProfile: UserProfile? {
        profiles.first ?? appState.currentUser
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Header
                    ProfileHeaderView(profile: currentProfile)
                        .padding(.horizontal)
                    
                    // Stats Overview
                    StatsOverviewCard()
                        .padding(.horizontal)
                    
                    // Goals & Targets
                    GoalsCard(profile: currentProfile)
                        .padding(.horizontal)
                    
                    // Settings Buttons
                    VStack(spacing: 12) {
                        SettingsButton(title: "Edit Profile", icon: "person.fill") {
                            isEditing = true
                        }
                        
                        SettingsButton(title: "Reminders", icon: "bell.fill") {
                            // Handle reminders
                        }
                        
                        SettingsButton(title: "Export Data", icon: "square.and.arrow.up.fill") {
                            // Handle export
                        }
                        
                        SettingsButton(title: "Privacy", icon: "lock.fill") {
                            // Handle privacy
                        }
                        
                        SettingsButton(title: "About", icon: "info.circle.fill") {
                            // Handle about
                        }
                    }
                    .padding(.horizontal)
                    
                    // Sign Out
                    Button(action: signOut) {
                        Text("Sign Out")
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
            .sheet(isPresented: $isEditing) {
                EditProfileView(profile: currentProfile)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }
    
    private func signOut() {
        appState.isOnboarding = true
        appState.currentUser = nil
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
    }
}

struct ProfileHeaderView: View {
    let profile: UserProfile?
    
    var body: some View {
        VStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 100, height: 100)
                
                Text(profile?.name.prefix(1).uppercased() ?? "U")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 8) {
                Text(profile?.name ?? "User")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(profile?.email ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 5)
    }
}

struct StatsOverviewCard: View {
    @Query private var entries: [FoodEntry]
    
    private var totalMealsLogged: Int {
        entries.count
    }
    
    private var daysTracked: Int {
        Set(entries.map { Calendar.current.startOfDay(for: $0.timestamp) }).count
    }
    
    private var averageCalories: Int {
        guard !entries.isEmpty else { return 0 }
        let total = entries.reduce(0) { $0 + $1.totalCalories }
        return Int(total / Double(entries.count))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Lifetime Stats")
                .font(.headline)
            
            HStack(spacing: 16) {
                StatItem(value: "\(totalMealsLogged)", label: "Meals Logged", icon: "fork.knife", color: .orange)
                StatItem(value: "\(daysTracked)", label: "Days Tracked", icon: "calendar", color: .blue)
                StatItem(value: "\(averageCalories)", label: "Avg Calories", icon: "flame.fill", color: .red)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct StatItem: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

struct GoalsCard: View {
    let profile: UserProfile?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Daily Targets")
                .font(.headline)
            
            VStack(spacing: 12) {
                TargetRow(label: "Calories", value: Int(profile?.dailyCalorieTarget ?? 2000), unit: "cal", color: .blue)
                TargetRow(label: "Protein", value: Int(profile?.dailyProteinTarget ?? 150), unit: "g", color: .red)
                TargetRow(label: "Carbs", value: Int(profile?.dailyCarbTarget ?? 250), unit: "g", color: .orange)
                TargetRow(label: "Fat", value: Int(profile?.dailyFatTarget ?? 65), unit: "g", color: .yellow)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct TargetRow: View {
    let label: String
    let value: Int
    let unit: String
    let color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(label)
                .font(.subheadline)
            
            Spacer()
            
            Text("\(value) \(unit)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
    }
}

struct SettingsButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(.blue)
                    .frame(width: 30)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
}