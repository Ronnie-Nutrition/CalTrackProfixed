import SwiftUI

struct SettingsView: View {
    @AppStorage("enableNotifications") private var enableNotifications = true
    @AppStorage("breakfastReminder") private var breakfastReminder = "08:00"
    @AppStorage("lunchReminder") private var lunchReminder = "12:00"
    @AppStorage("dinnerReminder") private var dinnerReminder = "18:00"
    @AppStorage("waterReminder") private var waterReminder = true
    @AppStorage("darkMode") private var darkMode = false
    @AppStorage("units") private var units = "metric"
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
                
                Section("Data") {
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
        }
    }
}