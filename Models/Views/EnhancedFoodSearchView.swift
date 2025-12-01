import SwiftUI

struct EnhancedFoodSearchView: View {
    @StateObject private var foodDatabase = EnhancedFoodDatabase.shared
    @State private var searchText = ""
    @State private var selectedFilters = SearchFilters()
    @State private var showingFilters = false
    @State private var showingFoodDetail = false
    @State private var selectedFood: EnhancedFoodItem?
    @State private var recentSearches: [String] = []
    @State private var isSearching = false

    @Binding var selectedFoodItem: FoodItem?
    @Binding var selectedMealType: FoodEntry.MealType
    
    var body: some View {
        NavigationStack {
            ZStack {
                GlassmorphismBackground(colors: [.blue, .green, .teal])
                
                VStack(spacing: 0) {
                    searchHeader
                    
                    if searchText.isEmpty {
                        emptySearchView
                    } else if foodDatabase.isLoading {
                        loadingView
                    } else if foodDatabase.searchResults.isEmpty && !searchText.isEmpty {
                        noResultsView
                    } else {
                        searchResultsList
                    }
                }
            }
            .navigationTitle("Enhanced Food Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingFilters = true }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                SearchFiltersView(filters: $selectedFilters)
            }
            .sheet(isPresented: $showingFoodDetail) {
                if let food = selectedFood {
                    EnhancedFoodDetailView(food: food) { convertedFood, mealType in
                        selectedFoodItem = convertedFood
                        selectedMealType = mealType
                    }
                }
            }
            .onAppear {
                loadRecentSearches()
            }
        }
    }
    
    // MARK: - Search Header
    
    private var searchHeader: some View {
        VStack(spacing: 16) {
            searchBar
            
            if !foodDatabase.searchSuggestions.isEmpty && !searchText.isEmpty {
                suggestionChips
            }
        }
        .padding()
    }
    
    private var searchBar: some View {
        LiquidGlassCard {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search foods, brands, or barcodes...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .onSubmit {
                        performSearch()
                    }
                    .onChange(of: searchText) { _, newValue in
                        updateSuggestions(for: newValue)
                    }
                
                if !searchText.isEmpty {
                    Button(action: clearSearch) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
        }
    }
    
    private var suggestionChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(foodDatabase.searchSuggestions, id: \.self) { suggestion in
                    SuggestionChip(text: suggestion) {
                        searchText = suggestion
                        performSearch()
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Content Views
    
    private var emptySearchView: some View {
        ScrollView {
            VStack(spacing: 24) {
                searchTipsCard
                
                if !recentSearches.isEmpty {
                    recentSearchesCard
                }
                
                popularCategoriesCard
            }
            .padding()
        }
    }
    
    private var searchTipsCard: some View {
        LiquidGlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .font(.title2)
                        .foregroundStyle(
                            LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                    
                    Text("Search Tips")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    SearchTipRow(icon: "globe", text: "Search in multiple languages", color: .blue)
                    SearchTipRow(icon: "barcode.viewfinder", text: "Try product barcodes", color: .green)
                    SearchTipRow(icon: "building.2", text: "Include brand names", color: .orange)
                    SearchTipRow(icon: "list.bullet", text: "Use common food names", color: .purple)
                }
            }
            .padding()
        }
    }
    
    private var recentSearchesCard: some View {
        LiquidGlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "clock.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    Text("Recent Searches")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button("Clear") {
                        clearRecentSearches()
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(recentSearches.prefix(6), id: \.self) { search in
                        Button(action: {
                            searchText = search
                            performSearch()
                        }) {
                            Text(search)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.ultraThinMaterial)
                                .foregroundColor(.primary)
                                .cornerRadius(16)
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    private var popularCategoriesCard: some View {
        LiquidGlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "star.fill")
                        .font(.title2)
                        .foregroundStyle(
                            LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                    
                    Text("Popular Categories")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                let categories = ["Fruits", "Vegetables", "Meat & Fish", "Dairy", "Grains", "Snacks"]
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(categories, id: \.self) { category in
                        CategoryButton(title: category) {
                            searchText = category.lowercased()
                            performSearch()
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            LiquidWaveAnimation(height: 80, color: .blue)
                .frame(width: 80, height: 80)
            
            Text("Searching across multiple databases...")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding()
    }
    
    private var noResultsView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No results found")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Try a different search term or check for typos")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Search Suggestions") {
                searchText = ""
                foodDatabase.searchSuggestions = foodDatabase.getSearchSuggestions(for: "")
            }
            .padding()
            .background(.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
            
            Spacer()
        }
        .padding()
    }
    
    private var searchResultsList: some View {
        List(foodDatabase.searchResults) { food in
            EnhancedFoodRow(food: food) {
                selectedFood = food
                showingFoodDetail = true
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
        .listStyle(PlainListStyle())
        .background(Color.clear)
    }
    
    // MARK: - Actions
    
    private func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        isSearching = true
        saveRecentSearch(searchText)
        
        Task {
            _ = await foodDatabase.searchFood(query: searchText, filters: selectedFilters)
            isSearching = false
        }
    }
    
    private func clearSearch() {
        searchText = ""
        foodDatabase.searchResults = []
        foodDatabase.searchSuggestions = []
    }
    
    private func updateSuggestions(for query: String) {
        guard !query.isEmpty else {
            foodDatabase.searchSuggestions = []
            return
        }
        
        foodDatabase.searchSuggestions = foodDatabase.getSearchSuggestions(for: query)
    }
    
    private func loadRecentSearches() {
        if let data = UserDefaults.standard.data(forKey: "recentFoodSearches"),
           let searches = try? JSONDecoder().decode([String].self, from: data) {
            recentSearches = searches
        }
    }
    
    private func saveRecentSearch(_ search: String) {
        let cleanSearch = search.trimmingCharacters(in: .whitespaces)
        
        recentSearches.removeAll { $0.lowercased() == cleanSearch.lowercased() }
        recentSearches.insert(cleanSearch, at: 0)
        
        if recentSearches.count > 20 {
            recentSearches = Array(recentSearches.prefix(20))
        }
        
        if let encoded = try? JSONEncoder().encode(recentSearches) {
            UserDefaults.standard.set(encoded, forKey: "recentFoodSearches")
        }
    }
    
    private func clearRecentSearches() {
        recentSearches = []
        UserDefaults.standard.removeObject(forKey: "recentFoodSearches")
    }
}

// MARK: - Supporting Views

struct SuggestionChip: View {
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial)
                .foregroundColor(.blue)
                .cornerRadius(16)
        }
    }
}

