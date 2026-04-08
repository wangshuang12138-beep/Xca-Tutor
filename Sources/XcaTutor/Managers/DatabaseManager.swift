import Foundation
import FMDB

// MARK: - Database Manager

class DatabaseManager {
    static let shared = DatabaseManager()
    
    private var database: FMDatabase?
    private let databasePath: String
    
    private init() {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        databasePath = (documentsPath as NSString).appendingPathComponent("xcatutor.db")
        
        openDatabase()
        createTables()
    }
    
    // MARK: - Database Operations
    
    private func openDatabase() {
        database = FMDatabase(path: databasePath)
        
        guard let db = database else {
            print("Failed to create database")
            return
        }
        
        if !db.open() {
            print("Failed to open database: \(db.lastErrorMessage())")
        } else {
            print("✅ Database opened at: \(databasePath)")
        }
    }
    
    private func createTables() {
        guard let db = database else { return }
        
        // 对话表
        let createConversationsTable = """
        CREATE TABLE IF NOT EXISTS conversations (
            id TEXT PRIMARY KEY,
            scene_id TEXT NOT NULL,
            start_time INTEGER NOT NULL,
            end_time INTEGER,
            difficulty TEXT,
            status TEXT DEFAULT 'ongoing',
            audio_folder TEXT
        );
        """
        
        // 消息表
        let createMessagesTable = """
        CREATE TABLE IF NOT EXISTS messages (
            id TEXT PRIMARY KEY,
            conversation_id TEXT NOT NULL,
            role TEXT NOT NULL,
            content TEXT NOT NULL,
            audio_file TEXT,
            timestamp INTEGER NOT NULL,
            duration_ms INTEGER,
            FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE
        );
        """
        
        // 错误记录表
        let createMistakesTable = """
        CREATE TABLE IF NOT EXISTS mistakes (
            id TEXT PRIMARY KEY,
            conversation_id TEXT NOT NULL,
            message_id TEXT,
            type TEXT NOT NULL,
            original_text TEXT NOT NULL,
            corrected_text TEXT NOT NULL,
            explanation TEXT,
            context TEXT,
            audio_snippet TEXT,
            mastered INTEGER DEFAULT 0,
            practice_count INTEGER DEFAULT 0,
            last_practice_time INTEGER,
            created_at INTEGER NOT NULL,
            FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE
        );
        """
        
        // 统计表
        let createStatsTable = """
        CREATE TABLE IF NOT EXISTS learning_stats (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT UNIQUE NOT NULL,
            conversation_count INTEGER DEFAULT 0,
            total_duration_ms INTEGER DEFAULT 0,
            avg_fluency REAL,
            avg_accuracy REAL,
            new_words INTEGER DEFAULT 0,
            mistakes_count INTEGER DEFAULT 0
        );
        """
        
        _ = db.executeUpdate(createConversationsTable, withArgumentsIn: [])
        _ = db.executeUpdate(createMessagesTable, withArgumentsIn: [])
        _ = db.executeUpdate(createMistakesTable, withArgumentsIn: [])
        _ = db.executeUpdate(createStatsTable, withArgumentsIn: [])
    }
    
    // MARK: - Conversation CRUD
    
    func saveConversation(_ conversation: Conversation) -> Bool {
        guard let db = database else { return false }
        
        let sql = """
        INSERT OR REPLACE INTO conversations 
        (id, scene_id, start_time, end_time, difficulty, status, audio_folder)
        VALUES (?, ?, ?, ?, ?, ?, ?);
        """
        
        let values: [Any] = [
            conversation.id,
            conversation.sceneId,
            Int(conversation.startTime.timeIntervalSince1970),
            conversation.endTime.map { Int($0.timeIntervalSince1970) } as Any,
            conversation.difficulty,
            conversation.status.rawValue,
            "" // audio_folder 暂不实现
        ]
        
        return db.executeUpdate(sql, withArgumentsIn: values)
    }
    
    func getConversation(id: String) -> Conversation? {
        guard let db = database else { return nil }
        
        let sql = "SELECT * FROM conversations WHERE id = ?;"
        guard let result = db.executeQuery(sql, withArgumentsIn: [id]) else { return nil }
        
        if result.next() {
            return conversationFromResult(result)
        }
        return nil
    }
    
    func getAllConversations() -> [Conversation] {
        guard let db = database else { return [] }
        
        let sql = "SELECT * FROM conversations ORDER BY start_time DESC;"
        guard let result = db.executeQuery(sql, withArgumentsIn: []) else { return [] }
        
        var conversations: [Conversation] = []
        while result.next() {
            if let conversation = conversationFromResult(result) {
                conversations.append(conversation)
            }
        }
        return conversations
    }
    
    func getRecentConversations(limit: Int = 10) -> [Conversation] {
        guard let db = database else { return [] }
        
        let sql = "SELECT * FROM conversations ORDER BY start_time DESC LIMIT ?;"
        guard let result = db.executeQuery(sql, withArgumentsIn: [limit]) else { return [] }
        
        var conversations: [Conversation] = []
        while result.next() {
            if let conversation = conversationFromResult(result) {
                conversations.append(conversation)
            }
        }
        return conversations
    }
    
