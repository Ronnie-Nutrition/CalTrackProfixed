import SwiftUI

struct SettingsView: View {
    @AppStorage("enableNotifications") private var enableNotifications = true
    @AppStorage("breakfastReminder") private var breakfastReminder = "08:00"
    @AppStorage("lunchReminder") private var lunchReminder = "12:00"
    @AppStorage("dinnerReminder") private var dinnerReminder = "18:00"
    @AppStorage("waterReminder") private var waterReminder = true
    @AppStorage("darkMode") private var darkMode = false
    @AppStorage("units") private var units = "metric"
    @State private var showingHealthIntegration = false
    @State private var showingPremiumUpgrade = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Notifications") {
                    Toggle("Enable Notifications", isOn: $enableNotifications)
                    
                    if enableNotifications {
                        HStack {
                            Text("Breakfast Reminder")
                            Spacer()
                            Text(breakfastReminder)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Lunch Reminder")
                            Spacer()
                            Text(lunchReminder)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Dinner Reminder")
                            Spacer()
                            Text(dinnerReminder)
                                .foregroundColor(.secondary)
                        }
                        
                        Toggle("Water Reminders", isOn: $waterReminder)
                    }
                }
                
                Section("Appearance") {
                    Toggle("Dark Mode", isOn: $darkMode)
                }
                
                Section("Units") {
                    Picker("Unit System", selection: $units) {
                        Text("Metric").tag("metric")
                        Text("Imperial").tag("imperial")
                    }
                }
                
                Section("Health & Premium") {
                    Button(action: { showingHealthIntegration = true }) {
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                            Text("Apple Health Integration")
                            Spacer()
                            Image(systemName: "crown.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                        }
                    }
                    .foregroundColor(.primary)
                    
                    Button(action: { showingPremiumUpgrade = true }) {
                        HStack {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.yellow)
                            Text("Upgrade to Premium")
                            Spacer()
                            Text("$4.99/mo")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                }
                
                Section("Data") {
                    HStack {
                        Text("Offline Cache")
                        Spacer()
                        Text("Cache size will be shown here")
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Clear Offline Cache") {
                        // Cache clearing will be implemented later
                        print("Cache cleared")
                    }
                    .foregroundColor(.orange)
                    
                    Button("Export All Data") {
                        // Export functionality
                    }
                    
                    Button("Clear All Data", role: .destructive) {
                        // Clear data functionality
                    }
                }
                
                Section("Support") {
                    Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                    Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)
                    Link("Contact Support", destination: URL(string: "mailto:support@caltrackpro.com")!)
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
                
                #if DEBUG
                Section("Debug") {
                    Button("Test Crash (Debug Only)", role: .destructive) {
                        fatalError("Test crash for debugging")
                    }
                    .foregroundColor(.red)
                }
                #endif
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingHealthIntegration) {
                Text("Health integration feature coming soon!")
                    .padding()
            }
            .sheet(isPresented: $showingPremiumUpgrade) {
                Text("Premium upgrade feature coming soon!")
                    .padding()
            }
        }
    }
}