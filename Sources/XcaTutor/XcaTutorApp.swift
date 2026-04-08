import SwiftUI
import AppKit

@main
struct XcaTutorApp {
    static func main() {
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
        // Create window
        let contentView = ContentView()
            .environmentObject(appState)
        
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1200, height: 800),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        window?.title = "Xca-Tutor"
        window?.contentView = NSHostingView(rootView: contentView)
        window?.makeKeyAndOrderFront(nil)
        window?.center()
        window?.minSize = NSSize(width: 900, height: 600)
        
        // Setup menu
        setupMenu()
    }
    
    func setupMenu() {
        let mainMenu = NSMenu()
        
        // App menu
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        let appMenu = NSMenu()
        appMenuItem.submenu = appMenu
        appMenu.addItem(withTitle: "Quit Xca-Tutor", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        
        // Practice menu
        let practiceMenuItem = NSMenuItem()
        practiceMenuItem.title = "Practice"
        mainMenu.addItem(practiceMenuItem)
        let practiceMenu = NSMenu()
        practiceMenuItem.submenu = practiceMenu
        
        let newChatItem = NSMenuItem(title: "New Practice", action: #selector(startNewPractice), keyEquivalent: "n")
        newChatItem.keyEquivalentModifierMask = .command
        practiceMenu.addItem(newChatItem)
        
        let mistakeBookItem = NSMenuItem(title: "Mistake Book", action: #selector(openMistakeBook), keyEquivalent: "b")
        mistakeBookItem.keyEquivalentModifierMask = .command
        practiceMenu.addItem(mistakeBookItem)
        
        // View menu
        let viewMenuItem = NSMenuItem()
        viewMenuItem.title = "View"
        mainMenu.addItem(viewMenuItem)
        let viewMenu = NSMenu()
        viewMenuItem.submenu = viewMenu
        
        let homeItem = NSMenuItem(title: "Home", action: #selector(goHome), keyEquivalent: "h")
        homeItem.keyEquivalentModifierMask = .command
        viewMenu.addItem(homeItem)
        
        let statsItem = NSMenuItem(title: "Statistics", action: #selector(showStats), keyEquivalent: "s")
        statsItem.keyEquivalentModifierMask = .command
        viewMenu.addItem(statsItem)
        
        NSApplication.shared.mainMenu = mainMenu
    }
    
    @objc func startNewPractice() {
        appState.selectedTab = .scenes
    }
    
    @objc func openMistakeBook() {
        appState.selectedTab = .mistakes
    }
    
    @objc func goHome() {
        appState.selectedTab = .home
    }
    
    @objc func showStats() {
        appState.selectedTab = .stats
    }
}
