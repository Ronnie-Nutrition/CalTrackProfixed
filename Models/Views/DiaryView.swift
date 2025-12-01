import SwiftUI
import SwiftData

struct DiaryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FoodEntry.timestamp, order: .reverse) private var allEntries: [FoodEntry]
    @State private var selectedDate = Date()
    @State private var editingEntry: FoodEntry?
    @State private var isOffline = false
    @State private var showingAddOptions = false
    @State private var showingManualEntry = false
    @State private var showingFoodSearch = false
    @State private var showingCamera = false
    @State private var selectedMealType: FoodEntry.MealType = .breakfast
    @State private var selectedFood: FoodItem?
    @State private var showingClearConfirmation = false
    @State private var showingExportSheet = false
    @State private var exportText = ""
    
    private var entriesForSelectedDate: [FoodEntry] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        return allEntries.filter { entry in
            entry.timestamp >= startOfDay && entry.timestamp < endOfDay
        }
    }
    
    private var groupedEntries: [(FoodEntry.MealType, [FoodEntry])] {
        let grouped = Dictionary(grouping: entriesForSelectedDate) { $0.mealType }
        return FoodEntry.MealType.allCases.compactMap { mealType in
            if let entries = grouped[mealType], !entries.isEmpty {
                return (mealType, entries)
            }
            return nil
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Offline Banner
                if isOffline {
                    HStack {
                        Image(systemName: "wifi.slash")
                        Text("Offline - data may be limited")
                    }
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                }
                
                // Date Picker
                DatePicker("", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding()
                    .background(Color(.systemBackground))
                
                if entriesForSelectedDate.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No meals logged for this day")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("Tap the + button above to add food")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Button(action: { showingAddOptions = true }) {
                            Label("Add Food", systemImage: "plus.circle.fill")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(
                                    LinearGradient(
                                        colors: [.blue, .cyan],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(25)
                        }
                        .padding(.top, 8)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Daily Summary
                            DailyNutritionSummary(entries: entriesForSelectedDate)
                                .padding(.horizontal)
                            
                            // Meals by Type
                            ForEach(groupedEntries, id: \.0) { mealType, entries in
                                MealSection(mealType: mealType, entries: entries)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Food Diary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button(action: { prepareExport() }) {
                            Label("Export Day", systemImage: "square.and.arrow.up")
                        }
                        .disabled(entriesForSelectedDate.isEmpty)

                        Button(role: .destructive, action: { showingClearConfirmation = true }) {
                            Label("Clear Day", systemImage: "trash")
                        }
                        .disabled(entriesForSelectedDate.isEmpty)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddOptions = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
            }
            .sheet(item: $editingEntry) { entry in
                EditFoodEntryView(entry: entry)
            }
            .sheet(isPresented: $showingAddOptions) {
                AddFoodOptionsSheet(
                    showingManualEntry: $showingManualEntry,
                    showingFoodSearch: $showingFoodSearch,
                    showingCamera: $showingCamera
                )
                .presentationDetents([.height(280)])
            }
            .sheet(isPresented: $showingManualEntry) {
                ManualEntryView(mealType: selectedMealType)
            }
            .sheet(isPresented: $showingFoodSearch) {
                FoodSearchView(selectedFood: $selectedFood)
            }
            .sheet(isPresented: $showingCamera) {
                EnhancedBarcodeScannerView()
            }
            .alert("Clear Day", isPresented: $showingClearConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Clear All", role: .destructive) {
                    clearDay()
                }
            } message: {
                Text("Are you sure you want to delete all \(entriesForSelectedDate.count) food entries for this day? This cannot be undone.")
            }
            .sheet(isPresented: $showingExportSheet) {
                ShareSheet(items: [exportText])
            }
        }
    }

    private func prepareExport() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long

        var text = "CalTrackPro Food Diary\n"
        text += "\(dateFormatter.string(from: selectedDate))\n"
        text += String(repeating: "=", count: 40) + "\n\n"

        // Calculate totals
        let totalCalories = entriesForSelectedDate.reduce(0) { $0 + $1.totalCalories }
        let totalProtein = entriesForSelectedDate.reduce(0) { $0 + $1.totalProtein }
        let totalCarbs = entriesForSelectedDate.reduce(0) { $0 + $1.totalCarbs }
        let totalFat = entriesForSelectedDate.reduce(0) { $0 + $1.totalFat }

        text += "DAILY TOTALS\n"
        text += "Calories: \(Int(totalCalories)) kcal\n"
        text += "Protein: \(Int(totalProtein))g\n"
        text += "Carbs: \(Int(totalCarbs))g\n"
        text += "Fat: \(Int(totalFat))g\n\n"
        text += String(repeating: "-", count: 40) + "\n\n"

        // Group by meal type
        let grouped = Dictionary(grouping: entriesForSelectedDate) { $0.mealType }

        for mealType in FoodEntry.MealType.allCases {
            if let entries = grouped[mealType], !entries.isEmpty {
                let mealCalories = entries.reduce(0) { $0 + $1.totalCalories }
                text += "\(mealType.rawValue.uppercased()) (\(Int(mealCalories)) cal)\n"

                for entry in entries {
                    text += "  • \(entry.name)\n"
                    text += "    \(Int(entry.quantity)) \(entry.servingUnit) - \(Int(entry.totalCalories)) cal\n"
                    text += "    P: \(Int(entry.totalProtein))g | C: \(Int(entry.totalCarbs))g | F: \(Int(entry.totalFat))g\n"
                }
                text += "\n"
            }
        }

        text += String(repeating: "-", count: 40) + "\n"
        text += "Exported from CalTrackPro"

        exportText = text
        showingExportSheet = true
    }

    private func clearDay() {
        for entry in entriesForSelectedDate {
            modelContext.delete(entry)
        }
        try? modelContext.save()
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) { }
}

