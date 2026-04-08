import SwiftUI

struct SettingsView: View {
    @StateObject private var settings = SettingsManager.shared
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: Spacing.xxl) {
                // Header
                Text("Settings")
                    .font(Typography.largeTitle)
                    .foregroundStyle(AppleColors.primaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, Spacing.lg)
                
                // API Configuration
                APIConfigurationSection(settings: settings)
                
                // Model Parameters
                ModelParametersSection(settings: settings)
                
                // Practice Preferences
                PracticePreferencesSection(settings: settings)
                
                // About
                AboutSection()
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.xxl)
        }
        .background(AppleColors.background)
    }
}

// MARK: - API Configuration Section

struct APIConfigurationSection: View {
    @ObservedObject var settings: SettingsManager
    @State private var showAPIKey = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            SectionHeader(title: "API Configuration")
            
            VStack(spacing: 0) {
                // ASR Provider Picker
                SettingsRow(icon: "waveform", title: "ASR Provider") {
                    Picker("", selection: $settings.asrProvider) {
                        Text("豆包").tag(ASRProvider.doubao)
                        Text("阿里云").tag(ASRProvider.qwen)
                        Text("OpenAI").tag(ASRProvider.openai)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 240)
                }
                
                Divider().padding(.leading, 44)
                
                // API Key
                SettingsRow(icon: "key.fill", title: "API Key") {
                    HStack(spacing: Spacing.sm) {
                        if showAPIKey {
                            TextField("Enter API Key", text: $settings.apiKey)
                                .textFieldStyle(.plain)
                                .frame(width: 200)
                        } else {
                            SecureField("Enter API Key", text: $settings.apiKey)
                                .textFieldStyle(.plain)
                                .frame(width: 200)
                        }
                        
                        Button(action: { showAPIKey.toggle() }) {
                            Image(systemName: showAPIKey ? "eye.slash" : "eye")
                                .foregroundStyle(AppleColors.secondaryText)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Divider().padding(.leading, 44)
                
                // Base URL (if using proxy)
                SettingsRow(icon: "link", title: "Base URL") {
                    TextField("https://api.openai.com/v1", text: $settings.proxyBaseURL)
                        .textFieldStyle(.plain)
                        .frame(width: 240)
                }
                
                // Doubao Credentials (only show when Doubao is selected)
                if settings.asrProvider == .doubao {
                    Divider().padding(.leading, 44)
                    
                    SettingsRow(icon: "number", title: "App ID") {
                        TextField("6316460778", text: $settings.doubaoAppId)
                            .textFieldStyle(.plain)
                            .frame(width: 240)
                    }
                    
                    Divider().padding(.leading, 44)
                    
                    SettingsRow(icon: "key", title: "API Key") {
                        SecureField("Enter Doubao API Key", text: $settings.doubaoApiKey)
                            .textFieldStyle(.plain)
                            .frame(width: 240)
                    }
                }
            }
            .padding(Spacing.lg)
            .background(AppleColors.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        }
    }
}

// MARK: - Model Parameters Section

struct ModelParametersSection: View {
    @ObservedObject var settings: SettingsManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            SectionHeader(title: "Model Parameters")
            
            VStack(spacing: 0) {
                // Chat Model
                SettingsRow(icon: "bubble.left.fill", title: "Chat Model") {
                    Picker("", selection: $settings.chatModel) {
                        Text("GPT-4o").tag("gpt-4o")
                        Text("GPT-4o-mini").tag("gpt-4o-mini")
                        Text("GPT-4").tag("gpt-4")
                        Text("GPT-3.5").tag("gpt-3.5-turbo")
                    }
                    .pickerStyle(.menu)
                    .frame(width: 160)
                }
                
                Divider().padding(.leading, 44)
                
                // Temperature
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    SettingsRow(icon: "thermometer", title: "Temperature") {
                        Text(String(format: "%.1f", settings.temperature))
                            .font(Typography.callout)
                            .foregroundStyle(AppleColors.secondaryText)
                            .frame(width: 40)
                    }
                    
                    Slider(value: $settings.temperature, in: 0...2, step: 0.1)
                        .tint(AppleColors.accent)
                        .padding(.leading, 44)
                }
                .padding(.vertical, Spacing.sm)
                
                Divider().padding(.leading, 44)
                
                // Voice
                SettingsRow(icon: "speaker.wave.2.fill", title: "Voice") {
                    Picker("", selection: $settings.voiceName) {
                        Text("Alloy").tag("alloy")
                        Text("Echo").tag("echo")
                        Text("Fable").tag("fable")
                        Text("Onyx").tag("onyx")
                        Text("Nova").tag("nova")
                        Text("Shimmer").tag("shimmer")
                    }
                    .pickerStyle(.menu)
                    .frame(width: 120)
                }
            }
            .padding(Spacing.lg)
            .background(AppleColors.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        }
    }
}

