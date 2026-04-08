import SwiftUI
import Combine

// MARK: - App State
class AppState: ObservableObject {
    @Published var selectedTab: Tab = .home
    @Published var showSceneSelection = false
    @Published var currentConversation: Conversation?
    @Published var showSettings = false
    
    // MARK: - Navigation Methods
    
    func startPractice(sceneId: UUID) {
        currentConversation = Conversation(
            id: UUID(),
            sceneId: sceneId,
            startTime: Date(),
            endTime: nil,
            difficulty: "B1",
            duration: 0
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
