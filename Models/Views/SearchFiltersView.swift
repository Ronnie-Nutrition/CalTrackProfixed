import SwiftUI

struct SearchFiltersView: View {
    @Binding var filters: SearchFilters
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedCategory: String = ""
    @State private var selectedBrand: String = ""
    @State private var minCalories: Double = 0
    @State private var maxCalories: Double = 1000
    @State private var minProtein: Double = 0
    @State private var maxProtein: Double = 100
    @State private var selectedAllergens: Set<String> = []
    @State private var selectedCertifications: Set<String> = []
    @State private var requireNutritionFacts = false
    @State private var selectedSource: FoodSource?
    
    private let categories = [
        "Fruits", "Vegetables", "Meat & Poultry", "Seafood", "Dairy", "Grains",
        "Nuts & Seeds", "Beverages", "Snacks", "Desserts", "Condiments", "Spices"
    ]
    
    private let allergens = [
        "Gluten", "Dairy", "Eggs", "Fish", "Shellfish", "Tree Nuts",
        "Peanuts", "Soy", "Sesame"
    ]
    
    private let certifications = [
        "Organic", "Non-GMO", "Fair Trade", "Kosher", "Halal",
        "Vegan", "Vegetarian", "Gluten-Free", "Sugar-Free"
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                GlassmorphismBackground(colors: [.purple, .blue, .indigo])
                
                Form {
                    categorySection
                    brandSection
                    nutritionRangeSection
                    allergenSection
                    certificationSection
                    dataQualitySection
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Search Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear All") {
                        clearAllFilters()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        applyFilters()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                loadCurrentFilters()
            }
        }
    }
    
    // MARK: - Form Sections
    
    private var categorySection: some View {
        Section {
            LiquidGlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "tag.fill")
                            .foregroundColor(.blue)
                        Text("Category")
                            .font(.headline)
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(categories, id: \.self) { category in
                                FilterChip(
                                    text: category,
                                    isSelected: selectedCategory == category
                                ) {
                                    selectedCategory = selectedCategory == category ? "" : category
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding()
            }
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets())
    }
    
    private var brandSection: some View {
        Section {
            LiquidGlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "building.2.fill")
                            .foregroundColor(.green)
                        Text("Brand")
                            .font(.headline)
                    }
                    
                    TextField("Enter brand name...", text: $selectedBrand)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding()
            }
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets())
    }
    
    private var nutritionRangeSection: some View {
        Section {
            LiquidGlassCard {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(.orange)
                        Text("Nutrition Range")
                            .font(.headline)
                    }
                    
                    VStack(spacing: 16) {
                        NutritionRangeSlider(
                            title: "Calories",
                            minValue: $minCalories,
                            maxValue: $maxCalories,
                            bounds: 0...2000,
                            step: 10,
                            unit: "cal"
                        )

                        NutritionRangeSlider(
                            title: "Protein",
                            minValue: $minProtein,
                            maxValue: $maxProtein,
                            bounds: 0...200,
                            step: 1,
                            unit: "g"
                        )
                    }
                }
                .padding()
            }
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets())
    }
    
    private var allergenSection: some View {
        Section {
            LiquidGlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text("Allergen-Free")
                            .font(.headline)
                    }
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        ForEach(allergens, id: \.self) { allergen in
                            FilterToggle(
                                text: allergen,
                                isSelected: selectedAllergens.contains(allergen)
                            ) {
                                if selectedAllergens.contains(allergen) {
                                    selectedAllergens.remove(allergen)
                                } else {
                                    selectedAllergens.insert(allergen)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets())
    }
    
    private var certificationSection: some View {
        Section {
            LiquidGlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.green)
                        Text("Certifications")
                            .font(.headline)
                    }
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        ForEach(certifications, id: \.self) { certification in
                            FilterToggle(
                                text: certification,
                                isSelected: selectedCertifications.contains(certification)
                            ) {
                                if selectedCertifications.contains(certification) {
                                    selectedCertifications.remove(certification)
                                } else {
                                    selectedCertifications.insert(certification)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets())
    }
    
    private var dataQualitySection: some View {
        Section {
            LiquidGlassCard {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("Data Quality")
                            .font(.headline)
                    }
                    
                    VStack(spacing: 12) {
                        Toggle("Require detailed nutrition facts", isOn: $requireNutritionFacts)
                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Preferred Data Source")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            HStack(spacing: 8) {
                                ForEach(FoodSource.allCases, id: \.self) { source in
                                    SourceFilterButton(
                                        source: source,
                                        isSelected: selectedSource == source
                                    ) {
                                        selectedSource = selectedSource == source ? nil : source
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets())
    }
    
    // MARK: - Actions
    
    private func loadCurrentFilters() {
        selectedCategory = filters.category ?? ""
        selectedBrand = filters.brand ?? ""
        minCalories = filters.minCalories ?? 0
        maxCalories = filters.maxCalories ?? 1000
        minProtein = filters.minProtein ?? 0
        maxProtein = filters.maxProtein ?? 100
        selectedAllergens = Set(filters.allergenFree ?? [])
        selectedCertifications = Set(filters.certifications ?? [])
        requireNutritionFacts = filters.hasNutritionFacts ?? false
        selectedSource = filters.source
    }
    
    private func applyFilters() {
        filters = SearchFilters(
            category: selectedCategory.isEmpty ? nil : selectedCategory,
            brand: selectedBrand.isEmpty ? nil : selectedBrand,
            minCalories: minCalories > 0 ? minCalories : nil,
            maxCalories: maxCalories < 1000 ? maxCalories : nil,
            minProtein: minProtein > 0 ? minProtein : nil,
            maxProtein: maxProtein < 100 ? maxProtein : nil,
            allergenFree: selectedAllergens.isEmpty ? nil : Array(selectedAllergens),
            certifications: selectedCertifications.isEmpty ? nil : Array(selectedCertifications),
            hasNutritionFacts: requireNutritionFacts ? true : nil,
            source: selectedSource
        )
    }
    
    private func clearAllFilters() {
        selectedCategory = ""
        selectedBrand = ""
        minCalories = 0
        maxCalories = 1000
        minProtein = 0
        maxProtein = 100
        selectedAllergens = []
        selectedCertifications = []
        requireNutritionFacts = false
        selectedSource = nil
    }
}

// MARK: - Supporting Views

struct FilterChip: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? .blue : .gray.opacity(0.2))
                .cornerRadius(16)
        }
    }
}

struct FilterToggle: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .green : .gray)
                
                Text(text)
                    .font(.caption)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.vertical, 4)
        }
    }
}

