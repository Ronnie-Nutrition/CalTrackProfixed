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
            ZStack {
                // Liquid Glass Background
                GlassmorphismBackground(colors: [.blue.opacity(0.3), .cyan.opacity(0.2), .purple.opacity(0.2)])

                ScrollView {
                    VStack(spacing: 24) {
                        // Daily Summary Card
                        DailySummaryCard()
                            .padding(.horizontal)

                        // Quick Add Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Quick Add")
                                .font(.headline)
                                .foregroundColor(AppColors.primaryText)
                                .padding(.horizontal)

                            HStack(spacing: 0) {
                                QuickAddButton(icon: "camera.viewfinder", title: "AI Photo", color: .blue) {
                                    showingCamera = true
                                }
                                .frame(maxWidth: .infinity)

                                QuickAddButton(icon: "barcode", title: "Barcode", color: .orange) {
                                    showingBarcodeScanner = true
                                }
                                .frame(maxWidth: .infinity)

                                QuickAddButton(icon: "square.and.pencil", title: "Manual", color: .green) {
                                    showingManualEntry = true
                                }
                                .frame(maxWidth: .infinity)

                                QuickAddButton(icon: "photo", title: "Gallery", color: .purple) {
                                    showingImagePicker = true
                                }
                                .frame(maxWidth: .infinity)

                                QuickAddButton(icon: "mic.fill", title: "Voice", color: .red) {
                                    showingVoiceInput = true
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .padding(.horizontal)
                        }

                        // AI Meal Planner - with Liquid Glass styling
                        NavigationLink(destination: AIMealPlannerView()) {
                            LiquidGlassCard(cornerRadius: 16) {
                                HStack {
                                    ZStack {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [.purple.opacity(0.3), .blue.opacity(0.2)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 44, height: 44)

                                        Image(systemName: "wand.and.stars")
                                            .font(.title2)
                                            .foregroundStyle(.linearGradient(
                                                colors: [.purple, .blue],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ))
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("AI Meal Planner")
                                            .font(.headline)
                                            .foregroundColor(AppColors.primaryText)

                                        Text("Generate personalized weekly meal plans")
                                            .font(.caption)
                                            .foregroundColor(AppColors.secondaryText)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(AppColors.tertiaryText)
                                }
                                .padding()
                            }
                        }
                        .padding(.horizontal)
                        .buttonStyle(PlainButtonStyle())

                        // Fasting Timer Widget
                        FastingWidgetCard()
                            .padding(.horizontal)

                        // Recent Meals
                        RecentMealsView()

                        // Bottom padding for comfortable scrolling
                        Spacer()
                            .frame(height: 30)
                    }
                    .padding(.top, 12)
                }
                .scrollIndicators(.hidden)
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

    private var calorieGoal: Double {
        appState.currentUser?.dailyCalorieTarget ?? 2000
    }

    private var proteinGoal: Double {
        appState.currentUser?.dailyProteinTarget ?? 150
    }

    private var carbsGoal: Double {
        appState.currentUser?.dailyCarbTarget ?? 250
    }

    private var fatGoal: Double {
        appState.currentUser?.dailyFatTarget ?? 65
    }

    var body: some View {
        LiquidGlassCard {
            VStack(spacing: 16) {
                // Liquid Glass Calorie Ring
                ZStack {
                    LiquidProgressRing(
                        progress: totalCalories,
                        total: calorieGoal,
                        color: .blue,
                        size: 120,
                        lineWidth: 12
                    )

                    VStack {
                        Text("\(Int(totalCalories))")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("of \(Int(calorieGoal))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("calories")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Liquid Glass Macros
                HStack(spacing: 20) {
                    LiquidMacroView(value: totalProtein, target: proteinGoal,
                                   unit: "g", label: "Protein 💪", color: .red)
                    LiquidMacroView(value: totalCarbs, target: carbsGoal,
                                   unit: "g", label: "Carbs", color: .orange)
                    LiquidMacroView(value: totalFat, target: fatGoal,
                                   unit: "g", label: "Fat", color: .yellow)
                }
            }
            .padding()
        }
        .fluidGlow(color: .blue.opacity(0.3))
        .onAppear {
            syncWidgetData()
        }
        .onChange(of: allEntries.count) { _, _ in
            syncWidgetData()
        }
    }

    private func syncWidgetData() {
        WidgetDataProvider.shared.updateNutritionData(
            calories: Int(totalCalories),
            calorieGoal: Int(calorieGoal),
            protein: Int(totalProtein),
            proteinGoal: Int(proteinGoal),
            carbs: Int(totalCarbs),
            carbsGoal: Int(carbsGoal),
            fat: Int(totalFat),
            fatGoal: Int(fatGoal)
        )
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
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) private var colorScheme

    private var isDark: Bool {
        themeManager.isDarkMode || colorScheme == .dark
    }

    var body: some View {
        Button(action: {
            AppHaptics.light()
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
            VStack(spacing: 10) {
                ZStack {
                    // Clean glass background - no blur material
                    RoundedRectangle(cornerRadius: 18)
                        .fill(
                            LinearGradient(
                                colors: [
                                    color.opacity(isDark ? 0.35 : 0.25),
                                    color.opacity(isDark ? 0.2 : 0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            // Inner highlight for glass effect
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            .white.opacity(isDark ? 0.25 : 0.5),
                                            .white.opacity(0.1),
                                            .clear
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                        .frame(width: 64, height: 64)

                    // Crisp icon
                    Image(systemName: icon)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(color)
                }
                .scaleEffect(isPressed ? 0.92 : 1.0)
                .shadow(color: color.opacity(isDark ? 0.4 : 0.3), radius: isPressed ? 4 : 8, y: isPressed ? 2 : 4)

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.primaryText)
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
                    .foregroundColor(AppColors.primaryText)

                Spacer()

                NavigationLink("See All") {
                    DiaryView()
                }
                .font(.caption)
                .foregroundColor(ThemeManager.shared.currentAccentColor)
            }
            .padding(.horizontal)

            if recentEntries.isEmpty {
                LiquidGlassCard(cornerRadius: 16) {
                    VStack(spacing: 16) {
                        Image(systemName: "fork.knife.circle")
                            .font(.system(size: 44))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue.opacity(0.6), .cyan.opacity(0.4)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        VStack(spacing: 6) {
                            Text("No recent meals")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(AppColors.primaryText)
                            Text("Add your first meal using Quick Add above")
                                .font(.caption)
                                .foregroundColor(AppColors.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .padding(.horizontal)
                }
                .padding(.horizontal)
            } else {
                VStack(spacing: 10) {
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
    @ObservedObject private var themeManager = ThemeManager.shared

    var body: some View {
        LiquidGlassRow(cornerRadius: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.primaryText)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Text(entry.mealType.rawValue)
                            .font(.caption)
                            .foregroundColor(themeManager.currentAccentColor)

                        Text("•")
                            .font(.caption)
                            .foregroundColor(AppColors.tertiaryText)

                        Text(entry.timestamp.formatted(date: .omitted, time: .shortened))
                            .font(.caption)
                            .foregroundColor(AppColors.secondaryText)
                    }
                }

                Spacer()

                Text("\(Int(entry.totalCalories))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.currentAccentColor)
                +
                Text(" cal")
                    .font(.caption)
                    .foregroundColor(AppColors.secondaryText)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
        }
        .liquidTransition()
    }
}

// MARK: - Fasting Widget Card
struct FastingWidgetCard: View {
    @StateObject private var fastingManager = FastingManager.shared
    @State private var showingFastingView = false

    private var stateColor: Color {
        fastingManager.currentState == .fasting ? .green : .orange
    }

    var body: some View {
        Button(action: { showingFastingView = true }) {
            LiquidGlassCard(cornerRadius: 16) {
                HStack(spacing: 16) {
                    // Liquid Glass Timer Ring
                    LiquidProgressRing(
                        progress: fastingManager.elapsedTime,
                        total: fastingManager.targetDuration > 0 ? fastingManager.targetDuration : 1,
                        color: stateColor,
                        size: 56,
                        lineWidth: 6
                    )
                    .overlay(
                        Image(systemName: fastingManager.currentState == .fasting ? "flame.fill" : "fork.knife")
                            .font(.title3)
                            .foregroundColor(stateColor)
                    )

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Intermittent Fasting")
                            .font(.headline)
                            .foregroundColor(AppColors.primaryText)

                        if fastingManager.currentState == .fasting {
                            Text(fastingManager.formattedElapsedTime)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                                .monospacedDigit()
                        } else if fastingManager.currentState == .eating {
                            Text("Eating Window")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                        } else {
                            Text("Tap to start fasting")
                                .font(.caption)
                                .foregroundColor(AppColors.secondaryText)
                        }

                        if fastingManager.currentStreak > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "flame.fill")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                                Text("\(fastingManager.currentStreak) day streak")
                                    .font(.caption2)
                                    .foregroundColor(AppColors.secondaryText)
                            }
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(AppColors.tertiaryText)
                }
                .padding()
            }
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingFastingView) {
            FastingView()
        }
    }
}