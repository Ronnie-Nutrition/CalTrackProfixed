import SwiftUI

struct EnhancedFoodDetailView: View {
    let food: EnhancedFoodItem
    let onAddToLog: (FoodItem) -> Void
    
    @StateObject private var foodDatabase = EnhancedFoodDatabase.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var detailedNutrition: DetailedNutrition?
    @State private var isLoadingDetails = false
    @State private var servingQuantity: Double = 1.0
    @State private var selectedTab = 0
    @State private var showingServingSizeOptions = false
    
    private let tabs = ["Nutrition", "Details", "Ingredients"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                GlassmorphismBackground(colors: [.blue, .purple, .indigo])
                
                ScrollView {
                    VStack(spacing: 20) {
                        headerSection
                        servingSizeSelector
                        tabSelector
                        
                        TabView(selection: $selectedTab) {
                            nutritionTabContent
                                .tag(0)
                            
                            detailsTabContent
                                .tag(1)
                            
                            ingredientsTabContent
                                .tag(2)
                        }
                        .frame(height: 500)
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                        
                        addToLogButton
                    }
                    .padding()
                }
            }
            .navigationTitle("Food Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadDetailedNutrition()
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        LiquidGlassCard {
            VStack(spacing: 16) {
                HStack {
                    // Food Image
                    AsyncImage(url: URL(string: food.imageURL ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                            
                            Image(systemName: "fork.knife")
                                .font(.title)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(food.name)
                            .font(.headline)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.leading)
                        
                        if let brand = food.brand {
                            Text(brand)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            SourceBadge(source: food.source)
                            
                            Spacer()
                            
                            QualityStars(score: food.qualityScore)
                        }
                    }
                }
                
                // Quick Nutrition Overview
                HStack(spacing: 16) {
                    QuickNutrientView(
                        label: "Calories",
                        value: adjustedValue(food.basicNutrition.calories),
                        unit: "",
                        color: .red
                    )
                    
                    QuickNutrientView(
                        label: "Protein",
                        value: adjustedValue(food.basicNutrition.protein),
                        unit: "g",
                        color: .blue
                    )
                    
                    QuickNutrientView(
                        label: "Carbs",
                        value: adjustedValue(food.basicNutrition.carbohydrates),
                        unit: "g",
                        color: .orange
                    )
                    
                    QuickNutrientView(
                        label: "Fat",
                        value: adjustedValue(food.basicNutrition.fat),
                        unit: "g",
                        color: .yellow
                    )
                }
            }
            .padding()
        }
    }
    
    // MARK: - Serving Size Selector
    
