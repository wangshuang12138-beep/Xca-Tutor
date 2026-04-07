import SwiftUI

struct ReportView: View {
    let report: ReviewReport
    let conversation: Conversation
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 总体评分
                overallScoreSection
                
                // 详细得分
                detailScoresSection
                
                // 错误分析
                if !report.mistakes.isEmpty {
                    mistakesSection
                }
                
                // 词汇亮点
                if !report.vocabularyHighlights.isEmpty {
                    vocabularySection
                }
                
                // 建议
                if !report.suggestions.isEmpty {
                    suggestionsSection
                }
                
                // 操作按钮
                actionButtons
            }
            .padding(32)
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Overall Score
    private var overallScoreSection: some View {
        VStack(spacing: 16) {
            Text("练习报告")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(formattedDate(report.createdAt))
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ZStack {
                Circle()
                    .stroke(Color.blue.opacity(0.2), lineWidth: 12)
                    .frame(width: 140, height: 140)
                
                Circle()
                    .trim(from: 0, to: CGFloat(report.taskCompletion) / 100)
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))
                
                VStack {
                    Text(report.overallLevel)
                        .font(.system(size: 36, weight: .bold))
                    Text("CEFR 等级")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text("任务完成度 \(report.taskCompletion)%")
                .font(.headline)
        }
    }
    
    // MARK: - Detail Scores
    private var detailScoresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("详细得分")
                .font(.headline)
            
            VStack(spacing: 12) {
                ScoreBar(title: "语法准确", score: report.grammarAccuracy)
                ScoreBar(title: "流利度", score: report.fluency)
                ScoreBar(title: "词汇丰富", score: report.vocabulary)
            }
        }
    }
    
    // MARK: - Mistakes Section
    private var mistakesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("错误分析")
                    .font(.headline)
                
                Spacer()
                
                Text("\(report.mistakes.count) 个")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 12) {
                ForEach(report.mistakes.prefix(5)) { mistake in
                    MistakeCard(mistake: mistake)
                }
            }
        }
    }
    
    // MARK: - Vocabulary Section
    private var vocabularySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("词汇亮点")
                .font(.headline)
            
            FlowLayout(spacing: 8) {
                ForEach(report.vocabularyHighlights, id: \.word) { highlight in
                    VocabularyTag(word: highlight.word)
                }
            }
        }
    }
    
    // MARK: - Suggestions Section
    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("改进建议")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(report.suggestions, id: \.self) { suggestion in
                    HStack(alignment: .top) {
                        Text("•")
                        Text(suggestion)
                    }
                }
            }
            .padding(16)
            .background(Color.yellow.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        HStack(spacing: 16) {
            Button("关闭") {
                dismiss()
            }
            .keyboardShortcut(.escape, modifiers: [])
            
            Button("再练一次") {
                // 重新开始同一场景
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views

struct ScoreBar: View {
    let title: String
    let score: Int
    
    var color: Color {
        if score >= 80 { return .green }
        if score >= 60 { return .blue }
        return .orange
    }
    
    var body: some View {
        HStack {
            Text(title)
                .frame(width: 80, alignment: .leading)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(score) / 100)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
            
            Text("\(score)%")
                .frame(width: 50, alignment: .trailing)
                .font(.caption.bold())
        }
    }
}

struct MistakeCard: View {
    let mistake: Mistake
    
    var icon: String {
        switch mistake.type {
        case .grammar: return "📝"
        case .vocabulary: return "📚"
        case .pronunciation: return "🎤"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(icon)
                Text(mistake.type == .grammar ? "语法错误" : "词汇问题")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text("❌ \(mistake.originalText)")
                .foregroundColor(.red)
            
            Text("✅ \(mistake.correctedText)")
                .foregroundColor(.green)
            
            Text(mistake.explanation)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.05))
        .cornerRadius(8)
        .overlay(
            Rectangle()
                .fill(Color.red)
                .frame(width: 4),
            alignment: .leading
        )
    }
}

struct VocabularyTag: View {
    let word: String
    
    var body: some View {
        Text(word)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.green.opacity(0.15))
            .foregroundColor(.green)
            .cornerRadius(16)
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
                
                self.size.width = max(self.size.width, x)
            }
            
            self.size.height = y + rowHeight
        }
    }
}
