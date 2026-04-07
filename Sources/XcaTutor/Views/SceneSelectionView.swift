import SwiftUI

struct SceneSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SceneSelectionViewModel()
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 280))], spacing: 20) {
                    ForEach(viewModel.scenes) { scene in
                        SceneDetailCard(scene: scene) {
                            startPractice(scene: scene)
                        }
                    }
                }
                .padding(24)
            }
            .navigationTitle("选择场景")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }
    
    private func startPractice(scene: Scene) {
        print("🎯 开始练习: \(scene.name)")
        
        let conversation = Conversation(
            sceneId: scene.id,
            difficulty: SettingsManager.shared.settings.defaultDifficulty
        )
        
        // 保存到数据库
        let saved = DatabaseManager.shared.saveConversation(conversation)
        print("💾 保存对话: \(saved ? "成功" : "失败")")
        
        // 先关闭 sheet，延迟设置 conversation
        print("🔒 关闭场景选择窗口...")
        dismiss()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            print("✅ 设置 currentConversation = \(conversation.id)")
            withAnimation {
                appState.currentConversation = conversation
            }
            print("✅ currentConversation 设置完成")
        }
    }
}

struct SceneDetailCard: View {
    let scene: Scene
    let onStart: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(scene.icon)
                    .font(.system(size: 48))
                
                Spacer()
                
                Text(scene.difficulty)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(4)
            }
            
            Text(scene.name)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(scene.description)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            Divider()
            
            HStack {
                Text("隐藏任务:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(scene.hiddenTasks.count) 个")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Button("开始练习") {
                onStart()
            }
            .buttonStyle(BorderedProminentButtonStyle())
            .frame(maxWidth: .infinity)
        }
        .padding(20)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(16)
    }
}

class SceneSelectionViewModel: ObservableObject {
    @Published var scenes: [Scene] = []
    
    init() {
        scenes = SceneRepository.shared.builtinScenes
    }
}
