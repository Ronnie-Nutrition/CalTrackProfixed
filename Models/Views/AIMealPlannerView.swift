import SwiftUI
import SwiftData

struct AIMealPlannerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @StateObject private var mealPlanService = AIMealPlanningService.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var userProfile: UserProfile?
    @State private var showingPremiumUpgrade = false

    // Preferences
    @State private var dietType: DietType = .balanced
    @State private var includedMeals: Set<MealType> = [.breakfast, .lunch, .dinner]
    @State private var allergies: String = ""
    @State private var avoidFoods: String = ""
    @State private var favoriteFoods: String = ""
    @State private var maxPrepTime: Double = 30
    @State private var budgetOptimized = false
    @State private var varietyLevel: VarietyLevel = .medium
    @State private var cuisinePreferences: Set<CuisineType> = []
    @State private var startDate = Date()
    @State private var selectedQuickStart: String? = nil

    @State private var showingGeneratedPlan = false
    @State private var generatedPlan: WeeklyMealPlan?
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero Section
                    heroSection
                    
                    // Quick Start Options
                    quickStartSection
                    
                    // Detailed Preferences
                    preferencesSection
                    
                    // Generate Button
                    generateButton
                }
                .padding()
            }
            .background(Color(.systemBackground).edgesIgnoringSafeArea(.all))
            .navigationTitle("AI Meal Planner")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingGeneratedPlan) {
                if let plan = generatedPlan {
                    GeneratedMealPlanView(mealPlan: plan)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .overlay {
                if mealPlanService.isGenerating {
                    generationOverlay
                }
            }
            .sheet(isPresented: $showingPremiumUpgrade) {
                PremiumUpgradeView()
            }
        }
        .onAppear {
            loadUserProfile()
        }
    }
    
    // MARK: - Hero Section
    private var heroSection: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 50))
                    .foregroundStyle(.linearGradient(
                        colors: [.purple, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))

                // Premium Badge
                if !subscriptionManager.isPremiumUser {
                    HStack(spacing: 4) {
                        Image(systemName: "crown.fill")
                            .font(.caption2)
                        Text("Premium")
                            .font(.caption2)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .offset(x: 30, y: -10)
                }
            }

            Text("Personalized Meal Plans")
                .font(.title2)
                .bold()

            Text("AI-powered weekly meal planning tailored to your goals")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical)
    }
    
    // MARK: - Quick Start Section
    private var quickStartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Start")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                quickStartOption(
                    title: "Weight Loss",
                    icon: "arrow.down.circle.fill",
                    color: .green,
                    isSelected: selectedQuickStart == "Weight Loss"
                ) {
                    selectedQuickStart = "Weight Loss"
                    dietType = .lowCarb
                    budgetOptimized = false
                    varietyLevel = .medium
                }

                quickStartOption(
                    title: "Muscle Gain",
                    icon: "figure.strengthtraining.traditional",
                    color: .orange,
                    isSelected: selectedQuickStart == "Muscle Gain"
                ) {
                    selectedQuickStart = "Muscle Gain"
                    dietType = .highProtein
                    includedMeals = [.breakfast, .morningSnack, .lunch, .afternoonSnack, .dinner]
                }

                quickStartOption(
                    title: "Balanced Diet",
                    icon: "leaf.fill",
                    color: .blue,
                    isSelected: selectedQuickStart == "Balanced Diet"
                ) {
                    selectedQuickStart = "Balanced Diet"
                    dietType = .balanced
                    varietyLevel = .high
                }

                quickStartOption(
                    title: "Budget Friendly",
                    icon: "dollarsign.circle.fill",
                    color: .purple,
                    isSelected: selectedQuickStart == "Budget Friendly"
                ) {
                    selectedQuickStart = "Budget Friendly"
                    budgetOptimized = true
                    varietyLevel = .low
                }
            }
        }
    }
    
    private func quickStartOption(
        title: String,
        icon: String,
        color: Color,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                action()
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : color)

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? color : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 2)
            )
        }
    }
    
    // MARK: - Preferences Section
    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Customize Your Plan")
                .font(.headline)
            
            // Diet Type
            VStack(alignment: .leading, spacing: 8) {
                Text("Diet Type")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Picker("Diet Type", selection: $dietType) {
                    ForEach(DietType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // Meals to Include
            VStack(alignment: .leading, spacing: 8) {
                Text("Meals to Include")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                ForEach(MealType.allCases, id: \.self) { meal in
                    Toggle(meal.rawValue, isOn: Binding(
                        get: { includedMeals.contains(meal) },
                        set: { isIncluded in
                            if isIncluded {
                                includedMeals.insert(meal)
                            } else {
                                includedMeals.remove(meal)
                            }
                        }
                    ))
                }
            }
            
            // Preparation Time
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Max Prep Time")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(maxPrepTime)) minutes")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Slider(value: $maxPrepTime, in: 5...60, step: 5)
            }
            
            // Variety Level
            VStack(alignment: .leading, spacing: 8) {
                Text("Meal Variety")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Picker("Variety", selection: $varietyLevel) {
                    ForEach(VarietyLevel.allCases, id: \.self) { level in
                        Text(level.rawValue).tag(level)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // Budget Optimization
            Toggle("Optimize for Budget", isOn: $budgetOptimized)
            
            // Food Preferences
            VStack(alignment: .leading, spacing: 12) {
                Text("Food Preferences")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextField("Allergies (comma separated)", text: $allergies)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Foods to avoid", text: $avoidFoods)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Favorite foods", text: $favoriteFoods)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            // Start Date
            DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                .datePickerStyle(CompactDatePickerStyle())
        }
    }
    
    // MARK: - Generate Button
    private var generateButton: some View {
        Button(action: generateMealPlan) {
            HStack {
                Image(systemName: "wand.and.stars")
                Text("Generate Weekly Meal Plan")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [.purple, .blue],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(mealPlanService.isGenerating || includedMeals.isEmpty)
    }
    
    // MARK: - Generation Overlay
    private var generationOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                Text("Creating Your Perfect Meal Plan")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Analyzing nutritional needs...")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                
                ProgressView(value: mealPlanService.generationProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .white))
                    .frame(width: 200)
            }
            .padding(40)
            .background(Color.black.opacity(0.8))
            .cornerRadius(20)
        }
    }
    
    // MARK: - Functions
    private func loadUserProfile() {
        let descriptor = FetchDescriptor<UserProfile>()
        if let profiles = try? modelContext.fetch(descriptor),
           let profile = profiles.first {
            self.userProfile = profile
        }
    }
    
    private func generateMealPlan() {
        // Premium-only feature check
        guard subscriptionManager.isPremiumUser else {
            showingPremiumUpgrade = true
            return
        }

        guard let profile = userProfile else {
            errorMessage = "Please set up your profile first"
            showError = true
            return
        }

        let preferences = MealPlanPreferences(
            dietType: dietType,
            includedMeals: includedMeals,
            allergies: allergies.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) },
            avoidFoods: avoidFoods.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) },
            favoriteFoods: favoriteFoods.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) },
            maxPrepTime: Int(maxPrepTime),
            budgetOptimized: budgetOptimized,
            varietyLevel: varietyLevel,
            cuisinePreferences: Array(cuisinePreferences),
            startDate: startDate
        )
        
        Task {
            do {
                let plan = try await mealPlanService.generateWeeklyMealPlan(
                    for: profile,
                    preferences: preferences
                )
                
                await MainActor.run {
                    self.generatedPlan = plan
                    self.showingGeneratedPlan = true
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                }
            }
        }
    }
}

