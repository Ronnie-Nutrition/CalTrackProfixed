import SwiftUI
import AVFoundation
import Vision
import CoreML
import Combine

struct CameraView: View {
    @Binding var selectedMealType: FoodEntry.MealType
    @StateObject private var camera = CameraViewModel()
    @State private var showingFoodDetails = false
    @State private var detectedFood: DetectedFood?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Camera Preview
                CameraPreview(camera: camera)
                    .edgesIgnoringSafeArea(.all)
                
                // Overlay
                VStack {
                    HStack {
                        Button("Cancel") {
                            dismiss()
                        }
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        
                        Spacer()
                        
                        Picker("Meal", selection: $selectedMealType) {
                            ForEach(FoodEntry.MealType.allCases, id: \.self) { meal in
                                Text(meal.rawValue).tag(meal)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Detection Guide
                    VStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(style: StrokeStyle(lineWidth: 3, dash: [10, 10]))
                            .foregroundColor(.white.opacity(0.8))
                            .frame(width: 300, height: 300)
                            .overlay(
                                Text("Position food within frame")
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.black.opacity(0.6))
                                    .cornerRadius(8)
                                    .padding(.top, 250)
                            )
                    }
                    
                    Spacer()
                    
                    // Capture Button
                    Button(action: {
                        camera.capturePhoto()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 70, height: 70)
                            
                            Circle()
                                .stroke(Color.white, lineWidth: 3)
                                .frame(width: 80, height: 80)
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
            .onAppear {
                camera.checkPermissions()
            }
            .onChange(of: camera.capturedImage) { image in
                if let image = image {
                    analyzeFood(image: image)
                }
            }
            .sheet(item: $detectedFood) { food in
                FoodDetailsView(detectedFood: food, mealType: selectedMealType)
            }
        }
    }
    
    private func analyzeFood(image: UIImage) {
        // Here we would use Core ML or Vision API to analyze the food
        // For now, we'll simulate the detection
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            detectedFood = DetectedFood(
                name: "Grilled Chicken Salad",
                confidence: 0.92,
                calories: 320,
                protein: 35,
                carbs: 12,
                fat: 15,
                servingSize: 250,
                servingUnit: "g",
                alternatives: [
                    DetectedFood(name: "Caesar Salad", confidence: 0.78, calories: 450, 
                               protein: 20, carbs: 20, fat: 35, servingSize: 300, servingUnit: "g", alternatives: [], image: image),
                    DetectedFood(name: "Greek Salad", confidence: 0.65, calories: 280, 
                               protein: 15, carbs: 18, fat: 20, servingSize: 280, servingUnit: "g", alternatives: [], image: image)
                ],
                image: image
            )
        }
    }
}

struct DetectedFood: Identifiable {
    let id = UUID()
    let name: String
    let confidence: Double
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let servingSize: Double
    let servingUnit: String
    var alternatives: [DetectedFood] = []
    let image: UIImage?
}

class CameraViewModel: NSObject, ObservableObject {
    @Published var session = AVCaptureSession()
    @Published var preview = AVCaptureVideoPreviewLayer()
    @Published var capturedImage: UIImage?
    
    private let output = AVCapturePhotoOutput()
    
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setUp()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.main.async {
                        self.setUp()
                    }
                }
            }
        default:
            break
        }
    }
    
    private func setUp() {
        do {
            session.beginConfiguration()
            
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else { return }
            
            let input = try AVCaptureDeviceInput(device: device)
            
            if session.canAddInput(input) {
                session.addInput(input)
            }
            
            if session.canAddOutput(output) {
                session.addOutput(output)
            }
            
            session.commitConfiguration()
            
            DispatchQueue.global(qos: .background).async {
                self.session.startRunning()
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .auto
        
        output.capturePhoto(with: settings, delegate: self)
    }
}

extension CameraViewModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else { return }
        
        DispatchQueue.main.async {
            self.capturedImage = image
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    @ObservedObject var camera: CameraViewModel
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        
        camera.preview = AVCaptureVideoPreviewLayer(session: camera.session)
        camera.preview.frame = view.frame
        camera.preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(camera.preview)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}