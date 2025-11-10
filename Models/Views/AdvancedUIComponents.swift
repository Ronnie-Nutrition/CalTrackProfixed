import SwiftUI

// MARK: - Advanced UI Components
// Enhanced micro-interactions and advanced animations for CalTrackPro

// MARK: - Morphing Button
struct MorphingButton: View {
    let text: String
    let icon: String
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var morphOffset: CGFloat = 0
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: {
            AppHaptics.medium()
            
            withAnimation(AppAnimations.bouncy) {
                isPressed = true
                morphOffset = 10
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(AppAnimations.spring) {
                    isPressed = false
                    morphOffset = 0
                }
                action()
            }
        }) {
            ZStack {
                // Background morphing shape
                RoundedRectangle(cornerRadius: isPressed ? 25 : 15)
                    .fill(
                        LinearGradient(
                            colors: [
                                themeManager.currentAccentColor.opacity(0.8),
                                themeManager.currentAccentColor
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: isPressed ? 25 : 15)
                            .fill(themeManager.isDarkMode ? AppColors.darkGlassGradient : AppColors.glassGradient)
                    )
                    .scaleEffect(isPressed ? 0.95 : 1.0)
                    .offset(y: morphOffset)
                
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: icon)
                        .font(AppFonts.subheadline(.semibold))
                        .foregroundColor(.white)
                        .scaleEffect(isPressed ? 1.2 : 1.0)
                        .rotationEffect(.degrees(isPressed ? 360 : 0))
                    
                    Text(text)
                        .font(AppFonts.subheadline(.semibold))
                        .foregroundColor(.white)
                        .scaleEffect(isPressed ? 1.05 : 1.0)
                }
                .offset(y: morphOffset / 2)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)
        }
        .buttonStyle(PlainButtonStyle())
        .shadow(
            color: themeManager.currentAccentColor.opacity(0.3),
            radius: isPressed ? 15 : 10,
            x: 0,
            y: isPressed ? 8 : 5
        )
    }
}

// MARK: - Floating Action Button
struct FloatingActionButton: View {
    let icon: String
    let action: () -> Void
    
    @State private var isHovered = false
    @State private var rotationAngle: Double = 0
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: {
            AppHaptics.light()
            withAnimation(AppAnimations.bouncy) {
                rotationAngle += 360
            }
            action()
        }) {
            ZStack {
                Circle()
                    .fill(themeManager.currentAccentColor)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Circle()
                            .fill(themeManager.isDarkMode ? AppColors.darkGlassGradient : AppColors.glassGradient)
                    )
                    .scaleEffect(isHovered ? 1.1 : 1.0)
                
                Image(systemName: icon)
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(rotationAngle))
            }
        }
        .buttonStyle(PlainButtonStyle())
        .shadow(
            color: themeManager.currentAccentColor.opacity(0.4),
            radius: isHovered ? 20 : 15,
            x: 0,
            y: isHovered ? 10 : 8
        )
        .animation(AppAnimations.spring, value: isHovered)
        .animation(AppAnimations.bouncy, value: rotationAngle)
        .onHover { hovering in
            isHovered = hovering
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isHovered = true }
                .onEnded { _ in isHovered = false }
        )
    }
}

// MARK: - Parallax Card
struct ParallaxCard<Content: View>: View {
    let content: Content
    @State private var offset: CGSize = .zero
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        GeometryReader { geometry in
            LiquidGlassCard {
                content
                    .offset(offset)
            }
            .rotation3DEffect(
                .degrees(Double(offset.width) / 20),
                axis: (x: 0, y: 1, z: 0)
            )
            .rotation3DEffect(
                .degrees(Double(-offset.height) / 20),
                axis: (x: 1, y: 0, z: 0)
            )
            .gesture(
                DragGesture()
                    .onChanged { value in
                        withAnimation(AppAnimations.smooth) {
                            offset = CGSize(
                                width: max(-20, min(20, value.translation.x / 10)),
                                height: max(-20, min(20, value.translation.y / 10))
                            )
                        }
                    }
                    .onEnded { _ in
                        withAnimation(AppAnimations.spring) {
                            offset = .zero
                        }
                    }
            )
        }
    }
}

// MARK: - Breathing Orb
struct BreathingOrb: View {
    let color: Color
    let size: CGFloat
    
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 0.7
    
