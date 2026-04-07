import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            Sidebar()
                .frame(minWidth: 180, maxWidth: 200)
            
            // 根据选中标签显示不同内容
            ContentArea()
                .frame(minWidth: 700)
        }
        .frame(minWidth: 900, minHeight: 600)
        .sheet(isPresented: $appState.showSceneSelection) {
            SceneSelectionView()
                .frame(minWidth: 800, minHeight: 600)
        }
        .overlay {
            // 使用 overlay 而不是 sheet 显示练习界面
            if let conversation = appState.currentConversation {
                PracticeOverlay(conversation: conversation)
                    .transition(.move(edge: .trailing))
            }
        }
    }
}

// MARK: - Practice Overlay
struct PracticeOverlay: View {
    let conversation: Conversation
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        PracticeView(conversation: conversation)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Sidebar
struct Sidebar: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 0) {
            // Logo
            HStack {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                Text("Xca")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding()
            
            Divider()
            
            // Menu Items
            VStack(spacing: 4) {
                NavItem(icon: "house", title: "首页", tab: .home)
                NavItem(icon: "book", title: "场景练习", tab: .scenes)
                NavItem(icon: "bookmark", title: "错题本", tab: .mistakeBook)
                NavItem(icon: "chart.bar", title: "统计", tab: .stats)
            }
            .padding(.vertical, 8)
            
            Spacer()
            
            Divider()
            
            // Settings
            NavItem(icon: "gear", title: "设置", tab: .settings)
                .padding(.vertical, 8)
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct NavItem: View {
    @EnvironmentObject var appState: AppState
    let icon: String
    let title: String
    let tab: Tab
    
    var isSelected: Bool { appState.selectedTab == tab }
    
    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                appState.selectedTab = tab
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 20)
                Text(title)
                    .font(.system(size: 14))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? Color.blue.opacity(0.12) : Color.clear)
            .foregroundColor(isSelected ? .blue : .primary.opacity(0.8))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
    }
}

// MARK: - Content Area
struct ContentArea: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        switch appState.selectedTab {
        case .home:
            HomeView()
        case .scenes:
            SceneSelectionView()
        case .mistakeBook:
            MistakeBookView()
        case .stats:
            StatisticsView()
        case .settings:
            SettingsView()
        }
    }
}


