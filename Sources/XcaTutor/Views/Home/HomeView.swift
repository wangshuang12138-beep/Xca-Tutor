import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var scenes: [Scene] = []
    @State private var recentConversation: Conversation?
    @State private var stats = PracticeStats()
    @State private var mistakeCount: Int = 0
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: Spacing.xxl) {
                // Greeting
                GreetingHeader()
                    .padding(.top, Spacing.lg)
                
                // Continue Practice Card (if there's ongoing session)
                if let conversation = recentConversation {
                    ContinuePracticeCard(conversation: conversation) {
                        appState.startPractice(sceneId: conversation.sceneId)
                    }
                }
                
                // Scenes Section
                ScenesSection(scenes: scenes) { scene in
                    appState.startPractice(sceneId: scene.id)
                }
                
                // Stats Section
                StatsSection(stats: stats)
                
                // Mistakes Preview
                MistakesPreview(count: mistakeCount) {
                    appState.selectedTab = .mistakes
                }
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.xxl)
        }
        .background(AppleColors.background)
        .navigationTitle("")
        .onAppear {
            loadData()
        }
    }
    
    private func loadData() {
        scenes = SceneRepository.shared.getAllScenes()
        
        // Load recent conversation
        let conversations = DatabaseManager.shared.getRecentConversations(limit: 1)
        if let last = conversations.first, last.endTime == nil {
            recentConversation = last
        }
        
        // Load stats
        stats = DatabaseManager.shared.getWeeklyStats()
        
        // Load mistake count
        mistakeCount = DatabaseManager.shared.getUnmasteredMistakes().count
    }
}

// MARK: - Greeting Header

struct GreetingHeader: View {
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12: return "Good morning"
        case 12..<18: return "Good afternoon"
        case 18..<22: return "Good evening"
        default: return "Good night"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(greeting + ", xca")
                .font(Typography.largeTitle)
                .foregroundStyle(AppleColors.primaryText)
            
            Text("Ready to practice?")
                .font(Typography.title2)
                .foregroundStyle(AppleColors.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Continue Practice Card

struct ContinuePracticeCard: View {
    let conversation: Conversation
    let onContinue: () -> Void
    
    var body: some View {
        ZStack {
            // Gradient background
            RoundedRectangle(cornerRadius: CornerRadius.xl)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "5856D6").opacity(0.9),
                            Color(hex: "AF52DE").opacity(0.9)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Glass overlay
            RoundedRectangle(cornerRadius: CornerRadius.xl)
                .fill(.ultraThinMaterial)
            
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Text("In Progress")
                        .font(Typography.caption2)
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs)
                        .background(.white.opacity(0.2))
                        .clipShape(Capsule())
                }
                
                Spacer()
                
                let scene = SceneRepository.shared.getScene(id: conversation.sceneId)
                Text(scene?.name ?? "Practice")
                    .font(Typography.title2)
                    .foregroundStyle(.white)
                
                let duration = conversation.duration
                Text("\(duration) min · \(conversation.difficulty) Level")
                    .font(Typography.callout)
                    .foregroundStyle(.white.opacity(0.8))
                
                Spacer()
                
                Button(action: onContinue) {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "arrow.right.circle.fill")
                        Text("Resume Practice")
                    }
                    .font(Typography.bodyLarge.weight(.medium))
                    .foregroundStyle(Color(hex: "5856D6"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                }
                .buttonStyle(.plain)
            }
            .padding(Spacing.xl)
        }
        .frame(height: 260)
        .hoverScale()
    }
}

// MARK: - Scenes Section

struct ScenesSection: View {
    let scenes: [Scene]
    let onSelect: (Scene) -> Void
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            SectionHeader(title: "Scenes")
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Spacing.lg) {
                ForEach(scenes) { scene in
                    SceneCard(scene: scene) {
                        onSelect(scene)
                    }
                }
            }
        }
    }
}

// MARK: - Scene Card

struct SceneCard: View {
    let scene: Scene
    let onTap: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .fill(AppleColors.secondaryBackground)
                    
                    Text(scene.icon)
                        .font(.system(size: 44))
                }
                .frame(height: 100)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .stroke(AppleColors.accent.opacity(isHovered ? 0.3 : 0), lineWidth: 2)
                )
                
                VStack(spacing: Spacing.xs) {
                    Text(scene.name)
                        .font(Typography.callout.weight(.medium))
                        .foregroundStyle(AppleColors.primaryText)
                    
                    Text(scene.difficultyRange)
                        .font(Typography.caption)
                        .foregroundStyle(AppleColors.secondaryText)
                }
            }
        }
        .buttonStyle(.plain)
        .onHover { hovered in
            withAnimation(.spring(response: 0.3)) {
                isHovered = hovered
            }
        }
        .scaleEffect(isHovered ? 1.03 : 1.0)
    }
}

// MARK: - Stats Section

struct StatsSection: View {
    let stats: PracticeStats
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            SectionHeader(title: "Stats")
            
            HStack(spacing: Spacing.lg) {
                StatCard(
                    title: "This Week",
                    value: String(format: "%.1f hours", stats.totalHours),
                    change: stats.weekOverWeekChange > 0 ? "↑ \(Int(stats.weekOverWeekChange))%" : nil,
                    icon: "clock",
                    color: AppleColors.accent
                )
                
                StatCard(
                    title: "Streak",
                    value: "\(stats.streakDays) days",
                    change: nil,
                    icon: "flame.fill",
                    color: AppleColors.orangeGradient[0]
                )
                
                StatCard(
                    title: "Accuracy",
                    value: "\(stats.accuracy)%",
                    change: stats.accuracyChange > 0 ? "↑ \(stats.accuracyChange)%" : nil,
                    icon: "target",
                    color: AppleColors.success
                )
            }
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let change: String?
    let icon: String
    let color: Color
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(color)
                
                Spacer()
                
                if let change = change {
                    Text(change)
                        .font(Typography.caption2)
                        .foregroundStyle(AppleColors.success)
                }
            }
            
            Spacer()
            
            Text(value)
                .font(Typography.title3)
                .foregroundStyle(AppleColors.primaryText)
            
            Text(title)
                .font(Typography.caption)
                .foregroundStyle(AppleColors.secondaryText)
        }
        .padding(Spacing.lg)
        .frame(height: 110)
        .background(AppleColors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .onHover { hovered in
            withAnimation(.spring(response: 0.3)) {
                isHovered = hovered
            }
        }
        .scaleEffect(isHovered ? 1.02 : 1.0)
    }
}

// MARK: - Mistakes Preview

struct MistakesPreview: View {
    let count: Int
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            SectionHeader(title: "Mistakes")
            
            Button(action: onTap) {
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("\(count) items waiting for review")
                            .font(Typography.body)
                            .foregroundStyle(AppleColors.primaryText)
                        
                        Text("Review them to improve your skills")
                            .font(Typography.callout)
                            .foregroundStyle(AppleColors.secondaryText)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: Spacing.xs) {
                        Text("Review Now")
                            .font(Typography.callout.weight(.medium))
                        Image(systemName: "arrow.right")
                            .font(.callout)
                    }
                    .foregroundStyle(AppleColors.accent)
                }
                .padding(Spacing.lg)
                .background(AppleColors.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
            }
            .buttonStyle(.plain)
            .opacity(count > 0 ? 1 : 0.5)
            .disabled(count == 0)
        }
    }
}

// MARK: - Models

struct PracticeStats {
    var totalHours: Double = 0
    var streakDays: Int = 0
    var accuracy: Int = 0
    var weekOverWeekChange: Double = 0
    var accuracyChange: Int = 0
}