    var body: some View {
        ZStack {
            ForEach(0..<3) { index in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                color.opacity(0.3),
                                color.opacity(0.1),
                                .clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: size / 2
                        )
                    )
                    .frame(width: size, height: size)
                    .scaleEffect(scale * (1.0 + Double(index) * 0.1))
                    .opacity(opacity * (1.0 - Double(index) * 0.2))
            }
        }
        .onAppear {
            withAnimation(
                AppAnimations.wave.repeatForever(autoreverses: true)
            ) {
                scale = 1.3
                opacity = 0.3
            }
        }
    }
}

// MARK: - Magnetic Button
struct MagneticButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    
    @State private var magnetOffset: CGSize = .zero
    @State private var isAttracted = false
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: {
            AppHaptics.selection()
            action()
        }) {
            HStack(spacing: AppSpacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(AppFonts.subheadline(.medium))
                }
                
                Text(title)
                    .font(AppFonts.subheadline(.medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(
                ZStack {
                    Capsule()
                        .fill(themeManager.currentAccentColor)
                    
                    Capsule()
                        .fill(themeManager.isDarkMode ? AppColors.darkGlassGradient : AppColors.glassGradient)
                }
            )
            .scaleEffect(isAttracted ? 1.05 : 1.0)
            .offset(magnetOffset)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(AppAnimations.spring, value: magnetOffset)
        .animation(AppAnimations.bouncy, value: isAttracted)
        .gesture(
            DragGesture(coordinateSpace: .local)
                .onChanged { value in
                    let distance = sqrt(pow(value.translation.x, 2) + pow(value.translation.y, 2))
                    
                    if distance < 50 {
                        let magnetStrength = max(0, 50 - distance) / 50
                        withAnimation(AppAnimations.spring) {
                            magnetOffset = CGSize(
                                width: -value.translation.x * magnetStrength * 0.3,
                                height: -value.translation.y * magnetStrength * 0.3
                            )
                            isAttracted = magnetStrength > 0.3
                        }
                    }
                }
                .onEnded { _ in
                    withAnimation(AppAnimations.spring) {
                        magnetOffset = .zero
                        isAttracted = false
                    }
                }
        )
    }
}

// MARK: - Ripple Effect
struct RippleEffect: ViewModifier {
    @State private var ripples: [RippleData] = []
    
    struct RippleData: Identifiable {
        let id = UUID()
        let position: CGPoint
        let startTime: Date
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(
                ZStack {
                    ForEach(ripples) { ripple in
                        RippleView(ripple: ripple)
                    }
                }
                .allowsHitTesting(false)
            )
            .onTapGesture { location in
                addRipple(at: location)
            }
    }
    
    private func addRipple(at location: CGPoint) {
        let newRipple = RippleData(position: location, startTime: Date())
        ripples.append(newRipple)
        
        // Remove ripple after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            ripples.removeAll { $0.id == newRipple.id }
        }
    }
}

struct RippleView: View {
    let ripple: RippleEffect.RippleData
    @State private var scale: CGFloat = 0
    @State private var opacity: Double = 0.7
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Circle()
            .stroke(themeManager.currentAccentColor, lineWidth: 2)
            .frame(width: 100, height: 100)
            .scaleEffect(scale)
            .opacity(opacity)
            .position(ripple.position)
            .onAppear {
                withAnimation(.easeOut(duration: 1.0)) {
                    scale = 1.0
                    opacity = 0.0
                }
            }
    }
}

// MARK: - Elastic Progress Bar
struct ElasticProgressBar: View {
    let progress: Double
    let height: CGFloat
    let color: Color
    
    @State private var animatedProgress: Double = 0
    @State private var elasticOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                Capsule()
                    .fill(color.opacity(0.2))
                    .frame(height: height)
                
                // Progress with elastic animation
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.8), color, color.opacity(0.9)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(
                        width: geometry.size.width * animatedProgress + elasticOffset,
                        height: height
                    )
                    .animation(AppAnimations.spring, value: animatedProgress)
                
                // Elastic overlay
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.4), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(
                        width: geometry.size.width * animatedProgress + elasticOffset,
                        height: height * 0.6
                    )
                    .offset(y: -height * 0.1)
            }
        }
        .frame(height: height)
        .onAppear {
            withAnimation(AppAnimations.spring.delay(0.2)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            // Elastic effect on change
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                elasticOffset = 15
                animatedProgress = newValue
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(AppAnimations.spring) {
                    elasticOffset = 0
                }
            }
        }
    }
}

// MARK: - Morphing Icon
struct MorphingIcon: View {
    let icons: [String]
    let currentIndex: Int
    let size: CGFloat
    
