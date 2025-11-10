import SwiftUI

struct AppearanceSettingsView: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var showingResetAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                GlassmorphismBackground(colors: [.indigo, .purple, .blue])
                
                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        themeSelectionCard
                        accentColorCard
                        displayOptionsCard
                        accessibilityCard
                        aboutCard
                        resetCard
                    }
                    .padding(AppSpacing.md)
                }
            }
            .navigationTitle("Appearance")
            .navigationBarTitleDisplayMode(.inline)
            .applyAdaptiveTheme()
        }
        .alert("Reset Appearance", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                resetToDefaults()
            }
        } message: {
            Text("This will reset all appearance settings to their default values. This action cannot be undone.")
        }
    }
    
    // MARK: - Theme Selection Card
    
    private var themeSelectionCard: some View {
        LiquidGlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                HStack {
                    Image(systemName: "paintbrush.fill")
                        .font(.title2)
                        .foregroundColor(themeManager.currentAccentColor)
                    
                    Text("Theme")
                        .font(AppFonts.headline(.semibold))
                        .foregroundColor(AppColors.primaryText)
                }
                
                Text("Choose your preferred appearance mode")
                    .font(AppFonts.subheadline())
                    .foregroundColor(AppColors.secondaryText)
                
                VStack(spacing: AppSpacing.sm) {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        ThemeOptionRow(
                            theme: theme,
                            isSelected: themeManager.currentTheme == theme
                        ) {
                            withAnimation(AppAnimations.spring) {
                                themeManager.setTheme(theme)
                                AppHaptics.selection()
                            }
                        }
                    }
                }
            }
            .padding(AppSpacing.md)
        }
    }
    
    // MARK: - Accent Color Card
    
    private var accentColorCard: some View {
        LiquidGlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                HStack {
                    Image(systemName: "palette.fill")
                        .font(.title2)
                        .foregroundColor(themeManager.currentAccentColor)
                    
                    Text("Accent Color")
                        .font(AppFonts.headline(.semibold))
                        .foregroundColor(AppColors.primaryText)
                }
                
                Text("Personalize the app with your favorite color")
                    .font(AppFonts.subheadline())
                    .foregroundColor(AppColors.secondaryText)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: AppSpacing.sm) {
                    ForEach(AccentColor.allCases, id: \.self) { accentColor in
                        AccentColorButton(
                            accentColor: accentColor,
                            isSelected: themeManager.accentColor == accentColor
                        ) {
                            withAnimation(AppAnimations.spring) {
                                themeManager.setAccentColor(accentColor)
                                AppHaptics.light()
                            }
                        }
                    }
                }
            }
            .padding(AppSpacing.md)
        }
    }
    
    // MARK: - Display Options Card
    
    private var displayOptionsCard: some View {
        LiquidGlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                HStack {
                    Image(systemName: "display")
                        .font(.title2)
                        .foregroundColor(themeManager.currentAccentColor)
                    
                    Text("Display Options")
                        .font(AppFonts.headline(.semibold))
                        .foregroundColor(AppColors.primaryText)
                }
                
                VStack(spacing: AppSpacing.md) {
                    SettingsToggleRow(
                        icon: "wand.and.stars",
                        title: "Animations",
                        description: "Enable smooth UI animations",
                        isOn: $themeManager.enableAnimations
                    ) {
                        themeManager.toggleAnimations()
                        AppHaptics.light()
                    }
                    
                    SettingsToggleRow(
                        icon: "hand.tap.fill",
                        title: "Haptic Feedback",
                        description: "Feel responsive touch feedback",
                        isOn: $themeManager.enableHaptics
                    ) {
                        themeManager.toggleHaptics()
                        AppHaptics.medium()
                    }
                }
            }
            .padding(AppSpacing.md)
        }
    }
    
    // MARK: - Accessibility Card
    
    private var accessibilityCard: some View {
        LiquidGlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                HStack {
                    Image(systemName: "accessibility")
                        .font(.title2)
                        .foregroundColor(themeManager.currentAccentColor)
                    
                    Text("Accessibility")
                        .font(AppFonts.headline(.semibold))
                        .foregroundColor(AppColors.primaryText)
                }
                
                SettingsToggleRow(
                    icon: "figure.walk.motion",
                    title: "Reduce Motion",
                    description: "Minimize animations for better accessibility",
                    isOn: $themeManager.enableReducedMotion
                ) {
                    themeManager.toggleReducedMotion()
                    AppHaptics.light()
                }
                
                NavigationLink(destination: SystemAccessibilityView()) {
                    HStack {
                        Image(systemName: "gear")
                            .font(.title3)
                            .foregroundColor(themeManager.currentAccentColor)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("System Accessibility")
                                .font(AppFonts.subheadline(.medium))
                                .foregroundColor(AppColors.primaryText)
                            
                            Text("Open iOS accessibility settings")
                                .font(AppFonts.caption())
                                .foregroundColor(AppColors.secondaryText)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(AppColors.tertiaryText)
                    }
                }
                .responsiveHaptic(.selection)
            }
            .padding(AppSpacing.md)
        }
    }
    
    // MARK: - About Card
    
    private var aboutCard: some View {
        LiquidGlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .font(.title2)
                        .foregroundColor(themeManager.currentAccentColor)
                    
                    Text("Theme System")
                        .font(AppFonts.headline(.semibold))
                        .foregroundColor(AppColors.primaryText)
                }
                
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    InfoRow(label: "Current Theme", value: themeManager.currentTheme.displayName)
                    InfoRow(label: "Accent Color", value: themeManager.accentColor.displayName)
                    InfoRow(label: "Animations", value: themeManager.enableAnimations ? "Enabled" : "Disabled")
                    InfoRow(label: "Haptics", value: themeManager.enableHaptics ? "Enabled" : "Disabled")
                }
            }
            .padding(AppSpacing.md)
        }
    }
    
    // MARK: - Reset Card
    
    private var resetCard: some View {
        LiquidGlassCard {
            VStack(spacing: AppSpacing.md) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                        .font(.title2)
                        .foregroundColor(.orange)
                    
                    Text("Reset Appearance")
                        .font(AppFonts.headline(.semibold))
                        .foregroundColor(AppColors.primaryText)
                    
                    Spacer()
                }
                
                Text("Reset all appearance settings to default values")
                    .font(AppFonts.subheadline())
                    .foregroundColor(AppColors.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Button(action: {
                    showingResetAlert = true
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .font(.subheadline)
                        
                        Text("Reset to Defaults")
                            .font(AppFonts.subheadline(.medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(AppSpacing.sm)
                    .background(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(AppSpacing.radiusMedium)
                }
                .responsiveHaptic(.warning)
            }
            .padding(AppSpacing.md)
        }
    }
    
    // MARK: - Helper Methods
    
    private func resetToDefaults() {
        withAnimation(AppAnimations.spring) {
            themeManager.setTheme(.system)
            themeManager.setAccentColor(.blue)
            themeManager.enableAnimations = true
            themeManager.enableHaptics = true
            themeManager.enableReducedMotion = false
        }
        
        AppHaptics.success()
    }
}

// MARK: - Supporting Views

struct ThemeOptionRow: View {
    let theme: AppTheme
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.sm) {
                ZStack {
                    Circle()
                        .fill(theme == .dark ? .black : .white)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Circle()
                                .stroke(isSelected ? ThemeManager.shared.currentAccentColor : .gray.opacity(0.3), lineWidth: 2)
                        )
                    
                    Image(systemName: theme.icon)
                        .font(.caption)
                        .foregroundColor(theme == .dark ? .white : .black)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(theme.displayName)
                        .font(AppFonts.subheadline(.medium))
                        .foregroundColor(AppColors.primaryText)
                    
                    Text(themeDescription(for: theme))
                        .font(AppFonts.caption())
                        .foregroundColor(AppColors.secondaryText)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(ThemeManager.shared.currentAccentColor)
                }
            }
            .padding(AppSpacing.sm)
            .background(isSelected ? ThemeManager.shared.currentAccentColor.opacity(0.1) : .clear)
            .cornerRadius(AppSpacing.radiusMedium)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func themeDescription(for theme: AppTheme) -> String {
        switch theme {
        case .light:
            return "Always use light appearance"
        case .dark:
            return "Always use dark appearance"
        case .system:
            return "Follow system setting"
        }
    }
}

