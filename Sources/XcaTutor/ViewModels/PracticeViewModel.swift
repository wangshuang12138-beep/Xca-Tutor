import SwiftUI
import Foundation

@MainActor
class PracticeViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentAgentMessage: String = ""
    @Published var isAgentSpeaking: Bool = false
    @Published var isRecording: Bool = false
    @Published var isProcessing: Bool = false
    @Published var elapsedTimeString: String = "00:00"
    @Published var currentLevel: String = "B1"
    @Published var fluencyScore: Int = 0
    @Published var accuracyScore: Int = 0
    @Published var showReport: Bool = false
    @Published var report: PracticeReport?
    
    // Internal message storage (not shown in UI during practice)
    var messages: [Message] = []
    
    // MARK: - Dependencies
    let conversation: Conversation
    var scene: Scene?
    
    private let audioPlayer = AudioPlayer()
    private let settings = SettingsManager.shared
    private var openAIService: OpenAIService?
    private var asrService: ASRServiceProtocol?
    private var elapsedTime: Int = 0
    private var timer: Timer?
    
    // MARK: - Initialization
    
    init(conversation: Conversation) {
        self.conversation = conversation
        self.scene = SceneRepository.shared.getScene(id: conversation.sceneId)
        self.currentLevel = conversation.difficulty
        
        setupAudioHandlers()
        setupTimer()
        setupServices()
        
        // Add system message
        if let scene = scene {
            let systemMessage = Message(
                role: .system,
                content: scene.systemPrompt
            )
            messages.append(systemMessage)
            
            // Agent greeting after short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                Task { @MainActor in
                    await self?.sendAgentGreeting()
                }
            }
        }
    }
    
    // MARK: - Setup
    
    private func setupServices() {
        // Initialize OpenAI service
        if !settings.apiKey.isEmpty {
            openAIService = OpenAIService(
                apiKey: settings.apiKey,
                baseURL: settings.baseURL
            )
        }
        
        // Initialize ASR service based on provider
        setupASRService()
    }
    
    private func setupASRService() {
        asrService = ASRServiceFactory.createService()
        
        // If Doubao credentials not available, fallback to Whisper
        if asrService == nil && settings.asrProvider == .doubao {
            setupWhisperASR()
        }
    }
    
    private func setupWhisperASR() {
        asrService = WhisperASRAdapter { [weak self] audioData in
            Task { @MainActor in
                await self?.handleWhisperRecognition(audioData)
            }
        }
    }
    
    private func setupAudioHandlers() {
        audioPlayer.onPlaybackFinished = { [weak self] in
            Task { @MainActor in
                self?.isAgentSpeaking = false
            }
        }
    }
    
    private func setupTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.elapsedTime += 1
            self.elapsedTimeString = self.formatTime(self.elapsedTime)
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
    
    // MARK: - Recording Control
    
    func startRecording() {
        guard openAIService != nil else {
            currentAgentMessage = "Please configure API key in Settings"
            return
        }
        
        Task {
            do {
                // Connect Doubao if needed
                if let doubaoService = asrService as? DoubaoASRService {
                    try await doubaoService.connect()
                }
                
                try await asrService?.startRecognition()
                isRecording = true
            } catch {
                print("Failed to start recording: \(error)")
            }
        }
    }
    
    func stopRecording() {
        Task {
            isRecording = false
            isProcessing = true
            
            let text = await asrService?.stopRecognition() ?? ""
            
            if !text.isEmpty {
                await handleUserInput(text)
            }
            
            isProcessing = false
        }
    }
    
    // MARK: - Recognition Handlers
    
    private func handleWhisperRecognition(_ audioData: Data) async {
        guard !audioData.isEmpty else { return }
        
        do {
            let userText = try await openAIService?.transcribe(audioData: audioData) ?? ""
            await handleUserInput(userText)
        } catch {
            print("Recognition error: \(error)")
        }
    }
    
    private func handleUserInput(_ text: String) async {
        guard !text.isEmpty else { return }
        
        // Store user message
        let userMessage = Message(role: .user, content: text)
        messages.append(userMessage)
        
        // Get AI response
        do {
            let assistantText = try await fetchAIResponse(userText: text)
            
            // Store AI message
            let assistantMessage = Message(role: .assistant, content: assistantText)
            messages.append(assistantMessage)
            
            // Display and speak
            currentAgentMessage = assistantText
            isAgentSpeaking = true
            
            if let audioData = try await openAIService?.synthesize(text: assistantText, voice: settings.voiceName) {
                try audioPlayer.play(data: audioData)
            } else {
                isAgentSpeaking = false
            }
            
        } catch {
            print("AI response error: \(error)")
            isAgentSpeaking = false
        }
    }
    
    private func fetchAIResponse(userText: String) async throws -> String {
        guard let service = openAIService else {
            throw PracticeError.noAPIKey
        }
        
        let chatMessages = messages.map { msg in
            ChatMessage(role: msg.roleString, content: msg.content)
        }
        
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
        
        // Store greeting
        let greetingMessage = Message(role: .assistant, content: greeting)
        messages.append(greetingMessage)
        
        // Display and speak
        currentAgentMessage = greeting
        isAgentSpeaking = true
        
        do {
            let audioData = try await service.synthesize(text: greeting, voice: settings.voiceName)
            try audioPlayer.play(data: audioData)
        } catch {
            print("Error playing greeting: \(error)")
            isAgentSpeaking = false
        }
    }
    
    // MARK: - Conversation Control
    
    func endPractice() {
        timer?.invalidate()
        
        // Save conversation
        var endedConversation = conversation
        endedConversation.endTime = Date()
        _ = DatabaseManager.shared.saveConversation(endedConversation)
        
        // Save messages
        for message in messages {
            _ = DatabaseManager.shared.saveMessage(message, conversationId: conversation.id)
        }
        
        // Generate report
        Task {
            await generateReport()
        }
    }
    
    func generateReport() async {
        guard let service = openAIService else {
            report = createSimpleReport()
            showReport = true
            return
        }
        
        isProcessing = true
        
        let chatMessages = messages.filter { $0.role != .system }
        
        guard chatMessages.count >= 2 else {
            report = createSimpleReport()
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
            
            report = parseReport(from: response, messages: chatMessages)
            showReport = true
            
        } catch {
            report = createSimpleReport()
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
        Student Level: \(currentLevel)
        
        Conversation:
        \(transcript)
        
        Provide analysis in this exact JSON format:
        {
            "overallLevel": "A1|A2|B1|B2|C1|C2",
            "overallScore": 82,
            "taskCompletion": 80,
            "grammarAccuracy": 85,
            "fluency": 78,
            "vocabulary": 82,
            "mistakes": [
                {
                    "title": "Brief description",
                    "original": "incorrect sentence",
                    "correction": "correct sentence",
                    "explanation": "why it's wrong"
                }
            ],
            "vocabularyHighlights": ["word1", "word2"],
            "suggestions": ["tip 1", "tip 2"]
        }
        
        Only return the JSON, no other text.
        """
    }
    
    private func parseReport(from response: String, messages: [Message]) -> PracticeReport {
        var jsonString = response
        if let start = response.firstIndex(of: "{"),
           let end = response.lastIndex(of: "}") {
            jsonString = String(response[start...end])
        }
        
        struct ReportData: Codable {
            let overallLevel: String
            let overallScore: Int
            let taskCompletion: Int
            let grammarAccuracy: Int
            let fluency: Int
            let vocabulary: Int
            let mistakes: [MistakeData]
            let vocabularyHighlights: [String]
            let suggestions: [String]
            
            struct MistakeData: Codable {
                let title: String
                let original: String
                let correction: String
                let explanation: String
            }
        }
        
        do {
            let data = jsonString.data(using: .utf8)!
            let reportData = try JSONDecoder().decode(ReportData.self, from: data)
            
            let mistakes = reportData.mistakes.map { m in
                MistakeItem(
                    title: m.title,
                    original: m.original,
                    correction: m.correction,
                    explanation: m.explanation
                )
            }
            
            return PracticeReport(
                overallLevel: reportData.overallLevel,
                overallScore: reportData.overallScore,
                taskCompletion: reportData.taskCompletion,
                grammarAccuracy: reportData.grammarAccuracy,
                fluency: reportData.fluency,
                vocabulary: reportData.vocabulary,
                mistakes: mistakes,
                vocabularyHighlights: reportData.vocabularyHighlights,
                suggestions: reportData.suggestions
            )
        } catch {
            return createSimpleReport()
        }
    }
    
    private func createSimpleReport() -> PracticeReport {
        PracticeReport(
            overallLevel: currentLevel,
            overallScore: 75,
            taskCompletion: 70,
            grammarAccuracy: 75,
            fluency: 70,
            vocabulary: 75,
            mistakes: [],
            vocabularyHighlights: [],
            suggestions: ["Keep practicing! Try to use more complex sentence structures."]
        )
    }
}

enum PracticeError: Error {
    case noAPIKey
}

// MARK: - Whisper ASR Adapter

class WhisperASRAdapter: ASRServiceProtocol {
    var onRecognitionResult: ((String) -> Void)?
    var onError: ((Error) -> Void)?
    
    private var audioRecorder = AudioRecorder()
    private var completion: ((Data) async -> Void)?
    
    init(completion: @escaping (Data) async -> Void) {
        self.completion = completion
    }
    
    func startRecognition() async throws {
        audioRecorder.onRecordingFinished = { [weak self] data in
            Task {
                await self?.completion?(data)
            }
        }
        try audioRecorder.startRecording()
    }
    
    func stopRecognition() async -> String {
        audioRecorder.stopRecording()
        // Text is returned via completion handler
        return ""
    }
}
