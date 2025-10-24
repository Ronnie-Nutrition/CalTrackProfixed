import SwiftUI
  import SwiftData

  @main
  struct CalTrackProFixedApp: App {
      var body: some Scene {
          WindowGroup {
              ContentView()
          }
          .modelContainer(for: [FoodEntry.self, Recipe.self,
  Ingredient.self, UserProfile.self], isStoredInMemoryOnly: false)
      }
  }

  2. ContentView.swift - Replace with this EXACT code:

  import SwiftUI

  struct ContentView: View {
      var body: some View {
          MainTabView()
      }
  }

  struct MainTabView: View {
      var body: some View {
          TabView {
              HomeView()
                  .tabItem {
                      Image(systemName: "house.fill")
                      Text("Home")
                  }

              DiaryView()
                  .tabItem {
                      Image(systemName: "book.fill")
                      Text("Diary")
                  }

              InsightsView()
                  .tabItem {
                      Image(systemName: "chart.bar.fill")
                      Text("Insights")
                  }

              ProfileView()
                  .tabItem {
                      Image(systemName: "person.fill")
                      Text("Profile")
                  }
          }
      }
  }
