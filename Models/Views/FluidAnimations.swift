import SwiftUI

// MARK: - Fluid Animation Utilities
// Liquid motion animations for premium CalTrackPro experience

struct FluidSpring {
    static let gentle = Animation.spring(response: 0.8, dampingFraction: 0.8, blendDuration: 0)
    static let bouncy = Animation.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0)
    static let snappy = Animation.spring(response: 0.4, dampingFraction: 0.9, blendDuration: 0)
    static let smooth = Animation.easeInOut(duration: 0.6)
    static let liquid = Animation.interpolatingSpring(mass: 1, stiffness: 100, damping: 10)
}

struct LiquidPulseEffect: ViewModifier {
    @State private var isPulsing = false
    let color: Color
    let intensity: Double
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Circle()
                    .stroke(color.opacity(isPulsing ? 0.0 : intensity), lineWidth: 2)
                    .scaleEffect(isPulsing ? 2.0 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: false),
                        value: isPulsing
                    )
            )
            .onAppear {
                isPulsing = true
            }
    }
}

struct LiquidMorphingShape: View {
    @State private var morphPhase: Double = 0
    let color: Color
    let size: CGFloat
    
    var body: some View {
        MorphingBlob(phase: morphPhase)
            .fill(
                LinearGradient(
                    colors: [color, color.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 3)
                    .repeatForever(autoreverses: true)
                ) {
                    morphPhase = 1.0
                }
            }
    }
}

struct MorphingBlob: Shape {
    var phase: Double
    
    var animatableData: Double {
        get { phase }
        set { phase = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        var path = Path()
        
        let points = 8
        let angleIncrement = 2 * .pi / Double(points)
        
        for i in 0..<points {
            let angle = Double(i) * angleIncrement
            let radiusVariation = 1.0 + 0.3 * sin(angle * 3 + phase * 2 * .pi)
            let adjustedRadius = radius * radiusVariation
            
            let x = center.x + adjustedRadius * cos(angle)
            let y = center.y + adjustedRadius * sin(angle)
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        path.closeSubpath()
        return path
    }
}

struct FluidDropAnimation: View {
    @State private var dropOffset: CGFloat = -50
    @State private var dropOpacity: Double = 1.0
    @State private var dropScale: CGFloat = 1.0
    
    let color: Color
    let size: CGFloat
    
    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [color, color.opacity(0.7), color.opacity(0.3)],
                    center: .center,
                    startRadius: 0,
                    endRadius: size / 2
                )
            )
            .frame(width: size, height: size)
            .offset(y: dropOffset)
            .opacity(dropOpacity)
            .scaleEffect(dropScale)
            .onAppear {
                animateDrop()
            }
    }
    
    private func animateDrop() {
        withAnimation(.easeIn(duration: 0.8)) {
            dropOffset = 100
        }
        
        withAnimation(.easeOut(duration: 0.3).delay(0.8)) {
            dropOpacity = 0.0
            dropScale = 1.5
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            resetDrop()
        }
    }
    
    private func resetDrop() {
        dropOffset = -50
        dropOpacity = 1.0
        dropScale = 1.0
        animateDrop()
    }
}

struct LiquidButton: View {
    let title: String
    let icon: String?
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var liquidPhase: Double = 0
    
    var body: some View {
        Button(action: {
            withAnimation(FluidSpring.snappy) {
                isPressed = true
            }
            
            withAnimation(FluidSpring.bouncy.delay(0.1)) {
                liquidPhase += 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(FluidSpring.gentle) {
                    isPressed = false
                }
            }
            
            action()
        }) {
            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .background(
                ZStack {
                    // Base liquid background
                    LiquidButtonBackground(color: color, phase: liquidPhase)
                    
                    // Glass overlay
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.4), .white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .shadow(
                color: color.opacity(0.4),
                radius: isPressed ? 8 : 15,
                x: 0,
                y: isPressed ? 4 : 8
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct LiquidButtonBackground: View {
    let color: Color
    let phase: Double
    
    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(
                AngularGradient(
                    colors: [
                        color,
                        color.opacity(0.8),
                        color,
                        color.opacity(0.9),
                        color
                    ],
                    center: .center,
                    angle: .degrees(phase * 180)
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.2), .clear, .white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
    }
}

struct FluidGlowEffect: ViewModifier {
    @State private var glowIntensity: Double = 0.5
    let color: Color
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(glowIntensity), radius: 10)
            .shadow(color: color.opacity(glowIntensity * 0.5), radius: 20)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 2)
                    .repeatForever(autoreverses: true)
                ) {
                    glowIntensity = 1.0
                }
            }
    }
}

struct LiquidProgressIndicator: View {
    let progress: Double
    let color: Color
    let height: CGFloat
    
    @State private var liquidOffset: Double = 0
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(color.opacity(0.2))
                
                // Liquid progress with wave animation
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.8), color],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * animatedProgress)
                    .overlay(
                        WaveShape(offset: liquidOffset, amplitude: 3)
                            .fill(
                                LinearGradient(
                                    colors: [.white.opacity(0.3), .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: geometry.size.width * animatedProgress)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: height / 2))
            }
        }
        .frame(height: height)
        .onAppear {
            withAnimation(FluidSpring.smooth) {
                animatedProgress = min(progress, 1.0)
            }
            
            withAnimation(
                .linear(duration: 2)
                .repeatForever(autoreverses: false)
            ) {
                liquidOffset = 360
            }
        }
        .onChange(of: progress) { oldValue, newValue in
            withAnimation(FluidSpring.gentle) {
                animatedProgress = min(newValue, 1.0)
            }
        }
    }
}

// MARK: - View Extensions
extension View {
    func liquidPulse(color: Color = .blue, intensity: Double = 0.3) -> some View {
        modifier(LiquidPulseEffect(color: color, intensity: intensity))
    }
    
    func fluidGlow(color: Color) -> some View {
        modifier(FluidGlowEffect(color: color))
    }
    
    func liquidTransition() -> some View {
        transition(
            .asymmetric(
                insertion: .scale.combined(with: .opacity).animation(FluidSpring.bouncy),
                removal: .scale.combined(with: .opacity).animation(FluidSpring.gentle)
            )
        )
    }
}

// MARK: - Preview
struct FluidAnimationPreview: View {
    @State private var progress: Double = 0.7
    
    var body: some View {
        VStack(spacing: 30) {
            LiquidMorphingShape(color: .blue, size: 100)
                .liquidPulse(color: .blue)
            
            FluidDropAnimation(color: .green, size: 40)
            
            LiquidButton(
                title: "Liquid Button",
                icon: "drop.fill",
                color: .purple
            ) {
                withAnimation(FluidSpring.bouncy) {
                    progress = Double.random(in: 0.1...1.0)
                }
            }
            .fluidGlow(color: .purple)
            
            LiquidProgressIndicator(
                progress: progress,
                color: .orange,
                height: 20
            )
            .frame(height: 20)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [.black.opacity(0.1), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

#Preview {
    FluidAnimationPreview()
}