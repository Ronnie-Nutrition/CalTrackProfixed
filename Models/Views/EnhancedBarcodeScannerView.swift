import SwiftUI
import AVFoundation
import Combine
import SwiftData

struct EnhancedBarcodeScannerView: View {
    @StateObject private var scanner = EnhancedBarcodeScanner()
    @State private var scannedCode: String?
    @State private var showingProductDetails = false
    @State private var isProcessing = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                if scanner.hasError {
                    // Error View
                    VStack(spacing: 20) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("Camera Access Required")
                            .font(.title2)
                            .bold()
                        
                        Text(scanner.errorMessage)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        Button("Open Settings") {
                            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(settingsUrl)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("Cancel") {
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                } else {
                    // Camera View
                    BarcodeScannerRepresentable(scanner: scanner)
                        .edgesIgnoringSafeArea(.all)
                        .onAppear {
                            scanner.startScanning()
                        }
                        .onDisappear {
                            scanner.stopScanning()
                        }
                    
                    // Overlay UI
                    VStack {
                        // Top Bar
                        HStack {
                            Button(action: { dismiss() }) {
                                Image(systemName: "xmark")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(Circle().fill(.black.opacity(0.6)))
                            }
                            
                            Spacer()
                            
                            // Torch Toggle
                            Button(action: { scanner.toggleTorch() }) {
                                Image(systemName: scanner.torchIsOn ? "flashlight.on.fill" : "flashlight.off.fill")
                                    .font(.title2)
                                    .foregroundColor(scanner.torchIsOn ? .yellow : .white)
                                    .frame(width: 44, height: 44)
                                    .background(Circle().fill(.black.opacity(0.6)))
                            }
                        }
                        .padding()
                        
                        Spacer()
                        
                        // Scanner Frame
                        VStack(spacing: 20) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(isProcessing ? Color.green : Color.yellow, lineWidth: 3)
                                    .frame(width: 280, height: 150)
                                    .animation(.easeInOut(duration: 0.3), value: isProcessing)
                                
                                if isProcessing {
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.green.opacity(0.2))
                                        .frame(width: 280, height: 150)
                                        .animation(.easeInOut(duration: 0.3), value: isProcessing)
                                }
                                
                                // Scanning line animation
                                if !isProcessing {
                                    Rectangle()
                                        .fill(Color.red)
                                        .frame(width: 250, height: 2)
                                        .offset(y: scanner.scanLineOffset)
                                        .animation(
                                            Animation.linear(duration: 2)
                                                .repeatForever(autoreverses: true),
                                            value: scanner.scanLineOffset
                                        )
                                        .onAppear {
                                            scanner.startScanAnimation()
                                        }
                                }
                            }
                            
                            // Instructions
                            VStack(spacing: 8) {
                                if isProcessing {
                                    HStack {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        Text("Processing...")
                                            .foregroundColor(.white)
                                    }
                                    .padding()
                                    .background(Capsule().fill(.green))
                                } else {
                                    Text("Position barcode within frame")
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 10)
                                        .background(Capsule().fill(.black.opacity(0.6)))
                                    
                                    Text("Supports: UPC, EAN, QR Codes")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                        }
                        .padding(.bottom, 100)
                        
                        Spacer()
                    }
                }
            }
            .onChange(of: scanner.scannedCode) { _, code in
                if let code = code, !isProcessing {
                    isProcessing = true
                    scannedCode = code
                    
                    // Haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    
                    // Delay to show success animation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showingProductDetails = true
                        isProcessing = false
                        scanner.scannedCode = nil // Reset for next scan
                    }
                }
            }
            .sheet(isPresented: $showingProductDetails) {
                if let code = scannedCode {
                    EnhancedProductDetailsView(barcode: code)
                        .onDisappear {
                            scannedCode = nil
                            scanner.startScanning()
                        }
                }
            }
        }
    }
}

class EnhancedBarcodeScanner: BarcodeScanner {
    @Published var scanLineOffset: CGFloat = -70
    
    func startScanAnimation() {
        scanLineOffset = 70
    }
}

#Preview {
    EnhancedBarcodeScannerView()
}