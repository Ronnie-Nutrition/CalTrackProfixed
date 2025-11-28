import SwiftUI
import Speech
import AVFoundation
import SwiftData

struct VoiceInputView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var isRecording = false
    @State private var speechText = ""
    @State private var showingResults = false
    @State private var detectedFoods: [DetectedFood] = []
    @State private var errorMessage: String?
    @State private var audioEngine = AVAudioEngine()
    @State private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    @State private var isAuthorized = false
    @State private var recordingTimer: Timer?
    @State private var simulatorDemoTimer: Timer?
    
    struct DetectedFood {
        let name: String
        let quantity: String?
        let calories: Double
        let protein: Double
        let carbs: Double
        let fat: Double
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Liquid glass background
                GlassmorphismBackground(colors: [.blue, .purple, .pink])
                
                VStack(spacing: 30) {
                    // Title
                    VStack(spacing: 8) {
                        Image(systemName: "mic.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Voice Food Entry")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        #if targetEnvironment(simulator)
                        Text("Simulator Demo: Tap the button to see a sample voice recognition")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        #else
                        Text("Say what you ate, like \"I had a turkey sandwich\"")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        #endif
                    }
                    
                    // Liquid glass recording button (with simulator demo)
                    Button(action: {
                        #if targetEnvironment(simulator)
                        simulatorDemoMode()
                        #else
                        toggleRecording()
                        #endif
                    }) {
                        ZStack {
                            if isRecording {
                                // Liquid wave animation while recording
                                LiquidWaveAnimation(
                                    height: 120,
                                    color: .red
                                )
                                .clipShape(Circle())
                                .frame(width: 120, height: 120)
                            }
                            
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 120, height: 120)
                                .overlay(
                                    Circle()
                                        .stroke(
                                            LinearGradient(
                                                colors: isRecording ? [.red.opacity(0.8), .red] : [.blue.opacity(0.8), .blue],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 3
                                        )
                                )
                                .liquidPulse(color: isRecording ? .red : .blue, intensity: 0.6)
                            
                            Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: isRecording ? [.red, .red.opacity(0.7)] : [.blue, .blue.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: isRecording ? .red.opacity(0.3) : .blue.opacity(0.3), radius: 5)
                        }
                    }
                    .disabled(!isAuthorized)
                    .fluidGlow(color: isRecording ? .red : .blue)
                    
                    // Status text
                    if isRecording {
                        Text("Listening...")
                            .font(.headline)
                            .foregroundColor(.red)
                    } else if !speechText.isEmpty {
                        VStack(spacing: 10) {
                            Text("You said:")
                                .font(.headline)
                            Text("\"\(speechText)\"")
                                .font(.body)
                                .italic()
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(10)
                        }
                    }
                    
                    // Error message
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding()
                    }
                    
                    // Example phrases
                    if !isRecording && speechText.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Example phrases:")
                                .font(.headline)
                            
                            ForEach([
                                "I ate a chicken sandwich",
                                "I had two eggs and toast for breakfast",
                                "I just finished a large coffee with milk",
                                "I had a bowl of rice with vegetables"
                            ], id: \.self) { example in
                                HStack {
                                    Image(systemName: "quote.bubble")
                                        .foregroundColor(.blue)
                                    Text(example)
                                        .font(.caption)
                                }
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                requestSpeechAuthorization()
            }
            .onDisappear {
                if isRecording {
                    #if targetEnvironment(simulator)
                    simulatorDemoTimer?.invalidate()
                    simulatorDemoTimer = nil
                    isRecording = false
                    #else
                    stopRecording()
                    #endif
                }
            }
            .sheet(isPresented: $showingResults) {
                FoodResultsView(detectedFoods: detectedFoods, speechText: speechText)
            }
        }
    }
    
    private func simulatorDemoMode() {
        if isRecording {
            // Stop demo
            simulatorDemoTimer?.invalidate()
            simulatorDemoTimer = nil
            isRecording = false
            return
        }
        
        // Start demo recording simulation
        isRecording = true
        speechText = ""
        errorMessage = nil
        
        // Simulate recording for 3 seconds
        simulatorDemoTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            DispatchQueue.main.async {
                self.isRecording = false
                self.speechText = "I ate a turkey sandwich and an apple"
                
                // Process the demo text after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.processSpokenText()
                }
            }
        }
    }
    
    private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func requestSpeechAuthorization() {
        // Check if we're running in simulator
        #if targetEnvironment(simulator)
        DispatchQueue.main.async {
            self.isAuthorized = false
            self.errorMessage = "Voice input requires a physical device. Speech recognition is not available in the iOS Simulator."
        }
        #else
        // Check if speech recognizer is available
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            DispatchQueue.main.async {
                self.isAuthorized = false
                self.errorMessage = "Speech recognition is not available on this device."
            }
            return
        }
        
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    self.isAuthorized = true
                case .denied:
                    self.errorMessage = "Speech recognition access denied. Please enable in Settings → Privacy & Security → Speech Recognition."
                case .restricted:
                    self.errorMessage = "Speech recognition is restricted on this device."
                case .notDetermined:
                    self.errorMessage = "Speech recognition permission not determined. Please grant permission."
                @unknown default:
                    self.errorMessage = "Speech recognition is unavailable."
                }
            }
        }
        #endif
    }

    private func startRecording() {
        // Reset previous session
        speechText = ""
        errorMessage = nil
        
        // Clean up any previous recording state
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        
        // Check if speech recognizer is available
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            errorMessage = "Speech recognition not available"
            return
        }
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "Failed to set up audio session: \(error.localizedDescription)"
            return
        }
        
        // Create fresh recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else {
            errorMessage = "Unable to create recognition request"
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Add timeout handling
        recognitionRequest.taskHint = .search
        if #available(iOS 16.0, *) {
            recognitionRequest.addsPunctuation = false
            recognitionRequest.requiresOnDeviceRecognition = false
        }
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            DispatchQueue.main.async {
                
                var isFinal = false
                
                if let result = result {
                    speechText = result.bestTranscription.formattedString
                    isFinal = result.isFinal
                }
                
                if let error = error {
                    print("Speech recognition error: \(error)")
                    errorMessage = "Recognition error: \(error.localizedDescription)"
                    stopRecording()
                    return
                }
                
                if isFinal {
                    stopRecording()
                    if !speechText.isEmpty {
                        processSpokenText()
                    } else {
                        errorMessage = "No speech detected. Please try again."
                    }
                }
            }
        }
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            DispatchQueue.main.async {
                isRecording = true
            }
            
            // Set up 15-second timeout
            recordingTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: false) { _ in
                DispatchQueue.main.async {
                    stopRecording()
                    if speechText.isEmpty {
                        errorMessage = "Recording timeout. Please try again and speak more clearly."
                    }
                }
            }
        } catch {
            errorMessage = "Audio engine couldn't start: \(error.localizedDescription)"
        }
    }
    
    private func stopRecording() {
        // Cancel timer
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        
        DispatchQueue.main.async {
            isRecording = false
        }
        
        // Deactivate audio session
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
    }
    
    private func processSpokenText() {
        // Process the spoken text to extract food items
        let foods = parseFoodFromSpeech(speechText)
        
        if !foods.isEmpty {
            detectedFoods = foods
            showingResults = true
        } else {
            errorMessage = "Couldn't detect any food items. Try saying something like 'I ate chicken and rice'"
        }
    }
    
    private func parseFoodFromSpeech(_ text: String) -> [DetectedFood] {
        let lowercased = text.lowercased()
        var detectedFoods: [DetectedFood] = []
        
        // Expanded food database with common variations
        let foodDatabase: [String: (calories: Double, protein: Double, carbs: Double, fat: Double)] = [
            // Sandwiches & Wraps
            "turkey sandwich": (300, 24, 30, 12),
            "sandwich": (350, 20, 35, 15),
            "ham sandwich": (320, 22, 28, 14),
            "tuna sandwich": (280, 25, 25, 10),
            "chicken sandwich": (380, 28, 32, 16),
            "wrap": (250, 15, 30, 8),
            "burrito": (450, 20, 50, 18),
            
            // Proteins
            "chicken": (165, 31, 0, 4),
            "chicken breast": (165, 31, 0, 4),
            "beef": (250, 26, 0, 15),
            "pork": (200, 22, 0, 12),
            "fish": (140, 26, 0, 3),
            "salmon": (180, 25, 0, 8),
            "tuna": (130, 28, 0, 1),
            "turkey": (135, 30, 0, 1),
            "ham": (140, 22, 1, 5),
            
            // Starches
            "rice": (130, 2.7, 28, 0.3),
            "white rice": (130, 2.7, 28, 0.3),
            "brown rice": (110, 2.6, 22, 0.9),
            "pasta": (220, 8, 43, 1.3),
            "spaghetti": (220, 8, 43, 1.3),
            "noodles": (220, 8, 43, 1.3),
            "bread": (80, 4, 15, 1),
            "toast": (75, 3, 14, 1),
            "bagel": (280, 11, 55, 2),
            "potato": (160, 4, 37, 0.2),
            "sweet potato": (100, 2, 23, 0.1),
            
            // Eggs & Dairy
            "egg": (70, 6, 0.6, 5),
            "eggs": (140, 12, 1.2, 10), // 2 eggs
            "scrambled eggs": (140, 12, 1.2, 10),
            "omelette": (200, 15, 2, 15),
            "milk": (150, 8, 12, 8),
            "cheese": (115, 7, 1, 9),
            "yogurt": (100, 6, 15, 0.4),
            "cottage cheese": (100, 14, 5, 2),
            
            // Fruits
            "apple": (95, 0.5, 25, 0.3),
            "banana": (105, 1.3, 27, 0.4),
            "orange": (65, 1.3, 16, 0.2),
            "grapes": (90, 0.9, 23, 0.2),
            "strawberries": (50, 1, 12, 0.5),
            "blueberries": (80, 1, 21, 0.5),
            
            // Vegetables
            "salad": (50, 3, 10, 0.5),
            "vegetables": (50, 2, 10, 0.5),
            "broccoli": (25, 3, 5, 0.3),
            "carrots": (25, 0.5, 6, 0.1),
            "spinach": (20, 3, 3, 0.4),
            "tomato": (20, 1, 4, 0.2),
            
            // Fast Food
            "burger": (500, 25, 40, 28),
            "hamburger": (500, 25, 40, 28),
            "cheeseburger": (550, 28, 42, 32),
            "pizza": (285, 12, 36, 10),
            "pizza slice": (285, 12, 36, 10),
            "fries": (365, 4, 63, 17),
            "french fries": (365, 4, 63, 17),
            "hot dog": (300, 12, 25, 18),
            
            // Beverages
            "coffee": (5, 0.3, 1, 0),
            "tea": (2, 0, 0.5, 0),
            "soda": (140, 0, 39, 0),
            "juice": (110, 0.5, 26, 0.3),
            "orange juice": (110, 1.7, 26, 0.5),
            "beer": (150, 1.6, 13, 0),
            "wine": (125, 0.1, 4, 0),
            "water": (0, 0, 0, 0),
            
            // Snacks
            "chips": (150, 2, 15, 10),
            "crackers": (120, 2.5, 20, 4),
            "nuts": (180, 6, 6, 16),
            "almonds": (160, 6, 6, 14),
            "peanuts": (160, 7, 4, 14),
            "cookie": (150, 2, 20, 7),
            "cake": (250, 3, 35, 12),
            
            // Breakfast Items
            "cereal": (150, 3, 32, 2),
            "oatmeal": (150, 5, 27, 3),
            "pancakes": (520, 8, 100, 9),
            "waffles": (520, 8, 100, 9),
            "muffin": (420, 6, 61, 16)
        ]
        
        // Enhanced quantity detection
        let quantities: [String: Double] = [
            "zero": 0, "one": 1, "two": 2, "three": 3, "four": 4, "five": 5,
            "six": 6, "seven": 7, "eight": 8, "nine": 9, "ten": 10,
            "a": 1, "an": 1, "some": 1, "few": 2, "couple": 2, "pair": 2,
            "bowl": 1, "cup": 1, "glass": 1, "plate": 1, "serving": 1,
            "small": 0.75, "medium": 1, "large": 1.5, "big": 1.5, "huge": 2,
            "half": 0.5, "quarter": 0.25, "piece": 1, "slice": 1, "scoop": 1
        ]
        
        // Clean up the text for better parsing
        let cleanText = lowercased
            .replacingOccurrences(of: "i ate", with: "")
            .replacingOccurrences(of: "i had", with: "")
            .replacingOccurrences(of: "i just ate", with: "")
            .replacingOccurrences(of: "i just had", with: "")
            .replacingOccurrences(of: "for breakfast", with: "")
            .replacingOccurrences(of: "for lunch", with: "")
            .replacingOccurrences(of: "for dinner", with: "")
            .replacingOccurrences(of: "for snack", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Sort foods by length (longest first) to match specific items before general ones
        let sortedFoods = foodDatabase.keys.sorted { $0.count > $1.count }
        
        var usedRanges: [Range<String.Index>] = []
        
        // Search for food items (avoiding overlaps)
        for food in sortedFoods {
            if let range = cleanText.range(of: food) {
                // Check if this range overlaps with any already used range
                let overlaps = usedRanges.contains { usedRange in
                    range.overlaps(usedRange) || usedRange.overlaps(range)
                }
                
                if !overlaps {
                    usedRanges.append(range)
                    let macros = foodDatabase[food]!
                    
                    // Enhanced quantity detection
                    var quantity = 1.0
                    
                    // Safely get context around the food item
                    var contextualText = cleanText
                    if let range = cleanText.range(of: food) {
                        let startOffset = max(0, cleanText.distance(from: cleanText.startIndex, to: range.lowerBound) - 20)
                        let endOffset = min(cleanText.count, cleanText.distance(from: cleanText.startIndex, to: range.upperBound) + 20)
                        
                        let startIndex = cleanText.index(cleanText.startIndex, offsetBy: startOffset)
                        let endIndex = cleanText.index(cleanText.startIndex, offsetBy: endOffset)
                        contextualText = String(cleanText[startIndex..<endIndex])
                    }
                    
                    // Look for numbers first (1-10)
                    for i in 1...10 {
                        if contextualText.contains("\(i) " + food) || contextualText.contains("\(i)" + food) {
                            quantity = Double(i)
                            break
                        }
                    }
                    
                    // If no number found, look for quantity words
                    if quantity == 1.0 {
                        for (word, multiplier) in quantities {
                            if contextualText.contains(word + " " + food) || 
                               contextualText.contains(word + " of " + food) ||
                               contextualText.contains(word + food) {
                                quantity = multiplier
                                break
                            }
                        }
                    }
                    
                    detectedFoods.append(DetectedFood(
                        name: food.capitalized,
                        quantity: quantity == 1.0 ? nil : (quantity.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(quantity))" : String(format: "%.1f", quantity)),
                        calories: macros.calories * quantity,
                        protein: macros.protein * quantity,
                        carbs: macros.carbs * quantity,
                        fat: macros.fat * quantity
                    ))
                }
            }
        }
        
        return detectedFoods
    }
}

