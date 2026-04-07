# Xca-Tutor 技术方案文档 (TECH_SPEC)

> 版本：v0.1.0  
> 对应 PRD：v0.1.0  
> 平台：macOS

---

## 1. 技术选型

### 1.1 核心栈

| 层级 | 技术 | 说明 |
|------|------|------|
| 前端 | Swift + SwiftUI | macOS 原生，体验最佳 |
| 网络 | URLSession | 系统原生，支持 HTTP/2 |
| 数据 | SQLite + FMDB | 本地存储，轻量级 |
| 音频 | AVFoundation | 录音 + 播放 |
| Keychain | Security | API Key 安全存储 |

### 1.2 为什么不选其他方案

| 方案 | 放弃原因 |
|------|----------|
| Flutter | macOS 体验不如原生，且我们只做 macOS MVP |
| React Native | macOS 支持弱，性能不如原生 |
| Electron | 包体积大，启动慢，不适合音频应用 |
| Core Data | 太重，SQLite 更轻量可控 |

---

## 2. 系统架构

### 2.1 分层架构

```
┌─────────────────────────────────────────────────────────────┐
│                      Presentation Layer                     │
│  SwiftUI Views │ ViewModels │ Animations │ Audio Visualizer│
├─────────────────────────────────────────────────────────────┤
│                      Business Layer                         │
│  SceneManager │ ConversationService │ ReviewService         │
│  MistakeBookService │ AdaptiveDifficultyService             │
├─────────────────────────────────────────────────────────────┤
│                      Data Layer                             │
│  SQLiteManager │ AudioFileManager │ SettingsManager         │
├─────────────────────────────────────────────────────────────┤
│                      Network Layer                          │
│  OpenAIService │ WhisperAPI │ TTSAPI │ ChatAPI              │
├─────────────────────────────────────────────────────────────┤
│                      Platform Layer                         │
│  AudioRecorder │ AudioPlayer │ KeychainManager             │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 核心流程

**对话流程：**

```
用户点击"开始练习"
    │
    ▼
[SceneManager] 加载场景配置
    │
    ▼
[AudioRecorder] 开始监听麦克风
    │
    ▼
用户说话 ──→ [AudioRecorder] 检测到语音结束
    │
    ▼
[WhisperAPI] 上传音频 ──→ 返回文本
    │
    ▼
[ChatAPI] 发送：用户文本 + 上下文 + 场景设定
    │
    ▼
GPT-4o 返回回复文本
    │
    ▼
[TTSAPI] 合成语音
    │
    ▼
[AudioPlayer] 播放 + [SQLite] 存储记录
    │
    ▼
循环继续，直到用户结束
```

**复盘流程：**

```
用户点击"结束练习"
    │
    ▼
[ConversationService] 获取完整对话记录
    │
    ▼
[ReviewService] 调用 GPT-4o 分析
    ├── 语法错误检测
    ├── 词汇亮点提取
    └── 流利度评估
    │
    ▼
生成 Report 对象
    │
    ▼
[SQLite] 存储报告
[UI] 展示报告界面
```

---

## 3. 核心模块设计

### 3.1 网络层：OpenAIService

```swift
protocol OpenAIServiceProtocol {
    func transcribe(audioData: Data) async throws -> String
    func chat(messages: [ChatMessage], config: ModelConfig) async throws -> String
    func synthesize(text: String, voice: String) async throws -> Data
}

struct ModelConfig {
    let model: String        // "gpt-4o", "gpt-4o-mini"
    let temperature: Double  // 0.0 - 2.0
    let maxTokens: Int       // 100 - 4000
}

class OpenAIService: OpenAIServiceProtocol {
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1"
    
    // MARK: - Speech to Text
    func transcribe(audioData: Data) async throws -> String {
        // POST /audio/transcriptions
        // Model: whisper-1
    }
    
    // MARK: - Chat Completion
    func chat(messages: [ChatMessage], config: ModelConfig) async throws -> String {
        // POST /chat/completions
        // Stream: false (MVP 用非流式，简化实现)
    }
    
