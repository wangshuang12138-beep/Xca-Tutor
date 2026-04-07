import Foundation

// MARK: - API Models

struct ChatMessage: Codable {
    let role: String
    let content: String
}

struct ChatRequest: Codable {
    let model: String
    let messages: [ChatMessage]
    let temperature: Double
    let max_tokens: Int
}

struct ChatResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}

struct ModelConfig {
    let model: String
    let temperature: Double
    let maxTokens: Int
}

// MARK: - OpenAI Service

class OpenAIService {
    private let apiKey: String
    private let baseURL: String
    
    init(apiKey: String, baseURL: String = "https://api.openai.com/v1") {
        self.apiKey = apiKey
        self.baseURL = baseURL.hasSuffix("/v1") ? baseURL : baseURL + "/v1"
    }
    
    // MARK: - Speech to Text
    
    func transcribe(audioData: Data) async throws -> String {
        let url = URL(string: "\(baseURL)/audio/transcriptions")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Model
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("whisper-1\r\n".data(using: .utf8)!)
        
        // File
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ Transcription Error (\(httpResponse.statusCode)): \(errorText)")
            throw OpenAIError.transcriptionFailed
        }
        
        struct TranscriptionResponse: Codable {
            let text: String
        }
        
        let result = try JSONDecoder().decode(TranscriptionResponse.self, from: data)
        return result.text
    }
    
    // MARK: - Chat Completion
    
    func chat(messages: [ChatMessage], config: ModelConfig) async throws -> String {
        let url = URL(string: "\(baseURL)/chat/completions")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ChatRequest(
            model: config.model,
            messages: messages,
            temperature: config.temperature,
            max_tokens: config.maxTokens
        )
        
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ API Error (\(httpResponse.statusCode)): \(errorText)")
            throw OpenAIError.apiError("HTTP \(httpResponse.statusCode): \(errorText)")
        }
        
        let result = try JSONDecoder().decode(ChatResponse.self, from: data)
        return result.choices.first?.message.content ?? ""
    }
    
    // MARK: - Text to Speech
    
    func synthesize(text: String, voice: String) async throws -> Data {
        let url = URL(string: "\(baseURL)/audio/speech")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": "tts-1",
            "input": text,
            "voice": voice
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw OpenAIError.synthesisFailed
        }
        
        return data
    }
}

// MARK: - Errors

enum OpenAIError: Error {
    case transcriptionFailed
    case synthesisFailed
    case invalidResponse
    case apiError(String)
    
    var localizedDescription: String {
        switch self {
        case .transcriptionFailed:
            return "语音识别失败"
        case .synthesisFailed:
            return "语音合成失败"
        case .invalidResponse:
            return "无效的响应"
        case .apiError(let message):
            return "API 错误: \(message)"
        }
    }
}