// Results view to confirm and add detected foods
struct FoodResultsView: View {
    let detectedFoods: [VoiceInputView.DetectedFood]
    let speechText: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var selectedMeal = FoodEntry.MealType.snack
    
    var body: some View {
        NavigationStack {
            VStack {
                // Show what was said
                VStack(alignment: .leading, spacing: 8) {
                    Text("You said:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\"\(speechText)\"")
                        .font(.body)
                        .italic()
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding()
                
                // Meal type picker
                Picker("Meal Type", selection: $selectedMeal) {
                    ForEach(FoodEntry.MealType.allCases, id: \.self) { meal in
                        Text(meal.rawValue.capitalized).tag(meal)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Detected foods
                List(detectedFoods, id: \.name) { food in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(food.name)
                                .font(.headline)
                            if let qty = food.quantity {
                                Text("(\(qty))")
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        HStack(spacing: 15) {
                            Label("\(Int(food.calories)) cal", systemImage: "flame")
                            Label("\(Int(food.protein))g", systemImage: "p.square")
                                .foregroundColor(.blue)
                            Label("\(Int(food.carbs))g", systemImage: "c.square")
                                .foregroundColor(.orange)
                            Label("\(Int(food.fat))g", systemImage: "f.square")
                                .foregroundColor(.green)
                        }
                        .font(.caption)
                    }
                    .padding(.vertical, 8)
                }
                
                // Total nutrition
                VStack(spacing: 12) {
                    Text("Total Nutrition")
                        .font(.headline)
                    
                    HStack(spacing: 20) {
                        VStack {
                            Text("\(Int(detectedFoods.reduce(0) { $0 + $1.calories }))")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Calories")
                                .font(.caption)
                        }
                        
                        VStack {
                            Text("\(Int(detectedFoods.reduce(0) { $0 + $1.protein }))g")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            Text("Protein")
                                .font(.caption)
                        }
                        
                        VStack {
                            Text("\(Int(detectedFoods.reduce(0) { $0 + $1.carbs }))g")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                            Text("Carbs")
                                .font(.caption)
                        }
                        
                        VStack {
                            Text("\(Int(detectedFoods.reduce(0) { $0 + $1.fat }))g")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                            Text("Fat")
                                .font(.caption)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding()
                
                // Add button
                Button(action: addFoodsToLog) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add to Food Log")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Confirm Foods")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func addFoodsToLog() {
        for food in detectedFoods {
            let entry = FoodEntry(
                name: food.name,
                calories: food.calories,
                protein: food.protein,
                carbs: food.carbs,
                fat: food.fat,
                servingSize: 1,
                servingUnit: "serving",
                quantity: 1,
                mealType: selectedMeal
            )
            modelContext.insert(entry)
        }
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving: \(error)")
        }
    }
}

#Preview {
    VoiceInputView()
}