// MARK: - Generated Meal Plan View
struct GeneratedMealPlanView: View {
    let mealPlan: WeeklyMealPlan
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDay = 0
    @State private var showingShoppingList = false
    @State private var selectedMeal: PlannedMeal?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Summary Card
                    summaryCard
                    
                    // Day Selector
                    daySelector
                    
                    // Daily Plan
                    if selectedDay < mealPlan.dailyPlans.count {
                        dailyPlanView(mealPlan.dailyPlans[selectedDay])
                    }
                }
                .padding()
            }
            .background(Color(.systemBackground))
            .navigationTitle("Your Meal Plan")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: saveToDiary) {
                            Label("Add to Food Diary", systemImage: "calendar.badge.plus")
                        }
                        
                        Button(action: { showingShoppingList = true }) {
                            Label("Shopping List", systemImage: "cart")
                        }
                        
                        Button(action: exportPlan) {
                            Label("Export PDF", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingShoppingList) {
                ShoppingListView(mealPlan: mealPlan)
            }
            .sheet(item: $selectedMeal) { meal in
                MealDetailView(meal: meal)
            }
        }
    }

    private var summaryCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Weekly Summary")
                        .font(.headline)
                    Text("\(mealPlan.startDate.formatted(.dateTime.month().day())) - \(mealPlan.endDate.formatted(.dateTime.month().day()))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                Image(systemName: "checkmark.seal.fill")
                    .font(.title)
                    .foregroundColor(.green)
            }
            
            HStack(spacing: 20) {
                nutritionStat(label: "Avg Daily", value: "\(Int(mealPlan.totalCalories / 7))", unit: "cal")
                nutritionStat(label: "Protein", value: "\(Int(mealPlan.totalProtein / 7))", unit: "g")
                nutritionStat(label: "Carbs", value: "\(Int(mealPlan.totalCarbs / 7))", unit: "g")
                nutritionStat(label: "Fat", value: "\(Int(mealPlan.totalFat / 7))", unit: "g")
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func nutritionStat(label: String, value: String, unit: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
            Text(unit)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    private var daySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(0..<7, id: \.self) { day in
                    dayButton(for: day)
                }
            }
        }
    }
    
    private func dayButton(for day: Int) -> some View {
        let date = mealPlan.startDate.addingTimeInterval(Double(day) * 24 * 60 * 60)
        let isSelected = selectedDay == day
        
        return Button(action: { selectedDay = day }) {
            VStack(spacing: 8) {
                Text(date.formatted(.dateTime.weekday(.abbreviated)))
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : .secondary)
                
                Text(date.formatted(.dateTime.day()))
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(width: 60, height: 60)
            .background(isSelected ? Color.blue : Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
    
    private func dailyPlanView(_ dailyPlan: DailyMealPlan) -> some View {
        VStack(spacing: 16) {
            ForEach(dailyPlan.meals) { meal in
                mealCard(meal)
            }
        }
    }
    
    private func mealCard(_ meal: PlannedMeal) -> some View {
        Button(action: { selectedMeal = meal }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(meal.mealType.rawValue)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    HStack(spacing: 6) {
                        Text("\(Int(meal.totalCalories)) cal")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(Color.gray.opacity(0.5))
                    }
                }

                ForEach(meal.foods) { food in
                    HStack {
                        Text(food.name)
                            .font(.subheadline)
                            .foregroundColor(.primary)

                        Spacer()

                        Text("\(Int(food.quantity)) \(food.unit)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if !meal.recipeSuggestions.isEmpty {
                    Divider()

                    HStack {
                        Image(systemName: "book.fill")
                            .foregroundColor(.blue)
                            .font(.caption)

                        Text("Tap for recipe details")
                            .font(.caption)
                            .foregroundColor(.blue)

                        Spacer()
                    }
                }

                HStack(spacing: 4) {
                    Label("\(meal.preparationTime) min", systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    HStack(spacing: 12) {
                        nutritionLabel("P", value: Int(meal.totalProtein))
                        nutritionLabel("C", value: Int(meal.totalCarbs))
                        nutritionLabel("F", value: Int(meal.totalFat))
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func nutritionLabel(_ label: String, value: Int) -> some View {
        Text("\(label): \(value)g")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    
    private func saveToDiary() {
        // Implementation to save meal plan to food diary
    }

    private func exportPlan() {
        // Generate PDF data
        let pdfData = generateMealPlanPDF()

        // Create a temporary file URL
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("MealPlan_\(mealPlan.startDate.formatted(.dateTime.month().day())).pdf")

        do {
            try pdfData.write(to: tempURL)

            // Present share sheet
            let activityVC = UIActivityViewController(
                activityItems: [tempURL],
                applicationActivities: nil
            )

            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                // Find the topmost presented view controller
                var topController = rootViewController
                while let presented = topController.presentedViewController {
                    topController = presented
                }
                activityVC.popoverPresentationController?.sourceView = topController.view
                topController.present(activityVC, animated: true)
            }
        } catch {
            print("Failed to export PDF: \(error)")
        }
    }

    private func generateMealPlanPDF() -> Data {
        let pageWidth: CGFloat = 612  // Letter size
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 50

        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        let data = pdfRenderer.pdfData { context in
            var currentY: CGFloat = margin
            var currentPage = 0

            func startNewPage() {
                context.beginPage()
                currentY = margin
                currentPage += 1
            }

            func checkPageBreak(neededHeight: CGFloat) {
                if currentY + neededHeight > pageHeight - margin {
                    startNewPage()
                }
            }

            // Title attributes
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24),
                .foregroundColor: UIColor.black
            ]

            let headerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 16),
                .foregroundColor: UIColor.darkGray
            ]

            let subheaderAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 14),
                .foregroundColor: UIColor(red: 0.2, green: 0.5, blue: 0.8, alpha: 1.0)
            ]

            let bodyAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.black
            ]

            let smallAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor.gray
            ]

            // Start first page
            startNewPage()

            // Title
            let title = "Weekly Meal Plan"
            title.draw(at: CGPoint(x: margin, y: currentY), withAttributes: titleAttributes)
            currentY += 35

            // Date range
            let dateRange = "\(mealPlan.startDate.formatted(.dateTime.month().day().year())) - \(mealPlan.endDate.formatted(.dateTime.month().day().year()))"
            dateRange.draw(at: CGPoint(x: margin, y: currentY), withAttributes: headerAttributes)
            currentY += 30

            // Weekly summary
            let avgCalories = Int(mealPlan.totalCalories / 7)
            let avgProtein = Int(mealPlan.totalProtein / 7)
            let avgCarbs = Int(mealPlan.totalCarbs / 7)
            let avgFat = Int(mealPlan.totalFat / 7)

            let summary = "Daily Averages: \(avgCalories) cal | \(avgProtein)g protein | \(avgCarbs)g carbs | \(avgFat)g fat"
            summary.draw(at: CGPoint(x: margin, y: currentY), withAttributes: bodyAttributes)
            currentY += 30

            // Separator line
            let linePath = UIBezierPath()
            linePath.move(to: CGPoint(x: margin, y: currentY))
            linePath.addLine(to: CGPoint(x: pageWidth - margin, y: currentY))
            UIColor.lightGray.setStroke()
            linePath.lineWidth = 1
            linePath.stroke()
            currentY += 20

            // Daily plans
            for (index, dailyPlan) in mealPlan.dailyPlans.enumerated() {
                checkPageBreak(neededHeight: 100)

                // Day header
                let dayDate = mealPlan.startDate.addingTimeInterval(Double(index) * 24 * 60 * 60)
                let dayHeader = dayDate.formatted(.dateTime.weekday(.wide).month().day())
                dayHeader.draw(at: CGPoint(x: margin, y: currentY), withAttributes: headerAttributes)
                currentY += 25

                // Day nutrition summary
                let dayNutrition = "\(Int(dailyPlan.totalCalories)) cal | P: \(Int(dailyPlan.totalProtein))g | C: \(Int(dailyPlan.totalCarbs))g | F: \(Int(dailyPlan.totalFat))g"
                dayNutrition.draw(at: CGPoint(x: margin, y: currentY), withAttributes: smallAttributes)
                currentY += 20

                // Meals for this day
                for meal in dailyPlan.meals {
                    checkPageBreak(neededHeight: 60)

                    // Meal type header
                    let mealHeader = "\(meal.mealType.rawValue) (\(Int(meal.totalCalories)) cal)"
                    mealHeader.draw(at: CGPoint(x: margin + 10, y: currentY), withAttributes: subheaderAttributes)
                    currentY += 18

                    // Foods in this meal
                    for food in meal.foods {
                        checkPageBreak(neededHeight: 20)

                        let foodLine = "• \(food.name) - \(Int(food.quantity)) \(food.unit)"
                        foodLine.draw(at: CGPoint(x: margin + 20, y: currentY), withAttributes: bodyAttributes)
                        currentY += 16

                        // Prep notes if available
                        if let notes = food.preparationNotes, !notes.isEmpty {
                            checkPageBreak(neededHeight: 15)
                            let notesLine = "  \(notes)"
                            // Truncate if too long
                            let truncatedNotes = notesLine.count > 80 ? String(notesLine.prefix(80)) + "..." : notesLine
                            truncatedNotes.draw(at: CGPoint(x: margin + 30, y: currentY), withAttributes: smallAttributes)
                            currentY += 14
                        }
                    }
                    currentY += 8
                }

                // Day separator
                currentY += 10
                if index < mealPlan.dailyPlans.count - 1 {
                    let separatorPath = UIBezierPath()
                    separatorPath.move(to: CGPoint(x: margin, y: currentY))
                    separatorPath.addLine(to: CGPoint(x: pageWidth - margin, y: currentY))
                    UIColor.lightGray.setStroke()
                    separatorPath.lineWidth = 0.5
                    separatorPath.stroke()
                    currentY += 15
                }
            }

            // Footer on last page
            checkPageBreak(neededHeight: 50)
            currentY = pageHeight - margin - 30
            let footer = "Generated by CalTrackPro"
            let footerSize = footer.size(withAttributes: smallAttributes)
            footer.draw(at: CGPoint(x: (pageWidth - footerSize.width) / 2, y: currentY), withAttributes: smallAttributes)
        }

        return data
    }
}