struct SourceFilterButton: View {
    let source: FoodSource
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: source.icon)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : source.color)
                
                Text(source.rawValue)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white : .primary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, minHeight: 40)
            .background(isSelected ? source.color : .gray.opacity(0.2))
            .cornerRadius(8)
        }
    }
}

struct NutritionRangeSlider: View {
    let title: String
    @Binding var minValue: Double
    @Binding var maxValue: Double
    let bounds: ClosedRange<Double>
    let step: Double
    let unit: String

    // Legacy init for range binding (deprecated)
    init(title: String, range: Binding<ClosedRange<Double>>, bounds: ClosedRange<Double>, step: Double, unit: String) {
        self.title = title
        self._minValue = Binding(get: { range.wrappedValue.lowerBound }, set: { _ in })
        self._maxValue = Binding(get: { range.wrappedValue.upperBound }, set: { _ in })
        self.bounds = bounds
        self.step = step
        self.unit = unit
    }

    init(title: String, minValue: Binding<Double>, maxValue: Binding<Double>, bounds: ClosedRange<Double>, step: Double, unit: String) {
        self.title = title
        self._minValue = minValue
        self._maxValue = maxValue
        self.bounds = bounds
        self.step = step
        self.unit = unit
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Text("\(Int(minValue))-\(Int(maxValue)) \(unit)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 4) {
                HStack {
                    Text("Min:")
                        .font(.caption)

                    Slider(value: $minValue, in: bounds, step: step)
                }

                HStack {
                    Text("Max:")
                        .font(.caption)

                    Slider(value: $maxValue, in: bounds, step: step)
                }
            }
        }
    }
}

#Preview {
    SearchFiltersView(filters: .constant(SearchFilters()))
}