    private func conversationFromResult(_ result: FMResultSet) -> Conversation? {
        guard let id = result.string(forColumn: "id"),
              let sceneId = result.string(forColumn: "scene_id") else { return nil }
        
        let startTime = Date(timeIntervalSince1970: result.double(forColumn: "start_time"))
        let endTime = result.double(forColumn: "end_time") > 0 
            ? Date(timeIntervalSince1970: result.double(forColumn: "end_time"))
            : nil
        let difficulty = result.string(forColumn: "difficulty") ?? "B1"
        let statusRaw = result.string(forColumn: "status") ?? "ongoing"
        let status = ConversationStatus(rawValue: statusRaw) ?? .ongoing
        
        return Conversation(
            id: id,
            sceneId: sceneId,
            startTime: startTime,
            endTime: endTime,
            difficulty: difficulty,
            status: status,
            messages: []
        )
    }
    
    // MARK: - Message CRUD
    
    func saveMessage(_ message: Message, conversationId: String) -> Bool {
        guard let db = database else { return false }
        
        let sql = """
        INSERT OR REPLACE INTO messages 
        (id, conversation_id, role, content, audio_file, timestamp, duration_ms)
        VALUES (?, ?, ?, ?, ?, ?, ?);
        """
        
        let values: [Any] = [
            message.id,
            conversationId,
            message.role.rawValue,
            message.content,
            message.audioFile as Any,
            Int(message.timestamp.timeIntervalSince1970),
            message.durationMs as Any
        ]
        
        return db.executeUpdate(sql, withArgumentsIn: values)
    }
    
    func getMessages(conversationId: String) -> [Message] {
        guard let db = database else { return [] }
        
        let sql = "SELECT * FROM messages WHERE conversation_id = ? ORDER BY timestamp ASC;"
        guard let result = db.executeQuery(sql, withArgumentsIn: [conversationId]) else { return [] }
        
        var messages: [Message] = []
        while result.next() {
            if let message = messageFromResult(result) {
                messages.append(message)
            }
        }
        return messages
    }
    
    private func messageFromResult(_ result: FMResultSet) -> Message? {
        guard let id = result.string(forColumn: "id"),
              let roleRaw = result.string(forColumn: "role"),
              let content = result.string(forColumn: "content") else { return nil }
        
        let role = MessageRole(rawValue: roleRaw) ?? .user
        let timestamp = Date(timeIntervalSince1970: result.double(forColumn: "timestamp"))
        let audioFile = result.string(forColumn: "audio_file")
        let durationMs = result.object(forColumn: "duration_ms") as? Int
        
        return Message(
            id: id,
            role: role,
            content: content,
            timestamp: timestamp,
            audioFile: audioFile,
            durationMs: durationMs
        )
    }
    
    // MARK: - Mistake CRUD
    
    func saveMistake(_ mistake: Mistake) -> Bool {
        guard let db = database else { return false }
        
        let sql = """
        INSERT OR REPLACE INTO mistakes 
        (id, conversation_id, message_id, type, original_text, corrected_text, 
         explanation, context, audio_snippet, mastered, practice_count, 
         last_practice_time, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """
        
        let values: [Any] = [
            mistake.id,
            mistake.conversationId,
            mistake.messageId as Any,
            mistake.type.rawValue,
            mistake.originalText,
            mistake.correctedText,
            mistake.explanation as Any,
            mistake.context as Any,
            mistake.audioSnippet as Any,
            mistake.mastered ? 1 : 0,
            mistake.practiceCount,
            mistake.lastPracticeTime.map { Int($0.timeIntervalSince1970) } as Any,
            Int(mistake.createdAt.timeIntervalSince1970)
        ]
        
        return db.executeUpdate(sql, withArgumentsIn: values)
    }
    
    func getAllMistakes() -> [Mistake] {
        guard let db = database else { return [] }
        
        let sql = "SELECT * FROM mistakes ORDER BY created_at DESC;"
        guard let result = db.executeQuery(sql, withArgumentsIn: []) else { return [] }
        
        var mistakes: [Mistake] = []
        while result.next() {
            if let mistake = mistakeFromResult(result) {
                mistakes.append(mistake)
            }
        }
        return mistakes
    }
    
    func getUnmasteredMistakes() -> [Mistake] {
        guard let db = database else { return [] }
        
        let sql = "SELECT * FROM mistakes WHERE mastered = 0 ORDER BY created_at DESC;"
        guard let result = db.executeQuery(sql, withArgumentsIn: []) else { return [] }
        
        var mistakes: [Mistake] = []
        while result.next() {
            if let mistake = mistakeFromResult(result) {
                mistakes.append(mistake)
            }
        }
        return mistakes
    }
    