    private var servingSizeSelector: some View {
        LiquidGlassCard {
            VStack(spacing: 12) {
                HStack {
                    Text("Serving Size")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button(action: {
                        showingServingSizeOptions = true
                    }) {
                        HStack {
                            Text(formattedServingSize)
                                .font(.subheadline)
                                .foregroundColor(.blue)
                            
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                HStack {
                    Text("Quantity:")
                        .font(.subheadline)
                    
                    Stepper(value: $servingQuantity, in: 0.1...20, step: 0.1) {
                        Text("\(servingQuantity, specifier: "%.1f")")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
            }
            .padding()
        }
        .actionSheet(isPresented: $showingServingSizeOptions) {
            ActionSheet(
                title: Text("Select Serving Size"),
                buttons: servingSizeOptions + [.cancel()]
            )
        }
    }
    
    // MARK: - Tab Selector
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                Button(action: {
                    withAnimation(.spring()) {
                        selectedTab = index
                    }
                }) {
                    Text(tab)
                        .font(.subheadline)
                        .fontWeight(selectedTab == index ? .semibold : .medium)
                        .foregroundColor(selectedTab == index ? .white : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            selectedTab == index ?
                                LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing) :
                                LinearGradient(colors: [.clear], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(selectedTab == index ? 10 : 0)
                }
            }
        }
        .padding(4)
        .background(.ultraThinMaterial)
        .cornerRadius(14)
    }
    
    // MARK: - Tab Content
    
    private var nutritionTabContent: some View {
        LiquidGlassCard {
            VStack(spacing: 16) {
                if isLoadingDetails {
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.2)
                        
                        Text("Loading detailed nutrition...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    nutritionContent
                }
            }
            .padding()
        }
    }
    
    private var nutritionContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Macronutrients
                VStack(alignment: .leading, spacing: 12) {
                    Text("Macronutrients")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 8) {
                        NutrientRow(
                            label: "Calories",
                            amount: adjustedValue(food.basicNutrition.calories),
                            unit: "",
                            percentage: nil,
                            color: .red
                        )
                        
                        NutrientRow(
                            label: "Protein",
                            amount: adjustedValue(food.basicNutrition.protein),
                            unit: "g",
                            percentage: calculateProteinPercentage(),
                            color: .blue
                        )
                        
                        NutrientRow(
                            label: "Total Carbohydrates",
                            amount: adjustedValue(food.basicNutrition.carbohydrates),
                            unit: "g",
                            percentage: calculateCarbPercentage(),
                            color: .orange
                        )
                        
                        if let fiber = food.basicNutrition.fiber {
                            NutrientRow(
                                label: "Dietary Fiber",
                                amount: adjustedValue(fiber),
                                unit: "g",
                                percentage: calculateFiberPercentage(fiber),
                                color: .green,
                                isIndented: true
                            )
                        }
                        
                        if let sugar = food.basicNutrition.sugar {
                            NutrientRow(
                                label: "Total Sugars",
                                amount: adjustedValue(sugar),
                                unit: "g",
                                percentage: nil,
                                color: .pink,
                                isIndented: true
                            )
                        }
                        
                        NutrientRow(
                            label: "Total Fat",
                            amount: adjustedValue(food.basicNutrition.fat),
                            unit: "g",
                            percentage: calculateFatPercentage(),
                            color: .yellow
                        )
                    }
                }
                
                if let detailed = detailedNutrition {
                    detailedNutritionSection(detailed)
                }
            }
        }
    }
    
    private func detailedNutritionSection(_ detailed: DetailedNutrition) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Vitamins
            if !detailed.vitamins.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Vitamins")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 6) {
                        ForEach(Array(detailed.vitamins.sorted(by: { $0.key < $1.key })), id: \.key) { vitamin, amount in
                            NutrientRow(
                                label: vitamin,
                                amount: adjustedValue(amount),
                                unit: getVitaminUnit(vitamin),
                                percentage: nil,
                                color: .purple
                            )
                        }
                    }
                }
            }
            
            // Minerals
            if !detailed.minerals.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Minerals")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 6) {
                        ForEach(Array(detailed.minerals.sorted(by: { $0.key < $1.key })), id: \.key) { mineral, amount in
                            NutrientRow(
                                label: mineral,
                                amount: adjustedValue(amount),
                                unit: getMineralUnit(mineral),
                                percentage: nil,
                                color: .cyan
                            )
                        }
                    }
                }
            }
        }
    }
    
    private var detailsTabContent: some View {
        LiquidGlassCard {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Food Information
                    DetailSection(title: "Food Information") {
                        DetailRow(label: "Name", value: food.name)
                        
                        if let brand = food.brand {
                            DetailRow(label: "Brand", value: brand)
                        }
                        
                        if let category = food.category {
                            DetailRow(label: "Category", value: category)
                        }
                        
                        DetailRow(label: "Data Source", value: food.source.rawValue)
                        
                        if let barcode = food.barcode {
                            DetailRow(label: "Barcode", value: barcode)
                        }
                        
                        DetailRow(label: "Quality Score", value: String(format: "%.1f/5.0", food.qualityScore * 5))
                    }
                    
                    // Serving Information
                    DetailSection(title: "Serving Information") {
                        DetailRow(label: "Standard Serving", value: food.basicNutrition.servingSize)
                        DetailRow(label: "Weight", value: "\(food.basicNutrition.servingSizeGrams, specifier: "%.0f")g")
                        DetailRow(label: "Selected Quantity", value: "\(servingQuantity, specifier: "%.1f")")
                    }
                    
                    // Certifications
                    if let certifications = food.certifications, !certifications.isEmpty {
                        DetailSection(title: "Certifications") {
                            ForEach(certifications, id: \.self) { cert in
                                CertificationBadge(name: cert)
                            }
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    private var ingredientsTabContent: some View {
        LiquidGlassCard {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let ingredients = food.ingredients, !ingredients.isEmpty {
                        DetailSection(title: "Ingredients") {
                            Text(ingredients.joined(separator: ", "))
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "list.clipboard")
                                .font(.title)
                                .foregroundColor(.secondary)
                            
                            Text("No ingredient information available")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    
                    if let allergens = food.allergens, !allergens.isEmpty {
                        DetailSection(title: "Allergens") {
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 8) {
                                ForEach(allergens, id: \.self) { allergen in
                                    AllergenBadge(name: allergen)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    // MARK: - Add to Log Button
    
    private var addToLogButton: some View {
        Button(action: addToFoodLog) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                
                Text("Add to Food Diary")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
        }
        .liquidPulse(color: .blue, intensity: 0.3)
    }
    
    // MARK: - Helper Methods
    
    private func loadDetailedNutrition() {
        guard food.hasDetailedNutrition else { return }
        
        isLoadingDetails = true
        
        Task {
            if let detailed = await foodDatabase.getDetailedNutrition(for: food.foodId, source: food.source) {
                await MainActor.run {
                    self.detailedNutrition = detailed
                    self.isLoadingDetails = false
                }
            } else {
                await MainActor.run {
                    self.isLoadingDetails = false
                }
            }
        }
    }
    
    private func adjustedValue(_ value: Double) -> Double {
        return value * servingQuantity
    }
    
    private var formattedServingSize: String {
        return food.basicNutrition.servingSize
    }
    
    private var servingSizeOptions: [ActionSheet.Button] {
        let commonSizes = ["1 cup", "1/2 cup", "1 piece", "1 slice", "1 tbsp", "1 tsp", "100g"]
        
        return commonSizes.map { size in
                .default(Text(size)) {
                // In a real implementation, you'd convert these to appropriate quantities
                servingQuantity = 1.0
            }
        }
    }
    
    private func calculateProteinPercentage() -> Double? {
        let totalCalories = adjustedValue(food.basicNutrition.calories)
        guard totalCalories > 0 else { return nil }
        return (adjustedValue(food.basicNutrition.protein) * 4 / totalCalories) * 100
    }
    
    private func calculateCarbPercentage() -> Double? {
        let totalCalories = adjustedValue(food.basicNutrition.calories)
        guard totalCalories > 0 else { return nil }
        return (adjustedValue(food.basicNutrition.carbohydrates) * 4 / totalCalories) * 100
    }
    
    private func calculateFatPercentage() -> Double? {
        let totalCalories = adjustedValue(food.basicNutrition.calories)
        guard totalCalories > 0 else { return nil }
        return (adjustedValue(food.basicNutrition.fat) * 9 / totalCalories) * 100
    }
    
    private func calculateFiberPercentage(_ fiber: Double) -> Double? {
        // Daily value for fiber is 28g
        return (adjustedValue(fiber) / 28) * 100
    }
    
    private func getVitaminUnit(_ vitamin: String) -> String {
        switch vitamin.lowercased() {
        case "vitamin c": return "mg"
        case "vitamin a": return "IU"
        case "vitamin d": return "IU"
        case "vitamin e": return "mg"
        case "vitamin k": return "μg"
        default: return "mg"
        }
    }
    
    private func getMineralUnit(_ mineral: String) -> String {
        switch mineral.lowercased() {
        case "calcium", "potassium": return "mg"
        case "iron": return "mg"
        case "sodium": return "mg"
        case "magnesium": return "mg"
        default: return "mg"
        }
    }
    
    private func addToFoodLog() {
        // Convert EnhancedFoodItem to FoodItem
        let convertedFood = FoodItem(
            foodId: food.foodId,
            label: food.name,
            categoryLabel: food.category,
            nutrients: FoodNutrients(
                calories: adjustedValue(food.basicNutrition.calories),
                protein: adjustedValue(food.basicNutrition.protein),
                carbs: adjustedValue(food.basicNutrition.carbohydrates),
                fat: adjustedValue(food.basicNutrition.fat)
            )
        )
        
        onAddToLog(convertedFood)
        dismiss()
    }
}

// MARK: - Supporting Detail Views

struct QuickNutrientView: View {
    let label: String
    let value: Double
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value, specifier: "%.0f")")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(unit.isEmpty ? label : "\(label) (\(unit))")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

struct QualityStars: View {
    let score: Double
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { index in
                Image(systemName: index < Int(score * 5) ? "star.fill" : "star")
                    .font(.caption)
                    .foregroundColor(.yellow)
            }
        }
    }
}

struct NutrientRow: View {
    let label: String
    let amount: Double
    let unit: String
    let percentage: Double?
    let color: Color
    var isIndented: Bool = false
    
    var body: some View {
        HStack {
            if isIndented {
                Spacer().frame(width: 16)
            }
            
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            
            Text(label)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(amount, specifier: "%.1f")\(unit)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let percentage = percentage {
                    Text("(\(percentage, specifier: "%.0f")%)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct DetailSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            content
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

struct CertificationBadge: View {
    let name: String
    
    var body: some View {
        Text(name)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.green)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.green.opacity(0.1))
            .cornerRadius(8)
    }
}

struct AllergenBadge: View {
    let name: String
    
    var body: some View {
        Text(name)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.red)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.red.opacity(0.1))
            .cornerRadius(8)
    }
}

#Preview {
    EnhancedFoodDetailView(
        food: EnhancedFoodItem(
            foodId: "123",
            name: "Organic Chicken Breast",
            brand: "Fresh Farms",
            category: "Meat & Poultry",
            source: .usda,
            qualityScore: 0.95,
            basicNutrition: BasicNutrition(
                calories: 165,
                protein: 31,
                carbohydrates: 0,
                fat: 3.6,
                fiber: nil,
                sugar: nil,
                sodium: 74,
                servingSize: "100g",
                servingSizeGrams: 100
            ),
            hasDetailedNutrition: true,
            imageURL: nil,
            barcode: nil,
            ingredients: ["Organic chicken breast"],
            allergens: nil,
            certifications: ["Organic", "Free-range"],
            lastUpdated: Date()
        )
    ) { _ in }
}