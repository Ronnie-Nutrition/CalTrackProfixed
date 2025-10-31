import SwiftUI
import SwiftData

@main
struct CalTrackProApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .modelContainer(for: [FoodEntry.self, UserProfile.self, Recipe.self])
        }
    }
}

class AppState: ObservableObject {
    @Published var selectedTab = 0
    @Published var isOnboarding = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    @Published var currentUser: UserProfile?
}