    // MARK: - Text to Speech
    func synthesize(text: String, voice: String) async throws -> Data {
        // POST /audio/speech
        // Model: tts-1, Voice: alloy/echo/fable/onyx/nova/shimmer
    }
}
```

### 3.2 数据层：SQLiteManager

**数据库 Schema：**

```sql
-- 用户配置表
CREATE TABLE user_settings (
    id INTEGER PRIMARY KEY CHECK (id = 1),
    api_key TEXT NOT NULL,
    use_proxy BOOLEAN DEFAULT FALSE,
    -- 模型参数
    chat_model TEXT DEFAULT 'gpt-4o',
    temperature REAL DEFAULT 0.7 CHECK (temperature BETWEEN 0 AND 2),
    max_tokens INTEGER DEFAULT 2000 CHECK (max_tokens BETWEEN 100 AND 4000),
    voice_name TEXT DEFAULT 'alloy' CHECK (voice_name IN ('alloy', 'echo', 'fable', 'onyx', 'nova', 'shimmer')),
    whisper_model TEXT DEFAULT 'whisper-1',
    -- 练习偏好
    default_difficulty TEXT DEFAULT 'B1' CHECK (default_difficulty IN ('A1', 'A2', 'B1', 'B2', 'C1', 'C2')),
    auto_upgrade BOOLEAN DEFAULT TRUE,
    correction_strictness TEXT DEFAULT 'standard',
    -- UI
    theme TEXT DEFAULT 'auto',
    language TEXT DEFAULT 'zh-CN'
);

-- 场景表
CREATE TABLE scenes (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    icon TEXT,
    system_prompt TEXT NOT NULL,
    hidden_tasks TEXT, -- JSON array
    difficulty TEXT,
    is_builtin BOOLEAN DEFAULT TRUE,
    created_at INTEGER
);

-- 对话记录表
CREATE TABLE conversations (
    id TEXT PRIMARY KEY,
    scene_id TEXT REFERENCES scenes(id),
    start_time INTEGER NOT NULL,
    end_time INTEGER,
    difficulty TEXT,
    status TEXT DEFAULT 'ongoing' CHECK (status IN ('ongoing', 'completed', 'aborted')),
    audio_folder TEXT -- 音频文件存储路径
);

-- 消息表
CREATE TABLE messages (
    id TEXT PRIMARY KEY,
    conversation_id TEXT REFERENCES conversations(id),
    role TEXT CHECK (role IN ('user', 'assistant', 'system')),
    content TEXT NOT NULL,
    audio_file TEXT, -- 音频文件名
    timestamp INTEGER NOT NULL,
    duration_ms INTEGER -- 音频时长
);

-- 错误记录表（错题本）
CREATE TABLE mistakes (
    id TEXT PRIMARY KEY,
    conversation_id TEXT REFERENCES conversations(id),
    message_id TEXT REFERENCES messages(id),
    type TEXT CHECK (type IN ('grammar', 'vocabulary', 'pronunciation')),
    original_text TEXT,
    corrected_text TEXT,
    explanation TEXT,
    context TEXT, -- 前后文
    audio_snippet TEXT, -- 错误片段音频
    mastered BOOLEAN DEFAULT FALSE,
    practice_count INTEGER DEFAULT 0,
    last_practice_time INTEGER,
    created_at INTEGER
);

-- 学习统计表（用于难度自适应）
CREATE TABLE learning_stats (
    id INTEGER PRIMARY KEY,
    date TEXT UNIQUE,
    conversation_count INTEGER DEFAULT 0,
    total_duration_ms INTEGER DEFAULT 0,
    avg_fluency REAL,
    avg_accuracy REAL,
    new_words INTEGER DEFAULT 0,
    mistakes_count INTEGER DEFAULT 0
);
```

**Swift 数据模型：**

```swift
struct UserSettings: Codable {
    var apiKey: String
    var chatModel: String
    var temperature: Double
    var maxTokens: Int
    var voiceName: String
    var whisperModel: String
    var defaultDifficulty: String
    var autoUpgrade: Bool
    // ...
}

struct Conversation: Codable {
    let id: String
    let sceneId: String
    let startTime: Date
    var endTime: Date?
    var difficulty: String
    var status: ConversationStatus
    var messages: [Message]
}

struct Message: Codable {
    let id: String
    let role: MessageRole
    let content: String
    let timestamp: Date
    var audioFile: String?
}

struct Mistake: Codable {
    let id: String
    let type: MistakeType
    let originalText: String
    let correctedText: String
    let explanation: String
    var mastered: Bool
    var practiceCount: Int
}
```

### 3.3 业务层：ConversationService

```swift
class ConversationService {
    private let openAI: OpenAIServiceProtocol
    private let sqlite: SQLiteManager
    private let audioRecorder: AudioRecorder
    private let audioPlayer: AudioPlayer
    
    // 当前对话状态
    private var currentConversation: Conversation?
    private var isRecording = false
    
