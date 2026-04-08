import SwiftUI

struct ReportView: View {
    let report: PracticeReport
    let conversation: Conversation
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: ReportTab = .summary
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: Spacing.xxl) {
                // Header
                ReportHeader(title: "Practice Report", onClose: { dismiss() })
                
                // Tab selector
                ReportTabSelector(selectedTab: $selectedTab)
                
                // Content based on selected tab
                switch selectedTab {
                case .summary:
                    SummaryTab(report: report)
                case .transcript:
                    TranscriptTab(conversation: conversation)
                case .mistakes:
                    MistakesTab(mistakes: report.mistakes)
                }
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.vertical, Spacing.xxl)
        }
        .background(AppleColors.background)
        .frame(minWidth: 700, minHeight: 800)
    }
}

// MARK: - Report Tab

enum ReportTab: String, CaseIterable {
    case summary = "Summary"
    case transcript = "Transcript"
    case mistakes = "Mistakes"
}

// MARK: - Report Tab Selector

struct ReportTabSelector: View {
    @Binding var selectedTab: ReportTab
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(ReportTab.allCases, id: \.self) { tab in
                Button(action: { selectedTab = tab }) {
                    VStack(spacing: Spacing.xs) {
                        Text(tab.rawValue)
                            .font(Typography.callout.weight(selectedTab == tab ? .semibold : .regular))
                            .foregroundStyle(selectedTab == tab ? AppleColors.primaryText : AppleColors.secondaryText)
                        
                        Rectangle()
                            .fill(selectedTab == tab ? AppleColors.accent : Color.clear)
                            .frame(height: 2)
                    }
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.bottom, Spacing.sm)
    }
}

// MARK: - Summary Tab

struct SummaryTab: View {
    let report: PracticeReport
    
    var body: some View {
        VStack(spacing: Spacing.xxl) {
            // Level Badge
            LevelBadge(level: report.overallLevel)
            
            // Overall Score Circle
            OverallScoreCircle(score: report.overallScore)
            
            // Detailed Scores
            DetailedScores(scores: [
                ("Task Completion", report.taskCompletion, "checkmark.circle"),
                ("Grammar Accuracy", report.grammarAccuracy, "textformat"),
                ("Fluency", report.fluency, "waveform"),
                ("Vocabulary", report.vocabulary, "character.book.closed")
            ])
            
            // Vocabulary Highlights
            if !report.vocabularyHighlights.isEmpty {
                VocabularyHighlights(words: report.vocabularyHighlights)
            }
            
            // Suggestions
            if !report.suggestions.isEmpty {
                SuggestionsSection(suggestions: report.suggestions)
            }
        }
    }
}

// MARK: - Transcript Tab

struct TranscriptTab: View {
    let conversation: Conversation
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            HStack {
                Text("Conversation Transcript")
                    .font(Typography.title3)
                    .foregroundStyle(AppleColors.primaryText)
                
                Spacer()
                
                Text("\(conversation.messages.count) messages")
                    .font(Typography.caption)
                    .foregroundStyle(AppleColors.secondaryText)
            }
            
            VStack(spacing: 0) {
                ForEach(Array(conversation.messages.enumerated()), id: \.element.id) { index, message in
                    TranscriptMessageRow(message: message, index: index + 1)
                    
                    if index < conversation.messages.count - 1 {
                        Divider().padding(.leading, 44)
                    }
                }
            }
            .padding(Spacing.lg)
            .background(AppleColors.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        }
    }
}

// MARK: - Transcript Message Row

struct TranscriptMessageRow: View {
    let message: Message
    let index: Int
    
    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            // Speaker indicator
            ZStack {
                Circle()
                    .fill(message.role == .assistant 
                          ? AppleColors.accent.opacity(0.1) 
                          : AppleColors.secondaryBackground)
                    .frame(width: 32, height: 32)
                
                Text(message.role == .assistant ? "AI" : "You")
                    .font(Typography.caption2.weight(.medium))
                    .foregroundStyle(message.role == .assistant 
                                     ? AppleColors.accent 
                                     : AppleColors.primaryText)
            }
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Text(message.role == .assistant ? "AI Agent" : "You")
                        .font(Typography.callout.weight(.medium))
                        .foregroundStyle(AppleColors.primaryText)
                    
                    Spacer()
                    
                    Text(formatTime(message.timestamp))
                        .font(Typography.caption2)
                        .foregroundStyle(AppleColors.tertiaryText)
                }
                
                Text(message.content)
                    .font(Typography.body)
                    .foregroundStyle(AppleColors.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, Spacing.sm)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}

