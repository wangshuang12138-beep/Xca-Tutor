import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = HomeViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // 欢迎
                VStack(alignment: .leading, spacing: 8) {
                    Text("欢迎回来")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("今天想练习什么场景？")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 开始练习按钮
                Button {
                    appState.showSceneSelection = true
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("开始练习")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                
                // 统计卡片
                HStack(spacing: 16) {
                    HomeStatCard(title: "练习时长", value: "3.5h", icon: "clock")
                    HomeStatCard(title: "词汇量", value: "45", icon: "textformat")
                    HomeStatCard(title: "准确率", value: "82%", icon: "checkmark.circle")
                }
                
                // 场景列表
                VStack(alignment: .leading, spacing: 16) {
                    Text("推荐场景")
                        .font(.headline)
                    
                    VStack(spacing: 8) {
                        ForEach(viewModel.scenes.prefix(3)) { scene in
                            SceneRow(scene: scene) {
                                appState.showSceneSelection = true
                            }
                        }
                    }
                }
            }
            .padding(32)
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct HomeStatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct SceneRow: View {
    let scene: Scene
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(scene.name)
                        .font(.headline)
                    Text(scene.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Text(scene.difficulty)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(4)
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

class HomeViewModel: ObservableObject {
    @Published var scenes: [Scene] = []
    
    init() {
        scenes = SceneRepository.shared.builtinScenes
    }
}