    // MARK: - 开始对话
    func startConversation(scene: Scene) async throws -> Conversation {
        let conversation = Conversation(
            id: UUID().uuidString,
            sceneId: scene.id,
            startTime: Date(),
            difficulty: UserSettings.defaultDifficulty
        )
        
        // 保存到数据库
        try sqlite.saveConversation(conversation)
        
        // 创建音频文件夹
        try createAudioFolder(for: conversation.id)
        
        currentConversation = conversation
        
        // Agent 开场白
        let greeting = await generateGreeting(scene: scene)
        try await speak(text: greeting)
        
        // 开始监听用户输入
        startListening()
        
        return conversation
    }
    
    // MARK: - 处理用户语音
    private func handleUserSpeech(audioData: Data) async {
        guard let conversation = currentConversation else { return }
        
        // 1. 语音识别
        let userText = try? await openAI.transcribe(audioData: audioData)
        
        // 2. 保存用户消息
        let userMessage = Message(
            id: UUID().uuidString,
            role: .user,
            content: userText ?? "",
            timestamp: Date(),
            audioFile: saveAudio(data: audioData, conversationId: conversation.id)
        )
        try? sqlite.saveMessage(userMessage, conversationId: conversation.id)
        
        // 3. 获取历史上下文
        let history = try? sqlite.getMessages(conversationId: conversation.id, limit: 10)
        
        // 4. 调用 GPT
        let config = ModelConfig(
            model: UserSettings.chatModel,
            temperature: UserSettings.temperature,
            maxTokens: UserSettings.maxTokens
        )
        
        let messages = buildChatMessages(
            scene: conversation.scene,
            history: history,
            latestUserMessage: userText ?? ""
        )
        
        let assistantText = try? await openAI.chat(
            messages: messages,
            config: config
        )
        
        // 5. 语音合成并播放
        try? await speak(text: assistantText ?? "Sorry, I didn't catch that.")
        
        // 6. 保存 Agent 消息
        let assistantMessage = Message(
            id: UUID().uuidString,
            role: .assistant,
            content: assistantText ?? "",
            timestamp: Date(),
            audioFile: nil // TTS 音频可选择保存
        )
        try? sqlite.saveMessage(assistantMessage, conversationId: conversation.id)
    }
    
    // MARK: - 语音合成与播放
    private func speak(text: String) async throws {
        let audioData = try await openAI.synthesize(
            text: text,
            voice: UserSettings.voiceName
        )
        try audioPlayer.play(data: audioData)
    }
    
    // MARK: - 结束对话
    func endConversation() async throws -> ReviewReport {
        guard let conversation = currentConversation else {
            throw ConversationError.noActiveConversation
        }
        
        // 更新对话状态
        var completedConversation = conversation
        completedConversation.endTime = Date()
        completedConversation.status = .completed
        try sqlite.updateConversation(completedConversation)
        
        // 生成复盘报告
        let report = try await generateReviewReport(conversation: completedConversation)
        
        // 保存错误到错题本
        for mistake in report.mistakes {
            try sqlite.saveMistake(mistake)
        }
        
        currentConversation = nil
        
        return report
    }
}
```

### 3.4 音频层：AudioRecorder + AudioPlayer

```swift
protocol AudioRecorderProtocol {
    var isRecording: Bool { get }
    func startRecording() throws
    func stopRecording() -> Data?
    func detectVoiceActivity(callback: @escaping (Bool) -> Void)
}

protocol AudioPlayerProtocol {
    var isPlaying: Bool { get }
    func play(data: Data) throws
    func play(url: URL) throws
    func stop()
}

class AudioRecorder: AudioRecorderProtocol {
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var audioBuffer: [Data] = []
    
    // 语音活动检测（VAD）
    // 使用简单能量阈值，后续可升级为 WebRTC VAD
    func detectVoiceActivity(callback: @escaping (Bool) -> Void) {
        // 实现省略...
    }
}

class AudioPlayer: AudioPlayerProtocol {
    private var player: AVAudioPlayer?
    
