import SwiftUI

struct StatisticsView: View {
    @StateObject private var viewModel = StatisticsViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 总览卡片
                    overviewSection
                    
                    // 学习趋势图（纯SwiftUI实现）
                    trendChartSection
                    
                    // 本周统计
                    weeklyStatsSection
                    
                    // 能力评估
                    skillsSection
                }
                .padding(24)
            }
            .navigationTitle("学习统计")
        }
    }
    
    // MARK: - Overview
    private var overviewSection: some View {
        HStack(spacing: 16) {
            StatCard(
                title: "总练习时长",
                value: viewModel.totalDuration,
                icon: "clock",
                color: .blue
            )
            
            StatCard(
                title: "对话次数",
                value: "\(viewModel.totalConversations)",
                icon: "bubble.left.and.bubble.right",
                color: .green
            )
            
            StatCard(
                title: "已掌握错误",
                value: "\(viewModel.masteredMistakes)/\(viewModel.totalMistakes)",
                icon: "checkmark.circle",
                color: .orange
            )
        }
    }
    
    // MARK: - Trend Chart
    private var trendChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("学习趋势（最近7天）")
                .font(.headline)
            
            // 纯 SwiftUI 柱状图
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(viewModel.dailyStats) { stat in
                    VStack(spacing: 4) {
                        // 计算柱子高度（最大2小时）
                        let hours = Double(stat.totalDurationMs) / 3600000
                        let maxHeight: CGFloat = 150
                        let height = min(CGFloat(hours / 2.0) * maxHeight, maxHeight)
                        
                        ZStack(alignment: .bottom) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.1))
                                .frame(width: 30, height: maxHeight)
                            
                            Rectangle()
                                .fill(Color.blue)
                                .frame(width: 30, height: max(height, 4))
                        }
                        .cornerRadius(4)
                        
                        Text(stat.shortDate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 180)
        }
        .padding(20)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    // MARK: - Weekly Stats
    private var weeklyStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("本周表现")
                .font(.headline)
            
            HStack(spacing: 24) {
                WeeklyStatItem(
                    title: "平均流利度",
                    value: "\(viewModel.avgFluency)%",
                    trend: viewModel.fluencyTrend
                )
                
                WeeklyStatItem(
                    title: "平均准确度",
                    value: "\(viewModel.avgAccuracy)%",
                    trend: viewModel.accuracyTrend
                )
                
                WeeklyStatItem(
                    title: "新词汇",
                    value: "\(viewModel.newWords)",
                    trend: nil
                )
            }
        }
        .padding(20)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    // MARK: - Skills
    private var skillsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("能力评估")
                .font(.headline)
            
            VStack(spacing: 12) {
                SkillBar(title: "语法", score: viewModel.grammarScore)
                SkillBar(title: "词汇", score: viewModel.vocabularyScore)
                SkillBar(title: "流利度", score: viewModel.fluencyScore)
                SkillBar(title: "听力", score: viewModel.listeningScore)
            }
        }
        .padding(20)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct WeeklyStatItem: View {
    let title: String
    let value: String
    let trend: String?
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
            
            if let trend = trend {
                Text(trend)
                    .font(.caption)
                    .foregroundColor(trend.hasPrefix("+") ? .green : .red)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct SkillBar: View {
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
                .frame(width: 60, alignment: .leading)
            
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
            
            Text("\(score)")
                .frame(width: 30, alignment: .trailing)
                .font(.caption.bold())
        }
    }
}

// MARK: - View Model

@MainActor
class StatisticsViewModel: ObservableObject {
    @Published var dailyStats: [DailyStatItem] = []
    
    var totalDuration: String {
        let totalMs = dailyStats.reduce(0) { $0 + $1.totalDurationMs }
        let hours = totalMs / 3600000
        let minutes = (totalMs % 3600000) / 60000
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var totalConversations: Int {
        dailyStats.reduce(0) { $0 + $1.conversationCount }
    }
    
    var totalMistakes: Int {
        dailyStats.reduce(0) { $0 + $1.mistakesCount }
    }
    
    var masteredMistakes: Int {
        // 从数据库获取
        let allMistakes = DatabaseManager.shared.getAllMistakes()
        return allMistakes.filter { $0.mastered }.count
    }
    
    var avgFluency: Int {
        let fluencies = dailyStats.compactMap { $0.avgFluency > 0 ? $0.avgFluency : nil }
        guard !fluencies.isEmpty else { return 0 }
        return Int(fluencies.reduce(0, +) / Double(fluencies.count))
    }
    
    var avgAccuracy: Int {
        let accuracies = dailyStats.compactMap { $0.avgAccuracy > 0 ? $0.avgAccuracy : nil }
        guard !accuracies.isEmpty else { return 0 }
        return Int(accuracies.reduce(0, +) / Double(accuracies.count))
    }
    
    var fluencyTrend: String? {
        "+5%"
    }
    
    var accuracyTrend: String? {
        "+3%"
    }
    
    var newWords: Int {
        dailyStats.reduce(0) { $0 + $1.newWords }
    }
    
    var grammarScore: Int { 75 }
    var vocabularyScore: Int { 68 }
    var fluencyScore: Int { 72 }
    var listeningScore: Int { 80 }
    
    init() {
        loadStats()
    }
    
    private func loadStats() {
        let stats = DatabaseManager.shared.getStats(forDays: 7)
        dailyStats = stats.map { DailyStatItem(from: $0) }
        
        // 如果数据不足，填充空数据
        if dailyStats.count < 7 {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            
            let existingDates = Set(dailyStats.map { $0.date })
            let calendar = Calendar.current
            
            for dayOffset in (0..<7).reversed() {
                let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date())!
                let dateString = formatter.string(from: date)
                
                if !existingDates.contains(dateString) {
                    dailyStats.append(DailyStatItem(
                        date: dateString,
                        shortDate: formatShortDate(dateString),
                        conversationCount: 0,
                        totalDurationMs: 0,
                        avgFluency: 0,
                        avgAccuracy: 0,
                        newWords: 0,
                        mistakesCount: 0
                    ))
                }
            }
            
            dailyStats.sort { $0.date < $1.date }
        }
    }
    
    private func formatShortDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return dateString }
        
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }
}

struct DailyStatItem: Identifiable {
    let id = UUID()
    let date: String
    let shortDate: String
    let conversationCount: Int
    let totalDurationMs: Int
    let avgFluency: Double
    let avgAccuracy: Double
    let newWords: Int
    let mistakesCount: Int
    
    init(from stats: DailyStats) {
        self.date = stats.date
        self.shortDate = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            guard let date = formatter.date(from: stats.date) else { return stats.date }
            formatter.dateFormat = "MM/dd"
            return formatter.string(from: date)
        }()
        self.conversationCount = stats.conversationCount
        self.totalDurationMs = stats.totalDurationMs
        self.avgFluency = stats.avgFluency
        self.avgAccuracy = stats.avgAccuracy
        self.newWords = stats.newWords
        self.mistakesCount = stats.mistakesCount
    }
    
    init(date: String, shortDate: String, conversationCount: Int, totalDurationMs: Int, 
         avgFluency: Double, avgAccuracy: Double, newWords: Int, mistakesCount: Int) {
        self.date = date
        self.shortDate = shortDate
        self.conversationCount = conversationCount
        self.totalDurationMs = totalDurationMs
        self.avgFluency = avgFluency
        self.avgAccuracy = avgAccuracy
        self.newWords = newWords
        self.mistakesCount = mistakesCount
    }
}
