import SwiftUI
import PhotosUI
import AVFoundation
import SwiftData

struct HomeView: View {
    @State private var showingCamera = false
    @State private var showingImagePicker = false
    @State private var showingBarcodeScanner = false
    @State private var showingManualEntry = false
    @State private var selectedImage: UIImage?
    @State private var selectedMealType: FoodEntry.MealType = .breakfast
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Daily Summary Card
                DailySummaryCard()
                    .padding(.horizontal)
                
                // Quick Add Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Quick Add")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            QuickAddButton(icon: "camera.fill", title: "Photo", color: .blue) {
                                showingCamera = true
                            }
                            
                            QuickAddButton(icon: "barcode", title: "Barcode", color: .orange) {
                                showingBarcodeScanner = true
                            }
                            
                            QuickAddButton(icon: "square.and.pencil", title: "Manual", color: .green) {
                                showingManualEntry = true
                            }
                            
                            QuickAddButton(icon: "photo", title: "Gallery", color: .purple) {
                                showingImagePicker = true
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Recent Meals
                RecentMealsView()
                
                Spacer()
            }
            .navigationTitle("Track")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingCamera) {
                CameraView(selectedMealType: $selectedMealType)
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImage: $selectedImage)
            }
            .sheet(isPresented: $showingBarcodeScanner) {
                BarcodeScannerView()
            }
            .sheet(isPresented: $showingManualEntry) {
                ManualEntryView(mealType: selectedMealType)
            }
        }
    }
}

struct DailySummaryCard: View {
    @EnvironmentObject var appState: AppState
    @Query(sort: \FoodEntry.timestamp) private var allEntries: [FoodEntry]
    
    private var todayEntries: [FoodEntry] {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? Date()
        
        return allEntries.filter { entry in
            entry.timestamp >= startOfToday && entry.timestamp < endOfToday
        }
    }
    
    private var totalCalories: Double {
        todayEntries.reduce(0) { $0 + $1.totalCalories }
    }
    
    private var totalProtein: Double {
        todayEntries.reduce(0) { $0 + $1.totalProtein }
    }
    
    private var totalCarbs: Double {
        todayEntries.reduce(0) { $0 + $1.totalCarbs }
    }
    
    private var totalFat: Double {
        todayEntries.reduce(0) { $0 + $1.totalFat }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Calorie Ring
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 12)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: min(totalCalories / (appState.currentUser?.dailyCalorieTarget ?? 2000), 1.0))
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                
                VStack {
                    Text("\(Int(totalCalories))")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("of \(Int(appState.currentUser?.dailyCalorieTarget ?? 2000))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("calories")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Macros
            HStack(spacing: 20) {
                MacroView(value: totalProtein, target: appState.currentUser?.dailyProteinTarget ?? 150, 
                         unit: "g", label: "Protein", color: .red)
                MacroView(value: totalCarbs, target: appState.currentUser?.dailyCarbTarget ?? 250, 
                         unit: "g", label: "Carbs", color: .orange)
                MacroView(value: totalFat, target: appState.currentUser?.dailyFatTarget ?? 65, 
                         unit: "g", label: "Fat", color: .yellow)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 10)
    }
}

struct MacroView: View {
    let value: Double
    let target: Double
    let unit: String
    let label: String
    let color: Color
    
    private var progress: Double {
        min(value / target, 1.0)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.3), lineWidth: 6)
                    .frame(width: 50, height: 50)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))
                
                Text("\(Int(value))")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct QuickAddButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(color)
                    .cornerRadius(16)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
        }
    }
}

struct RecentMealsView: View {
    @Query(sort: \FoodEntry.timestamp, order: .reverse) private var recentEntries: [FoodEntry]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent")
                    .font(.headline)
                
                Spacer()
                
                NavigationLink("See All") {
                    DiaryView()
                }
                .font(.caption)
            }
            .padding(.horizontal)
            
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(recentEntries.prefix(5)) { entry in
                        RecentMealRow(entry: entry)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct RecentMealRow: View {
    let entry: FoodEntry
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(entry.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("\(entry.mealType.rawValue) • \(entry.timestamp.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(Int(entry.totalCalories)) cal")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.blue)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}