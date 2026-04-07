import Foundation

// MARK: - Data Models

struct Conversation: Identifiable, Codable {
    let id: String
    let sceneId: String
    let startTime: Date
    var endTime: Date?
    var difficulty: String
    var status: ConversationStatus
    var messages: [Message]
    
    init(id: String = UUID().uuidString,
         sceneId: String,
         startTime: Date = Date(),
         endTime: Date? = nil,
         difficulty: String = "B1",
         status: ConversationStatus = .ongoing,
         messages: [Message] = []) {
        self.id = id
        self.sceneId = sceneId
        self.startTime = startTime
        self.endTime = endTime
        self.difficulty = difficulty
        self.status = status
        self.messages = messages
    }
}

enum ConversationStatus: String, Codable {
    case ongoing, completed, aborted
}

struct Message: Identifiable, Codable {
    let id: String
    let role: MessageRole
    let content: String
    let timestamp: Date
    var audioFile: String?
    var durationMs: Int?
}

enum MessageRole: String, Codable {
    case user, assistant, system
}

struct Scene: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let difficulty: String
    let roleDescription: String
    let userRoleDescription: String
    let settingDescription: String
    let systemPrompt: String
    let hiddenTasks: [String]
    let openingLines: [String]
    let hints: [String]
    let isBuiltin: Bool
}

struct Mistake: Identifiable, Codable {
    let id: String
    let conversationId: String
    let messageId: String?
    let type: MistakeType
    let originalText: String
    let correctedText: String
    let explanation: String
    let context: String?
    let audioSnippet: String?
    var mastered: Bool
    var practiceCount: Int
    var lastPracticeTime: Date?
    let createdAt: Date
}

enum MistakeType: String, Codable {
    case grammar, vocabulary, pronunciation
}

struct ReviewReport: Identifiable, Codable {
    let id: String
    let conversationId: String
    let overallLevel: String
    let taskCompletion: Int
    let grammarAccuracy: Int
    let fluency: Int
    let vocabulary: Int
    let mistakes: [Mistake]
    let vocabularyHighlights: [VocabularyHighlight]
    let suggestions: [String]
    let createdAt: Date
}

struct VocabularyHighlight: Codable {
    let word: String
    let context: String
}

struct UserSettings: Codable {
    var apiKey: String
    var useProxy: Bool
    
    // 模型参数
    var chatModel: String
    var temperature: Double
    var maxTokens: Int
    var voiceName: String
    var whisperModel: String
    
    // 练习偏好
    var defaultDifficulty: String
    var autoUpgrade: Bool
    var correctionStrictness: String
    
    // UI
    var theme: String
    var language: String
    
    static let `default` = UserSettings(
        apiKey: "",
        useProxy: false,
        chatModel: "gpt-4o",
        temperature: 0.7,
        maxTokens: 2000,
        voiceName: "alloy",
        whisperModel: "whisper-1",
        defaultDifficulty: "B1",
        autoUpgrade: true,
        correctionStrictness: "standard",
        theme: "auto",
        language: "zh-CN"
    )
}

// MARK: - CEFR Levels
enum CEFRLevel: String, CaseIterable {
    case a1 = "A1"
    case a2 = "A2"
    case b1 = "B1"
    case b2 = "B2"
    case c1 = "C1"
    case c2 = "C2"
    
    var description: String {
        switch self {
        case .a1: return "入门级"
        case .a2: return "初级"
        case .b1: return "中级"
        case .b2: return "中高级"
        case .c1: return "高级"
        case .c2: return "精通级"
        }
    }
    
    var color: String {
        switch self {
        case .a1, .a2: return "levelA"
        case .b1, .b2: return "levelB"
        case .c1, .c2: return "levelC"
        }
    }
}
