import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Group {
            if appState.currentConversation != nil {
                // 有对话时，显示练习界面（全屏）
                PracticeContainerView()
                    .environmentObject(appState)
            } else {
                // 没有对话时，显示主界面
                MainView()
                    .environmentObject(appState)
            }
        }
        .frame(minWidth: 900, minHeight: 600)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 主界面（左侧菜单 + 右侧内容）
struct MainView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            // 左侧边栏
            VStack(spacing: 0) {
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
                
                VStack(spacing: 4) {
                    MenuButton(icon: "house", title: "首页", tab: .home)
                    MenuButton(icon: "book", title: "场景练习", tab: .scenes)
                    MenuButton(icon: "bookmark", title: "错题本", tab: .mistakeBook)
                    MenuButton(icon: "chart.bar", title: "统计", tab: .stats)
                }
                .padding(.vertical, 8)
                
                Spacer()
                
                Divider()
                
                MenuButton(icon: "gear", title: "设置", tab: .settings)
                    .padding(.vertical, 8)
            }
            .frame(minWidth: 180, maxWidth: 200)
            .background(Color(NSColor.controlBackgroundColor))
            
            // 右侧内容区
            Group {
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
            .frame(minWidth: 700)
        }
        .sheet(isPresented: $appState.showSceneSelection) {
            SceneSelectionSheet()
                .environmentObject(appState)
                .frame(minWidth: 800, minHeight: 600)
        }
    }
}

// MARK: - 练习界面容器
struct PracticeContainerView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Group {
            if let conversation = appState.currentConversation {
                PracticeView(conversation: conversation)
                    .environmentObject(appState)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // 不应该发生，但为了防止崩溃
                Text("加载中...")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 菜单按钮
struct MenuButton: View {
    @EnvironmentObject var appState: AppState
    let icon: String
    let title: String
    let tab: Tab
    
    var isSelected: Bool { appState.selectedTab == tab }
    
    var body: some View {
        Button {
            appState.selectedTab = tab
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
