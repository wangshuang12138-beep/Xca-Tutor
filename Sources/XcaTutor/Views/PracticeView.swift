import SwiftUI

struct PracticeView: View {
    let conversation: Conversation
    @StateObject private var viewModel: PracticeViewModel
    @EnvironmentObject var appState: AppState
    @State private var textInput: String = ""
    
    init(conversation: Conversation) {
        self.conversation = conversation
        _viewModel = StateObject(wrappedValue: PracticeViewModel(conversation: conversation))
    }

    var body: some View {
        VStack(spacing: 0) {
            // 顶部工具栏
            HStack {
                Button {
                    viewModel.showEndConfirmation = true
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .frame(width: 32, height: 32)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
                
                Spacer()
                
                VStack(spacing: 2) {
                    Text(viewModel.scene?.name ?? "练习")
                        .font(.headline)
                    Text(viewModel.difficulty)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 占位保持居中
                Color.clear
                    .frame(width: 32, height: 32)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(NSColor.controlBackgroundColor))
            
            // 对话区域
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(viewModel.messages.filter { $0.role != .system }) { message in
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
                    .padding(.horizontal, 20)
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
            
            Divider()
            
            // 底部控制区
            VStack(spacing: 12) {
                // 状态文字
                if let status = viewModel.statusText {
                    Text(status)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .transition(.opacity)
                }
                
                // 文字输入框
                HStack(spacing: 8) {
                    TextField("输入消息...", text: $textInput)
                        .textFieldStyle(.roundedBorder)
                        .disabled(viewModel.isProcessing)
                    
                    Button {
                        sendTextMessage()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                    .disabled(textInput.isEmpty || viewModel.isProcessing)
                }
                .padding(.horizontal, 16)
                
                // 录音按钮
                Button {
                    viewModel.toggleRecording()
                } label: {
                    ZStack {
                        Circle()
                            .fill(viewModel.isRecording ? Color.red : Color.blue)
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: viewModel.isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isProcessing)
                
                Text(viewModel.isRecording ? "点击结束" : "点击说话")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 12)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert("结束练习？", isPresented: $viewModel.showEndConfirmation) {
            Button("取消", role: .cancel) { }
            Button("结束", role: .destructive) {
                endPractice()
            }
        } message: {
            Text("结束后将生成练习报告")
        }
        .sheet(isPresented: $viewModel.showReport) {
            if let report = viewModel.report {
                ReportSheet(report: report, conversation: viewModel.conversation) {
                    appState.currentConversation = nil  // 关闭练习视图
                }
            }
        }
        .alert("错误", isPresented: $viewModel.showError) {
            Button("确定") { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
    
    private func endPractice() {
        Task {
            await viewModel.generateReport()
        }
    }
    
    private func sendTextMessage() {
        let text = textInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        textInput = ""
        Task {
            await viewModel.sendMessage(text: text)
        }
    }
}

// MARK: - 报告 Sheet（带关闭按钮）
struct ReportSheet: View {
    let report: ReviewReport
    let conversation: Conversation
    let onClose: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部工具栏
            HStack {
                Spacer()
                
                Text("练习报告")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    dismiss()  // 关闭 sheet
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        onClose()  // 关闭 PracticeView
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            Divider()
            
            // 报告内容
            ScrollView {
                VStack(spacing: 24) {
                    // 总体评分
                    VStack(spacing: 8) {
                        Text("总体水平")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(report.overallLevel)
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.blue)
                    }
                    
                    // 分数条
                    HStack(spacing: 16) {
                        ScoreItem(title: "任务完成", score: report.taskCompletion)
                        ScoreItem(title: "语法", score: report.grammarAccuracy)
                        ScoreItem(title: "流利度", score: report.fluency)
                        ScoreItem(title: "词汇", score: report.vocabulary)
                    }
                    
                    // 建议
                    if !report.suggestions.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("改进建议")
                                .font(.headline)
                            
                            ForEach(report.suggestions, id: \.self) { suggestion in
                                HStack(alignment: .top) {
                                    Text("•")
                                    Text(suggestion)
                                }
                                .font(.subheadline)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    // 返回按钮
                    Button {
                        dismiss()  // 关闭 report sheet
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            onClose()  // 关闭 PracticeView
                        }
                    } label: {
                        Text("返回首页")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
            }
        }
        .frame(width: 500, height: 600)
    }
}

struct ScoreItem: View {
    let title: String
    let score: Int
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(score)")
                .font(.title2)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Message Bubble
struct MessageBubble: View {
    let message: Message
    
    var isUser: Bool { message.role == .user }
    
    var body: some View {
        HStack {
            if isUser { Spacer() }
            
            Text(message.content)
                .font(.body)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(isUser ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isUser ? .white : .primary)
                .cornerRadius(16)
            
            if !isUser { Spacer() }
        }
    }
}
