import SwiftUI
import SwiftData

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var name = ""
    @State private var email = ""
    @State private var age = ""
    @State private var gender = UserProfile.Gender.male
    @State private var height = ""
    @State private var weight = ""
    @State private var activityLevel = UserProfile.ActivityLevel.moderatelyActive
    @State private var goal = UserProfile.Goal.maintainWeight
    @State private var showingMainApp = false
    @EnvironmentObject var appState: AppState
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationStack {
            TabView(selection: $currentPage) {
                // Welcome
                VStack(spacing: 30) {
                    Spacer()
                    
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 100))
                        .foregroundColor(.blue)
                    
                    Text("Welcome to CalTrackPro")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Your AI-powered nutrition companion")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("Get Started") {
                        withAnimation {
                            currentPage = 1
                        }
                    }
                    .buttonStyle(OnboardingButtonStyle())
                }
                .tag(0)
                
                // Personal Info
                VStack(spacing: 20) {
                    Text("Tell us about yourself")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top, 40)
                    
                    VStack(spacing: 16) {
                        TextField("Name", text: $name)
                            .textFieldStyle(OnboardingTextFieldStyle())
                        
                        TextField("Email", text: $email)
                            .textFieldStyle(OnboardingTextFieldStyle())
                            .keyboardType(.emailAddress)
                        
                        HStack(spacing: 16) {
                            TextField("Age", text: $age)
                                .textFieldStyle(OnboardingTextFieldStyle())
                                .keyboardType(.numberPad)
                                .frame(width: 80)
                            
                            Picker("Gender", selection: $gender) {
                                ForEach(UserProfile.Gender.allCases, id: \.self) { gender in
                                    Text(gender.rawValue).tag(gender)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    HStack(spacing: 16) {
                        Button("Back") {
                            withAnimation {
                                currentPage = 0
                            }
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        
                        Button("Next") {
                            withAnimation {
                                currentPage = 2
                            }
                        }
                        .buttonStyle(OnboardingButtonStyle())
                        .disabled(name.isEmpty || email.isEmpty || age.isEmpty)
                    }
                }
                .tag(1)
                
                // Physical Stats
                VStack(spacing: 20) {
                    Text("Your measurements")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top, 40)
                    
                    VStack(spacing: 16) {
                        HStack {
                            TextField("Height", text: $height)
                                .textFieldStyle(OnboardingTextFieldStyle())
                                .keyboardType(.decimalPad)
                            
                            Text("cm")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            TextField("Weight", text: $weight)
                                .textFieldStyle(OnboardingTextFieldStyle())
                                .keyboardType(.decimalPad)
                            
                            Text("kg")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    HStack(spacing: 16) {
                        Button("Back") {
                            withAnimation {
                                currentPage = 1
                            }
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        
                        Button("Next") {
                            withAnimation {
                                currentPage = 3
                            }
                        }
                        .buttonStyle(OnboardingButtonStyle())
                        .disabled(height.isEmpty || weight.isEmpty)
                    }
                }
                .tag(2)
                
                // Activity & Goals
                VStack(spacing: 20) {
                    Text("Your fitness profile")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top, 40)
                    
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Activity Level")
                            .font(.headline)
                        
                        Picker("Activity Level", selection: $activityLevel) {
                            ForEach(UserProfile.ActivityLevel.allCases, id: \.self) { level in
                                Text(level.rawValue).tag(level)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 120)
                        
                        Text("Goal")
                            .font(.headline)
                        
                        Picker("Goal", selection: $goal) {
                            ForEach(UserProfile.Goal.allCases, id: \.self) { goal in
                                Text(goal.rawValue).tag(goal)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 120)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    HStack(spacing: 16) {
                        Button("Back") {
                            withAnimation {
                                currentPage = 2
                            }
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        
                        Button("Complete Setup") {
                            completeOnboarding()
                        }
                        .buttonStyle(OnboardingButtonStyle())
                    }
                }
                .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .padding(.horizontal)
        }
        .fullScreenCover(isPresented: $showingMainApp) {
            ContentView()
        }
    }
    
    private func completeOnboarding() {
        guard let ageInt = Int(age),
              let heightDouble = Double(height),
              let weightDouble = Double(weight) else { return }
        
        let profile = UserProfile(
            name: name,
            email: email,
            age: ageInt,
            gender: gender,
            height: heightDouble,
            weight: weightDouble,
            activityLevel: activityLevel,
            goal: goal
        )
        
        modelContext.insert(profile)
        
        do {
            try modelContext.save()
            
            appState.currentUser = profile
            appState.completeOnboarding()
            
            showingMainApp = true
        } catch {
            print("Error saving profile: \(error)")
        }
    }
}

struct OnboardingButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray5))
            .foregroundColor(.primary)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}

struct OnboardingTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
    }
}