    func play(data: Data) throws {
        player = try AVAudioPlayer(data: data)
        player?.prepareToPlay()
        player?.play()
    }
}
```

---

## 4. Prompt 工程

### 4.1 场景系统 Prompt 模板

```swift
func buildSystemPrompt(scene: Scene, difficulty: String) -> String {
    return """
    You are an English tutor helping a student practice \(scene.name) scenarios.
    
    Context:
    - Your role: \(scene.roleDescription)
    - Student's role: \(scene.userRoleDescription)
    - Current setting: \(scene.settingDescription)
    
    Difficulty level: \(difficulty)
    - A1-A2: Use simple sentences, basic vocabulary
    - B1-B2: Use natural conversation, some idioms
    - C1-C2: Use sophisticated language, nuanced expressions
    
    Instructions:
    1. Stay in character throughout the conversation
    2. Adapt your language complexity to the student's level
    3. If the student makes mistakes, don't interrupt - correct gently at the end
    4. Encourage the student to speak more
    5. Keep responses concise (2-3 sentences typically)
    
    Hidden tasks for this scene (don't reveal these directly):
    \(scene.hiddenTasks.joined(separator: "\n"))
    """
}
```

### 4.2 复盘分析 Prompt

```swift
func buildReviewPrompt(conversation: Conversation) -> String {
    let transcript = conversation.messages.map { msg in
        "\(msg.role == .user ? "Student" : "Tutor"): \(msg.content)"
    }.joined(separator: "\n")
    
    return """
    Analyze this English practice conversation and provide a detailed review.
    
    Conversation:
    \(transcript)
    
    Provide analysis in this JSON format:
    {
        "overallLevel": "A1|A2|B1|B2|C1|C2",
        "taskCompletion": 85,
        "grammarAccuracy": 82,
        "fluency": 78,
        "vocabulary": 80,
        "mistakes": [
            {
                "type": "grammar|vocabulary|pronunciation",
                "original": "incorrect sentence",
                "correction": "correct sentence",
                "explanation": "why it's wrong and how to improve"
            }
        ],
        "vocabularyHighlights": [
            {
                "word": "impressive word",
                "context": "how it was used"
            }
        ],
        "suggestions": ["improvement tip 1", "tip 2"]
    }
    """
}
```

---

## 5. 场景配置文件

**JSON 格式：**

```json
{
  "id": "restaurant-dining",
  "name": "餐厅点餐",
  "description": "在餐厅点餐、询问推荐、提出特殊要求",
  "icon": "🍽️",
  "difficulty": "A2-B1",
  "roleDescription": "You are a friendly waiter/waitress at an Italian restaurant",
  "userRoleDescription": "You are a customer dining at the restaurant",
  "settingDescription": "A cozy Italian restaurant with pasta, pizza, and wine on the menu",
  "systemPrompt": "...",
  "hiddenTasks": [
    "Successfully order a main course",
    "Ask for a recommendation from the server",
    "Specify a dietary requirement or preference (e.g., no onions, vegetarian)",
    "Request the check/bill",
    "(Bonus) Make a complaint about the food and get it resolved"
  ],
  "openingLines": [
    "Good evening! Welcome to Trattoria Roma. Do you have a reservation?",
    "Hi there! Table for how many?"
  ],
  "hints": [
    "Try asking 'What's your specialty?'",
    "You can say 'I'd like...' to order politely"
  ]
}
```

---

## 6. 开发路线图

### 6.1 模块依赖图

```
Week 1: 基础框架
├── Project Setup
├── SQLite Schema
├── Settings UI
└── API Key Management

Week 2: 音频 + 网络
├── Audio Recorder/Player
├── OpenAIService
├── Whisper Integration
└── TTS Integration

Week 3: 对话核心
├── ConversationService
├── Scene System
├── Chat UI
└── Real-time Subtitle

Week 4: 复盘 + 错题本
├── ReviewService
├── Report Generation
├── MistakeBook UI
└── Timeline Playback

Week 5:  polish
├── Difficulty Adaptation
├── UI Polish
├── Bug Fixes
└── TestFlight Beta
```

### 6.2 关键里程碑

| 里程碑 | 验收标准 | 时间 |
|--------|----------|------|
| M1 | 能录音 → 识别 → GPT 回复 → 语音播放 | Week 2 |
| M2 | 完整对话流程跑通，有字幕显示 | Week 3 |
| M3 | 对话结束后生成报告 | Week 4 |
| M4 | MVP 功能完整，可内测 | Week 5 |

---

## 7. 风险与应对

| 风险 | 影响 | 应对策略 |
|------|------|----------|
| OpenAI API 延迟高 | 用户体验差 | 添加加载动画，优化超时处理 |
| 语音识别不准 | 误解用户意图 | 允许用户手动编辑识别结果 |
| 音频文件过大 | 占用存储 | 使用 AAC 压缩，定期清理旧文件 |
| API Key 泄露 | 安全问题 | 存储在 Keychain，不在内存长期保留 |

---

## 8. 待补充文档

- [ ] API 接口详细文档
- [ ] 场景配置 JSON Schema
- [ ] 测试用例文档
- [ ] UI 组件规范（颜色、字体、间距）
