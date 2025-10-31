import SwiftUI
import Combine

class AppState: ObservableObject {
    @Published var isOnboarding: Bool = false
    @Published var selectedTab: Int = 0
    @Published var currentUser: UserProfile?
    
    init() {
        // Check if user has completed onboarding
        self.isOnboarding = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }
    
    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        self.isOnboarding = false
    }
}