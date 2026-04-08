import Foundation

// MARK: - Conversation Extensions

extension Conversation {
    var duration: Int {
        guard let endTime = endTime else {
            return Int(Date().timeIntervalSince(startTime) / 60)
        }
        return Int(endTime.timeIntervalSince(startTime) / 60)
    }
    
    var sceneName: String {
        return SceneRepository.shared.getScene(id: UUID(uuidString: sceneId) ?? UUID())?.name ?? "Practice"
    }
}

// MARK: - Scene Extensions

extension Scene {
    var difficultyRange: String {
        return difficulty
    }
    
    var category: SceneCategory {
        if name.contains("Restaurant") || name.contains("Hotel") || name.contains("Airport") {
            return .travel
        } else if name.contains("Interview") || name.contains("Meeting") {
            return .business
        }
        return .daily
    }
    
    var estimatedDuration: Int {
        return 15
    }
}

// MARK: - Message Extensions

extension Message {
    var role: MessageRole {
        return MessageRole(rawValue: roleString) ?? .user
    }
}

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
    
    init(id: UUID, sceneId: UUID, startTime: Date, endTime: Date?, difficulty: String, duration: Int) {
        self.id = id.uuidString
        self.sceneId = sceneId.uuidString
        self.startTime = startTime
        self.endTime = endTime
        self.difficulty = difficulty
        self.status = endTime == nil ? .ongoing : .completed
        self.messages = []
    }
}

enum ConversationStatus: String, Codable {
    case ongoing, completed, aborted
}

struct Message: Identifiable, Codable {
    let id: String
    let roleString: String
    let content: String
    let timestamp: Date
    var audioFile: String?
    var durationMs: Int?
    
    init(id: String = UUID().uuidString,
         role: MessageRole,
         content: String,
         timestamp: Date = Date(),
         audioFile: String? = nil,
         durationMs: Int? = nil) {
        self.id = id
        self.roleString = role.rawValue
        self.content = content
        self.timestamp = timestamp
        self.audioFile = audioFile
        self.durationMs = durationMs
    }
    
    init(role: MessageRole, content: String) {
        self.id = UUID().uuidString
        self.roleString = role.rawValue
        self.content = content
        self.timestamp = Date()
        self.audioFile = nil
        self.durationMs = nil
    }
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

enum MistakeType: String, Codable, CaseIterable, Identifiable {
    case grammar, vocabulary, pronunciation
    
    var id: String { rawValue }
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

// MARK: - Scene Category

enum SceneCategory: String, CaseIterable, Identifiable {
    case daily = "Daily"
    case business = "Business"
    case travel = "Travel"
    case academic = "Academic"
    
    var id: String { rawValue }
}
