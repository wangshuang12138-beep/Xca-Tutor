import SwiftUI

struct MistakeBookView: View {
    @StateObject private var viewModel = MistakeBookViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 筛选标签
                filterTabs
                
                // 错误列表
                if viewModel.filteredMistakes.isEmpty {
                    emptyState
                } else {
                    mistakeList
                }
            }
            .navigationTitle("错题本 (\(viewModel.allMistakes.count))")
            .toolbar {
                ToolbarItem {
                    Menu {
                        Button("按时间排序") {
                            viewModel.sortOrder = .date
                        }
                        Button("按类型排序") {
                            viewModel.sortOrder = .type
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                }
            }
        }
    }
    
    // MARK: - Filter Tabs
    private var filterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                FilterTab(
                    title: "全部",
                    count: viewModel.allMistakes.count,
                    isSelected: viewModel.filter == .all
                ) {
                    viewModel.filter = .all
                }
                
                FilterTab(
                    title: "语法",
                    count: viewModel.grammarMistakes.count,
                    isSelected: viewModel.filter == .grammar
                ) {
                    viewModel.filter = .grammar
                }
                
                FilterTab(
                    title: "词汇",
                    count: viewModel.vocabularyMistakes.count,
                    isSelected: viewModel.filter == .vocabulary
                ) {
                    viewModel.filter = .vocabulary
                }
                
                FilterTab(
                    title: "未掌握",
                    count: viewModel.unmasteredMistakes.count,
                    isSelected: viewModel.filter == .unmastered
                ) {
                    viewModel.filter = .unmastered
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 64))
                .foregroundColor(.green)
            
            Text("太棒了！")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("当前筛选条件下没有错误记录")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Mistake List
    private var mistakeList: some View {
        List {
            ForEach(viewModel.filteredMistakes) { mistake in
                MistakeBookRow(mistake: mistake) {
                    viewModel.markAsMastered(mistake)
                }
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - Filter Tab

struct FilterTab: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                Text("\(count)")
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(isSelected ? Color.white.opacity(0.3) : Color.gray.opacity(0.2))
                    .cornerRadius(10)
            }
            .font(.subheadline.weight(isSelected ? .semibold : .regular))
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color.clear)
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Mistake Book Row

struct MistakeBookRow: View {
    let mistake: Mistake
    let onMaster: () -> Void
    
    var icon: String {
        switch mistake.type {
        case .grammar: return "📝"
        case .vocabulary: return "📚"
        case .pronunciation: return "🎤"
        }
    }
    
    var typeText: String {
        switch mistake.type {
        case .grammar: return "语法"
        case .vocabulary: return "词汇"
        case .pronunciation: return "发音"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 头部
            HStack {
                Text(icon)
                Text(typeText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if mistake.mastered {
                    Label("已掌握", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Text("练习 \(mistake.practiceCount)/3")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            // 错误内容
            VStack(alignment: .leading, spacing: 8) {
                Text("❌ \(mistake.originalText)")
                    .foregroundColor(.red)
                
                Text("✅ \(mistake.correctedText)")
                    .foregroundColor(.green)
            }
            
            // 解释
            Text(mistake.explanation)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            // 来源和时间
            HStack {
                Text("来自: 餐厅点餐")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(formattedDate(mistake.createdAt))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // 操作按钮
            if !mistake.mastered {
                HStack {
                    Button("练习") {
                        // 打开练习界面
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Button("标记掌握") {
                        onMaster()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }
}

// MARK: - View Model

@MainActor
class MistakeBookViewModel: ObservableObject {
    @Published var allMistakes: [Mistake] = []
    @Published var filter: MistakeFilter = .all
    @Published var sortOrder: SortOrder = .date
    
    enum MistakeFilter {
        case all, grammar, vocabulary, pronunciation, unmastered
    }
    
    enum SortOrder {
        case date, type
    }
    
    var filteredMistakes: [Mistake] {
        let filtered: [Mistake]
        switch filter {
        case .all:
            filtered = allMistakes
        case .grammar:
            filtered = allMistakes.filter { $0.type == .grammar }
        case .vocabulary:
            filtered = allMistakes.filter { $0.type == .vocabulary }
        case .pronunciation:
            filtered = allMistakes.filter { $0.type == .pronunciation }
        case .unmastered:
            filtered = allMistakes.filter { !$0.mastered }
        }
        
        switch sortOrder {
        case .date:
            return filtered.sorted { $0.createdAt > $1.createdAt }
        case .type:
            return filtered.sorted { $0.type.rawValue < $1.type.rawValue }
        }
    }
    
    var grammarMistakes: [Mistake] {
        allMistakes.filter { $0.type == .grammar }
    }
    
    var vocabularyMistakes: [Mistake] {
        allMistakes.filter { $0.type == .vocabulary }
    }
    
    var unmasteredMistakes: [Mistake] {
        allMistakes.filter { !$0.mastered }
    }
    
    init() {
        loadMistakes()
    }
    
    private func loadMistakes() {
        allMistakes = DatabaseManager.shared.getAllMistakes()
    }
    
    func markAsMastered(_ mistake: Mistake) {
        if DatabaseManager.shared.markMistakeAsMastered(id: mistake.id) {
            if let index = allMistakes.firstIndex(where: { $0.id == mistake.id }) {
                allMistakes[index].mastered = true
            }
        }
    }
}
