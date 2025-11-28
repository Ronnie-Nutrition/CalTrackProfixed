import SwiftUI

// MARK: - Liquid Glass Components
// Premium glassmorphism effects for CalTrackPro with adaptive dark mode support

struct LiquidGlassCard<Content: View>: View {
    let content: Content
    var blur: CGFloat = 10
    var opacity: Double = 0.1
    var cornerRadius: CGFloat = 20
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) private var colorScheme
    
    init(blur: CGFloat = 10, opacity: Double = 0.1, cornerRadius: CGFloat = 20, @ViewBuilder content: () -> Content) {
        self.blur = blur
        self.opacity = opacity
        self.cornerRadius = cornerRadius
        self.content = content()
    }
    
    private var adaptiveBorderGradient: LinearGradient {
        if themeManager.isDarkMode || colorScheme == .dark {
            return LinearGradient(
                colors: [.white.opacity(0.15), .white.opacity(0.05), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [.white.opacity(0.4), .white.opacity(0.1), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var adaptiveBackground: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(.regularMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(themeManager.isDarkMode ? AppColors.darkGlassGradient : AppColors.glassGradient)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(adaptiveBorderGradient, lineWidth: 1)
            )
    }
    
    var body: some View {
        content
            .background(adaptiveBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(
                color: themeManager.isDarkMode ? .black.opacity(0.3) : .black.opacity(0.1),
                radius: 10,
                x: 0,
                y: 5
            )
    }
}

// MARK: - Liquid Progress Indicator
struct LiquidProgressIndicator: View {
    let progress: Double
    let color: Color
    let height: CGFloat
    
    @State private var animatedProgress: Double = 0
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) private var colorScheme
    
    private var adaptiveOverlayGradient: LinearGradient {
        if themeManager.isDarkMode || colorScheme == .dark {
            return LinearGradient(
                colors: [.white.opacity(0.2), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            return LinearGradient(
                colors: [.white.opacity(0.5), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    private var backgroundOpacity: Double {
        themeManager.isDarkMode || colorScheme == .dark ? 0.15 : 0.1
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(color.opacity(backgroundOpacity))
                    .frame(width: geometry.size.width)
                
                // Progress bar
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(
                        LinearGradient(
                            colors: [
                                color.opacity(0.9),
                                themeManager.currentAccentColor,
                                color.opacity(0.7)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * min(animatedProgress, 1.0))
                    .shadow(
                        color: color.opacity(themeManager.isDarkMode ? 0.4 : 0.3),
                        radius: themeManager.isDarkMode ? 3 : 2
                    )
                
                // Adaptive liquid glass overlay
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(adaptiveOverlayGradient)
                    .frame(width: geometry.size.width * min(animatedProgress, 1.0))
                    .frame(height: height * 0.6)
                    .offset(y: -height * 0.1)
            }
        }
        .frame(height: height)
        .onAppear {
            withAnimation(AppAnimations.smooth) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { oldValue, newValue in
            withAnimation(AppAnimations.spring) {
                animatedProgress = newValue
            }
        }
    }
}

struct LiquidGlassButton: View {
    let title: String
    let icon: String?
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) private var colorScheme
    
    private var adaptiveBorderGradient: LinearGradient {
        if themeManager.isDarkMode || colorScheme == .dark {
            return LinearGradient(
                colors: [color.opacity(0.4), color.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [color.opacity(0.6), color.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var adaptiveIconGradient: LinearGradient {
        LinearGradient(
            colors: [themeManager.currentAccentColor, color.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var body: some View {
        Button(action: {
            // Haptic feedback
            AppHaptics.light()
            
            withAnimation(AppAnimations.buttonPress) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(AppAnimations.buttonPress) {
                    isPressed = false
                }
            }
            
            action()
        }) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(AppFonts.caption(weight: .medium))
                        .foregroundStyle(adaptiveIconGradient)
                }
                
                Text(title)
                    .font(AppFonts.caption(weight: .medium))
                    .foregroundColor(AppColors.primaryText)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: AppSpacing.radiusMedium)
                        .fill(.regularMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppSpacing.radiusMedium)
                                .fill(themeManager.isDarkMode ? AppColors.darkGlassGradient : AppColors.glassGradient)
                        )
                    
                    RoundedRectangle(cornerRadius: AppSpacing.radiusMedium)
                        .stroke(adaptiveBorderGradient, lineWidth: 1)
                }
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .shadow(
                color: color.opacity(themeManager.isDarkMode ? 0.4 : 0.3),
                radius: isPressed ? 5 : 10,
                x: 0,
                y: isPressed ? 2 : 5
            )
            .animation(AppAnimations.buttonPress, value: isPressed)
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
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) private var colorScheme
    
    private var progressValue: Double {
        min(progress / total, 1.0)
    }
    
    private var backgroundOpacity: Double {
        themeManager.isDarkMode || colorScheme == .dark ? 0.15 : 0.2
    }
    
    private var adaptiveProgressGradient: AngularGradient {
        AngularGradient(
            colors: [
                color.opacity(0.4),
                themeManager.currentAccentColor,
                color.opacity(0.9),
                themeManager.currentAccentColor.opacity(0.6),
                color.opacity(0.4)
            ],
            center: .center,
            startAngle: .degrees(-90),
            endAngle: .degrees(270)
        )
    }
    
    private var adaptiveOverlayGradient: LinearGradient {
        if themeManager.isDarkMode || colorScheme == .dark {
            return LinearGradient(
                colors: [.white.opacity(0.3), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [.white.opacity(0.6), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(
                    color.opacity(backgroundOpacity),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
            
            // Adaptive liquid glass progress ring
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    adaptiveProgressGradient,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .shadow(
                    color: color.opacity(themeManager.isDarkMode ? 0.6 : 0.4),
                    radius: themeManager.isDarkMode ? 4 : 3
                )
            
            // Adaptive liquid glass overlay
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    adaptiveOverlayGradient,
                    style: StrokeStyle(lineWidth: 2, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
        }
        .onAppear {
            withAnimation(AppAnimations.smooth.delay(0.2)) {
                animatedProgress = progressValue
            }
        }
        .onChange(of: progressValue) { oldValue, newValue in
            withAnimation(AppAnimations.spring) {
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
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) private var colorScheme
    
    private var adaptiveBaseBackground: some View {
        Group {
            if themeManager.isDarkMode || colorScheme == .dark {
                AppColors.primaryBackground
                    .overlay(.thinMaterial)
            } else {
                AppColors.primaryBackground
                    .overlay(.ultraThinMaterial)
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Adaptive base background
            adaptiveBaseBackground
            
            // Animated background gradients with theme-aware opacity
            ForEach(0..<colors.count, id: \.self) { index in
                AnimatedGradientBlob(
                    color: colors[index],
                    size: CGFloat.random(in: 200...400),
                    offset: CGSize(
                        width: CGFloat.random(in: -100...100),
                        height: CGFloat.random(in: -100...100)
                    ),
                    animationDelay: Double(index) * 0.5,
                    isDarkMode: themeManager.isDarkMode || colorScheme == .dark
                )
            }
        }
        .ignoresSafeArea()
    }
}

struct AnimatedGradientBlob: View {
    let color: Color
    let size: CGFloat
    @State private var offset: CGSize
    let animationDelay: Double
    let isDarkMode: Bool
    
    @State private var animatedOffset: CGSize
    
    init(color: Color, size: CGFloat, offset: CGSize, animationDelay: Double, isDarkMode: Bool = false) {
        self.color = color
        self.size = size
        self.offset = offset
        self.animationDelay = animationDelay
        self.isDarkMode = isDarkMode
        self._animatedOffset = State(initialValue: offset)
    }
    
    private var adaptiveGradient: RadialGradient {
        if isDarkMode {
            return RadialGradient(
                colors: [color.opacity(0.2), color.opacity(0.1), .clear],
                center: .center,
                startRadius: 0,
                endRadius: size / 2
            )
        } else {
            return RadialGradient(
                colors: [color.opacity(0.4), color.opacity(0.15), .clear],
                center: .center,
                startRadius: 0,
                endRadius: size / 2
            )
        }
    }
    
    var body: some View {
        Circle()
            .fill(adaptiveGradient)
            .frame(width: size, height: size)
            .blur(radius: isDarkMode ? 25 : 30)
            .offset(animatedOffset)
            .onAppear {
                withAnimation(
                    AppAnimations.wave.delay(animationDelay)
                ) {
                    animatedOffset = CGSize(
                        width: offset.width + CGFloat.random(in: -50...50),
                        height: offset.height + CGFloat.random(in: -50...50)
                    )
                }
            }
    }
}

// MARK: - Fluid Animation Utilities
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
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Circle()
                    .stroke(
                        themeManager.currentAccentColor.opacity(isPulsing ? 0.0 : intensity),
                        lineWidth: 2
                    )
                    .scaleEffect(isPulsing ? 2.0 : 1.0)
                    .animation(AppAnimations.pulse, value: isPulsing)
            )
            .onAppear {
                isPulsing = true
            }
    }
}

struct FluidGlowEffect: ViewModifier {
    @State private var glowIntensity: Double = 0.5
    let color: Color
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) private var colorScheme
    
    private var adaptiveGlowIntensity: Double {
        let baseIntensity = glowIntensity
        return (themeManager.isDarkMode || colorScheme == .dark) ? baseIntensity * 0.8 : baseIntensity
    }
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(adaptiveGlowIntensity), radius: 10)
            .shadow(color: color.opacity(adaptiveGlowIntensity * 0.5), radius: 20)
            .onAppear {
                withAnimation(AppAnimations.wave) {
                    glowIntensity = 1.0
                }
            }
    }
}

// MARK: - Liquid Macro Progress Bar (for Diary/Nutrition displays)
struct LiquidMacroProgressBar: View {
    let label: String
    let value: Double
    let target: Double
    let unit: String
    let color: Color

    @State private var animatedProgress: Double = 0
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) private var colorScheme

    private var progress: Double {
        min(value / target, 1.0)
    }

    private var backgroundOpacity: Double {
        themeManager.isDarkMode || colorScheme == .dark ? 0.15 : 0.2
    }

    private var adaptiveGradient: LinearGradient {
        LinearGradient(
            colors: [
                color.opacity(0.9),
                themeManager.currentAccentColor.opacity(0.7),
                color.opacity(0.8)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var adaptiveOverlay: LinearGradient {
        if themeManager.isDarkMode || colorScheme == .dark {
            return LinearGradient(
                colors: [.white.opacity(0.2), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            return LinearGradient(
                colors: [.white.opacity(0.4), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(AppFonts.subheadline(weight: .medium))
                    .foregroundColor(AppColors.primaryText)
                Spacer()
                Text("\(Int(value)) / \(Int(target)) \(unit)")
                    .font(AppFonts.caption())
                    .foregroundColor(AppColors.secondaryText)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track with glass effect
                    RoundedRectangle(cornerRadius: 5)
                        .fill(color.opacity(backgroundOpacity))
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(color.opacity(0.1), lineWidth: 0.5)
                        )

                    // Animated progress bar
                    RoundedRectangle(cornerRadius: 5)
                        .fill(adaptiveGradient)
                        .frame(width: geometry.size.width * animatedProgress)
                        .shadow(color: color.opacity(0.3), radius: 2)

                    // Liquid glass overlay on progress
                    RoundedRectangle(cornerRadius: 5)
                        .fill(adaptiveOverlay)
                        .frame(width: geometry.size.width * animatedProgress, height: 5)
                        .offset(y: -1)
                }
            }
            .frame(height: 10)
        }
        .onAppear {
            withAnimation(AppAnimations.smooth) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { oldValue, newValue in
            withAnimation(AppAnimations.spring) {
                animatedProgress = newValue
            }
        }
    }
}

// MARK: - Liquid Macro Badge (compact macro display)
struct LiquidMacroBadge: View {
    let value: Double
    let label: String
    let color: Color

    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) private var colorScheme

    private var backgroundOpacity: Double {
        themeManager.isDarkMode || colorScheme == .dark ? 0.25 : 0.2
    }

    var body: some View {
        HStack(spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .bold))
            Text("\(Int(value))")
                .font(.system(size: 9, weight: .medium))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(color.opacity(backgroundOpacity))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(color.opacity(0.3), lineWidth: 0.5)
                )
        )
        .foregroundColor(color)
    }
}

// MARK: - Liquid Glass Row (for list items)
struct LiquidGlassRow<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat = 12

    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) private var colorScheme

    init(cornerRadius: CGFloat = 12, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    private var adaptiveBackground: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(.thinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(themeManager.isDarkMode ? AppColors.darkGlassGradient : AppColors.glassGradient)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(themeManager.isDarkMode ? 0.1 : 0.3), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
    }

    var body: some View {
        content
            .background(adaptiveBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
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
                insertion: .scale.combined(with: .opacity).animation(AppAnimations.bouncy),
                removal: .scale.combined(with: .opacity).animation(AppAnimations.smooth)
            )
        )
    }
    
    /// Apply the app's adaptive theme with smooth transitions
    func applyAdaptiveTheme() -> some View {
        self.modifier(AdaptiveThemeModifier())
    }
    
    /// Apply responsive haptic feedback on tap
    func responsiveHaptic(_ type: HapticFeedbackType = .light) -> some View {
        self.onTapGesture {
            switch type {
            case .light: AppHaptics.light()
            case .medium: AppHaptics.medium()
            case .heavy: AppHaptics.heavy()
            case .success: AppHaptics.success()
            case .warning: AppHaptics.warning()
            case .error: AppHaptics.error()
            case .selection: AppHaptics.selection()
            }
        }
    }
    
    /// Apply liquid glass styling with theme awareness
    func liquidGlass(cornerRadius: CGFloat = 20) -> some View {
        LiquidGlassCard(cornerRadius: cornerRadius) {
            self
        }
    }

    /// Apply enhanced glass background effect
    /// Note: When iOS 26 SDK is available, this will automatically use native `.glassBackgroundEffect()`
    /// For now, uses our custom liquid glass implementation which provides similar visual results
    func nativeGlassBackground(cornerRadius: CGFloat = 20) -> some View {
        self.liquidGlass(cornerRadius: cornerRadius)
    }
}

// MARK: - Adaptive Glass Card
/// Uses LiquidGlassCard for now. When iOS 26 SDK becomes available,
/// this will automatically use native glass effects.
/// The custom implementation provides excellent glassmorphism on iOS 17+
struct AdaptiveGlassCard<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat = 20

    init(cornerRadius: CGFloat = 20, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        LiquidGlassCard(cornerRadius: cornerRadius) {
            content
        }
    }
}

// MARK: - Preview Helpers
struct LiquidGlassPreview: View {
    @State private var showDarkMode = false
    
    var body: some View {
        ZStack {
            GlassmorphismBackground(colors: [.blue, .purple, .pink])
            
            VStack(spacing: AppSpacing.lg) {
                // Theme toggle
                LiquidGlassCard {
                    HStack {
                        Text("Dark Mode Preview")
                            .font(AppFonts.headline())
                            .foregroundColor(AppColors.primaryText)
                        
                        Spacer()
                        
                        Toggle("", isOn: $showDarkMode)
                            .toggleStyle(SwitchToggleStyle())
                    }
                    .padding(AppSpacing.md)
                }
                
                LiquidGlassCard {
                    VStack(spacing: AppSpacing.sm) {
                        HStack {
                            Image(systemName: "sparkles")
                                .font(.title2)
                                .foregroundColor(AppColors.accent)
                            
                            Text("Enhanced Liquid Glass")
                                .font(AppFonts.title2(weight: .semibold))
                                .foregroundColor(AppColors.primaryText)
                        }
                        
                        Text("Adaptive glassmorphism with dark mode support")
                            .font(AppFonts.caption())
                            .foregroundColor(AppColors.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(AppSpacing.lg)
                }
                
                HStack(spacing: AppSpacing.md) {
                    LiquidProgressRing(
                        progress: 1450,
                        total: 2000,
                        color: .blue,
                        size: 100,
                        lineWidth: 10
                    )
                    
                    LiquidProgressRing(
                        progress: 85,
                        total: 100,
                        color: .green,
                        size: 100,
                        lineWidth: 10
                    )
                }
                
                VStack(spacing: AppSpacing.sm) {
                    LiquidProgressIndicator(
                        progress: 0.75,
                        color: .orange,
                        height: 8
                    )
                    
                    LiquidProgressIndicator(
                        progress: 0.45,
                        color: .purple,
                        height: 12
                    )
                }
                .frame(maxWidth: 200)
                
                HStack(spacing: AppSpacing.sm) {
                    LiquidGlassButton(
                        title: "Success",
                        icon: "checkmark.circle.fill",
                        color: .green
                    ) {
                        AppHaptics.success()
                    }
                    
                    LiquidGlassButton(
                        title: "Premium",
                        icon: "crown.fill",
                        color: .orange
                    ) {
                        AppHaptics.medium()
                    }
                }
            }
            .padding(AppSpacing.md)
        }
        .applyAdaptiveTheme()
        .preferredColorScheme(showDarkMode ? .dark : .light)
    }
}

#Preview("Light Mode") {
    LiquidGlassPreview()
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    LiquidGlassPreview()
        .preferredColorScheme(.dark)
}