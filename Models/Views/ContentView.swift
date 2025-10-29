import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedFood: FoodItem? = nil
    
    var body: some View {
        TabView {
            DiaryView()
                .tabItem {
                    Label("Diary", systemImage: "book.fill")
                }
            
            FoodSearchView(selectedFood: $selectedFood)
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
            
            InsightsView()
                .tabItem {
                    Label("Insights", systemImage: "chart.line.uptrend.xyaxis")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [FoodEntry.self, Recipe.self, UserProfile.self])
}
