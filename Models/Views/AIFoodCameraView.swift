import SwiftUI
import AVFoundation

struct AIFoodCameraView: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.cameraDevice = .rear
        picker.cameraFlashMode = .auto
        picker.allowsEditing = false
        
        // Configure camera overlay
        picker.cameraOverlayView = createCameraOverlay()
        picker.showsCameraControls = true
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func createCameraOverlay() -> UIView {
        let screenBounds = UIScreen.main.bounds
        let overlayView = UIView(frame: screenBounds)
        overlayView.backgroundColor = .clear
        overlayView.isUserInteractionEnabled = false

        // Add food detection guide with absolute positioning
        let guideLabel = UILabel()
        guideLabel.text = "Position food in frame"
        guideLabel.textColor = .white
        guideLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        guideLabel.textAlignment = .center
        guideLabel.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        guideLabel.layer.cornerRadius = 12
        guideLabel.clipsToBounds = true
        guideLabel.numberOfLines = 1

        // Use absolute frame positioning to avoid safe area issues
        let labelWidth: CGFloat = 240
        let labelHeight: CGFloat = 44
        let labelX = (screenBounds.width - labelWidth) / 2
        let labelY: CGFloat = 60  // Fixed position from top

        guideLabel.frame = CGRect(x: labelX, y: labelY, width: labelWidth, height: labelHeight)
        overlayView.addSubview(guideLabel)

        return overlayView
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: AIFoodCameraView
        
        init(_ parent: AIFoodCameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.capturedImage = image
            }
            parent.isPresented = false
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }
}

// MARK: - Photo Library Picker

struct PhotoLibraryPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = false
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: PhotoLibraryPicker
        
        init(_ parent: PhotoLibraryPicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.isPresented = false
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }
}

// MARK: - Camera Permission View

struct CameraPermissionView: View {
    @StateObject private var permissionManager = CameraPermissionManager()
    let onPermissionGranted: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            GlassmorphismBackground(colors: [.blue, .purple, .indigo])
            
            VStack(spacing: 24) {
                // Icon
                Image(systemName: "camera.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                VStack(spacing: 12) {
                    Text("Camera Access Required")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("CalTrackPro needs camera access to identify food from photos and automatically log nutrition information.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                VStack(spacing: 16) {
                    Button("Enable Camera Access") {
                        Task {
                            await permissionManager.requestCameraPermission()
                            if permissionManager.permissionStatus == .authorized {
                                onPermissionGranted()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .shadow(color: .blue.opacity(0.3), radius: 10)
                    
                    if permissionManager.permissionStatus == .denied {
                        VStack(spacing: 8) {
                            Text("Camera access was denied")
                                .font(.subheadline)
                                .foregroundColor(.red)
                            
                            Button("Open Settings") {
                                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(settingsURL)
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                    }
                    
                    Button("Cancel") {
                        onDismiss()
                    }
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal, 24)
            }
            .padding()
        }
        .onAppear {
            permissionManager.checkCameraPermission()
        }
    }
}