// MARK: - Practice Preferences Section

struct PracticePreferencesSection: View {
    @ObservedObject var settings: SettingsManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            SectionHeader(title: "Practice Preferences")
            
            VStack(spacing: 0) {
                // Default Difficulty
                SettingsRow(icon: "chart.bar.fill", title: "Default Difficulty") {
                    Picker("", selection: $settings.defaultDifficulty) {
                        Text("A1").tag("A1")
                        Text("A2").tag("A2")
                        Text("B1").tag("B1")
                        Text("B2").tag("B2")
                        Text("C1").tag("C1")
                        Text("C2").tag("C2")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 240)
                }
                
                Divider().padding(.leading, 44)
                
                // Auto Upgrade
                SettingsRow(icon: "arrow.up.circle.fill", title: "Auto Upgrade Difficulty") {
                    Toggle("", isOn: $settings.autoUpgrade)
                        .toggleStyle(.switch)
                        .tint(AppleColors.accent)
                }
                
                Divider().padding(.leading, 44)
                
                // Correction Strictness
                SettingsRow(icon: "checkmark.shield.fill", title: "Correction Strictness") {
                    Picker("", selection: $settings.correctionStrictness) {
                        Text("Gentle").tag("gentle")
                        Text("Normal").tag("normal")
                        Text("Strict").tag("strict")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 220)
                }
            }
            .padding(Spacing.lg)
            .background(AppleColors.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        }
    }
}

// MARK: - About Section

struct AboutSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            SectionHeader(title: "About")
            
            VStack(spacing: 0) {
                SettingsRow(icon: "info.circle.fill", title: "Version") {
                    Text("2.0.0")
                        .font(Typography.callout)
                        .foregroundStyle(AppleColors.secondaryText)
                }
                
                Divider().padding(.leading, 44)
                
                SettingsRow(icon: "doc.text.fill", title: "Documentation") {
                    Button("Open") {}
                        .font(Typography.callout)
                        .foregroundStyle(AppleColors.accent)
                }
                
                Divider().padding(.leading, 44)
                
                SettingsRow(icon: "envelope.fill", title: "Feedback") {
                    Button("Contact") {}
                        .font(Typography.callout)
                        .foregroundStyle(AppleColors.accent)
                }
            }
            .padding(Spacing.lg)
            .background(AppleColors.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        }
    }
}

// MARK: - Settings Row

struct SettingsRow<Content: View>: View {
    let icon: String
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(AppleColors.accent)
                .frame(width: 28)
            
            Text(title)
                .font(Typography.body)
                .foregroundStyle(AppleColors.primaryText)
            
            Spacer()
            
            content
        }
        .padding(.vertical, Spacing.sm)
    }
}

// MARK: - Models

enum ASRProvider: String, CaseIterable {
    case doubao = "doubao"
    case qwen = "qwen"
    case openai = "openai"
}

// MARK: - Settings Manager (Stub)

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @Published var asrProvider: ASRProvider = .doubao
    @Published var apiKey: String = ""
    @Published var baseURL: String = "https://api.openai.com/v1"
    @Published var chatModel: String = "gpt-4o"
    @Published var temperature: Double = 0.7
    @Published var voiceName: String = "alloy"
    @Published var defaultDifficulty: String = "B1"
    @Published var autoUpgrade: Bool = true
    @Published var correctionStrictness: String = "normal"
}

// MARK: - Preview

#Preview {
    SettingsView()
        .frame(width: 700, height: 800)
}
