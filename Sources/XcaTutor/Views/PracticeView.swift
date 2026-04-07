import SwiftUI

struct PracticeView: View {
    let conversation: Conversation
    @StateObject private var viewModel: PracticeViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(conversation: Conversation) {
        self.conversation = conversation
        _viewModel = StateObject(wrappedValue: PracticeViewModel(conversation: conversation))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部工具栏
            toolbar
            
            // 对话区域
            messagesScrollView
            
            // 底部控制区
            bottomControls
        }
        .background(Color(NSColor.windowBackgroundColor))
        .alert("错误", isPresented: $viewModel.showError) {
            Button("确定") { }
        } message: {
            Text(viewModel.errorMessage)
        }
        .alert("结束练习？", isPresented: $viewModel.showEndConfirmation) {
            Button("取消", role: .cancel) { }
            Button("结束", role: .destructive) {
                viewModel.endConversation()
            }
        } message: {
            Text("结束后将生成练习报告")
        }
        .sheet(isPresented: $viewModel.showReport) {
            if let report = viewModel.report {
                ReportView(report: report, conversation: viewModel.conversation)
            }
        }
    }
    
    // MARK: - Toolbar
    private var toolbar: some View {
        HStack {
            Button {
                viewModel.showEndConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("结束")
                }
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            VStack(spacing: 2) {
                Text(viewModel.scene?.name ?? "练习")
                    .font(.headline)
                Text(viewModel.difficulty)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button {
                    viewModel.isPaused.toggle()
                } label: {
                    Image(systemName: viewModel.isPaused ? "play.fill" : "pause.fill")
                }
                .buttonStyle(.plain)
                
                Button {
                    // 打开设置
                } label: {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Messages
    private var messagesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }
                    
                    if viewModel.isProcessing {
                        HStack {
                            Spacer()
                            ProgressView()
                                .scaleEffect(0.8)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
            .onChange(of: viewModel.messages.count) { _ in
                if let lastId = viewModel.messages.last?.id {
                    withAnimation {
                        proxy.scrollTo(lastId, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    // MARK: - Bottom Controls
    private var bottomControls: some View {
        VStack(spacing: 12) {
            // 状态栏
            HStack {
                Label(viewModel.difficulty, systemImage: "chart.bar")
                    .font(.caption)
                
                Spacer()
                
                if let status = viewModel.statusText {
                    Text(status)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "waveform")
                    Text(viewModel.isRecording ? "正在听..." : "点击说话")
                        .font(.caption)
                }
                .foregroundColor(viewModel.isRecording ? .red : .secondary)
            }
            .padding(.horizontal, 20)
            
            // 录音按钮
            Button {
                viewModel.toggleRecording()
            } label: {
                ZStack {
                    Circle()
                        .fill(viewModel.isRecording ? Color.red : Color.blue)
                        .frame(width: viewModel.isRecording ? 72 : 64, height: viewModel.isRecording ? 72 : 64)
                    
                    Image(systemName: viewModel.isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: viewModel.isRecording ? 32 : 28))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isProcessing)
            // .keyboardShortcut(.space, modifiers: [])  // macOS 13+ only, removed for compatibility
            
            Text("按空格键说话")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: Message
    
    var isUser: Bool {
        message.role == .user
    }
    
    var body: some View {
        HStack {
            if isUser { Spacer() }
            
            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                Text(isUser ? "你" : "Agent")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(message.content)
                    .font(.body)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(isUser ? Color.blue : Color.gray.opacity(0.2))
                    .foregroundColor(isUser ? .white : .primary)
                    .cornerRadius(16)
                    .cornerRadius(isUser ? 4 : 16, corners: [.bottomTrailing])
                    .cornerRadius(isUser ? 16 : 4, corners: [.bottomLeading])
            }
            
            if !isUser { Spacer() }
        }
    }
}

// MARK: - Corner Radius Extension

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
