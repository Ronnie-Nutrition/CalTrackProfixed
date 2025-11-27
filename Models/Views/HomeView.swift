import SwiftUI
import PhotosUI
import AVFoundation
import SwiftData

struct HomeView: View {
    @State private var showingCamera = false
    @State private var showingImagePicker = false
    @State private var showingBarcodeScanner = false
    @State private var showingManualEntry = false
    @State private var showingVoiceInput = false
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
                            QuickAddButton(icon: "camera.viewfinder", title: "AI Photo", color: .blue) {
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
                            
                            QuickAddButton(icon: "mic.fill", title: "Voice", color: .red) {
                                showingVoiceInput = true
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // AI Meal Planner
                NavigationLink(destination: AIMealPlannerView()) {
                    HStack {
                        Image(systemName: "wand.and.stars")
                            .font(.title2)
                            .foregroundStyle(.linearGradient(
                                colors: [.purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                        
                        VStack(alignment: .leading) {
                            Text("AI Meal Planner")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("Generate personalized weekly meal plans")
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
                        LinearGradient(
                            colors: [.purple.opacity(0.1), .blue.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .cornerRadius(12)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    colors: [.purple.opacity(0.3), .blue.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                }
                .padding(.horizontal)
                .buttonStyle(PlainButtonStyle())
                
                // Recent Meals
                RecentMealsView()
                
                Spacer()
            }
            .navigationTitle("Track")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingCamera) {
                AIFoodRecognitionView()
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImage: $selectedImage)
            }
            .sheet(isPresented: $showingBarcodeScanner) {
                EnhancedBarcodeScannerView()
            }
            .sheet(isPresented: $showingManualEntry) {
                ManualEntryView(mealType: selectedMealType)
            }
            .sheet(isPresented: $showingVoiceInput) {
                VoiceInputView()
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
        LiquidGlassCard {
            VStack(spacing: 16) {
                // Liquid Glass Calorie Ring
                ZStack {
                    LiquidProgressRing(
                        progress: totalCalories,
                        total: appState.currentUser?.dailyCalorieTarget ?? 2000,
                        color: .blue,
                        size: 120,
                        lineWidth: 12
                    )
                    
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
                
                // Liquid Glass Macros
                HStack(spacing: 20) {
                    LiquidMacroView(value: totalProtein, target: appState.currentUser?.dailyProteinTarget ?? 150, 
                                   unit: "g", label: "Protein 💪", color: .red)
                    LiquidMacroView(value: totalCarbs, target: appState.currentUser?.dailyCarbTarget ?? 250, 
                                   unit: "g", label: "Carbs", color: .orange)
                    LiquidMacroView(value: totalFat, target: appState.currentUser?.dailyFatTarget ?? 65, 
                                   unit: "g", label: "Fat", color: .yellow)
                }
            }
            .padding()
        }
        .fluidGlow(color: .blue.opacity(0.3))
    }
}

struct LiquidMacroView: View {
    let value: Double
    let target: Double
    let unit: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                LiquidProgressRing(
                    progress: value,
                    total: target,
                    color: color,
                    size: 50,
                    lineWidth: 6
                )
                
                Text("\(Int(value))")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .liquidPulse(color: color, intensity: 0.2)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
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
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(FluidSpring.snappy) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(FluidSpring.gentle) {
                    isPressed = false
                }
            }
            action()
        }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(color)
                            
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [.white.opacity(0.3), .clear],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.4), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .scaleEffect(isPressed ? 0.95 : 1.0)
                    .shadow(color: color.opacity(0.4), radius: isPressed ? 5 : 10)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
        }
        .buttonStyle(PlainButtonStyle())
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
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.2), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                )
        )
        .liquidTransition()
    }
}