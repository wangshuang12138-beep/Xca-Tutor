import SwiftUI

@main
struct XcaTutorApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .frame(minWidth: 900, minHeight: 600)
        }
        .windowStyle(.titleBar)
        .commands {
            CommandMenu("练习") {
                Button("开始新对话") {
                    appState.showSceneSelection = true
                }
                .keyboardShortcut("n", modifiers: .command)
                
                Button("打开错题本") {
                    appState.selectedTab = .mistakeBook
                }
                .keyboardShortcut("b", modifiers: .command)
            }
            
            CommandMenu("视图") {
                Button("返回首页") {
                    appState.selectedTab = .home
                }
                .keyboardShortcut("h", modifiers: .command)
                
                Button("学习统计") {
                    appState.selectedTab = .stats
                }
                .keyboardShortcut("s", modifiers: .command)
            }
        }
        
        Settings {
            SettingsView()
                .frame(minWidth: 600, minHeight: 500)
        }
    }
}

// MARK: - App State
class AppState: ObservableObject {
    @Published var selectedTab: Tab = .home
    @Published var showSceneSelection = false
    @Published var currentConversation: Conversation?
    @Published var showSettings = false
}

enum Tab {
    case home, scenes, mistakeBook, stats
}
