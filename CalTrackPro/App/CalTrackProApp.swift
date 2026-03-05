import SwiftUI
import SwiftData
import FirebaseCore
import FirebaseCrashlytics
import RevenueCat

@main
struct CalTrackProApp: App {
    @StateObject private var appState = AppState()

    init() {
        // Configure security first
        configureAppSecurity()

        // Configure Firebase before any other initialization
        FirebaseApp.configure()

        // Configure Crashlytics settings
        configureCrashlytics()

        // Configure RevenueCat
        configureRevenueCat()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .modelContainer(for: [FoodEntry.self, UserProfile.self, Recipe.self])
        }
    }
    
    private func configureCrashlytics() {
        // Enable Crashlytics collection
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
        
        // Set up custom keys for better debugging
        let crashlytics = Crashlytics.crashlytics()
        
        // Set app version info
        if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            crashlytics.setCustomValue(appVersion, forKey: "app_version")
        }
        
        if let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            crashlytics.setCustomValue(buildNumber, forKey: "build_number")
        }
        
        // Set device info
        crashlytics.setCustomValue(UIDevice.current.systemVersion, forKey: "ios_version")
        crashlytics.setCustomValue(UIDevice.current.model, forKey: "device_model")
        
        #if DEBUG
        print("🔥 Firebase Crashlytics configured for DEBUG")
        #else
        print("🔥 Firebase Crashlytics configured for RELEASE")
        #endif
    }
    
    private func configureRevenueCat() {
        #if DEBUG
        Purchases.logLevel = .debug
        #endif
        Purchases.configure(withAPIKey: "appl_KExajelckHGxUUEYUZbwgcfNnkD")
        print("[RevenueCat] Configured with production API key")
    }

    private func configureAppSecurity() {
        // Initialize security configuration
        SecurityConfig.configureNetworkSecurity()
        SecurityConfig.configureDataProtection()
        
        // Handle jailbreak detection
        SecurityConfig.handleJailbreakDetection()
        
        // Migrate API credentials to secure storage
        SecureAPIConfig.migrateFromOldConfig()
        
        CrashlyticsManager.shared.log("App security configured", category: "Security")
    }
}

class AppState: ObservableObject {
    @Published var selectedTab = 0
    @Published var isOnboarding = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    @Published var currentUser: UserProfile?
}