struct SearchTipRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }
}

struct CategoryButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: categoryIcon(for: title))
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 60)
            .background(.ultraThinMaterial)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func categoryIcon(for category: String) -> String {
        switch category.lowercased() {
        case "fruits": return "apple.logo"
        case "vegetables": return "carrot.fill"
        case "meat & fish": return "fish.fill"
        case "dairy": return "drop.fill"
        case "grains": return "leaf.fill"
        case "snacks": return "birthday.cake.fill"
        default: return "fork.knife"
        }
    }
}

struct EnhancedFoodRow: View {
    let food: EnhancedFoodItem
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            LiquidGlassCard {
                HStack(spacing: 12) {
                    // Food Image or Icon
                    AsyncImage(url: URL(string: food.imageURL ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "fork.knife.circle.fill")
                            .font(.title)
                            .foregroundColor(.gray)
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    // Food Information
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(food.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                                .lineLimit(2)
                            
                            Spacer()
                            
                            SourceBadge(source: food.source)
                        }
                        
                        if let category = food.category {
                            Text(category)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        
                        // Nutrition Summary
                        HStack(spacing: 12) {
                            NutrientPill(label: "Cal", value: Int(food.basicNutrition.calories), color: .red)
                            NutrientPill(label: "P", value: Int(food.basicNutrition.protein), color: .blue)
                            NutrientPill(label: "C", value: Int(food.basicNutrition.carbohydrates), color: .orange)
                            NutrientPill(label: "F", value: Int(food.basicNutrition.fat), color: .yellow)
                            
                            Spacer()
                            
                            QualityIndicator(score: food.qualityScore)
                        }
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SourceBadge: View {
    let source: FoodSource
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: source.icon)
                .font(.caption2)
            
            Text(source.rawValue)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundColor(source.color)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(source.color.opacity(0.1))
        .cornerRadius(4)
    }
}

struct NutrientPill: View {
    let label: String
    let value: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct QualityIndicator: View {
    let score: Double
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { index in
                Circle()
                    .fill(index < Int(score * 5) ? .green : .gray.opacity(0.3))
                    .frame(width: 4, height: 4)
            }
        }
    }
}

#Preview {
    EnhancedFoodSearchView(selectedFoodItem: .constant(nil), selectedMealType: .constant(.breakfast))
}