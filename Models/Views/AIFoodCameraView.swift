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
            // Dismiss immediately for better UX
            parent.isPresented = false

            // Process image in background to avoid UI freeze
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }

                if let originalImage = info[.originalImage] as? UIImage {
                    // Resize image to max 1200px for faster processing
                    // This dramatically reduces the 20-30 second delay
                    let resizedImage = self.resizeImageForRecognition(originalImage, maxDimension: 1200)

                    DispatchQueue.main.async {
                        self.parent.capturedImage = resizedImage
                    }
                }
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }

        /// Resizes image to a maximum dimension while maintaining aspect ratio
        /// This prevents the 20-30 second delay caused by processing full-resolution camera images
        private func resizeImageForRecognition(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
            let size = image.size

            // If image is already small enough, return as-is
            if size.width <= maxDimension && size.height <= maxDimension {
                return image
            }

            // Calculate new size maintaining aspect ratio
            let aspectRatio = size.width / size.height
            var newSize: CGSize

            if size.width > size.height {
                newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
            } else {
                newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
            }

            // Use UIGraphicsImageRenderer for efficient resizing
            let renderer = UIGraphicsImageRenderer(size: newSize)
            let resizedImage = renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: newSize))
            }

            return resizedImage
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
            // Dismiss immediately for better UX
            parent.isPresented = false

            // Process image in background to avoid UI freeze
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }

                if let originalImage = info[.originalImage] as? UIImage {
                    // Resize image to max 1200px for faster processing
                    let resizedImage = self.resizeImageForRecognition(originalImage, maxDimension: 1200)

                    DispatchQueue.main.async {
                        self.parent.selectedImage = resizedImage
                    }
                }
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }

        /// Resizes image to a maximum dimension while maintaining aspect ratio
        private func resizeImageForRecognition(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
            let size = image.size

            if size.width <= maxDimension && size.height <= maxDimension {
                return image
            }

            let aspectRatio = size.width / size.height
            var newSize: CGSize

            if size.width > size.height {
                newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
            } else {
                newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
            }

            let renderer = UIGraphicsImageRenderer(size: newSize)
            return renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: newSize))
            }
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
                    Button("Continue") {
                        Task {
                            await permissionManager.requestCameraPermission()
                            if permissionManager.permissionStatus == .authorized {
                                onPermissionGranted()
                            } else if permissionManager.permissionStatus == .denied {
                                // Permission denied - user can go to Settings
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
                            Text("Camera access was denied. You can enable it in Settings.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)

                            Button("Open Settings") {
                                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(settingsURL)
                                }
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        }
                    }
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