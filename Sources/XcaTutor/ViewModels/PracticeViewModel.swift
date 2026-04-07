import SwiftUI
import Foundation

@MainActor
class PracticeViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var messages: [Message] = []
    @Published var isRecording = false
    @Published var isProcessing = false
    @Published var isPaused = false
    @Published var statusText: String?
    @Published var difficulty: String
    
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var showEndConfirmation = false
    @Published var showReport = false
    @Published var report: ReviewReport?
    
    // MARK: - Dependencies
    let conversation: Conversation
    var scene: Scene?
    
    private let audioRecorder = AudioRecorder()
    private let audioPlayer = AudioPlayer()
    private let settings = SettingsManager.shared.settings
    private var openAIService: OpenAIService?
    
    // MARK: - Initialization
    
    init(conversation: Conversation) {
        self.conversation = conversation
        self.difficulty = conversation.difficulty
        self.scene = SceneRepository.shared.builtinScenes.first { $0.id == conversation.sceneId }
        
        setupAudioHandlers()
        
        // 重新加载设置以确保最新
        SettingsManager.shared.loadSettings()
        let currentSettings = SettingsManager.shared.settings
        
        print("📋 当前设置:")
        print("  API Key: \(currentSettings.apiKey.prefix(10))...")
        print("  Use Proxy: \(currentSettings.useProxy)")
        print("  Proxy URL: \(currentSettings.proxyBaseURL)")
        
        // 如果有 API Key，初始化服务
        if !currentSettings.apiKey.isEmpty {
            let baseURL = currentSettings.useProxy ? currentSettings.proxyBaseURL : "https://api.openai.com/v1"
            print("🌐 使用 Base URL: \(baseURL)")
            openAIService = OpenAIService(apiKey: currentSettings.apiKey, baseURL: baseURL)
        } else {
            print("⚠️ API Key 为空")
        }
        
        // 添加系统消息
        if let scene = scene {
            let systemMessage = Message(
                id: UUID().uuidString,
                role: .system,
                content: scene.systemPrompt,
                timestamp: Date()
            )
            messages.append(systemMessage)
            
            // Agent 开场白 - 延迟执行确保视图已加载
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                Task { @MainActor in
                    await self?.sendAgentGreeting()
                }
            }
        }
    }
    
    // MARK: - Setup
    
    private func setupAudioHandlers() {
        audioRecorder.onRecordingFinished = { [weak self] data in
            Task { @MainActor in
                await self?.handleRecordingFinished(data)
            }
        }
        
        audioRecorder.onError = { [weak self] error in
            Task { @MainActor in
                self?.showError(message: error.localizedDescription)
            }
        }
        
        audioPlayer.onPlaybackFinished = { [weak self] in
            Task { @MainActor in
                self?.statusText = nil
            }
        }
    }
    
    // MARK: - Recording Control
    
    func toggleRecording() {
        guard !isProcessing else { return }
        
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        guard openAIService != nil else {
            showError(message: "请先配置 OpenAI API Key")
            return
        }
        
        guard !isPaused else {
            showError(message: "练习已暂停，请先恢复")
            return
        }
        
        do {
            try audioRecorder.startRecording()
            isRecording = true
            statusText = "正在听..."
        } catch AudioError.permissionDenied {
            showError(message: "需要麦克风权限，请在系统设置中允许访问")
        } catch {
            showError(message: "启动录音失败: \(error.localizedDescription)")
        }
    }
    
    private func stopRecording() {
        audioRecorder.stopRecording()
        isRecording = false
        statusText = nil
    }
    
    // MARK: - Message Handling
    
    private func handleRecordingFinished(_ audioData: Data) async {
        guard let service = openAIService else { return }
        
        isProcessing = true
        statusText = "识别中..."
        
        do {
            // 1. 语音识别
            let userText = try await service.transcribe(audioData: audioData)
            
            guard !userText.isEmpty else {
                isProcessing = false
                statusText = nil
                return
            }
            
            // 2. 添加用户消息
            let userMessage = Message(
                id: UUID().uuidString,
                role: .user,
                content: userText,
                timestamp: Date()
            )
            messages.append(userMessage)
            
            // 3. 获取 AI 回复
            statusText = "思考中..."
            let assistantText = try await fetchAIResponse(userText: userText)
            
            // 4. 添加 AI 消息
            let assistantMessage = Message(
                id: UUID().uuidString,
                role: .assistant,
                content: assistantText,
                timestamp: Date()
            )
            messages.append(assistantMessage)
            
            // 5. 语音合成并播放
            statusText = "朗读中..."
            let audioData = try await service.synthesize(text: assistantText, voice: settings.voiceName)
            try audioPlayer.play(data: audioData)
            
        } catch {
            showError(message: error.localizedDescription)
        }
        
        isProcessing = false
        if !audioPlayer.isPlaying {
            statusText = nil
        }
    }
    
    private func fetchAIResponse(userText: String) async throws -> String {
        guard let service = openAIService else {
            throw PracticeError.noAPIKey
        }
        
        // 构建对话历史
        let chatMessages = messages.map { msg in
            ChatMessage(role: msg.role.rawValue, content: msg.content)
        } + [ChatMessage(role: "user", content: userText)]
        
        let config = ModelConfig(
            model: settings.chatModel,
            temperature: settings.temperature,
            maxTokens: settings.maxTokens
        )
        
        return try await service.chat(messages: chatMessages, config: config)
    }
    
    private func sendAgentGreeting() async {
        guard let scene = scene,
              let greeting = scene.openingLines.first,
              let service = openAIService else { return }
        
        isProcessing = true
        statusText = "准备中..."
        
        do {
            // 添加开场白消息
            let greetingMessage = Message(
                id: UUID().uuidString,
                role: .assistant,
                content: greeting,
                timestamp: Date()
            )
            messages.append(greetingMessage)
            
            // 播放开场白
            let audioData = try await service.synthesize(text: greeting, voice: settings.voiceName)
            try audioPlayer.play(data: audioData)
            
        } catch {
            showError(message: error.localizedDescription)
        }
        
        isProcessing = false
    }
    
    // MARK: - Conversation Control
    
    func endConversation() {
        Task {
            await generateReport()
        }
    }
    
    func generateReport() async {
        guard let service = openAIService else {
            showError(message: "无法生成报告：未配置 API")
            return
        }
        
        isProcessing = true
        statusText = "生成报告中..."
        
        // 过滤掉系统消息
        let chatMessages = messages.filter { $0.role != .system }
        
        guard chatMessages.count >= 2 else {
            report = createEmptyReport()
            showReport = true
            isProcessing = false
            return
        }
        
        do {
            let prompt = buildReviewPrompt(messages: chatMessages)
            let config = ModelConfig(
                model: settings.chatModel,
                temperature: 0.3,
                maxTokens: 2000
            )
            
            let response = try await service.chat(
                messages: [.init(role: "user", content: prompt)],
                config: config
            )
            
            // 解析报告
            report = parseReport(from: response, messages: chatMessages)
            showReport = true
            
        } catch {
            // 如果解析失败，生成空报告
            report = createEmptyReport()
            showReport = true
        }
        
        isProcessing = false
    }
    
    private func buildReviewPrompt(messages: [Message]) -> String {
        let transcript = messages.map { msg in
            "\(msg.role == .user ? "Student" : "Tutor"): \(msg.content)"
        }.joined(separator: "\n")
        
        return """
        Analyze this English practice conversation and provide a detailed review.
        
        Scene: \(scene?.name ?? "General Conversation")
        Student Level: \(difficulty)
        
        Conversation:
        \(transcript)
        
        Provide analysis in this exact JSON format:
        {
            "overallLevel": "A1|A2|B1|B2|C1|C2",
            "taskCompletion": 85,
            "grammarAccuracy": 82,
            "fluency": 78,
            "vocabulary": 80,
            "mistakes": [
                {
                    "type": "grammar|vocabulary",
                    "original": "incorrect sentence",
                    "corrected": "correct sentence",
                    "explanation": "why it's wrong"
                }
            ],
            "vocabularyHighlights": [
                {
                    "word": "impressive word",
                    "context": "how it was used"
                }
            ],
            "suggestions": ["tip 1", "tip 2"]
        }
        
        Only return the JSON, no other text.
        """
    }
    
    private func parseReport(from response: String, messages: [Message]) -> ReviewReport {
        // 尝试提取 JSON
        var jsonString = response
        if let start = response.firstIndex(of: "{"),
           let end = response.lastIndex(of: "}") {
            jsonString = String(response[start...end])
        }
        
        // 解析
        struct ReportData: Codable {
            let overallLevel: String
            let taskCompletion: Int
            let grammarAccuracy: Int
            let fluency: Int
            let vocabulary: Int
            let mistakes: [MistakeData]
            let vocabularyHighlights: [VocabData]
            let suggestions: [String]
            
            struct MistakeData: Codable {
                let type: String
                let original: String
                let corrected: String
                let explanation: String
            }
            
            struct VocabData: Codable {
                let word: String
                let context: String
            }
        }
        
        do {
            let data = jsonString.data(using: .utf8)!
            let reportData = try JSONDecoder().decode(ReportData.self, from: data)
            
            let mistakes = reportData.mistakes.map { m in
                Mistake(
                    id: UUID().uuidString,
                    conversationId: conversation.id,
                    messageId: nil,
                    type: MistakeType(rawValue: m.type) ?? .grammar,
                    originalText: m.original,
                    correctedText: m.corrected,
                    explanation: m.explanation,
                    context: nil,
                    audioSnippet: nil,
                    mastered: false,
                    practiceCount: 0,
                    lastPracticeTime: nil,
                    createdAt: Date()
                )
            }
            
            let highlights = reportData.vocabularyHighlights.map { VocabularyHighlight(word: $0.word, context: $0.context) }
            
            return ReviewReport(
                id: UUID().uuidString,
                conversationId: conversation.id,
                overallLevel: reportData.overallLevel,
                taskCompletion: reportData.taskCompletion,
                grammarAccuracy: reportData.grammarAccuracy,
                fluency: reportData.fluency,
                vocabulary: reportData.vocabulary,
                mistakes: mistakes,
                vocabularyHighlights: highlights,
                suggestions: reportData.suggestions,
                createdAt: Date()
            )
        } catch {
            return createEmptyReport()
        }
    }
    
    private func createEmptyReport() -> ReviewReport {
        ReviewReport(
            id: UUID().uuidString,
            conversationId: conversation.id,
            overallLevel: difficulty,
            taskCompletion: 0,
            grammarAccuracy: 0,
            fluency: 0,
            vocabulary: 0,
            mistakes: [],
            vocabularyHighlights: [],
            suggestions: ["多练习，继续加油！"],
            createdAt: Date()
        )
    }
    
    // MARK: - Helpers
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}

enum PracticeError: Error {
    case noAPIKey
}
