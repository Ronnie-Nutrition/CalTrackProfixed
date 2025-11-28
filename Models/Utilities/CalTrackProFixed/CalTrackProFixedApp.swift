import SwiftUI
import SwiftData

@main
struct CalTrackProFixedApp: App {
    let modelContainer: ModelContainer
    
    init() {
        do {
            let schema = Schema([
                FoodEntry.self,
                Recipe.self,
                UserProfile.self
            ])

            let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true) // TODO: Change back to false after fixing schema

            self.modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Ensure we have at least one user profile
                    createDefaultUserProfileIfNeeded()
                }
        }
        .modelContainer(modelContainer)
    }
    
    private func createDefaultUserProfileIfNeeded() {
        let context = modelContainer.mainContext
        
        let descriptor = FetchDescriptor<UserProfile>()
        do {
            let profiles = try context.fetch(descriptor)
            if profiles.isEmpty {
                let defaultProfile = UserProfile()
                context.insert(defaultProfile)
                try context.save()
            }
        } catch {
            print("Error checking/creating default profile: \(error)")
        }
    }
}
