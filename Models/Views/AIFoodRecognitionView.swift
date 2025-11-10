import SwiftUI
import SwiftData

struct AIFoodRecognitionView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var recognitionService = AIFoodRecognitionService()
    @StateObject private var permissionManager = CameraPermissionManager()
    
    @State private var showingCamera = false
    @State private var showingPhotoLibrary = false
    @State private var showingPermissionView = false
    @State private var capturedImage: UIImage?
    @State private var selectedImage: UIImage?
    @State private var showingResultsView = false
    @State private var showingHowItWorks = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                GlassmorphismBackground(colors: [.green, .blue, .purple])
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header Section
                        LiquidGlassCard {
                            VStack(spacing: 16) {
                                HStack {
                                    Image(systemName: "camera.viewfinder")
                                        .font(.title)
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.green, .blue],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                    
                                    VStack(alignment: .leading) {
                                        Text("AI Food Recognition")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                        Text("Identify food automatically from photos")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Button(action: { showingHowItWorks = true }) {
                                        Image(systemName: "questionmark.circle.fill")
                                            .font(.title3)
                                            .foregroundColor(.blue)
                                    }
                                }
                                
                                // Quick Stats
                                HStack(spacing: 20) {
                                    StatPill(icon: "sparkles", text: "AI Powered", color: .green)
                                    StatPill(icon: "bolt.fill", text: "Instant ID", color: .blue)
                                    StatPill(icon: "leaf.fill", text: "Auto Nutrition", color: .orange)
                                }
                            }
                            .padding()
                        }
                        
                        // Action Buttons
                        VStack(spacing: 16) {
                            // Take Photo Button
                            Button(action: {
                                if permissionManager.permissionStatus == .authorized {
                                    showingCamera = true
                                } else {
                                    showingPermissionView = true
                                }
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "camera.fill")
                                        .font(.title3)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Take Photo")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                        Text("Capture food with camera")
                                            .font(.caption)
                                            .opacity(0.8)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .opacity(0.6)
                                }
                                .foregroundColor(.white)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [.green, .blue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                                .shadow(color: .green.opacity(0.3), radius: 10)
                            }
                            .liquidPulse(color: .green, intensity: 0.3)
                            
                            // Choose from Library Button
                            Button(action: { showingPhotoLibrary = true }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "photo.on.rectangle")
                                        .font(.title3)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Choose from Library")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                        Text("Select existing photo")
                                            .font(.caption)
                                            .opacity(0.8)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .opacity(0.6)
                                }
                                .foregroundColor(.primary)
                                .padding()
                            }
                            .background(.ultraThinMaterial)
                            .cornerRadius(16)
                        }
                        
                        // Recent Results Section
                        if let lastResult = recognitionService.lastResult {
                            recentResultsSection(lastResult)
                        }
                        
                        // How It Works Section
                        LiquidGlassCard {
                            VStack(spacing: 16) {
                                Text("How It Works")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                VStack(spacing: 12) {
                                    HowItWorksStep(
                                        number: 1,
                                        title: "Take a Photo",
                                        description: "Capture or select a photo of your food",
                                        icon: "camera.fill",
                                        color: .green
                                    )
                                    
                                    HowItWorksStep(
                                        number: 2,
                                        title: "AI Analysis",
                                        description: "Our AI identifies food items and estimates portions",
                                        icon: "brain.head.profile.fill",
                                        color: .blue
                                    )
                                    
                                    HowItWorksStep(
                                        number: 3,
                                        title: "Nutrition Lookup",
                                        description: "Get detailed nutrition information automatically",
                                        icon: "chart.bar.fill",
                                        color: .orange
                                    )
                                    
                                    HowItWorksStep(
                                        number: 4,
                                        title: "Add to Diary",
                                        description: "Confirm and save to your food diary",
                                        icon: "checkmark.circle.fill",
                                        color: .purple
                                    )
                                }
                            }
                            .padding()
                        }
                        
                        // Tips Section
                        LiquidGlassCard {
                            VStack(spacing: 12) {
                                Text("Tips for Better Results")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                VStack(spacing: 8) {
                                    TipRow(icon: "lightbulb.fill", text: "Use good lighting for clearer photos", color: .yellow)
                                    TipRow(icon: "viewfinder", text: "Frame food items clearly in the center", color: .blue)
                                    TipRow(icon: "hand.raised.fill", text: "Include reference objects for portion estimation", color: .green)
                                    TipRow(icon: "rectangle.stack.fill", text: "Separate mixed dishes for better identification", color: .orange)
                                }
                            }
                            .padding()
                        }
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("How It Works") {
                        showingHowItWorks = true
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            .fullScreenCover(isPresented: $showingCamera) {
                AIFoodCameraView(capturedImage: $capturedImage, isPresented: $showingCamera)
            }
            .sheet(isPresented: $showingPhotoLibrary) {
                PhotoLibraryPicker(selectedImage: $selectedImage, isPresented: $showingPhotoLibrary)
            }
            .sheet(isPresented: $showingPermissionView) {
                CameraPermissionView(
                    onPermissionGranted: {
                        showingPermissionView = false
                        showingCamera = true
                    },
                    onDismiss: {
                        showingPermissionView = false
                    }
                )
            }
            .sheet(isPresented: $showingHowItWorks) {
                HowItWorksDetailView()
            }
            .sheet(isPresented: $showingResultsView) {
                if let result = recognitionService.lastResult {
                    FoodRecognitionResultView(result: result)
                }
            }
            .onAppear {
                permissionManager.checkCameraPermission()
            }
            .onChange(of: capturedImage) { _, newImage in
                if let image = newImage {
                    processImage(image)
                }
            }
            .onChange(of: selectedImage) { _, newImage in
                if let image = newImage {
                    processImage(image)
                }
            }
        }
    }
    
    // MARK: - Recent Results Section
    
    private func recentResultsSection(_ result: FoodRecognitionResult) -> some View {
        LiquidGlassCard {
            VStack(spacing: 16) {
                HStack {
                    Text("Last Recognition")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button("View Details") {
                        showingResultsView = true
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                
                HStack(spacing: 12) {
                    // Thumbnail
                    Image(uiImage: result.image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        if let topFood = result.topResult {
                            Text(topFood.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text("\(Int(topFood.confidence * 100))% confidence")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 4) {
                                Image(systemName: topFood.category.icon)
                                    .foregroundColor(topFood.category.color)
                                Text(topFood.category.rawValue)
                                    .foregroundColor(.secondary)
                            }
                            .font(.caption)
                        } else {
                            Text("No food detected")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    if result.recognizedFoods.count > 1 {
                        Text("+\(result.recognizedFoods.count - 1)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.ultraThinMaterial)
                            .cornerRadius(4)
                    }
                }
            }
            .padding()
        }
        .onTapGesture {
            showingResultsView = true
        }
    }
    
    // MARK: - Process Image
    
    private func processImage(_ image: UIImage) {
        Task {
            do {
                let result = try await recognitionService.recognizeFood(from: image)
                await MainActor.run {
                    showingResultsView = true
                }
            } catch {
                print("Food recognition failed: \(error)")
                // Handle error - could show an alert
            }
        }
    }
}

// MARK: - Supporting Views

struct StatPill: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.2))
        .cornerRadius(12)
    }
}