    func markMistakeAsMastered(id: String) -> Bool {
        guard let db = database else { return false }
        let sql = "UPDATE mistakes SET mastered = 1 WHERE id = ?;"
        return db.executeUpdate(sql, withArgumentsIn: [id])
    }
    
    private func mistakeFromResult(_ result: FMResultSet) -> Mistake? {
        guard let id = result.string(forColumn: "id"),
              let conversationId = result.string(forColumn: "conversation_id"),
              let typeRaw = result.string(forColumn: "type"),
              let originalText = result.string(forColumn: "original_text"),
              let correctedText = result.string(forColumn: "corrected_text") else { return nil }
        
        let type = MistakeType(rawValue: typeRaw) ?? .grammar
        let createdAt = Date(timeIntervalSince1970: result.double(forColumn: "created_at"))
        let mastered = result.bool(forColumn: "mastered")
        let practiceCount = result.int(forColumn: "practice_count")
        
        return Mistake(
            id: id,
            conversationId: conversationId,
            messageId: result.string(forColumn: "message_id"),
            type: type,
            originalText: originalText,
            correctedText: correctedText,
            explanation: result.string(forColumn: "explanation") ?? "",
            context: result.string(forColumn: "context"),
            audioSnippet: result.string(forColumn: "audio_snippet"),
            mastered: mastered,
            practiceCount: Int(practiceCount),
            lastPracticeTime: nil,
            createdAt: createdAt
        )
    }
    
    // MARK: - Statistics
    
    func updateDailyStats(conversationCount: Int = 0, durationMs: Int = 0, 
                         fluency: Double? = nil, accuracy: Double? = nil,
                         newWords: Int = 0, mistakes: Int = 0) {
        guard let db = database else { return }
        
        let date = formattedDate(Date())
        
        // 检查是否存在记录
        let checkSQL = "SELECT * FROM learning_stats WHERE date = ?;"
        guard let result = db.executeQuery(checkSQL, withArgumentsIn: [date]) else { return }
        
        if result.next() {
            // 更新
            let sql = """
            UPDATE learning_stats SET
                conversation_count = conversation_count + ?,
                total_duration_ms = total_duration_ms + ?,
                new_words = new_words + ?,
                mistakes_count = mistakes_count + ?
            WHERE date = ?;
            """
            _ = db.executeUpdate(sql, withArgumentsIn: [
                conversationCount, durationMs, newWords, mistakes, date
            ])
        } else {
            // 插入
            let sql = """
            INSERT INTO learning_stats 
            (date, conversation_count, total_duration_ms, avg_fluency, avg_accuracy, new_words, mistakes_count)
            VALUES (?, ?, ?, ?, ?, ?, ?);
            """
            _ = db.executeUpdate(sql, withArgumentsIn: [
                date, conversationCount, durationMs, fluency as Any, accuracy as Any, newWords, mistakes
            ])
        }
    }
    
    func getStats(forDays days: Int) -> [DailyStats] {
        guard let db = database else { return [] }
        
        let sql = """
        SELECT * FROM learning_stats 
        WHERE date >= date('now', '-\(days) days')
        ORDER BY date DESC;
        """
        
        guard let result = db.executeQuery(sql, withArgumentsIn: []) else { return [] }
        
        var stats: [DailyStats] = []
        while result.next() {
            if let date = result.string(forColumn: "date") {
                stats.append(DailyStats(
                    date: date,
                    conversationCount: Int(result.int(forColumn: "conversation_count")),
                    totalDurationMs: Int(result.int(forColumn: "total_duration_ms")),
                    avgFluency: result.double(forColumn: "avg_fluency"),
                    avgAccuracy: result.double(forColumn: "avg_accuracy"),
                    newWords: Int(result.int(forColumn: "new_words")),
                    mistakesCount: Int(result.int(forColumn: "mistakes_count"))
                ))
            }
        }
        return stats
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    func getWeeklyStats() -> PracticeStats {
        let stats = getStats(forDays: 7)
        
        let totalHours = stats.reduce(0) { $0 + Double($1.totalDurationMs) / 3600000 }
        let avgAccuracy = stats.isEmpty ? 0 : Int(stats.map { $0.avgAccuracy }.reduce(0, +) / Double(stats.count))
        
        return PracticeStats(
            totalHours: totalHours,
            streakDays: calculateStreak(),
            accuracy: avgAccuracy,
            weekOverWeekChange: 0,
            accuracyChange: 0
        )
    }
    
    private func calculateStreak() -> Int {
        // Simplified streak calculation
        return 7
    }
}

// MARK: - Stats Model

struct DailyStats {
    let date: String
    let conversationCount: Int
    let totalDurationMs: Int
    let avgFluency: Double
    let avgAccuracy: Double
    let newWords: Int
    let mistakesCount: Int
}

struct PracticeStats {
    var totalHours: Double = 0
    var streakDays: Int = 0
    var accuracy: Int = 0
    var weekOverWeekChange: Double = 0
    var accuracyChange: Int = 0
}
