import SwiftUI
import SwiftData

@main
struct CalTrackProFixedApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [FoodEntry.self, Recipe.self, UserProfile.self])
    }
}
