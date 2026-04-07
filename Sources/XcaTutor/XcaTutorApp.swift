import SwiftUI
import AppKit

@main
struct XcaTutorApp {
    static func main() {
        // 手动启动 NSApplication 和 SwiftUI
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}

// MARK: - App Delegate
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow?
    var appState = AppState()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 创建窗口
        let contentView = ContentView()
            .environmentObject(appState)
        
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window?.title = "Xca Tutor"
        window?.contentView = NSHostingView(rootView: contentView)
        window?.makeKeyAndOrderFront(nil)
        window?.center()
        
        // 设置菜单
        setupMenu()
    }
    
    func setupMenu() {
        let mainMenu = NSMenu()
        
        // App 菜单
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        let appMenu = NSMenu()
        appMenuItem.submenu = appMenu
        appMenu.addItem(withTitle: "退出 Xca Tutor", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        
        // 练习菜单
        let practiceMenuItem = NSMenuItem()
        practiceMenuItem.title = "练习"
        mainMenu.addItem(practiceMenuItem)
        let practiceMenu = NSMenu()
        practiceMenuItem.submenu = practiceMenu
        
        let newChatItem = NSMenuItem(title: "开始新对话", action: #selector(startNewChat), keyEquivalent: "n")
        newChatItem.keyEquivalentModifierMask = .command
        practiceMenu.addItem(newChatItem)
        
        let mistakeBookItem = NSMenuItem(title: "打开错题本", action: #selector(openMistakeBook), keyEquivalent: "b")
        mistakeBookItem.keyEquivalentModifierMask = .command
        practiceMenu.addItem(mistakeBookItem)
        
        // 视图菜单
        let viewMenuItem = NSMenuItem()
        viewMenuItem.title = "视图"
        mainMenu.addItem(viewMenuItem)
        let viewMenu = NSMenu()
        viewMenuItem.submenu = viewMenu
        
        let homeItem = NSMenuItem(title: "返回首页", action: #selector(goHome), keyEquivalent: "h")
        homeItem.keyEquivalentModifierMask = .command
        viewMenu.addItem(homeItem)
        
        let statsItem = NSMenuItem(title: "学习统计", action: #selector(showStats), keyEquivalent: "s")
        statsItem.keyEquivalentModifierMask = .command
        viewMenu.addItem(statsItem)
        
        NSApplication.shared.mainMenu = mainMenu
    }
    
    @objc func startNewChat() {
        appState.showSceneSelection = true
    }
    
    @objc func openMistakeBook() {
        appState.selectedTab = .mistakeBook
    }
    
    @objc func goHome() {
        appState.selectedTab = .home
    }
    
    @objc func showStats() {
        appState.selectedTab = .stats
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
