import Foundation

// MARK: - ASR Service Protocol

protocol ASRServiceProtocol {
    func startRecognition() async throws
    func stopRecognition() async -> String
    var onRecognitionResult: ((String) -> Void)? { get set }
    var onError: ((Error) -> Void)? { get set }
}

// MARK: - ASR Service Factory

class ASRServiceFactory {
    @MainActor
    static func createService() -> ASRServiceProtocol? {
        let settings = SettingsManager.shared
        
        switch settings.asrProvider {
        case .doubao:
            // Check if we have Doubao credentials
            guard settings.hasDoubaoCredentials else {
                print("⚠️ Doubao credentials not configured")
                return nil
            }
            
            return DoubaoASRService(
                appId: settings.doubaoAppId,
                apiKey: settings.doubaoApiKey
            )
            
        case .openai, .qwen:
            // Use OpenAI Whisper through the existing OpenAIService
            return WhisperASRWrapper()
        }
    }
}

// MARK: - Whisper ASR Wrapper (for OpenAI/compatible APIs)

class WhisperASRWrapper: ASRServiceProtocol {
    var onRecognitionResult: ((String) -> Void)?
    var onError: ((Error) -> Void)?
    
    private var recordedData: Data?
    private var audioRecorder = AudioRecorder()
    
    func startRecognition() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            do {
                audioRecorder.onRecordingFinished = { [weak self] data in
                    self?.recordedData = data
                }
                try audioRecorder.startRecording()
                continuation.resume()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    func stopRecognition() async -> String {
        return await withCheckedContinuation { continuation in
            audioRecorder.onRecordingFinished = { [weak self] data in
                self?.recordedData = data
                
                // Transcribe using OpenAI
                Task {
                    let text = await self?.transcribe(data: data) ?? ""
                    continuation.resume(returning: text)
                }
            }
            audioRecorder.stopRecording()
        }
    }
    
    private func transcribe(data: Data) async -> String {
        let settings = SettingsManager.shared
        guard !settings.apiKey.isEmpty else { return "" }
        
        let service = OpenAIService(
            apiKey: settings.apiKey,
            baseURL: settings.baseURL
        )
        
        do {
            return try await service.transcribe(audioData: data)
        } catch {
            onError?(error)
            return ""
        }
    }
}
