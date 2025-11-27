import SwiftUI
import Foundation
import Combine

// MARK: - Theme Manager

@MainActor
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: AppTheme = .system
    @Published var colorScheme: ColorScheme?
    @Published var accentColor: AccentColor = .blue
    @Published var enableAnimations = true
    @Published var enableHaptics = true
    @Published var enableReducedMotion = false
    
    private let userDefaults = UserDefaults.standard
    
    private init() {
        loadThemeSettings()
        updateColorScheme()
    }
    
    // MARK: - Theme Management
    
    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
        saveThemeSettings()
        updateColorScheme()
    }
    
    func setAccentColor(_ color: AccentColor) {
        accentColor = color
        saveThemeSettings()
    }
    
    func toggleAnimations() {
        enableAnimations.toggle()
        saveThemeSettings()
    }
    
    func toggleHaptics() {
        enableHaptics.toggle()
        saveThemeSettings()
    }
    
    func toggleReducedMotion() {
        enableReducedMotion.toggle()
        saveThemeSettings()
    }
    
    private func updateColorScheme() {
        switch currentTheme {
        case .light:
            colorScheme = .light
        case .dark:
            colorScheme = .dark
        case .system:
            colorScheme = nil // Uses system setting
        }
    }
    
    // MARK: - Persistence
    
    private func saveThemeSettings() {
        userDefaults.set(currentTheme.rawValue, forKey: "app_theme")
        userDefaults.set(accentColor.rawValue, forKey: "accent_color")
        userDefaults.set(enableAnimations, forKey: "enable_animations")
        userDefaults.set(enableHaptics, forKey: "enable_haptics")
        userDefaults.set(enableReducedMotion, forKey: "enable_reduced_motion")
    }
    
    private func loadThemeSettings() {
        if let themeRawValue = userDefaults.object(forKey: "app_theme") as? String,
           let theme = AppTheme(rawValue: themeRawValue) {
            currentTheme = theme
        }
        
        if let accentRawValue = userDefaults.object(forKey: "accent_color") as? String,
           let accent = AccentColor(rawValue: accentRawValue) {
            accentColor = accent
        }
        
        enableAnimations = userDefaults.object(forKey: "enable_animations") as? Bool ?? true
        enableHaptics = userDefaults.object(forKey: "enable_haptics") as? Bool ?? true
        enableReducedMotion = userDefaults.object(forKey: "enable_reduced_motion") as? Bool ?? false
    }
    
    // MARK: - Computed Properties
    
    var isDarkMode: Bool {
        if let colorScheme = colorScheme {
            return colorScheme == .dark
        }
        // System theme - check environment
        return UITraitCollection.current.userInterfaceStyle == .dark
    }
    
    var currentAccentColor: Color {
        accentColor.color
    }
    
    var animationSpeed: Double {
        enableReducedMotion ? 0.1 : (enableAnimations ? 1.0 : 0.1)
    }
}

// MARK: - Theme Types

enum AppTheme: String, CaseIterable {
    case light = "light"
    case dark = "dark"
    case system = "system"
    
    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .system: return "System"
        }
    }
    
    var icon: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .system: return "circle.lefthalf.filled"
        }
    }
}

enum AccentColor: String, CaseIterable {
    case blue = "blue"
    case green = "green"
    case orange = "orange"
    case purple = "purple"
    case pink = "pink"
    case red = "red"
    case teal = "teal"
    case indigo = "indigo"
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var color: Color {
        switch self {
        case .blue: return .blue
        case .green: return .green
        case .orange: return .orange
        case .purple: return .purple
        case .pink: return .pink
        case .red: return .red
        case .teal: return .teal
        case .indigo: return .indigo
        }
    }
}

// MARK: - Adaptive Colors

struct AppColors {
    static let shared = AppColors()
    private init() {}
    
    // MARK: - Background Colors
    
    static let primaryBackground = Color(UIColor.systemBackground)
    static let secondaryBackground = Color(UIColor.secondarySystemBackground)
    static let tertiaryBackground = Color(UIColor.tertiarySystemBackground)
    
    // MARK: - Glass Effects
    
    static var glassBackground: Color {
        Color(UIColor.systemBackground).opacity(0.1)
    }
    
    static var glassBorder: Color {
        Color.white.opacity(0.2)
    }
    
    // MARK: - Text Colors
    
    static let primaryText = Color(UIColor.label)
    static let secondaryText = Color(UIColor.secondaryLabel)
    static let tertiaryText = Color(UIColor.tertiaryLabel)
    
    // MARK: - Accent Colors
    
    static let accent = Color.accentColor
    static let accentSecondary = Color.blue
    
    // MARK: - Semantic Colors
    
    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red
    static let info = Color.blue
    
    // MARK: - Nutrition Colors
    
    static let caloriesColor = Color.blue
    static let proteinColor = Color.red
    static let carbsColor = Color.orange
    static let fatColor = Color.yellow
    static let fiberColor = Color.green
    
    // MARK: - Gradient Colors
    