struct DailyNutritionSummary: View {
    let entries: [FoodEntry]
    @EnvironmentObject var appState: AppState
    
    private var totalCalories: Double {
        entries.reduce(0) { $0 + $1.totalCalories }
    }
    
    private var totalProtein: Double {
        entries.reduce(0) { $0 + $1.totalProtein }
    }
    
    private var totalCarbs: Double {
        entries.reduce(0) { $0 + $1.totalCarbs }
    }
    
    private var totalFat: Double {
        entries.reduce(0) { $0 + $1.totalFat }
    }
    
    var body: some View {
        LiquidGlassCard {
            VStack(spacing: 16) {
                HStack {
                    Text("Daily Total")
                        .font(.headline)
                        .foregroundColor(AppColors.primaryText)
                    Spacer()
                    Text("\(Int(totalCalories)) cal")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }

                VStack(spacing: 12) {
                    LiquidMacroProgressBar(
                        label: "Protein",
                        value: totalProtein,
                        target: appState.currentUser?.dailyProteinTarget ?? 150,
                        unit: "g",
                        color: .red
                    )

                    LiquidMacroProgressBar(
                        label: "Carbs",
                        value: totalCarbs,
                        target: appState.currentUser?.dailyCarbTarget ?? 250,
                        unit: "g",
                        color: .orange
                    )

                    LiquidMacroProgressBar(
                        label: "Fat",
                        value: totalFat,
                        target: appState.currentUser?.dailyFatTarget ?? 65,
                        unit: "g",
                        color: .yellow
                    )
                }
            }
            .padding()
        }
    }
}

struct MacroProgressBar: View {
    let label: String
    let value: Double
    let target: Double
    let unit: String
    let color: Color
    
    private var progress: Double {
        min(value / target, 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.subheadline)
                Spacer()
                Text("\(Int(value)) / \(Int(target)) \(unit)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(color.opacity(0.3))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * progress, height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
        }
    }
}

