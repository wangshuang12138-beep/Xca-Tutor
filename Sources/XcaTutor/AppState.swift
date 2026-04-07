import SwiftUI
import Combine

// MARK: - App State
class AppState: ObservableObject {
    @Published var selectedTab: Tab = .home
    @Published var showSceneSelection = false
    @Published var currentConversation: Conversation?
    @Published var showSettings = false
}

// MARK: - Tab Enum
enum Tab {
    case home, scenes, mistakeBook, stats, settings
}
