import SwiftUI
import SwiftData

struct AchievementDetailView: View {
    let achievement: Achievement
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                GlassmorphismBackground(colors: [.purple, .indigo, .blue])
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Hero Section
                        LiquidGlassCard {
                            VStack(spacing: 20) {
                                // Achievement Icon with Animation
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [rarityColor.opacity(0.3), rarityColor.opacity(0.1)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 120, height: 120)
                                    
                                    Image(systemName: achievement.icon)
                                        .font(.system(size: 50))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [rarityColor, rarityColor.opacity(0.7)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                }
                                .liquidPulse(color: rarityColor, intensity: achievement.isUnlocked ? 0.5 : 0.2)
                                .scaleEffect(achievement.isUnlocked ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: achievement.isUnlocked)
                                
                                VStack(spacing: 8) {
                                    Text(achievement.name)
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(achievement.isUnlocked ? .primary : .secondary)
                                        .multilineTextAlignment(.center)
                                    
                                    Text(achievement.achievementDescription)
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(3)
                                }
                                
                                // Status and Rarity
                                HStack(spacing: 16) {
                                    StatusChip(
                                        text: achievement.isUnlocked ? "Unlocked" : "Locked",
                                        color: achievement.isUnlocked ? .green : .gray,
                                        icon: achievement.isUnlocked ? "checkmark.seal.fill" : "lock.fill"
                                    )
                                    
                                    RarityChip(rarity: achievement.rarity)
                                    
                                    CategoryChip(category: achievement.category)
                                }
                            }
                            .padding()
                        }
                        
                        // Achievement Details
                        LiquidGlassCard {
                            VStack(spacing: 16) {
                                Text("Details")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 16) {
                                    DetailCard(
                                        title: "Points Awarded",
                                        value: "\(achievement.points)",
                                        icon: "star.fill",
                                        color: .yellow
                                    )
                                    
                                    DetailCard(
                                        title: "Type",
                                        value: achievement.type.displayName,
                                        icon: "tag.fill",
                                        color: .blue
                                    )
                                    
                                    DetailCard(
                                        title: "Requirement",
                                        value: formattedRequirement,
                                        icon: "target",
                                        color: .green
                                    )
                                    
                                    DetailCard(
                                        title: "Rarity",
                                        value: achievement.rarity.displayName,
                                        icon: "diamond.fill",
                                        color: rarityColor
                                    )
                                }
                            }
                            .padding()
                        }
                        
                        // Unlock Information
                        if achievement.isUnlocked {
                            LiquidGlassCard {
                                VStack(spacing: 12) {
                                    HStack {
                                        Image(systemName: "trophy.fill")
                                            .foregroundColor(.yellow)
                                        
                                        Text("Achievement Unlocked!")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                        
                                        Spacer()
                                    }
                                    
                                    if let unlockedAt = achievement.unlockedAt {
                                        HStack {
                                            Text("Unlocked on:")
                                                .foregroundColor(.secondary)
                                            
                                            Text(unlockedAt, style: .date)
                                                .fontWeight(.medium)
                                            
                                            Spacer()
                                        }
                                        .font(.subheadline)
                                        
                                        HStack {
                                            Text("Time:")
                                                .foregroundColor(.secondary)
                                            
                                            Text(unlockedAt, style: .time)
                                                .fontWeight(.medium)
                                            
                                            Spacer()
                                        }
                                        .font(.subheadline)
                                    }
                                }
                                .padding()
                            }
                        } else {
                            LiquidGlassCard {
                                VStack(spacing: 12) {
                                    HStack {
                                        Image(systemName: "lock.fill")
                                            .foregroundColor(.gray)
                                        
                                        Text("How to Unlock")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                        
                                        Spacer()
                                    }
                                    
                                    Text(unlockHint)
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding()
                            }
                        }
                        
                        // Related Achievements
                        if !relatedAchievements.isEmpty {
                            LiquidGlassCard {
                                VStack(spacing: 16) {
                                    Text("Related Achievements")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    LazyVGrid(columns: [
                                        GridItem(.flexible()),
                                        GridItem(.flexible()),
                                        GridItem(.flexible())
                                    ], spacing: 12) {
                                        ForEach(relatedAchievements, id: \.name) { related in
                                            MiniAchievementCard(achievement: related)
                                        }
                                    }
                                }
                                .padding()
                            }
                        }
                        
                        // Share Button (if unlocked)
                        if achievement.isUnlocked {
                            Button("Share Achievement") {
                                shareAchievement()
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(16)
                            .shadow(color: .blue.opacity(0.3), radius: 10)
                        }
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }
    
    private var rarityColor: Color {
        switch achievement.rarity {
        case .common: return .gray
        case .uncommon: return .green
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .orange
        }
    }
    
    private var formattedRequirement: String {
        switch achievement.type {
        case .streak, .consecutiveDays:
            return "\(Int(achievement.requirement)) days"
        case .goalCompletion:
            return "\(Int(achievement.requirement)) goals"
        case .totalLogged:
            return "\(Int(achievement.requirement)) items"
        case .recipeCreation:
            return "\(Int(achievement.requirement)) recipes"
        case .discovery:
            return "\(Int(achievement.requirement)) foods"
        default:
            return "\(Int(achievement.requirement))"
        }
    }
    
    private var unlockHint: String {
        switch achievement.type {
        case .streak:
            return "Log your meals consistently for \(Int(achievement.requirement)) consecutive days to unlock this achievement."
        case .goalCompletion:
            return "Complete \(Int(achievement.requirement)) personal goals to unlock this achievement."
        case .totalLogged:
            return "Log a total of \(Int(achievement.requirement)) food items to unlock this achievement."
        case .recipeCreation:
            return "Create \(Int(achievement.requirement)) custom recipes to unlock this achievement."
        case .discovery:
            return "Try \(Int(achievement.requirement)) different types of food to unlock this achievement."
        case .perfectDay:
            return "Hit all your macro targets for \(Int(achievement.requirement)) day(s) to unlock this achievement."
        case .consistency:
            return "Maintain consistent food logging to unlock this achievement."
        case .milestone:
            return "Reach specific milestones in your nutrition journey to unlock this achievement."
        }
    }
    
    private var relatedAchievements: [Achievement] {
        // Mock related achievements for demonstration
        // In a real app, this would fetch from the database
        []
    }
    
    private func shareAchievement() {
        // Implement sharing functionality
        let text = "I just unlocked the '\(achievement.name)' achievement in CalTrackPro! 🏆"
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
}

// MARK: - Supporting Views

struct StatusChip: View {
    let text: String
    let color: Color
    let icon: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.2))
        .cornerRadius(8)
    }
}

