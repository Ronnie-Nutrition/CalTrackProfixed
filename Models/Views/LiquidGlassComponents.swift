import SwiftUI

// MARK: - Liquid Glass Components
// Premium glassmorphism effects for CalTrackPro using native iOS APIs

struct LiquidGlassCard<Content: View>: View {
    let content: Content
    var blur: CGFloat = 10
    var opacity: Double = 0.1
    
    init(blur: CGFloat = 10, opacity: Double = 0.1, @ViewBuilder content: () -> Content) {
        self.blur = blur
        self.opacity = opacity
        self.content = content()
    }
    
    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.3), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

struct LiquidGlassButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isPressed = false
                }
            }
            action()
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.regularMaterial)
                    
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [color.opacity(0.6), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                }
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .shadow(color: color.opacity(0.3), radius: isPressed ? 5 : 10, x: 0, y: isPressed ? 2 : 5)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct LiquidProgressRing: View {
    let progress: Double
    let total: Double
    let color: Color
    let size: CGFloat
    let lineWidth: CGFloat
    
    @State private var animatedProgress: Double = 0
    
    private var progressValue: Double {
        min(progress / total, 1.0)
    }
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(
                    color.opacity(0.2),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
            
            // Liquid glass progress ring
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        colors: [
                            color.opacity(0.3),
                            color,
                            color.opacity(0.8),
                            color.opacity(0.3)
                        ],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .shadow(color: color.opacity(0.5), radius: 3)
            
            // Liquid glass overlay
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.6), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5)) {
                animatedProgress = progressValue
            }
        }
        .onChange(of: progressValue) { oldValue, newValue in
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                animatedProgress = newValue
            }
        }
    }
}

struct LiquidWaveAnimation: View {
    @State private var waveOffset1 = 0.0
    @State private var waveOffset2 = 0.0
    
    let height: CGFloat
    let color: Color
    
    var body: some View {
        ZStack {
            WaveShape(offset: waveOffset1, amplitude: 8)
                .fill(
                    LinearGradient(
                        colors: [color.opacity(0.3), color.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: height)
            
            WaveShape(offset: waveOffset2, amplitude: 6)
                .fill(
                    LinearGradient(
                        colors: [color.opacity(0.2), color.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: height)
        }
        .onAppear {
            withAnimation(
                .linear(duration: 3)
                .repeatForever(autoreverses: false)
            ) {
                waveOffset1 = 360
            }
            
            withAnimation(
                .linear(duration: 2.5)
                .repeatForever(autoreverses: false)
            ) {
                waveOffset2 = -360
            }
        }
    }
}

struct WaveShape: Shape {
    var offset: Double
    var amplitude: Double
    
    var animatableData: Double {
        get { offset }
        set { offset = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        let wavelength = width / 2
        
        path.move(to: CGPoint(x: 0, y: height))
        
        for x in stride(from: 0, through: width, by: 1) {
            let relativeX = x / wavelength
            let sine = sin(relativeX * .pi + offset * .pi / 180)
            let y = amplitude * sine + height / 2
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        
        return path
    }
}

struct GlassmorphismBackground: View {
    let colors: [Color]
    
    var body: some View {
        ZStack {
            // Animated background gradients
            ForEach(0..<colors.count, id: \.self) { index in
                AnimatedGradientBlob(
                    color: colors[index],
                    size: CGFloat.random(in: 200...400),
                    offset: CGSize(
                        width: CGFloat.random(in: -100...100),
                        height: CGFloat.random(in: -100...100)
                    ),
                    animationDelay: Double(index) * 0.5
                )
            }
        }
        .background(.ultraThinMaterial)
        .ignoresSafeArea()
    }
}

struct AnimatedGradientBlob: View {
    let color: Color
    let size: CGFloat
    @State private var offset: CGSize
    let animationDelay: Double
    
    @State private var animatedOffset: CGSize
    
    init(color: Color, size: CGFloat, offset: CGSize, animationDelay: Double) {
        self.color = color
        self.size = size
        self.offset = offset
        self.animationDelay = animationDelay
        self._animatedOffset = State(initialValue: offset)
    }
    
    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [color.opacity(0.3), color.opacity(0.1), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: size / 2
                )
            )
            .frame(width: size, height: size)
            .blur(radius: 30)
            .offset(animatedOffset)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 4)
                    .repeatForever(autoreverses: true)
                    .delay(animationDelay)
                ) {
                    animatedOffset = CGSize(
                        width: offset.width + CGFloat.random(in: -50...50),
                        height: offset.height + CGFloat.random(in: -50...50)
                    )
                }
            }
    }
}

// MARK: - Preview Helpers
struct LiquidGlassPreview: View {
    var body: some View {
        ZStack {
            GlassmorphismBackground(colors: [.blue, .purple, .pink])
            
            VStack(spacing: 20) {
                LiquidGlassCard {
                    VStack {
                        Text("Liquid Glass Card")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Premium glassmorphism effect")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(20)
                }
                
                LiquidProgressRing(
                    progress: 850,
                    total: 2000,
                    color: .blue,
                    size: 120,
                    lineWidth: 12
                )
                
                LiquidGlassButton(
                    title: "Premium Feature",
                    icon: "star.fill",
                    color: .orange
                ) {
                    // Action
                }
            }
            .padding()
        }
    }
}

#Preview {
    LiquidGlassPreview()
}