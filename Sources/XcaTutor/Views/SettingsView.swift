import SwiftUI

struct SettingsView: View {
    @StateObject private var settingsManager = SettingsManager.shared
    @State private var isValidating = false
    @State private var validationResult: Bool?
    
    var body: some View {
        TabView {
            generalSettings
                .tabItem {
                    Label("通用", systemImage: "gear")
                }
            
            modelSettings
                .tabItem {
                    Label("模型", systemImage: "cpu")
                }
            
            practiceSettings
                .tabItem {
                    Label("练习", systemImage: "book")
                }
        }
        .padding(20)
        .frame(minWidth: 600, minHeight: 400)
    }
    
    // MARK: - General Settings
    private var generalSettings: some View {
        Form {
            Section("API 配置") {
                VStack(alignment: .leading, spacing: 12) {
                    // 代理开关
                    Toggle("使用国内代理", isOn: $settingsManager.settings.useProxy)
                    
                    if settingsManager.settings.useProxy {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("代理地址")
                                .font(.caption)
                            TextField("https://oa.api2d.net", text: $settingsManager.settings.proxyBaseURL)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    
                    Divider()
                    
                    Text("API Key")
                        .font(.headline)
                    
                    HStack {
                        SecureField("fk-... 或 sk-...", text: $settingsManager.settings.apiKey)
                            .textFieldStyle(.roundedBorder)
                        
                        Button {
                            isValidating = true
                            Task {
                                validationResult = await settingsManager.validateAPIKey()
                                isValidating = false
                            }
                        } label: {
                            if isValidating {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Text("验证")
                            }
                        }
                        .disabled(settingsManager.settings.apiKey.isEmpty || isValidating)
                    }
                    
                    if let result = validationResult {
                        HStack {
                            Image(systemName: result ? "checkmark.circle.fill" : "xmark.circle.fill")
                            Text(result ? "API Key 有效" : "API Key 无效")
                        }
                        .foregroundColor(result ? .green : .red)
                        .font(.caption)
                    }
                    
                    Text("您的 API Key 将安全存储在系统钥匙串中")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Section("外观") {
                Picker("主题", selection: $settingsManager.settings.theme) {
                    Text("自动").tag("auto")
                    Text("浅色").tag("light")
                    Text("深色").tag("dark")
                }
                
                Picker("语言", selection: $settingsManager.settings.language) {
                    Text("简体中文").tag("zh-CN")
                    Text("English").tag("en")
                }
            }
        }
        .formStyle(.grouped)
    }
    
    // MARK: - Model Settings
    private var modelSettings: some View {
        Form {
            Section("对话模型") {
                Picker("模型", selection: $settingsManager.settings.chatModel) {
                    Text("GPT-4o (推荐)").tag("gpt-4o")
                    Text("GPT-4o-mini (更快更便宜)").tag("gpt-4o-mini")
                    Text("GPT-4-turbo").tag("gpt-4-turbo")
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Temperature: \(String(format: "%.1f", settingsManager.settings.temperature))")
                        Spacer()
                        Text("稳定")
                        Text("← →")
                            .foregroundColor(.secondary)
                        Text("创意")
                    }
                    .font(.caption)
                    
                    Slider(value: $settingsManager.settings.temperature, in: 0...2, step: 0.1)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Max Tokens: \(settingsManager.settings.maxTokens)")
                        .font(.caption)
                    
                    Slider(value: .init(
                        get: { Double(settingsManager.settings.maxTokens) },
                        set: { settingsManager.settings.maxTokens = Int($0) }
                    ), in: 100...4000, step: 100)
                }
            }
            
            Section("语音") {
                Picker("音色", selection: $settingsManager.settings.voiceName) {
                    Text("Alloy (中性)").tag("alloy")
                    Text("Echo (男性)").tag("echo")
                    Text("Fable (叙事)").tag("fable")
                    Text("Onyx (低沉男性)").tag("onyx")
                    Text("Nova (女性)").tag("nova")
                    Text("Shimmer (明亮女性)").tag("shimmer")
                }
                
                Button("试听") {
                    // 播放试听音频
                }
                
                Picker("语音识别", selection: $settingsManager.settings.whisperModel) {
                    Text("Whisper-1 (标准)").tag("whisper-1")
                    Text("Whisper-large-v3 (更准更慢)").tag("whisper-large-v3")
                }
            }
        }
        .formStyle(.grouped)
    }
    
    // MARK: - Practice Settings
    private var practiceSettings: some View {
        Form {
            Section("难度设置") {
                Picker("默认难度", selection: $settingsManager.settings.defaultDifficulty) {
                    ForEach(["A1", "A2", "B1", "B2", "C1", "C2"], id: \.self) { level in
                        Text("\(level) - \(levelDescription(level))").tag(level)
                    }
                }
                
                Toggle("自动升级难度", isOn: $settingsManager.settings.autoUpgrade)
                
                Picker("纠错严格度", selection: $settingsManager.settings.correctionStrictness) {
                    Text("宽松").tag("lenient")
                    Text("标准").tag("standard")
                    Text("严格").tag("strict")
                }
            }
            
            Section("数据管理") {
                Button("导出学习记录") {
                    // 导出功能
                }
                
                Button("清空错题本") {
                    // 确认后清空
                }
                .foregroundColor(.red)
                
                Button("删除所有数据") {
                    // 确认后删除
                }
                .foregroundColor(.red)
            }
        }
        .formStyle(.grouped)
    }
    
    private func levelDescription(_ level: String) -> String {
        switch level {
        case "A1": return "入门级"
        case "A2": return "初级"
        case "B1": return "中级"
        case "B2": return "中高级"
        case "C1": return "高级"
        case "C2": return "精通级"
        default: return ""
        }
    }
}
