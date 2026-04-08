import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            // Sidebar
            Sidebar()
                .frame(minWidth: 220, maxWidth: 260)
            
            // Main content based on selection
            mainContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationViewStyle(.automatic)
    }
    
    @ViewBuilder
    private var mainContent: some View {
        if let conversation = appState.currentConversation {
            PracticeView(conversation: conversation)
        } else {
            switch appState.selectedTab {
            case .home:
                HomeView()
            case .scenes:
                SceneSelectionView()
            case .mistakes:
                MistakeBookView()
            case .stats:
                StatisticsView()
            case .settings:
                SettingsView()
            }
        }
    }
}

// MARK: - Sidebar

struct Sidebar: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 0) {
            // App Icon
            HStack(spacing: Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .fill(
                            LinearGradient(
                                colors: AppleColors.purpleGradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "mic.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.white)
                }
                
                Text("Xca-Tutor")
                    .font(Typography.title3)
                    .foregroundStyle(AppleColors.primaryText)
                
                Spacer()
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.lg)
            
            Divider()
            
            // Navigation Items
            VStack(spacing: Spacing.xs) {
                SidebarItem(
                    icon: "house.fill",
                    title: "Home",
                    isSelected: appState.selectedTab == .home
                ) {
                    appState.selectedTab = .home
                }
                
                SidebarItem(
                    icon: "square.grid.2x2",
                    title: "Scenes",
                    isSelected: appState.selectedTab == .scenes
                ) {
                    appState.selectedTab = .scenes
                }
                
                SidebarItem(
                    icon: "exclamationmark.triangle.fill",
                    title: "Mistakes",
                    isSelected: appState.selectedTab == .mistakes,
                    badge: 12
                ) {
                    appState.selectedTab = .mistakes
                }
                
                SidebarItem(
                    icon: "chart.bar.fill",
                    title: "Statistics",
                    isSelected: appState.selectedTab == .stats
                ) {
                    appState.selectedTab = .stats
                }
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.md)
            
            Spacer()
            
            Divider()
            
            // Settings at bottom
            SidebarItem(
                icon: "gear",
                title: "Settings",
                isSelected: appState.selectedTab == .settings
            ) {
                appState.selectedTab = .settings
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.md)
        }
        .background(AppleColors.secondaryBackground)
    }
}

// MARK: - Sidebar Item

struct SidebarItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    var badge: Int? = nil
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? AppleColors.accent : AppleColors.secondaryText)
                    .frame(width: 24)
                
                Text(title)
                    .font(Typography.body.weight(isSelected ? .medium : .regular))
                    .foregroundStyle(isSelected ? AppleColors.primaryText : AppleColors.secondaryText)
                
                Spacer()
                
                if let badge = badge, badge > 0 {
                    Text("\(badge)")
                        .font(Typography.caption2.weight(.medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs)
                        .background(AppleColors.error)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(
                isSelected
                    ? AppleColors.accent.opacity(0.1)
                    : Color.clear
            )
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Scene Selection View

struct SceneSelectionView: View {
    @EnvironmentObject var appState: AppState
    @State private var scenes: [Scene] = []
    @State private var selectedCategory: SceneCategory? = nil
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: Spacing.xxl) {
                // Header
                Text("Choose a Scene")
                    .font(Typography.largeTitle)
                    .foregroundStyle(AppleColors.primaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, Spacing.lg)
                
                // Category filters
                CategoryFilter(
                    selected: $selectedCategory,
                    categories: [.daily, .business, .travel, .academic]
                )
                
                // Scenes grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: Spacing.lg) {
                    ForEach(filteredScenes) { scene in
                        LargeSceneCard(scene: scene) {
                            appState.startPractice(sceneId: scene.id)
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.xxl)
        }
        .background(AppleColors.background)
        .onAppear {
            scenes = SceneRepository.shared.getAllScenes()
        }
    }
    
    private var filteredScenes: [Scene] {
        guard let category = selectedCategory else { return scenes }
        return scenes.filter { $0.category == category }
    }
}

// MARK: - Category Filter

struct CategoryFilter: View {
    @Binding var selected: SceneCategory?
    let categories: [SceneCategory]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.md) {
                FilterChip(
                    title: "All",
                    isSelected: selected == nil
                ) {
                    selected = nil
                }
                
                ForEach(categories) { category in
                    FilterChip(
                        title: category.rawValue,
                        isSelected: selected == category
                    ) {
                        selected = category
                    }
                }
            }
            .padding(.vertical, Spacing.sm)
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Typography.callout.weight(isSelected ? .medium : .regular))
                .foregroundStyle(isSelected ? .white : AppleColors.primaryText)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(isSelected ? AppleColors.accent : AppleColors.secondaryBackground)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Large Scene Card

struct LargeSceneCard: View {
    let scene: Scene
    let onTap: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .fill(AppleColors.secondaryBackground)
                    
                    Text(scene.icon)
                        .font(.system(size: 64))
                }
                .frame(height: 160)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .stroke(AppleColors.accent.opacity(isHovered ? 0.3 : 0), lineWidth: 2)
                )
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(scene.name)
                        .font(Typography.title3)
                        .foregroundStyle(AppleColors.primaryText)
                    
                    Text(scene.description)
                        .font(Typography.callout)
                        .foregroundStyle(AppleColors.secondaryText)
                        .lineLimit(2)
                    
                    HStack(spacing: Spacing.sm) {
                        DifficultyBadge(difficulty: scene.difficultyRange)
                        
                        Spacer()
                        
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "clock")
                                .font(.caption)
                            Text("\(scene.estimatedDuration) min")
                                .font(Typography.caption)
                        }
                        .foregroundStyle(AppleColors.secondaryText)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .onHover { hovered in
            withAnimation(.spring(response: 0.3)) {
                isHovered = hovered
            }
        }
        .scaleEffect(isHovered ? 1.02 : 1.0)
    }
}

// MARK: - Difficulty Badge

struct DifficultyBadge: View {
    let difficulty: String
    
    var body: some View {
        Text(difficulty)
            .font(Typography.caption2.weight(.medium))
            .foregroundStyle(AppleColors.accent)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(AppleColors.accent.opacity(0.1))
            .clipShape(Capsule())
    }
}