// MARK: - Shopping List View (Enhanced with GroceryListService)
struct ShoppingListView: View {
    let mealPlan: WeeklyMealPlan
    @Environment(\.dismiss) private var dismiss
    @StateObject private var groceryService = GroceryListService.shared
    @State private var hasGeneratedList = false

    var body: some View {
        NavigationStack {
            Group {
                if let list = groceryService.currentList, hasGeneratedList {
                    enhancedGroceryListContent(list)
                } else {
                    generatingView
                }
            }
            .navigationTitle("Grocery List")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }

                if groceryService.currentList != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button(action: shareList) {
                                Label("Share List", systemImage: "square.and.arrow.up")
                            }
                            Button(action: { groceryService.saveCurrentList() }) {
                                Label("Save List", systemImage: "square.and.arrow.down")
                            }
                            Divider()
                            Button(role: .destructive) {
                                groceryService.clearCheckedItems()
                            } label: {
                                Label("Clear Checked", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .onAppear {
                if !hasGeneratedList {
                    _ = groceryService.generateGroceryList(from: mealPlan)
                    hasGeneratedList = true
                }
            }
        }
    }

    private var generatingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Generating grocery list...")
                .font(.headline)
            Text("Analyzing your meal plan")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private func enhancedGroceryListContent(_ list: GroceryList) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                // Progress Card
                progressCard(list)

                // Cost Summary
                costSummary(list)

                // Items by Category
                ForEach(GroceryCategory.allCases, id: \.self) { category in
                    if let items = list.itemsByCategory[category], !items.isEmpty {
                        categorySection(category: category, items: items)
                    }
                }
            }
            .padding()
        }
        .background(AppColors.primaryBackground)
    }

    private func progressCard(_ list: GroceryList) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Shopping Progress")
                    .font(.headline)
                Text("\(list.checkedCount) of \(list.items.count) items")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                    .frame(width: 60, height: 60)

                Circle()
                    .trim(from: 0, to: list.progress)
                    .stroke(
                        LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))

                Text("\(Int(list.progress * 100))%")
                    .font(.caption)
                    .fontWeight(.bold)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
        )
    }

    private func costSummary(_ list: GroceryList) -> some View {
        HStack {
            Image(systemName: "cart.fill")
                .foregroundColor(.green)
            Text("Estimated Total")
                .font(.subheadline)
            Spacer()
            Text("$\(String(format: "%.2f", list.totalEstimatedCost))")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.green)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.green.opacity(0.1))
        )
    }

    private func categorySection(category: GroceryCategory, items: [GroceryItem]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: category.icon)
                    .foregroundColor(category.color)
                Text(category.rawValue)
                    .font(.headline)
                Spacer()
                Text("\(items.filter { !$0.isChecked }.count) left")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)

            ForEach(items) { item in
                groceryItemRow(item)
            }
        }
    }

    private func groceryItemRow(_ item: GroceryItem) -> some View {
        Button(action: { groceryService.toggleItem(item) }) {
            HStack(spacing: 12) {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(item.isChecked ? .green : .gray)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.subheadline)
                        .strikethrough(item.isChecked)
                        .foregroundColor(item.isChecked ? .secondary : .primary)

                    Text(item.quantity)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text("$\(String(format: "%.2f", item.estimatedCost))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppColors.secondaryBackground)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func shareList() {
        guard let list = groceryService.currentList else { return }

        var shareText = "Grocery List for Week of \(mealPlan.startDate.formatted(.dateTime.month().day()))\n\n"

        for category in GroceryCategory.allCases {
            if let items = list.itemsByCategory[category], !items.isEmpty {
                shareText += "\(category.rawValue):\n"
                for item in items {
                    let checkmark = item.isChecked ? "[x]" : "[ ]"
                    shareText += "  \(checkmark) \(item.name) - \(item.quantity)\n"
                }
                shareText += "\n"
            }
        }

        shareText += "Estimated Total: $\(String(format: "%.2f", list.totalEstimatedCost))"

        let activityVC = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }
}

// MARK: - Meal Detail View
struct MealDetailView: View {
    let meal: PlannedMeal
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with meal type and calories
                    mealHeader

                    // Nutrition Summary Card
                    nutritionCard

                    // Ingredients Section
                    ingredientsSection

                    // Preparation Steps
                    preparationSection

                    // Recipe Suggestions
                    if !meal.recipeSuggestions.isEmpty {
                        recipeSuggestionsSection
                    }
                }
                .padding()
            }
            .background(Color(.systemBackground))
            .navigationTitle(meal.mealType.rawValue)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var mealHeader: some View {
        VStack(spacing: 12) {
            // Icon based on meal type
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [mealTypeColor.opacity(0.3), mealTypeColor.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: mealTypeIcon)
                    .font(.system(size: 36))
                    .foregroundColor(mealTypeColor)
            }

            Text(mainFoodName)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                Label("\(meal.preparationTime) min", systemImage: "clock.fill")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text("•")
                    .foregroundColor(.secondary)

                Text("\(Int(meal.totalCalories)) calories")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical)
    }

    private var nutritionCard: some View {
        VStack(spacing: 16) {
            Text("Nutrition Facts")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 20) {
                nutritionCircle(
                    value: Int(meal.totalProtein),
                    label: "Protein",
                    color: .red,
                    unit: "g"
                )

                nutritionCircle(
                    value: Int(meal.totalCarbs),
                    label: "Carbs",
                    color: .orange,
                    unit: "g"
                )

                nutritionCircle(
                    value: Int(meal.totalFat),
                    label: "Fat",
                    color: .yellow,
                    unit: "g"
                )

                nutritionCircle(
                    value: Int(meal.totalCalories),
                    label: "Calories",
                    color: .blue,
                    unit: "cal"
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    private func nutritionCircle(value: Int, label: String, color: Color, unit: String) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.3), lineWidth: 4)
                    .frame(width: 50, height: 50)

                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 50, height: 50)

                Text("\(value)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "list.bullet.clipboard")
                    .foregroundColor(.green)
                Text("Ingredients")
                    .font(.headline)
            }

            VStack(spacing: 16) {
                ForEach(meal.foods) { food in
                    VStack(alignment: .leading, spacing: 10) {
                        // Food name header
                        HStack {
                            Text(food.name)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)

                            Spacer()

                            // Nutrition badge
                            Text("\(Int(food.calories)) cal")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.15))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                        }

                        // Detailed ingredients list
                        if let ingredients = food.ingredients, !ingredients.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(ingredients, id: \.self) { ingredient in
                                    HStack(alignment: .top, spacing: 8) {
                                        Image(systemName: "circle.fill")
                                            .font(.system(size: 5))
                                            .foregroundColor(.green)
                                            .padding(.top, 5)

                                        Text(ingredient)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.leading, 8)
                        } else {
                            // Fallback to quantity/unit if no detailed ingredients
                            HStack(spacing: 8) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 5))
                                    .foregroundColor(.green)
                                    .padding(.top, 5)

                                Text("\(Int(food.quantity)) \(food.unit)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.leading, 8)
                        }

                        // Macro breakdown
                        HStack(spacing: 12) {
                            macroTag(label: "Protein", value: Int(food.protein), color: .red)
                            macroTag(label: "Carbs", value: Int(food.carbs), color: .orange)
                            macroTag(label: "Fat", value: Int(food.fat), color: .yellow)
                        }
                    }
                    .padding(12)
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    private func macroTag(label: String, value: Int, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text("\(label): \(value)g")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    private var preparationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                Text("How to Prepare")
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 20) {
                ForEach(meal.foods) { food in
                    VStack(alignment: .leading, spacing: 12) {
                        // Food name header with prep time
                        HStack {
                            Text(food.name)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)

                            Spacer()

                            if let prepTime = food.estimatedPrepTime, prepTime > 0 {
                                HStack(spacing: 4) {
                                    Image(systemName: "clock.fill")
                                        .font(.caption2)
                                    Text("\(prepTime) min")
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.orange.opacity(0.15))
                                .foregroundColor(.orange)
                                .cornerRadius(8)
                            }
                        }

                        // Detailed step-by-step instructions
                        if let detailedInstructions = food.detailedInstructions, !detailedInstructions.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                // Parse the numbered steps
                                let steps = detailedInstructions.components(separatedBy: "\n")
                                ForEach(Array(steps.enumerated()), id: \.offset) { stepIndex, step in
                                    if !step.isEmpty {
                                        HStack(alignment: .top, spacing: 10) {
                                            // Step number circle
                                            ZStack {
                                                Circle()
                                                    .fill(
                                                        LinearGradient(
                                                            colors: [.blue, .cyan],
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        )
                                                    )
                                                    .frame(width: 22, height: 22)

                                                Text("\(stepIndex + 1)")
                                                    .font(.caption2)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.white)
                                            }

                                            // Step text (remove leading number if present)
                                            Text(cleanStepText(step))
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                    }
                                }
                            }
                        } else if let notes = food.preparationNotes, !notes.isEmpty {
                            // Fallback to simple notes
                            HStack(alignment: .top, spacing: 10) {
                                ZStack {
                                    Circle()
                                        .fill(Color.blue.opacity(0.2))
                                        .frame(width: 22, height: 22)

                                    Image(systemName: "info.circle.fill")
                                        .font(.caption2)
                                        .foregroundColor(.blue)
                                }

                                Text(notes)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding(14)
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(12)
                }

                // If no prep notes at all, show a default message
                if meal.foods.allSatisfy({ ($0.detailedInstructions == nil || $0.detailedInstructions?.isEmpty == true) && ($0.preparationNotes == nil || $0.preparationNotes?.isEmpty == true) }) {
                    Text("Prepare each ingredient as desired and combine on a plate. Season to taste.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    // Helper to clean step text by removing leading numbers
    private func cleanStepText(_ step: String) -> String {
        // Remove patterns like "1. " or "1) " from the beginning
        let pattern = "^\\d+[.)]\\s*"
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let range = NSRange(step.startIndex..., in: step)
            return regex.stringByReplacingMatches(in: step, options: [], range: range, withTemplate: "")
        }
        return step
    }

    private var recipeSuggestionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Recipe Ideas")
                    .font(.headline)
            }

            ForEach(meal.recipeSuggestions, id: \.name) { recipe in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(recipe.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Spacer()

                        Label("\(recipe.estimatedTime) min", systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text(recipe.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    // MARK: - Helpers
    private var mainFoodName: String {
        meal.foods.first?.name ?? meal.mealType.rawValue
    }

    private var mealTypeColor: Color {
        switch meal.mealType {
        case .breakfast: return .orange
        case .morningSnack: return .green
        case .lunch: return .blue
        case .afternoonSnack: return .purple
        case .dinner: return .red
        }
    }

    private var mealTypeIcon: String {
        switch meal.mealType {
        case .breakfast: return "sun.horizon.fill"
        case .morningSnack: return "carrot.fill"
        case .lunch: return "sun.max.fill"
        case .afternoonSnack: return "cup.and.saucer.fill"
        case .dinner: return "moon.stars.fill"
        }
    }
}

#Preview {
    AIMealPlannerView()
        .modelContainer(for: [UserProfile.self, FoodEntry.self], inMemory: true)
}