    static let primaryGradient = LinearGradient(
        colors: [Color.blue, Color.purple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let glassGradient = LinearGradient(
        colors: [
            Color.white.opacity(0.25),
            Color.white.opacity(0.1)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let darkGlassGradient = LinearGradient(
        colors: [
            Color.black.opacity(0.3),
            Color.black.opacity(0.1)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Adaptive Typography

struct AppFonts {
    static let shared = AppFonts()
    private init() {}
    
    // MARK: - Custom Font Names
    
    static let primaryFontName = "SF Pro Display"
    static let secondaryFontName = "SF Pro Text"
    static let monospaceFontName = "SF Mono"
    
    // MARK: - Font Styles
    
    static func largeTitle(weight: Font.Weight = .bold) -> Font {
        .system(.largeTitle, design: .default, weight: weight)
    }
    
    static func title(weight: Font.Weight = .semibold) -> Font {
        .system(.title, design: .default, weight: weight)
    }
    
    static func title2(weight: Font.Weight = .semibold) -> Font {
        .system(.title2, design: .default, weight: weight)
    }
    
    static func title3(weight: Font.Weight = .medium) -> Font {
        .system(.title3, design: .default, weight: weight)
    }
    
    static func headline(weight: Font.Weight = .semibold) -> Font {
        .system(.headline, design: .default, weight: weight)
    }
    
    static func subheadline(weight: Font.Weight = .medium) -> Font {
        .system(.subheadline, design: .default, weight: weight)
    }
    
    static func body(weight: Font.Weight = .regular) -> Font {
        .system(.body, design: .default, weight: weight)
    }
    
    static func callout(weight: Font.Weight = .regular) -> Font {
        .system(.callout, design: .default, weight: weight)
    }
    
    static func footnote(weight: Font.Weight = .regular) -> Font {
        .system(.footnote, design: .default, weight: weight)
    }
    
    static func caption(weight: Font.Weight = .regular) -> Font {
        .system(.caption, design: .default, weight: weight)
    }
    
    static func caption2(weight: Font.Weight = .regular) -> Font {
        .system(.caption2, design: .default, weight: weight)
    }
    
    // MARK: - Custom Fonts
    
    static func monospace(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
    
    static func rounded(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

// MARK: - Spacing System

struct AppSpacing {
    static let shared = AppSpacing()
    private init() {}
    
    // MARK: - Base Spacing Values
    
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
    static let xxxl: CGFloat = 64
    
    // MARK: - Semantic Spacing
    
    static let cardPadding: CGFloat = md
    static let sectionSpacing: CGFloat = lg
    static let componentSpacing: CGFloat = sm
    static let screenPadding: CGFloat = md
    
    // MARK: - Border Radius
    
    static let radiusSmall: CGFloat = 8
    static let radiusMedium: CGFloat = 12
    static let radiusLarge: CGFloat = 16
    static let radiusXLarge: CGFloat = 24
    
    // MARK: - Shadow Values
    
    static let shadowRadius: CGFloat = 10
    static let shadowOffset = CGSize(width: 0, height: 5)
    static let shadowOpacity: Double = 0.1
}

// MARK: - Animation Presets

struct AppAnimations {
    static let shared = AppAnimations()
    private init() {}
    
    // MARK: - Timing
    
    static let fast: Double = 0.2
    static let medium: Double = 0.4
    static let slow: Double = 0.6
    
    // MARK: - Spring Animations
    
    static let spring = Animation.spring(response: 0.5, dampingFraction: 0.8)
    static let bouncy = Animation.spring(response: 0.4, dampingFraction: 0.6)
    static let smooth = Animation.easeInOut(duration: medium)
    
    // MARK: - Interactive Animations
    
    static let buttonPress = Animation.easeInOut(duration: fast)
    static let cardFlip = Animation.spring(response: 0.6, dampingFraction: 0.8)
    static let slideIn = Animation.spring(response: 0.5, dampingFraction: 0.9)
    
    // MARK: - Loading Animations
    
    static let pulse = Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)
    static let rotate = Animation.linear(duration: 1.0).repeatForever(autoreverses: false)
    static let wave = Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)
}

// MARK: - Haptic Feedback

struct AppHaptics {
    static let shared = AppHaptics()
    private init() {}
    
    // MARK: - Feedback Types
    
    static func light() {
        guard ThemeManager.shared.enableHaptics else { return }
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    static func medium() {
        guard ThemeManager.shared.enableHaptics else { return }
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    static func heavy() {
        guard ThemeManager.shared.enableHaptics else { return }
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }
    
    static func success() {
        guard ThemeManager.shared.enableHaptics else { return }
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }
    
    static func warning() {
        guard ThemeManager.shared.enableHaptics else { return }
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.warning)
    }
    
    static func error() {
        guard ThemeManager.shared.enableHaptics else { return }
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.error)
    }
    
    static func selection() {
        guard ThemeManager.shared.enableHaptics else { return }
        let selectionFeedback = UISelectionFeedbackGenerator()
        selectionFeedback.selectionChanged()
    }
}

// MARK: - View Extensions for Theme Support

extension View {
    func adaptiveTheme() -> some View {
        self.modifier(AdaptiveThemeModifier())
    }
    
    func hapticFeedback(_ type: HapticFeedbackType) -> some View {
        self.modifier(HapticFeedbackModifier(type: type))
    }
    
    func animatedScale(pressed: Binding<Bool>) -> some View {
        self.scaleEffect(pressed.wrappedValue ? 0.96 : 1.0)
            .animation(AppAnimations.buttonPress, value: pressed.wrappedValue)
    }
}

// MARK: - View Modifiers

struct AdaptiveThemeModifier: ViewModifier {
    @ObservedObject private var themeManager = ThemeManager.shared
    
    func body(content: Content) -> some View {
        content
            .preferredColorScheme(themeManager.colorScheme)
            .accentColor(themeManager.currentAccentColor)
            .animation(.easeInOut(duration: 0.3), value: themeManager.colorScheme)
    }
}

struct HapticFeedbackModifier: ViewModifier {
    let type: HapticFeedbackType
    
    func body(content: Content) -> some View {
        content
            .onTapGesture {
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
}

enum HapticFeedbackType {
    case light, medium, heavy, success, warning, error, selection
}