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
        let overlayView = UIView()
        overlayView.backgroundColor = .clear
        
        // Add food detection guide
        let guideLabel = UILabel()
        guideLabel.text = "Center food in frame"
        guideLabel.textColor = .white
        guideLabel.font = .systemFont(ofSize: 16, weight: .medium)
        guideLabel.textAlignment = .center
        guideLabel.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        guideLabel.layer.cornerRadius = 8
        guideLabel.clipsToBounds = true
        
        overlayView.addSubview(guideLabel)
        guideLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            guideLabel.topAnchor.constraint(equalTo: overlayView.safeAreaLayoutGuide.topAnchor, constant: 20),
            guideLabel.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            guideLabel.widthAnchor.constraint(equalToConstant: 200),
            guideLabel.heightAnchor.constraint(equalToConstant: 40)
        ])
        
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