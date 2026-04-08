import Foundation

// MARK: - User Settings Model

struct UserSettings: Codable {
    var apiKey: String
    var useProxy: Bool
    var proxyBaseURL: String
    
    // ASR Provider
    var asrProvider: String
    
    // Doubao ASR (New Console)
    var doubaoAppId: String
    var doubaoApiKey: String
    
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
        proxyBaseURL: "https://api.openai.com/v1",
        asrProvider: "doubao",
        doubaoAppId: "",
        doubaoApiKey: "",
        chatModel: "gpt-4o",
        temperature: 0.7,
        maxTokens: 2000,
        voiceName: "alloy",
        whisperModel: "whisper-1",
        defaultDifficulty: "B1",
        autoUpgrade: true,
        correctionStrictness: "normal",
        theme: "auto",
        language: "zh-CN"
    )
}

// MARK: - ASR Provider

enum ASRProvider: String, CaseIterable {
    case doubao = "doubao"
    case qwen = "qwen"
    case openai = "openai"
}

// MARK: - Settings Manager

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @Published var settings: UserSettings = .default
    
    private let settingsKey = "com.xca.tutor.settings"
    private let keychainKey = "com.xca.tutor.apikey"
    private let doubaoKeychainKey = "com.xca.tutor.doubao.apikey"
    
    private init() {
        loadSettings()
    }
    
    // MARK: - Settings Persistence
    
    func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(UserSettings.self, from: data) {
            settings = decoded
        }
        
        // Load API Keys from Keychain
        if let apiKey = KeychainManager.shared.get(key: keychainKey) {
            settings.apiKey = apiKey
        }
        if let doubaoApiKey = KeychainManager.shared.get(key: doubaoKeychainKey) {
            settings.doubaoApiKey = doubaoApiKey
        }
    }
    
    func saveSettings() {
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: settingsKey)
        }
        
        // Save API Keys to Keychain
        KeychainManager.shared.set(key: keychainKey, value: settings.apiKey)
        KeychainManager.shared.set(key: doubaoKeychainKey, value: settings.doubaoApiKey)
    }
    
    // MARK: - Convenience Properties
    
    var baseURL: String {
        settings.useProxy ? settings.proxyBaseURL : "https://api.openai.com/v1"
    }
    
    var proxyBaseURL: String {
        get { settings.proxyBaseURL }
        set { settings.proxyBaseURL = newValue }
    }
    
    var apiKey: String {
        get { settings.apiKey }
        set { settings.apiKey = newValue }
    }
    
    var chatModel: String {
        get { settings.chatModel }
        set { settings.chatModel = newValue }
    }
    
    var temperature: Double {
        get { settings.temperature }
        set { settings.temperature = newValue }
    }
    
    var maxTokens: Int {
        get { settings.maxTokens }
        set { settings.maxTokens = newValue }
    }
    
    var voiceName: String {
        get { settings.voiceName }
        set { settings.voiceName = newValue }
    }
    
    var defaultDifficulty: String {
        get { settings.defaultDifficulty }
        set { settings.defaultDifficulty = newValue }
    }
    
    var autoUpgrade: Bool {
        get { settings.autoUpgrade }
        set { settings.autoUpgrade = newValue }
    }
    
    var correctionStrictness: String {
        get { settings.correctionStrictness }
        set { settings.correctionStrictness = newValue }
    }
    
    var asrProvider: ASRProvider {
        get { ASRProvider(rawValue: settings.asrProvider) ?? .doubao }
        set { settings.asrProvider = newValue.rawValue }
    }
    
    var doubaoAppId: String {
        get { settings.doubaoAppId }
        set { settings.doubaoAppId = newValue }
    }
    
    var doubaoApiKey: String {
        get { settings.doubaoApiKey }
        set { settings.doubaoApiKey = newValue }
    }
    
    var hasDoubaoCredentials: Bool {
        !settings.doubaoAppId.isEmpty && !settings.doubaoApiKey.isEmpty
    }
    
    // MARK: - Validation
    
    var isValid: Bool {
        !settings.apiKey.isEmpty
    }
    
    func validateAPIKey() async -> Bool {
        guard isValid else { return false }
        
        do {
            let service = OpenAIService(apiKey: settings.apiKey, baseURL: baseURL)
            _ = try await service.chat(
                messages: [.init(role: "user", content: "Hi")],
                config: .init(model: settings.chatModel, temperature: 0.5, maxTokens: 10)
            )
            return true
        } catch {
            return false
        }
    }
}

// MARK: - Keychain Manager

class KeychainManager {
    static let shared = KeychainManager()
    
    func set(key: String, value: String) {
        let data = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    func get(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        
        guard let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
