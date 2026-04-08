import SwiftUI

struct MistakeBookView: View {
    @EnvironmentObject var appState: AppState
    @State private var mistakes: [MistakeRecord] = []
    @State private var selectedCategory: MistakeCategory? = nil
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: Spacing.xxl) {
                // Header with stats
                MistakeBookHeader(
                    totalCount: mistakes.count,
                    masteredCount: mistakes.filter { $0.isMastered }.count
                )
                
                // Category filters
                MistakeCategoryFilter(
                    selected: $selectedCategory,
                    categories: MistakeCategory.allCases
                )
                
                // Mistakes list
                if filteredMistakes.isEmpty {
                    EmptyStateView(
                        icon: "checkmark.circle.fill",
                        title: "No mistakes to review",
                        subtitle: "Great job! Keep practicing to maintain your streak."
                    )
                } else {
                    VStack(spacing: Spacing.md) {
                        ForEach(filteredMistakes) { mistake in
                            MistakeDetailCard(mistake: mistake)
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.vertical, Spacing.xxl)
        }
        .background(AppleColors.background)
        .onAppear {
            loadMistakes()
        }
    }
    
    private var filteredMistakes: [MistakeRecord] {
        guard let category = selectedCategory else { return mistakes }
        return mistakes.filter { $0.category == category }
    }
    
    private func loadMistakes() {
        mistakes = DatabaseManager.shared.getUnmasteredMistakes()
    }
}

// MARK: - Mistake Book Header

struct MistakeBookHeader: View {
    let totalCount: Int
    let masteredCount: Int
    
    var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(masteredCount) / Double(totalCount)
    }
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Mistake Book")
                        .font(Typography.largeTitle)
                        .foregroundStyle(AppleColors.primaryText)
                    
                    Text("Review and master your mistakes")
                        .font(Typography.title2)
                        .foregroundStyle(AppleColors.secondaryText)
                }
                
                Spacer()
                
                // Progress ring
                ZStack {
                    Circle()
                        .stroke(AppleColors.tertiaryBackground, lineWidth: 8)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(AppleColors.success, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 0) {
                        Text("\(masteredCount)/\(totalCount)")
                            .font(Typography.callout.weight(.medium))
                            .foregroundStyle(AppleColors.primaryText)
                    }
                }
            }
        }
    }
}

// MARK: - Mistake Category Filter

struct MistakeCategoryFilter: View {
    @Binding var selected: MistakeCategory?
    let categories: [MistakeCategory]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.md) {
                FilterChip(
                    title: "All",
                    isSelected: selected == nil
                ) {
                    selected = nil
                }
                
                ForEach(categories) { category in
                    FilterChip(
                        title: category.rawValue,
                        isSelected: selected == category
                    ) {
                        selected = category
                    }
                }
            }
            .padding(.vertical, Spacing.sm)
        }
    }
}

// MARK: - Mistake Detail Card

struct MistakeDetailCard: View {
    let mistake: MistakeRecord
    @State private var isExpanded = false
    @State private var isMastered: Bool
    
    init(mistake: MistakeRecord) {
        self.mistake = mistake
        _isMastered = State(initialValue: mistake.isMastered)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button(action: { isExpanded.toggle() }) {
                HStack(spacing: Spacing.md) {
                    // Mastery indicator
                    Button(action: { isMastered.toggle() }) {
                        Image(systemName: isMastered ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 24))
                            .foregroundStyle(isMastered ? AppleColors.success : AppleColors.tertiaryText)
                    }
                    .buttonStyle(.plain)
                    
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(mistake.title)
                            .font(Typography.body.weight(.medium))
                            .foregroundStyle(AppleColors.primaryText)
                        
                        Text(mistake.category.rawValue)
                            .font(Typography.caption2)
                            .foregroundStyle(AppleColors.secondaryText)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppleColors.secondaryText)
                }
                .padding(Spacing.lg)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
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
                            .padding(.top, Spacing.sm)
                    }
                    
                    // Practice button
                    Button(action: { /* practice */ }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Practice This")
                        }
                        .font(Typography.callout.weight(.medium))
                        .foregroundStyle(AppleColors.accent)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, Spacing.sm)
                }
                .padding(Spacing.lg)
            }
        }
        .background(AppleColors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
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
        .padding(Spacing.xxl)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Models

enum MistakeCategory: String, CaseIterable, Identifiable {
    case grammar = "Grammar"
    case vocabulary = "Vocabulary"
    case pronunciation = "Pronunciation"
    case fluency = "Fluency"
    
    var id: String { rawValue }
}

struct MistakeRecord: Identifiable {
    let id = UUID()
    let title: String
    let original: String
    let correction: String
    let explanation: String
    let category: MistakeCategory
    var isMastered: Bool
    let createdAt: Date
}

// MARK: - Preview

#Preview {
    MistakeBookView()
        .environmentObject(AppState())
        .frame(width: 900, height: 700)
}