struct RarityChip: View {
    let rarity: Achievement.Rarity
    
    private var rarityColor: Color {
        switch rarity {
        case .common: return .gray
        case .uncommon: return .green
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .orange
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "diamond.fill")
                .font(.caption)
            Text(rarity.displayName)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(rarityColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(rarityColor.opacity(0.2))
        .cornerRadius(8)
    }
}

struct CategoryChip: View {
    let category: Achievement.Category
    
    private var categoryColor: Color {
        switch category {
        case .nutrition: return .green
        case .goals: return .blue
        case .consistency: return .orange
        case .social: return .purple
        case .learning: return .indigo
        case .creativity: return .pink
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "folder.fill")
                .font(.caption)
            Text(category.displayName)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(categoryColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(categoryColor.opacity(0.2))
        .cornerRadius(8)
    }
}

struct DetailCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .lineLimit(1)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, minHeight: 80)
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}

struct MiniAchievementCard: View {
    let achievement: Achievement
    
    private var rarityColor: Color {
        switch achievement.rarity {
        case .common: return .gray
        case .uncommon: return .green
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .orange
        }
    }
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: achievement.icon)
                .font(.title3)
                .foregroundColor(achievement.isUnlocked ? rarityColor : .secondary)
            
            Text(achievement.name)
                .font(.caption2)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, minHeight: 60)
        .padding(8)
        .background(.ultraThinMaterial)
        .cornerRadius(8)
        .opacity(achievement.isUnlocked ? 1.0 : 0.6)
    }
}

#Preview {
    let achievement = Achievement(
        name: "Week Warrior",
        achievementDescription: "Log food for 7 consecutive days",
        type: .streak,
        category: .consistency,
        requirement: 7,
        icon: "flame.fill",
        rarity: .uncommon
    )
    achievement.unlock()
    
    return AchievementDetailView(achievement: achievement)
        .modelContainer(for: [Achievement.self])
}