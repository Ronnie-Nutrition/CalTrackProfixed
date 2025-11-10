


import SwiftUI
import SwiftData

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @Query private var profiles: [UserProfile]
    @State private var isEditing = false
    @State private var showingSettings = false
    @ObservedObject private var themeManager = ThemeManager.shared
    
    private var currentProfile: UserProfile? {
        profiles.first ?? appState.currentUser
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Simple Profile Header
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [themeManager.currentAccentColor, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 100, height: 100)
                            
                            Text(currentProfile?.name.prefix(1).uppercased() ?? "D")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 8) {
                            Text(currentProfile?.name ?? "Default User")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(AppColors.primaryText)
                            
                            Text(currentProfile?.email ?? "user@caltrackpro.com")
                                .font(.subheadline)
                                .foregroundColor(AppColors.secondaryText)
                        }
                    }
                    .padding()
                    .background(AppColors.secondaryBackground)
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    // Settings Buttons
                    VStack(spacing: 12) {
                        Button(action: { isEditing = true }) {
                            SettingsRow(title: "Edit Profile", icon: "person.fill", color: .blue)
                        }
                        
                        NavigationLink(destination: AppearanceSettingsView()) {
                            SettingsRow(title: "Appearance", icon: "paintbrush.fill", color: .purple)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: {}) {
                            SettingsRow(title: "Settings", icon: "gearshape.fill", color: .gray)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Sign Out
                    Button(action: signOut) {
                        Text("Sign Out")
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppColors.secondaryBackground)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .background(AppColors.primaryBackground)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isEditing) {
                Text("Edit Profile Coming Soon")
            }
        }
        .applyAdaptiveTheme()
    }
    
    private func signOut() {
        appState.isOnboarding = true
        appState.currentUser = nil
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
    }
}

struct SettingsRow: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(color)
                .frame(width: 30)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(AppColors.primaryText)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(AppColors.tertiaryText)
        }
        .padding()
        .background(AppColors.secondaryBackground)
        .cornerRadius(10)
    }
}

