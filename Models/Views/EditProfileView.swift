import SwiftUI
import SwiftData

struct EditProfileView: View {
    let profile: UserProfile?
    @State private var name: String
    @State private var email: String
    @State private var age: Int
    @State private var gender: UserProfile.Gender
    @State private var heightFeet: Int
    @State private var heightInches: Int
    @State private var weightPounds: Double
    @State private var activityLevel: UserProfile.ActivityLevel
    @State private var goal: UserProfile.Goal
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    init(profile: UserProfile?) {
        self.profile = profile
        _name = State(initialValue: profile?.name ?? "")
        _email = State(initialValue: profile?.email ?? "")
        _age = State(initialValue: profile?.age ?? 30)
        _gender = State(initialValue: profile?.gender ?? .male)

        // Convert cm to feet/inches (height in cm)
        if let p = profile {
            let totalInches = p.height / 2.54
            _heightFeet = State(initialValue: Int(totalInches / 12))
            _heightInches = State(initialValue: Int(totalInches.truncatingRemainder(dividingBy: 12)))
            // Convert kg to pounds
            _weightPounds = State(initialValue: p.weight * 2.20462)
        } else {
            _heightFeet = State(initialValue: 5)
            _heightInches = State(initialValue: 8)
            _weightPounds = State(initialValue: 150.0)
        }

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
                        .textInputAutocapitalization(.never)

                    Stepper("Age: \(age) years", value: $age, in: 13...100)

                    Picker("Gender", selection: $gender) {
                        ForEach(UserProfile.Gender.allCases, id: \.self) { gender in
                            Text(gender.rawValue).tag(gender)
                        }
                    }
                }

                Section("Measurements") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Height")
                            .font(.headline)

                        HStack(spacing: 20) {
                            // Feet stepper
                            VStack {
                                Text("\(heightFeet)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("feet")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(width: 60)

                            Stepper("", value: $heightFeet, in: 3...8)
                                .labelsHidden()

                            Divider()
                                .frame(height: 40)

                            // Inches stepper
                            VStack {
                                Text("\(heightInches)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("inches")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(width: 60)

                            Stepper("", value: $heightInches, in: 0...11)
                                .labelsHidden()
                        }

                        Text("Total: \(heightFeet)' \(heightInches)\" (\(formattedHeightCm) cm)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Weight")
                            .font(.headline)

                        HStack(spacing: 20) {
                            VStack {
                                Text("\(Int(weightPounds))")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("pounds")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(width: 80)

                            Stepper("", value: $weightPounds, in: 80...500, step: 1)
                                .labelsHidden()
                        }

                        Text("(\(formattedWeightKg) kg)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
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
        !name.isEmpty && !email.isEmpty && age > 0 && weightPounds > 0
    }

    // Computed properties for unit conversion display
    private var formattedHeightCm: String {
        let totalInches = Double(heightFeet * 12 + heightInches)
        let cm = totalInches * 2.54
        return String(format: "%.0f", cm)
    }

    private var formattedWeightKg: String {
        let kg = weightPounds / 2.20462
        return String(format: "%.1f", kg)
    }

    // Convert imperial to metric for storage
    private var heightInCm: Double {
        let totalInches = Double(heightFeet * 12 + heightInches)
        return totalInches * 2.54
    }

    private var weightInKg: Double {
        return weightPounds / 2.20462
    }

    private func saveProfile() {
        let heightDouble = heightInCm
        let weightDouble = weightInKg

        if let profile = profile {
            // Update existing profile
            profile.name = name
            profile.email = email
            profile.age = age
            profile.gender = gender
            profile.height = heightDouble
            profile.weight = weightDouble
            profile.activityLevel = activityLevel
            profile.goal = goal
            profile.updatedAt = Date()

            // Recalculate targets
            let bmr = calculateBMR(weight: weightDouble, height: heightDouble, age: age, gender: gender)
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
        } else {
            // Create new profile
            let newProfile = UserProfile(
                name: name,
                email: email,
                age: age,
                gender: gender,
                height: heightDouble,
                weight: weightDouble,
                activityLevel: activityLevel,
                goal: goal
            )

            // Calculate targets for new profile
            let bmr = calculateBMR(weight: weightDouble, height: heightDouble, age: age, gender: gender)
            newProfile.dailyCalorieTarget = (bmr * activityLevel.multiplier) + goal.calorieAdjustment

            switch goal {
            case .buildMuscle:
                newProfile.dailyProteinTarget = weightDouble * 2.2
                newProfile.dailyFatTarget = newProfile.dailyCalorieTarget * 0.25 / 9
                newProfile.dailyCarbTarget = (newProfile.dailyCalorieTarget - (newProfile.dailyProteinTarget * 4) - (newProfile.dailyFatTarget * 9)) / 4
            default:
                newProfile.dailyProteinTarget = weightDouble * 1.6
                newProfile.dailyFatTarget = newProfile.dailyCalorieTarget * 0.3 / 9
                newProfile.dailyCarbTarget = (newProfile.dailyCalorieTarget - (newProfile.dailyProteinTarget * 4) - (newProfile.dailyFatTarget * 9)) / 4
            }

            modelContext.insert(newProfile)
        }

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving profile: \(error)")
        }
    }

    private func calculateBMR(weight: Double, height: Double, age: Int, gender: UserProfile.Gender) -> Double {
        // Mifflin-St Jeor formula (weight in kg, height in cm)
        if gender == .male {
            return 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * Double(age))
        } else {
            return 447.593 + (9.247 * weight) + (3.098 * height) - (4.330 * Double(age))
        }
    }
}