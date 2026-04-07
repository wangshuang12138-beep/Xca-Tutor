import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = HomeViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 欢迎区域
                welcomeSection
                
                // 继续练习（如果有）
                if let lastConversation = viewModel.lastConversation {
                    continueSection(conversation: lastConversation)
                }
                
                // 场景选择
                scenesSection
                
                // 学习数据
                statsSection
                
                // 错题本入口
                mistakeBookSection
            }
            .padding(32)
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Welcome Section
    private var welcomeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("👋 欢迎回来")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("今天想练习什么场景？")
                .font(.title3)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Continue Section
    private func continueSection(conversation: Conversation) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("🎯 继续练习")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("餐厅点餐")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("练习了 12 分钟 · B1 难度")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("继续练习") {
                    appState.currentConversation = conversation
                }
                .buttonStyle(.primary)
            }
            .padding(20)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Scenes Section
    private var scenesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("📚 选择场景")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 16) {
                ForEach(viewModel.scenes) { scene in
                    SceneCard(scene: scene) {
                        appState.showSceneSelection = true
                    }
                }
            }
        }
    }
    
    // MARK: - Stats Section
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("📊 本周学习")
                .font(.headline)
            
            HStack(spacing: 24) {
                StatItem(title: "练习时长", value: "3.5 小时", trend: "+12%")
                StatItem(title: "新掌握词汇", value: "45 个", trend: "+8")
                StatItem(title: "平均准确率", value: "82%", trend: "+5%")
            }
            .padding(20)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Mistake Book Section
    private var mistakeBookSection: some View {
        Button {
            appState.selectedTab = .mistakeBook
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("📝 错题本")
                        .font(.headline)
                    Text("共 12 条错误待复习")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding(20)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Supporting Views

struct SceneCard: View {
    let scene: Scene
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Text(scene.icon)
                    .font(.system(size: 40))
                
                Text(scene.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(scene.difficulty)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(4)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .padding(12)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let trend: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(trend)
                .font(.caption)
                .foregroundColor(.green)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - View Model

class HomeViewModel: ObservableObject {
    @Published var scenes: [Scene] = []
    @Published var lastConversation: Conversation?
    
    init() {
        loadScenes()
        loadLastConversation()
    }
    
    private func loadScenes() {
        // 加载内置场景
        scenes = SceneRepository.shared.builtinScenes
    }
    
    private func loadLastConversation() {
        // 从数据库加载最近未完成的对话
        // 暂时用模拟数据
    }
}

// MARK: - Button Style

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.blue)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
    }
}