struct AccentColorButton: View {
    let accentColor: AccentColor
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(accentColor.color)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .stroke(.white, lineWidth: isSelected ? 3 : 0)
                    )
                    .overlay(
                        Circle()
                            .stroke(accentColor.color.opacity(0.3), lineWidth: 2)
                    )
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                }
            }
            .scaleEffect(isSelected ? 1.1 : 1.0)
            .animation(AppAnimations.spring, value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SettingsToggleRow: View {
    let icon: String
    let title: String
    let description: String
    @Binding var isOn: Bool
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(ThemeManager.shared.currentAccentColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFonts.subheadline(.medium))
                    .foregroundColor(AppColors.primaryText)
                
                Text(description)
                    .font(AppFonts.caption())
                    .foregroundColor(AppColors.secondaryText)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: ThemeManager.shared.currentAccentColor))
                .onChange(of: isOn) { _, _ in
                    action()
                }
        }
        .padding(.vertical, 2)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(AppFonts.caption())
                .foregroundColor(AppColors.secondaryText)
            
            Spacer()
            
            Text(value)
                .font(AppFonts.caption(.medium))
                .foregroundColor(AppColors.primaryText)
        }
    }
}

struct SystemAccessibilityView: View {
    var body: some View {
        ZStack {
            GlassmorphismBackground(colors: [.blue, .indigo])
            
            VStack(spacing: AppSpacing.lg) {
                Spacer()
                
                Image(systemName: "accessibility")
                    .font(.system(size: 60))
                    .foregroundColor(ThemeManager.shared.currentAccentColor)
                
                VStack(spacing: AppSpacing.sm) {
                    Text("System Accessibility")
                        .font(AppFonts.title(.bold))
                        .foregroundColor(AppColors.primaryText)
                        .multilineTextAlignment(.center)
                    
                    Text("To access system-wide accessibility settings, please open the iOS Settings app and navigate to Accessibility.")
                        .font(AppFonts.subheadline())
                        .foregroundColor(AppColors.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.lg)
                }
                
                Button(action: {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }) {
                    HStack {
                        Image(systemName: "gear")
                            .font(.title3)
                        
                        Text("Open Settings")
                            .font(AppFonts.headline(.semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(AppSpacing.md)
                    .background(ThemeManager.shared.currentAccentColor)
                    .cornerRadius(AppSpacing.radiusLarge)
                }
                .padding(.horizontal, AppSpacing.lg)
                .responsiveHaptic(.light)
                
                Spacer()
            }
        }
        .navigationTitle("System Accessibility")
        .navigationBarTitleDisplayMode(.inline)
        .applyAdaptiveTheme()
    }
}

#Preview("Light Mode") {
    AppearanceSettingsView()
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    AppearanceSettingsView()
        .preferredColorScheme(.dark)
}