    @State private var rotationAngle: Double = 0
    @State private var scale: CGFloat = 1.0
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var currentIcon: String {
        icons[currentIndex % icons.count]
    }
    
    var body: some View {
        Image(systemName: currentIcon)
            .font(.system(size: size))
            .foregroundColor(themeManager.currentAccentColor)
            .rotationEffect(.degrees(rotationAngle))
            .scaleEffect(scale)
            .animation(AppAnimations.bouncy, value: rotationAngle)
            .animation(AppAnimations.spring, value: scale)
            .onChange(of: currentIndex) { _, _ in
                morphIcon()
            }
    }
    
    private func morphIcon() {
        withAnimation(AppAnimations.bouncy) {
            rotationAngle += 360
            scale = 1.2
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(AppAnimations.spring) {
                scale = 1.0
            }
        }
    }
}

// MARK: - View Extensions for Advanced UI
extension View {
    func rippleEffect() -> some View {
        modifier(RippleEffect())
    }
    
    func elasticScale(trigger: Bool) -> some View {
        scaleEffect(trigger ? 1.1 : 1.0)
            .animation(AppAnimations.bouncy, value: trigger)
    }
    
    func magneticHover() -> some View {
        modifier(MagneticHoverEffect())
    }
    
    func breathingPulse(color: Color = .blue) -> some View {
        background(
            BreathingOrb(color: color, size: 100)
                .blur(radius: 20)
        )
    }
}

// MARK: - Magnetic Hover Effect
struct MagneticHoverEffect: ViewModifier {
    @State private var offset: CGSize = .zero
    @State private var scale: CGFloat = 1.0
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .offset(offset)
            .gesture(
                DragGesture(coordinateSpace: .local)
                    .onChanged { value in
                        let distance = sqrt(pow(value.translation.x, 2) + pow(value.translation.y, 2))
                        
                        if distance < 30 {
                            let attraction = (30 - distance) / 30
                            withAnimation(AppAnimations.spring) {
                                offset = CGSize(
                                    width: value.translation.x * attraction * 0.2,
                                    height: value.translation.y * attraction * 0.2
                                )
                                scale = 1.0 + attraction * 0.1
                            }
                        }
                    }
                    .onEnded { _ in
                        withAnimation(AppAnimations.spring) {
                            offset = .zero
                            scale = 1.0
                        }
                    }
            )
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        GlassmorphismBackground(colors: [.blue, .purple, .pink])
        
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                Text("Advanced UI Components")
                    .font(AppFonts.title(.bold))
                    .foregroundColor(AppColors.primaryText)
                
                MorphingButton(
                    text: "Morphing Button",
                    icon: "star.fill"
                ) {
                    print("Morphing button tapped")
                }
                
                HStack {
                    FloatingActionButton(icon: "plus") {
                        print("FAB tapped")
                    }
                    
                    MorphingIcon(
                        icons: ["heart", "heart.fill", "star", "star.fill"],
                        currentIndex: 0,
                        size: 30
                    )
                }
                
                ParallaxCard {
                    VStack {
                        Text("Parallax Card")
                            .font(AppFonts.headline(.semibold))
                            .foregroundColor(AppColors.primaryText)
                        
                        Text("Drag me around!")
                            .font(AppFonts.subheadline())
                            .foregroundColor(AppColors.secondaryText)
                    }
                    .padding()
                }
                .frame(height: 120)
                
                ElasticProgressBar(
                    progress: 0.65,
                    height: 12,
                    color: .green
                )
                
                MagneticButton(
                    title: "Magnetic Button",
                    icon: "magnet"
                ) {
                    print("Magnetic button tapped")
                }
                
                Rectangle()
                    .fill(.clear)
                    .frame(height: 100)
                    .overlay(
                        Text("Tap for Ripple Effect")
                            .font(AppFonts.subheadline())
                            .foregroundColor(AppColors.primaryText)
                    )
                    .rippleEffect()
                
                Text("Breathing Pulse Example")
                    .font(AppFonts.subheadline())
                    .foregroundColor(AppColors.primaryText)
                    .breathingPulse(color: .purple)
                    .padding()
                
                Text("Hover Effect")
                    .font(AppFonts.subheadline())
                    .foregroundColor(AppColors.primaryText)
                    .padding()
                    .background(.regularMaterial)
                    .cornerRadius(AppSpacing.radiusMedium)
                    .magneticHover()
            }
            .padding(AppSpacing.lg)
        }
    }
    .applyAdaptiveTheme()
}