import SwiftUI
import SwiftData

struct EditProfileView: View {
    let profile: UserProfile?
    @State private var name: String
    @State private var email: String
    @State private var age: String
    @State private var gender: UserProfile.Gender
    @State private var height: String
    @State private var weight: String
    @State private var activityLevel: UserProfile.ActivityLevel
    @State private var goal: UserProfile.Goal
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    init(profile: UserProfile?) {
        self.profile = profile
        _name = State(initialValue: profile?.name ?? "")
        _email = State(initialValue: profile?.email ?? "")
        _age = State(initialValue: profile != nil ? "\(profile!.age)" : "")
        _gender = State(initialValue: profile?.gender ?? .male)
        _height = State(initialValue: profile != nil ? "\(Int(profile!.height))" : "")
        _weight = State(initialValue: profile != nil ? "\(Int(profile!.weight))" : "")
        _activityLevel = State(initialValue: profile?.activityLevel ?? .moderatelyActive)
        _goal = State(initialValue: profile?.goal ?? .maintainWeight)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Personal Information") {
                    TextField("Name", text: $name)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                    
                    HStack {
                        Text("Age")
                        Spacer()
                        TextField("Age", text: $age)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                    }
                    
                    Picker("Gender", selection: $gender) {
                        ForEach(UserProfile.Gender.allCases, id: \.self) { gender in
                            Text(gender.rawValue).tag(gender)
                        }
                    }
                }
                
                Section("Measurements") {
                    HStack {
                        Text("Height")
                        Spacer()
                        TextField("Height", text: $height)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text("cm")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Weight")
                        Spacer()
                        TextField("Weight", text: $weight)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text("kg")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Fitness Profile") {
                    Picker("Activity Level", selection: $activityLevel) {
                        ForEach(UserProfile.ActivityLevel.allCases, id: \.self) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    
                    Picker("Goal", selection: $goal) {
                        ForEach(UserProfile.Goal.allCases, id: \.self) { goal in
                            Text(goal.rawValue).tag(goal)
                        }
                    }
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Daily Targets will be recalculated")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let profile = profile {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Current Calories: \(Int(profile.dailyCalorieTarget))")
                                    Text("Current Protein: \(Int(profile.dailyProteinTarget))g")
                                }
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProfile()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private var isValid: Bool {
        !name.isEmpty && !email.isEmpty && !age.isEmpty && !height.isEmpty && !weight.isEmpty
    }
    
    private func saveProfile() {
        guard let ageInt = Int(age),
              let heightDouble = Double(height),
              let weightDouble = Double(weight) else { return }
        
        if let profile = profile {
            // Update existing profile
            profile.name = name
            profile.email = email
            profile.age = ageInt
            profile.gender = gender
            profile.height = heightDouble
            profile.weight = weightDouble
            profile.activityLevel = activityLevel
            profile.goal = goal
            profile.updatedAt = Date()
            
            // Recalculate targets
            let bmr = calculateBMR(weight: weightDouble, height: heightDouble, age: ageInt, gender: gender)
            profile.dailyCalorieTarget = (bmr * activityLevel.multiplier) + goal.calorieAdjustment
            
            switch goal {
            case .buildMuscle:
                profile.dailyProteinTarget = weightDouble * 2.2
                profile.dailyFatTarget = profile.dailyCalorieTarget * 0.25 / 9
                profile.dailyCarbTarget = (profile.dailyCalorieTarget - (profile.dailyProteinTarget * 4) - (profile.dailyFatTarget * 9)) / 4
            default:
                profile.dailyProteinTarget = weightDouble * 1.6
                profile.dailyFatTarget = profile.dailyCalorieTarget * 0.3 / 9
                profile.dailyCarbTarget = (profile.dailyCalorieTarget - (profile.dailyProteinTarget * 4) - (profile.dailyFatTarget * 9)) / 4
            }
        }
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving profile: \(error)")
        }
    }
    
    private func calculateBMR(weight: Double, height: Double, age: Int, gender: UserProfile.Gender) -> Double {
        if gender == .male {
            return 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * Double(age))
        } else {
            return 447.593 + (9.247 * weight) + (3.098 * height) - (4.330 * Double(age))
        }
    }
}