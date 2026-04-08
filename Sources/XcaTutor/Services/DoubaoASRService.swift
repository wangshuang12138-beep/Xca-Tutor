import Foundation
import ObjectiveC

// MARK: - Doubao ASR Service (New Console - API Key)

@MainActor
class DoubaoASRService: NSObject, ObservableObject {
    // MARK: - Published
    @Published var isConnected = false
    @Published var isRecording = false
    
    // MARK: - Configuration (New Console)
    private let appId: String
    private let apiKey: String
    private let resourceId = "volc.seedasr.sauc.duration" // 流式语音识别2.0 小时版
    private let cluster = "volcengine_streaming_common"
    
    // WebSocket
    private var webSocketTask: URLSessionWebSocketTask?
    private let session = URLSession(configuration: .default)
    
    // Audio
    private var audioRecorder: AudioRecorder?
    private var recognitionResult = ""
    
    // Callbacks
    var onRecognitionResult: ((String) -> Void)?
    var onError: ((Error) -> Void)?
    
    // MARK: - Init
    
    init(appId: String, apiKey: String) {
        self.appId = appId
        self.apiKey = apiKey
        super.init()
    }
    
    // MARK: - Connection
    
    func connect() async throws {
        // New console WebSocket endpoint for streaming ASR v3
        let wsUrl = "wss://openspeech.bytedance.com/api/v3/sauc/bigmodel"
        
        guard let url = URL(string: wsUrl) else {
            throw ASRError.invalidURL
        }
        
        var request = URLRequest(url: url)
        // New console uses X-Api-Key header
        request.setValue(apiKey, forHTTPHeaderField: "X-Api-Key")
        request.setValue(appId, forHTTPHeaderField: "X-Api-App-Key")
        request.setValue(resourceId, forHTTPHeaderField: "X-Api-Resource-Id")
        request.setValue(UUID().uuidString, forHTTPHeaderField: "X-Api-Connect-Id")
        
        webSocketTask = session.webSocketTask(with: request)
        webSocketTask?.delegate = self
        
        webSocketTask?.resume()
        
        // Wait for connection
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3s
        
        isConnected = true
        
        // Start receiving messages
        receiveMessage()
    }
    
    // MARK: - Recognition
    
    func startRecognition() throws {
        guard isConnected else {
            throw ASRError.notConnected
        }
        
        recognitionResult = ""
        isRecording = true
        
        // Send start recognition request
        let startPayload: [String: Any] = [
            "user": [
                "uid": appId
            ],
            "audio_config": [
                "format": "raw",
                "sample_rate": 16000,
                "bits": 16,
                "channel": 1
            ],
            "request_config": [
                "model_name": "bigmodel",
                "enable_punc": true,
                "enable_itn": true,
                "enable_ddc": true
            ]
        ]
        
        let message: [String: Any] = [
            "header": [
                "appid": appId,
                "namespace": "SpeechRecognizer",
                "name": "StartRecognition"
            ],
            "payload": startPayload
        ]
        
        sendJSON(message)
        
        // Start audio recording with chunk callback
        audioRecorder = AudioRecorder()
        audioRecorder?.onAudioChunk = { [weak self] chunk in
            self?.sendAudioChunk(chunk)
        }
        try audioRecorder?.startRecording()
    }
    
    func stopRecognition() -> String {
        isRecording = false
        audioRecorder?.stopRecording()
        
        // Send stop recognition
        let message: [String: Any] = [
            "header": [
                "appid": appId,
                "namespace": "SpeechRecognizer",
                "name": "StopRecognition"
            ],
            "payload": [:]
        ]
        
        sendJSON(message)
        
        // Disconnect after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.disconnect()
        }
        
        return recognitionResult
    }
    
    // MARK: - Private Methods
    
    private func sendAudioChunk(_ data: Data) {
        guard isConnected else { return }
        
        // Convert audio to base64 and send
        let base64String = data.base64EncodedString()
        let message: [String: Any] = [
            "payload": [
                "audio": base64String
            ]
        ]
        
        sendJSON(message)
    }
    
    private func sendJSON(_ dict: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: dict),
              let string = String(data: data, encoding: .utf8) else {
            return
        }
        
        webSocketTask?.send(.string(string)) { [weak self] error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.onError?(error)
                }
            }
        }
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                self.handleMessage(message)
                // Continue receiving
                self.receiveMessage()
                
            case .failure(let error):
                DispatchQueue.main.async {
                    self.isConnected = false
                    self.onError?(error)
                }
            }
        }
    }
    
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        guard case .string(let text) = message,
              let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }
        
        // Check for error
        if let header = json["header"] as? [String: Any],
           let code = header["code"] as? Int,
           code != 0 {
            let message = header["message"] as? String ?? "Unknown error"
            DispatchQueue.main.async { [weak self] in
                self?.onError?(ASRError.apiError(message))
            }
            return
        }
        
        // Parse recognition result
        if let payload = json["payload"] as? [String: Any],
           let result = payload["result"] as? [String: Any],
           let text = result["text"] as? String {
            
            DispatchQueue.main.async { [weak self] in
                self?.recognitionResult = text
                self?.onRecognitionResult?(text)
            }
        }
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        isConnected = false
        isRecording = false
    }
}

// MARK: - WebSocket Delegate

extension DoubaoASRService: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        DispatchQueue.main.async {
            self.isConnected = true
        }
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        DispatchQueue.main.async {
            self.isConnected = false
            self.isRecording = false
        }
    }
}

// MARK: - ASR Errors

enum ASRError: Error, LocalizedError {
    case invalidURL
    case notConnected
    case authenticationFailed
    case recognitionFailed
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的 URL"
        case .notConnected:
            return "未连接到语音识别服务"
        case .authenticationFailed:
            return "认证失败，请检查 API Key"
        case .recognitionFailed:
            return "语音识别失败"
        case .apiError(let message):
            return "API 错误: \(message)"
        }
    }
}

// MARK: - Audio Recorder Extension

extension AudioRecorder {
    var onAudioChunk: ((Data) -> Void)? {
        get { objc_getAssociatedObject(self, &AssociatedKeys.onAudioChunk) as? (Data) -> Void }
        set { objc_setAssociatedObject(self, &AssociatedKeys.onAudioChunk, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC) }
    }
    
    private struct AssociatedKeys {
        static var onAudioChunk = "onAudioChunk"
    }
}
