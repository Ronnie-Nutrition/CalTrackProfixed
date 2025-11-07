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
                // Background gradient
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Title
                    VStack(spacing: 8) {
                        Image(systemName: "mic.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Voice Food Entry")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Say what you ate, like \"I had a turkey sandwich\"")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // Recording button
                    Button(action: toggleRecording) {
                        ZStack {
                            Circle()
                                .fill(isRecording ? Color.red : Color.blue)
                                .frame(width: 120, height: 120)
                            
                            if isRecording {
                                // Pulse animation
                                Circle()
                                    .stroke(Color.red, lineWidth: 4)
                                    .frame(width: 120, height: 120)
                                    .scaleEffect(isRecording ? 1.5 : 1)
                                    .opacity(isRecording ? 0 : 1)
                                    .animation(.easeOut(duration: 1).repeatForever(autoreverses: false), value: isRecording)
                            }
                            
                            Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                        }
                    }
                    .disabled(!isAuthorized)
                    
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
            .sheet(isPresented: $showingResults) {
                FoodResultsView(detectedFoods: detectedFoods, speechText: speechText)
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
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    self.isAuthorized = true
                case .denied:
                    self.errorMessage = "Speech recognition access denied"
                case .restricted:
                    self.errorMessage = "Speech recognition restricted"
                case .notDetermined:
                    self.errorMessage = "Speech recognition not determined"
                @unknown default:
                    self.errorMessage = "Speech recognition unavailable"
                }
            }
        }
    }
    
    private func startRecording() {
        // Reset previous session
        speechText = ""
        errorMessage = nil
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "Failed to set up audio session"
            return
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
        guard let recognitionRequest = recognitionRequest else {
            errorMessage = "Unable to create recognition request"
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            
            if let result = result {
                self.speechText = result.bestTranscription.formattedString
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                if isFinal {
                    self.processSpokenText()
                }
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            isRecording = true
        } catch {
            errorMessage = "Audio engine couldn't start"
        }
    }
    
    private func stopRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        isRecording = false
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
        
        // Common food database (this would be expanded)
        let foodDatabase: [String: (calories: Double, protein: Double, carbs: Double, fat: Double)] = [
            "turkey sandwich": (300, 24, 30, 12),
            "sandwich": (350, 20, 35, 15),
            "chicken": (165, 31, 0, 4),
            "rice": (130, 2.7, 28, 0.3),
            "egg": (155, 13, 1.1, 11),
            "eggs": (155, 13, 1.1, 11),
            "toast": (75, 3, 14, 1),
            "coffee": (5, 0.3, 1, 0),
            "milk": (150, 8, 12, 8),
            "apple": (95, 0.5, 25, 0.3),
            "banana": (105, 1.3, 27, 0.4),
            "salad": (50, 3, 10, 0.5),
            "vegetables": (50, 2, 10, 0.5),
            "burger": (500, 25, 40, 28),
            "pizza": (285, 12, 36, 10),
            "pasta": (220, 8, 43, 1.3)
        ]
        
        // Quantity words
        let quantities = [
            "one": 1, "two": 2, "three": 3, "four": 4, "five": 5,
            "a": 1, "an": 1, "some": 1, "bowl": 1, "cup": 1, "glass": 1,
            "small": 0.75, "large": 1.5, "big": 1.5, "huge": 2
        ]
        
        // Search for food items
        for (food, macros) in foodDatabase {
            if lowercased.contains(food) {
                // Try to find quantity
                var quantity = 1.0
                for (word, multiplier) in quantities {
                    if lowercased.contains(word + " " + food) || 
                       lowercased.contains(word + " of " + food) {
                        quantity = multiplier
                        break
                    }
                }
                
                detectedFoods.append(DetectedFood(
                    name: food.capitalized,
                    quantity: quantity == 1 ? nil : "\(Int(quantity))",
                    calories: macros.calories * quantity,
                    protein: macros.protein * quantity,
                    carbs: macros.carbs * quantity,
                    fat: macros.fat * quantity
                ))
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