struct HowItWorksStep: View {
    let number: Int
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Text("\(number)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(color)
                .frame(width: 20, height: 20)
                .background(color.opacity(0.2))
                .clipShape(Circle())
        }
        .padding(.vertical, 4)
    }
}

struct TipRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
                .frame(width: 16)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

// MARK: - How It Works Detail View

struct HowItWorksDetailView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                GlassmorphismBackground(colors: [.blue, .purple, .indigo])
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        LiquidGlassCard {
                            VStack(spacing: 16) {
                                Image(systemName: "brain.head.profile.fill")
                                    .font(.system(size: 50))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                
                                Text("AI Food Recognition")
                                    .font(.title)
                                    .fontWeight(.bold)
                                
                                Text("Advanced computer vision technology identifies food items and provides accurate nutrition information automatically.")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                        }
                        
                        // Detailed Steps
                        VStack(spacing: 16) {
                            DetailedStep(
                                number: 1,
                                title: "Image Capture",
                                description: "Take a photo or select from your library. Our system works best with clear, well-lit images where food items are clearly visible.",
                                icon: "camera.fill",
                                color: .green,
                                features: ["Auto-focus optimization", "Lighting adjustment", "Multiple food detection"]
                            )
                            
                            DetailedStep(
                                number: 2,
                                title: "AI Processing",
                                description: "Our advanced neural network analyzes your image to identify food items, estimate portions, and detect ingredients.",
                                icon: "brain.head.profile.fill",
                                color: .blue,
                                features: ["Object detection", "Portion estimation", "Ingredient analysis"]
                            )
                            
                            DetailedStep(
                                number: 3,
                                title: "Nutrition Database",
                                description: "Identified foods are matched against our comprehensive nutrition database to provide accurate macro and micronutrient information.",
                                icon: "chart.bar.fill",
                                color: .orange,
                                features: ["USDA database", "Macro tracking", "Micronutrient data"]
                            )
                            
                            DetailedStep(
                                number: 4,
                                title: "Smart Logging",
                                description: "Review and confirm the detected foods, adjust portions if needed, and automatically add to your food diary.",
                                icon: "checkmark.circle.fill",
                                color: .purple,
                                features: ["Manual adjustment", "Meal categorization", "Auto-save to diary"]
                            )
                        }
                        
                        // Accuracy Info
                        LiquidGlassCard {
                            VStack(spacing: 12) {
                                Text("Accuracy & Performance")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                VStack(spacing: 8) {
                                    AccuracyRow(metric: "Food Identification", accuracy: "94%", color: .green)
                                    AccuracyRow(metric: "Portion Estimation", accuracy: "87%", color: .blue)
                                    AccuracyRow(metric: "Nutrition Accuracy", accuracy: "96%", color: .orange)
                                    AccuracyRow(metric: "Processing Speed", accuracy: "< 3s", color: .purple)
                                }
                            }
                            .padding()
                        }
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }
}

struct DetailedStep: View {
    let number: Int
    let title: String
    let description: String
    let icon: String
    let color: Color
    let features: [String]
    
    var body: some View {
        LiquidGlassCard {
            VStack(spacing: 16) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.2))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: icon)
                            .font(.title2)
                            .foregroundColor(color)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Step \(number)")
                            .font(.caption)
                            .foregroundColor(color)
                            .fontWeight(.medium)
                        
                        Text(title)
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    
                    Spacer()
                }
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(features, id: \.self) { feature in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(color)
                            
                            Text(feature)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
        }
    }
}

struct AccuracyRow: View {
    let metric: String
    let accuracy: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(metric)
                .font(.subheadline)
            
            Spacer()
            
            Text(accuracy)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

#Preview {
    AIFoodRecognitionView()
        .modelContainer(for: [FoodEntry.self])
}