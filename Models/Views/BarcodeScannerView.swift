import SwiftUI
import AVFoundation
import Combine
import SwiftData

struct BarcodeScannerView: View {
    @StateObject private var scanner = BarcodeScanner()
    @State private var scannedCode: String?
    @State private var showingProductDetails = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                BarcodeScannerRepresentable(scanner: scanner)
                    .edgesIgnoringSafeArea(.all)
                
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
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Scanning guide
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(style: StrokeStyle(lineWidth: 3, dash: [10, 10]))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(width: 280, height: 150)
                        .overlay(
                            Text("Align barcode within frame")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(8)
                                .offset(y: 100)
                        )
                    
                    Spacer()
                }
            }
            .onChange(of: scanner.scannedCode) { _, code in
                if let code = code {
                    scannedCode = code
                    showingProductDetails = true
                    // Here you would look up the product in a database
                }
            }
            .sheet(isPresented: $showingProductDetails) {
                if let code = scannedCode {
                    EnhancedProductDetailsView(barcode: code)
                }
            }
        }
    }
}

class BarcodeScanner: NSObject, ObservableObject {
    @Published var scannedCode: String?
    @Published var torchIsOn = false
    @Published var hasError = false
    @Published var errorMessage = ""
    
    let captureSession = AVCaptureSession()
    private var videoDevice: AVCaptureDevice?
    
    override init() {
        super.init()
        checkCameraPermissions()
    }
    
    private func checkCameraPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupScanner()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.main.async {
                        self.setupScanner()
                    }
                } else {
                    DispatchQueue.main.async {
                        self.hasError = true
                        self.errorMessage = "Camera access is required to scan barcodes."
                    }
                }
            }
        case .denied, .restricted:
            hasError = true
            errorMessage = "Camera access is required. Please enable it in Settings."
        @unknown default:
            break
        }
    }
    
    private func setupScanner() {
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            hasError = true
            errorMessage = "Unable to access camera."
            return
        }
        
        self.videoDevice = videoCaptureDevice
        
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            hasError = true
            errorMessage = "Unable to initialize camera: \(error.localizedDescription)"
            return
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            hasError = true
            errorMessage = "Unable to add camera input."
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean8, .ean13, .pdf417, .qr, .upce, .code128, .code39, .code93, .itf14]
        } else {
            hasError = true
            errorMessage = "Unable to add metadata output."
            return
        }
    }
    
    func toggleTorch() {
        guard let device = videoDevice, device.hasTorch else { return }
        
        do {
            try device.lockForConfiguration()
            
            if torchIsOn {
                device.torchMode = .off
            } else {
                try device.setTorchModeOn(level: 0.5)
            }
            torchIsOn.toggle()
            
            device.unlockForConfiguration()
        } catch {
            print("Torch could not be toggled: \(error)")
        }
    }
    
    func startScanning() {
        if !captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.startRunning()
            }
        }
    }
    
    func stopScanning() {
        if captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.stopRunning()
            }
        }
    }
}

extension BarcodeScanner: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            scannedCode = stringValue
            stopScanning()
        }
    }
}

struct BarcodeScannerRepresentable: UIViewRepresentable {
    let scanner: BarcodeScanner
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: scanner.captureSession)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        scanner.startScanning()
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

struct ProductDetailsView: View {
    let barcode: String
    @State private var productName = "Product Name"
    @State private var brand = "Brand"
    @State private var calories = 250.0
    @State private var protein = 10.0
    @State private var carbs = 30.0
    @State private var fat = 12.0
    @State private var servingSize = 100.0
    @State private var servingUnit = "g"
    @State private var quantity = 1.0
    @State private var selectedMealType = FoodEntry.MealType.breakfast
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Product Info
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Product Information")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(productName)
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Text(brand)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text("Barcode: \(barcode)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    // Nutrition Info
                    NutritionSummaryCard(
                        calories: calories * quantity,
                        protein: protein * quantity,
                        carbs: carbs * quantity,
                        fat: fat * quantity
                    )
                    .padding(.horizontal)
                    
                    // Quantity Selector
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quantity")
                            .font(.headline)
                        
                        HStack {
                            Button(action: {
                                if quantity > 0.5 {
                                    quantity -= 0.5
                                }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            }
                            
                            Spacer()
                            
                            Text("\(quantity, specifier: "%.1f") servings")
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            Button(action: {
                                quantity += 0.5
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    // Meal Type Selector
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Add to")
                            .font(.headline)
                        
                        Picker("Meal", selection: $selectedMealType) {
                            ForEach(FoodEntry.MealType.allCases, id: \.self) { meal in
                                Text(meal.rawValue).tag(meal)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.horizontal)
                    
                    // Action Buttons
                    HStack(spacing: 16) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                        
                        Button("Add to Diary") {
                            saveEntry()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding()
                }
            }
            .navigationTitle("Scanned Product")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            // Here you would fetch product details from a database using the barcode
            // For demo purposes, we're using mock data
            loadProductDetails()
        }
    }
    
    private func loadProductDetails() {
        // Mock data - in real app, fetch from API
        productName = "Greek Yogurt"
        brand = "Healthy Choice"
        calories = 150
        protein = 15
        carbs = 12
        fat = 5
        servingSize = 170
        servingUnit = "g"
    }
    
    private func saveEntry() {
        let entry = FoodEntry(
            name: productName,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            servingSize: servingSize,
            servingUnit: servingUnit,
            quantity: quantity * servingSize,
            mealType: selectedMealType
        )
        
        entry.brand = brand
        entry.barcode = barcode
        
        modelContext.insert(entry)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving entry: \(error)")
        }
    }
}