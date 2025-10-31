import SwiftUI
import SwiftData

struct DiaryView: View {
    @Query(sort: \FoodEntry.timestamp, order: .reverse) private var allEntries: [FoodEntry]
    @State private var selectedDate = Date()
    @State private var editingEntry: FoodEntry?
    
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
                        Text("Tap + to add your first meal")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { exportDiary() }) {
                            Label("Export Day", systemImage: "square.and.arrow.up")
                        }
                        Button(action: { clearDay() }) {
                            Label("Clear Day", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(item: $editingEntry) { entry in
                EditFoodEntryView(entry: entry)
            }
        }
    }
    
    private func exportDiary() {
        // Export functionality
    }
    
    private func clearDay() {
        // Clear day functionality
    }
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
        VStack(spacing: 16) {
            HStack {
                Text("Daily Total")
                    .font(.headline)
                Spacer()
                Text("\(Int(totalCalories)) cal")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }
            
            VStack(spacing: 12) {
                MacroProgressBar(
                    label: "Protein",
                    value: totalProtein,
                    target: appState.currentUser?.dailyProteinTarget ?? 150,
                    unit: "g",
                    color: .red
                )
                
                MacroProgressBar(
                    label: "Carbs",
                    value: totalCarbs,
                    target: appState.currentUser?.dailyCarbTarget ?? 250,
                    unit: "g",
                    color: .orange
                )
                
                MacroProgressBar(
                    label: "Fat",
                    value: totalFat,
                    target: appState.currentUser?.dailyFatTarget ?? 65,
                    unit: "g",
                    color: .yellow
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
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
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.name)
                    .font(.subheadline)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text("\(entry.quantity, specifier: "%.0f") \(entry.servingUnit)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        MacroBadge(value: entry.totalProtein, label: "P", color: .red)
                        MacroBadge(value: entry.totalCarbs, label: "C", color: .orange)
                        MacroBadge(value: entry.totalFat, label: "F", color: .yellow)
                    }
                }
            }
            
            Spacer()
            
            Text("\(Int(entry.totalCalories))")
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
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