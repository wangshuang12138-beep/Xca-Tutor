import SwiftUI
import Combine

// MARK: - App State
class AppState: ObservableObject {
    @Published var selectedTab: Tab = .home
    @Published var showSceneSelection = false
    @Published var currentConversation: Conversation?
    @Published var showSettings = false
    
    // MARK: - Navigation Methods
    
    func startPractice(sceneId: String) {
        currentConversation = Conversation(
            sceneId: sceneId,
            difficulty: "B1"
        )
    }
    
    func endPractice() {
        currentConversation = nil
    }
}

// MARK: - Tab Enum
enum Tab: String, CaseIterable {
    case home = "Home"
    case scenes = "Scenes"
    case mistakes = "Mistakes"
    case stats = "Stats"
    case settings = "Settings"
}
