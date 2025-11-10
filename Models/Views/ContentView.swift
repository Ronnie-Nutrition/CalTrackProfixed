import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedFood: FoodItem? = nil
    @StateObject private var appState = AppState()
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .environmentObject(appState)
            
            DiaryView()
                .tabItem {
                    Label("Diary", systemImage: "book.fill")
                }
            
            FoodSearchView(selectedFood: $selectedFood)
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
            
            EnhancedInsightsView()
                .tabItem {
                    Label("Insights", systemImage: "chart.line.uptrend.xyaxis")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
        .environmentObject(appState)
        .applyAdaptiveTheme()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [FoodEntry.self, Recipe.self, UserProfile.self, Goal.self, Achievement.self])
}