// MARK: - Mistakes Tab

struct MistakesTab: View {
    let mistakes: [MistakeItem]
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            if mistakes.isEmpty {
                EmptyStateView(
                    icon: "checkmark.circle.fill",
                    title: "No mistakes found",
                    subtitle: "Great job! You performed very well in this conversation."
                )
                .padding(Spacing.xxl)
            } else {
                HStack {
                    Text("Mistakes (\(mistakes.count))")
                        .font(Typography.title3)
                        .foregroundStyle(AppleColors.primaryText)
                    
                    Spacer()
                }
                
                VStack(spacing: Spacing.md) {
                    ForEach(mistakes) { mistake in
                        MistakeDetailCard(mistake: mistake)
                    }
                }
            }
        }
    }
}

// MARK: - Report Header

struct ReportHeader: View {
    let title: String
    let onClose: () -> Void
    
    var body: some View {
        HStack {
            Text(title)
                .font(Typography.title1)
                .foregroundStyle(AppleColors.primaryText)
            
            Spacer()
            
            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(AppleColors.secondaryText)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Level Badge

struct LevelBadge: View {
    let level: String
    
    var body: some View {
        ZStack {
            // Gradient background
            Circle()
                .fill(
                    LinearGradient(
                        colors: AppleColors.orangeGradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 120)
            
            // Inner circle
            Circle()
                .fill(.white.opacity(0.2))
                .frame(width: 100, height: 100)
            
            VStack(spacing: Spacing.xs) {
                Text(level)
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(.white)
                
                Text("Level")
                    .font(Typography.caption)
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
        .shadow(color: AppleColors.orangeGradient[0].opacity(0.4), radius: 20, x: 0, y: 10)
    }
}

// MARK: - Overall Score Circle

struct OverallScoreCircle: View {
    let score: Int
    @State private var animatedScore: Int = 0
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(AppleColors.secondaryBackground, lineWidth: 12)
                .frame(width: 180, height: 180)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: CGFloat(animatedScore) / 100)
                .stroke(
                    AngularGradient(
                        colors: [AppleColors.accent, Color(hex: "5856D6")],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 180, height: 180)
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 1.5, dampingFraction: 0.8), value: animatedScore)
            
            VStack(spacing: Spacing.xs) {
                Text("\(animatedScore)")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundStyle(AppleColors.primaryText)
                
                Text("/100")
                    .font(Typography.title2)
                    .foregroundStyle(AppleColors.secondaryText)
            }
        }
        .frame(height: 220)
        .onAppear {
            withAnimation(.easeOut(duration: 1.5)) {
                animatedScore = score
            }
        }
    }
}

// MARK: - Detailed Scores

struct DetailedScores: View {
    let scores: [(name: String, value: Int, icon: String)]
    
    var body: some View {
        VStack(spacing: Spacing.md) {
            ForEach(Array(scores.enumerated()), id: \.element.name) { index, score in
                ScoreRow(
                    name: score.name,
                    value: score.value,
                    icon: score.icon
                )
                
                if index < scores.count - 1 {
                    Divider()
                        .padding(.leading, 44)
                }
            }
        }
        .padding(Spacing.lg)
        .background(AppleColors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
    }
}

// MARK: - Score Row

struct ScoreRow: View {
    let name: String
    let value: Int
    let icon: String
    @State private var animatedValue: CGFloat = 0
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(scoreColor)
                .frame(width: 28)
            
            Text(name)
                .font(Typography.body)
                .foregroundStyle(AppleColors.primaryText)
            
            Spacer()
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppleColors.tertiaryBackground)
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(scoreColor)
                        .frame(width: geometry.size.width * animatedValue, height: 8)
                        .animation(.spring(response: 1, dampingFraction: 0.8).delay(0.3), value: animatedValue)
                }
            }
            .frame(width: 80, height: 8)
            
            Text("\(value)%")
                .font(Typography.callout.weight(.medium))
                .foregroundStyle(AppleColors.primaryText)
                .frame(width: 40, alignment: .trailing)
        }
        .padding(.vertical, Spacing.sm)
        .onAppear {
            animatedValue = CGFloat(value) / 100
        }
    }
    
    private var scoreColor: Color {
        if value >= 80 { return AppleColors.success }
        if value >= 60 { return AppleColors.warning }
        return AppleColors.error
    }
}

// MARK: - Vocabulary Highlights

struct VocabularyHighlights: View {
    let words: [String]
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            HStack {
                Text("Vocabulary Highlights")
                    .font(Typography.title3)
                    .foregroundStyle(AppleColors.primaryText)
                
                Spacer()
            }
            
