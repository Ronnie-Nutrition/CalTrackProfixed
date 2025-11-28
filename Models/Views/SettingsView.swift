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
    @State private var showingAPIKeySetup = false
    @State private var hasOpenAIKey = AIFoodRecognitionService.hasOpenAIAPIKey()
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
                
                Section("AI Food Camera") {
                    Button(action: { showingAPIKeySetup = true }) {
                        HStack {
                            Image(systemName: "camera.viewfinder")
                                .foregroundColor(.purple)
                            Text("OpenAI Vision API")
                            Spacer()
                            if hasOpenAIKey {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            } else {
                                Text("Not configured")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .foregroundColor(.primary)

                    if hasOpenAIKey {
                        Text("AI camera uses OpenAI Vision for accurate food recognition")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Configure OpenAI API key to enable advanced AI food recognition. Without it, basic recognition is used.")
                            .font(.caption)
                            .foregroundColor(.secondary)
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
                HealthIntegrationView()
            }
            .sheet(isPresented: $showingPremiumUpgrade) {
                PremiumUpgradeView()
            }
            .sheet(isPresented: $showingAPIKeySetup) {
                OpenAIAPIKeySetupView(hasOpenAIKey: $hasOpenAIKey)
            }
        }
    }
}

// MARK: - OpenAI API Key Setup View
struct OpenAIAPIKeySetupView: View {
    @Binding var hasOpenAIKey: Bool
    @State private var apiKey = ""
    @State private var showingKey = false
    @State private var isSaving = false
    @State private var showingSuccess = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 50))
                            .foregroundColor(.purple)
                            .frame(maxWidth: .infinity)
                            .padding(.bottom, 8)

                        Text("OpenAI Vision API")
                            .font(.title2)
                            .bold()
                            .frame(maxWidth: .infinity)

                        Text("Enable advanced AI food recognition that accurately identifies foods from photos. OpenAI Vision can recognize specific dishes, ingredients, and portion sizes.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 8)
                }

                Section("API Key") {
                    HStack {
                        if showingKey {
                            TextField("sk-...", text: $apiKey)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .font(.system(.body, design: .monospaced))
                        } else {
                            SecureField("sk-...", text: $apiKey)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                        }

                        Button(action: { showingKey.toggle() }) {
                            Image(systemName: showingKey ? "eye.slash" : "eye")
                                .foregroundColor(.secondary)
                        }
                    }

                    if hasOpenAIKey && apiKey.isEmpty {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("API key is configured")
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section {
                    Link(destination: URL(string: "https://platform.openai.com/api-keys")!) {
                        HStack {
                            Image(systemName: "key.fill")
                                .foregroundColor(.blue)
                            Text("Get API Key from OpenAI")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondary)
                        }
                    }
                } footer: {
                    Text("You need an OpenAI account. API usage is pay-per-use (~$0.01 per image analysis).")
                }

                Section {
                    Button(action: saveAPIKey) {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                            }
                            Text(apiKey.isEmpty && hasOpenAIKey ? "Key Already Saved" : "Save API Key")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(apiKey.isEmpty || isSaving)

                    if hasOpenAIKey {
                        Button(role: .destructive, action: removeAPIKey) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Remove API Key")
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .navigationTitle("AI Camera Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("API Key Saved", isPresented: $showingSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your OpenAI API key has been securely saved. The AI camera will now use OpenAI Vision for food recognition.")
            }
        }
    }

    private func saveAPIKey() {
        guard !apiKey.isEmpty else { return }
        isSaving = true

        // Validate key format
        if !apiKey.hasPrefix("sk-") {
            isSaving = false
            return
        }

        AIFoodRecognitionService.setOpenAIAPIKey(apiKey)
        hasOpenAIKey = true
        isSaving = false
        showingSuccess = true
    }

    private func removeAPIKey() {
        AIFoodRecognitionService.clearOpenAIAPIKey()
        hasOpenAIKey = false
        apiKey = ""
    }
}