struct MealSection: View {
    let mealType: FoodEntry.MealType
    let entries: [FoodEntry]
    @Environment(\.modelContext) private var modelContext
    
    private var totalCalories: Double {
        entries.reduce(0) { $0 + $1.totalCalories }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(mealType.rawValue)
                    .font(.headline)
                Spacer()
                Text("\(Int(totalCalories)) cal")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            VStack(spacing: 8) {
                ForEach(entries) { entry in
                    FoodEntryRow(entry: entry)
                        .contextMenu {
                            Button(action: { duplicateEntry(entry) }) {
                                Label("Duplicate", systemImage: "doc.on.doc")
                            }
                            Button(role: .destructive, action: { deleteEntry(entry) }) {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func duplicateEntry(_ entry: FoodEntry) {
        let newEntry = FoodEntry(
            name: entry.name,
            calories: entry.calories,
            protein: entry.protein,
            carbs: entry.carbs,
            fat: entry.fat,
            servingSize: entry.servingSize,
            servingUnit: entry.servingUnit,
            quantity: entry.quantity,
            mealType: entry.mealType
        )
        newEntry.brand = entry.brand
        newEntry.barcode = entry.barcode
        newEntry.imageData = entry.imageData
        
        modelContext.insert(newEntry)
    }
    
    private func deleteEntry(_ entry: FoodEntry) {
        modelContext.delete(entry)
    }
}

struct FoodEntryRow: View {
    let entry: FoodEntry
    @ObservedObject private var themeManager = ThemeManager.shared

    var body: some View {
        LiquidGlassRow(cornerRadius: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.name)
                        .font(AppFonts.subheadline(weight: .medium))
                        .foregroundColor(AppColors.primaryText)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        Text("\(entry.quantity, specifier: "%.0f") \(entry.servingUnit)")
                            .font(AppFonts.caption())
                            .foregroundColor(AppColors.secondaryText)

                        Text("•")
                            .font(AppFonts.caption())
                            .foregroundColor(AppColors.tertiaryText)

                        HStack(spacing: 4) {
                            LiquidMacroBadge(value: entry.totalProtein, label: "P", color: .red)
                            LiquidMacroBadge(value: entry.totalCarbs, label: "C", color: .orange)
                            LiquidMacroBadge(value: entry.totalFat, label: "F", color: .yellow)
                        }
                    }
                }

                Spacer()

                Text("\(Int(entry.totalCalories))")
                    .font(AppFonts.subheadline(weight: .semibold))
                    .foregroundColor(themeManager.currentAccentColor)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
        }
    }
}

struct MacroBadge: View {
    let value: Double
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .fontWeight(.semibold)
            Text("\(Int(value))")
                .font(.caption2)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(color.opacity(0.2))
        .foregroundColor(color)
        .cornerRadius(4)
    }
}

// MARK: - Add Food Options Sheet
struct AddFoodOptionsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var showingManualEntry: Bool
    @Binding var showingFoodSearch: Bool
    @Binding var showingCamera: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Add Food")
                    .font(.headline)
                    .padding(.top)

                VStack(spacing: 12) {
                    AddFoodOptionButton(
                        icon: "magnifyingglass",
                        title: "Search Food",
                        subtitle: "Find foods in our database",
                        color: .blue
                    ) {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showingFoodSearch = true
                        }
                    }

                    AddFoodOptionButton(
                        icon: "barcode.viewfinder",
                        title: "Scan Barcode",
                        subtitle: "Scan a product's barcode",
                        color: .green
                    ) {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showingCamera = true
                        }
                    }

                    AddFoodOptionButton(
                        icon: "square.and.pencil",
                        title: "Manual Entry",
                        subtitle: "Enter nutrition info manually",
                        color: .orange
                    ) {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showingManualEntry = true
                        }
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
        }
    }
}

struct AddFoodOptionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(10)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}