            FlowLayout(spacing: Spacing.md) {
                ForEach(words, id: \.self) { word in
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(AppleColors.success)
                        
                        Text(word)
                            .font(Typography.callout.weight(.medium))
                            .foregroundStyle(AppleColors.primaryText)
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(AppleColors.success.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
        }
        .padding(Spacing.lg)
        .background(AppleColors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
    }
}

// MARK: - Suggestions Section

struct SuggestionsSection: View {
    let suggestions: [String]
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            HStack {
                Text("Suggestions")
                    .font(Typography.title3)
                    .foregroundStyle(AppleColors.primaryText)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: Spacing.md) {
                ForEach(suggestions, id: \.self) { suggestion in
                    HStack(alignment: .top, spacing: Spacing.sm) {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption)
                            .foregroundStyle(AppleColors.warning)
                        
                        Text(suggestion)
                            .font(Typography.callout)
                            .foregroundStyle(AppleColors.primaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(Spacing.lg)
        .background(AppleColors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
    }
}

// MARK: - Mistake Detail Card

struct MistakeDetailCard: View {
    let mistake: MistakeItem
    @State private var isExpanded = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(AppleColors.error)
                
                Text(mistake.title)
                    .font(Typography.body.weight(.medium))
                    .foregroundStyle(AppleColors.primaryText)
                
                Spacer()
                
                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppleColors.secondaryText)
                }
                .buttonStyle(.plain)
            }
            .padding(Spacing.lg)
            .contentShape(Rectangle())
            .onTapGesture {
                isExpanded.toggle()
            }
            
            if isExpanded {
                Divider().padding(.horizontal, Spacing.lg)
                
                VStack(alignment: .leading, spacing: Spacing.md) {
                    // Original vs Correction
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        MistakeComparisonRow(
                            label: "Your sentence",
                            text: mistake.original,
                            color: AppleColors.error
                        )
                        
                        MistakeComparisonRow(
                            label: "Correct",
                            text: mistake.correction,
                            color: AppleColors.success
                        )
                    }
                    
                    // Explanation
                    if !mistake.explanation.isEmpty {
                        Text(mistake.explanation)
                            .font(Typography.callout)
                            .foregroundStyle(AppleColors.secondaryText)
                            .padding(.top, Spacing.xs)
                    }
                }
                .padding(Spacing.lg)
            }
        }
        .background(AppleColors.tertiaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        .animation(.spring(response: 0.3), value: isExpanded)
    }
}

// MARK: - Mistake Comparison Row

struct MistakeComparisonRow: View {
    let label: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Text(label + ":")
                .font(Typography.caption)
                .foregroundStyle(AppleColors.tertiaryText)
                .frame(width: 90, alignment: .leading)
            
            Text("\"\(text)\"")
                .font(Typography.callout)
                .foregroundStyle(color)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundStyle(AppleColors.success)
            
            Text(title)
                .font(Typography.title2)
                .foregroundStyle(AppleColors.primaryText)
            
            Text(subtitle)
                .font(Typography.callout)
                .foregroundStyle(AppleColors.secondaryText)
                .multilineTextAlignment(.center)
        }
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

// MARK: - Models

struct PracticeReport {
    let overallLevel: String
    let overallScore: Int
    let taskCompletion: Int
    let grammarAccuracy: Int
    let fluency: Int
    let vocabulary: Int
    let mistakes: [MistakeItem]
    let vocabularyHighlights: [String]
    let suggestions: [String]
}

struct MistakeItem: Identifiable {
    let id = UUID()
    let title: String
    let original: String
    let correction: String
    let explanation: String
}

// MARK: - Preview

#Preview {
    ReportView(
        report: PracticeReport(
            overallLevel: "B1",
            overallScore: 82,
            taskCompletion: 80,
            grammarAccuracy: 85,
            fluency: 78,
            vocabulary: 82,
            mistakes: [
                MistakeItem(
                    title: "I'd like vs I want",
                    original: "I want a steak",
                    correction: "I'd like a steak, please",
                    explanation: "Use 'I'd like' for polite requests in restaurants."
                )
            ],
            vocabularyHighlights: ["recommend", "specialty", "check, please"],
            suggestions: ["Try using more complex sentence structures", "Practice polite forms more"]
        ),
        conversation: Conversation(
            id: UUID(),
            sceneId: UUID(),
            startTime: Date(),
            endTime: nil,
            difficulty: "B1",
            duration: 15
        )
    )
    .frame(width: 800, height: 900)
}
