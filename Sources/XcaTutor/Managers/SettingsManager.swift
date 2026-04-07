import Foundation

// MARK: - User Settings Model

struct UserSettings: Codable {
    var apiKey: String
    var useProxy: Bool
    var proxyBaseURL: String  // 代理 API 地址，如 https://oa.api2d.net
    
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
        proxyBaseURL: "https://oa.api2d.net",
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

// MARK: - Settings Manager

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @Published var settings: UserSettings = .default
    
    private let settingsKey = "com.xca.tutor.settings"
    private let keychainKey = "com.xca.tutor.apikey"
    
    private init() {
        loadSettings()
        
        // 预填充 API2D 配置（如果 API Key 为空）
        if settings.apiKey.isEmpty || !settings.apiKey.hasPrefix("fk-") {
            settings.apiKey = "fk239252-gcj2PsZit6oB8Rb1AFotIyaGLspGEpba"
            settings.useProxy = true
            settings.proxyBaseURL = "https://oa.api2d.net"
            saveSettings()
            print("✅ 已自动配置 API2D 凭据")
        }
    }
    
    // MARK: - Settings Persistence
    
    func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(UserSettings.self, from: data) {
            settings = decoded
        }
        
        // 从 Keychain 加载 API Key
        if let apiKey = KeychainManager.shared.get(key: keychainKey) {
            settings.apiKey = apiKey
        }
    }
    
    func saveSettings() {
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: settingsKey)
        }
        
        // API Key 单独存 Keychain
        KeychainManager.shared.set(key: keychainKey, value: settings.apiKey)
    }
    
    // MARK: - Validation
    
    var isValid: Bool {
        !settings.apiKey.isEmpty && settings.apiKey.hasPrefix("sk-")
    }
    
    func validateAPIKey() async -> Bool {
        guard isValid else { return false }
        
        do {
            let baseURL = settings.useProxy ? settings.proxyBaseURL : "https://api.openai.com/v1"
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
