import SwiftUI
import Charts

struct StatisticsView: View {
    @State private var weeklyData: [PracticeData] = []
    @State private var selectedMetric: MetricType = .practiceTime
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: Spacing.xxl) {
                // Header
                StatisticsHeader()
                
                // Key metrics cards
                KeyMetricsRow()
                
                // Chart section
                if #available(macOS 13.0, *) {
                    ChartSection(
                        data: weeklyData,
                        selectedMetric: $selectedMetric
                    )
                }
                
                // Skills breakdown
                SkillsBreakdownSection()
                
                // Recent activity
                RecentActivitySection()
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.vertical, Spacing.xxl)
        }
        .background(AppleColors.background)
        .onAppear {
            loadData()
        }
    }
    
    private func loadData() {
        // Generate sample data
        weeklyData = (0..<7).map { dayOffset in
            let date = Calendar.current.date(byAdding: .day, value: -dayOffset, to: Date())!
            return PracticeData(
                date: date,
                practiceMinutes: Int.random(in: 0...60),
                accuracy: Int.random(in: 60...95),
                fluency: Int.random(in: 60...90)
            )
        }.reversed()
    }
}

// MARK: - Statistics Header

struct StatisticsHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Statistics")
                .font(Typography.largeTitle)
                .foregroundStyle(AppleColors.primaryText)
            
            Text("Track your progress over time")
                .font(Typography.title2)
                .foregroundStyle(AppleColors.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Key Metrics Row

struct KeyMetricsRow: View {
    var body: some View {
        HStack(spacing: Spacing.lg) {
            LargeMetricCard(
                title: "Total Practice",
                value: "24.5",
                unit: "hours",
                change: "↑ 12%",
                icon: "clock.fill",
                color: AppleColors.accent
            )
            
            LargeMetricCard(
                title: "Current Streak",
                value: "7",
                unit: "days",
                change: nil,
                icon: "flame.fill",
                color: AppleColors.orangeGradient[0]
            )
            
            LargeMetricCard(
                title: "Avg Accuracy",
                value: "82",
                unit: "%",
                change: "↑ 5%",
                icon: "target",
                color: AppleColors.success
            )
        }
    }
}

// MARK: - Large Metric Card

struct LargeMetricCard: View {
    let title: String
    let value: String
    let unit: String
    let change: String?
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(color)
                
                Spacer()
                
                if let change = change {
                    Text(change)
                        .font(Typography.caption2)
                        .foregroundStyle(AppleColors.success)
                }
            }
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                    Text(value)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(AppleColors.primaryText)
                    
                    Text(unit)
                        .font(Typography.callout)
                        .foregroundStyle(AppleColors.secondaryText)
                }
                
                Text(title)
                    .font(Typography.caption)
                    .foregroundStyle(AppleColors.secondaryText)
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, minHeight: 140, alignment: .leading)
        .background(AppleColors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
    }
}

// MARK: - Chart Section

@available(macOS 13.0, *)
struct ChartSection: View {
    let data: [PracticeData]
    @Binding var selectedMetric: MetricType
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            HStack {
                Text("Weekly Progress")
                    .font(Typography.title3)
                    .foregroundStyle(AppleColors.primaryText)
                
                Spacer()
                
                Picker("", selection: $selectedMetric) {
                    Text("Time").tag(MetricType.practiceTime)
                    Text("Accuracy").tag(MetricType.accuracy)
                    Text("Fluency").tag(MetricType.fluency)
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }
            
            Chart(data) { item in
                BarMark(
                    x: .value("Day", item.dayLabel),
                    y: .value(selectedMetric.title, selectedMetric.value(for: item))
                )
                .foregroundStyle(selectedMetric.color)
                .cornerRadius(4)
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
        .padding(Spacing.lg)
        .background(AppleColors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
    }
}

// MARK: - Skills Breakdown Section

struct SkillsBreakdownSection: View {
    let skills = [
        ("Grammar", 85, AppleColors.accent),
        ("Vocabulary", 78, Color(hex: "5856D6")),
        ("Fluency", 72, AppleColors.warning),
        ("Pronunciation", 80, AppleColors.success)
    ]
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Text("Skills Breakdown")
                .font(Typography.title3)
                .foregroundStyle(AppleColors.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: Spacing.md) {
                ForEach(skills, id: \.0) { skill in
                    SkillProgressRow(
                        name: skill.0,
                        value: skill.1,
                        color: skill.2
                    )
                }
            }
        }
        .padding(Spacing.lg)
        .background(AppleColors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
    }
}

// MARK: - Skill Progress Row

struct SkillProgressRow: View {
    let name: String
    let value: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            Text(name)
                .font(Typography.body)
                .foregroundStyle(AppleColors.primaryText)
                .frame(width: 100, alignment: .leading)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppleColors.tertiaryBackground)
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(value) / 100, height: 8)
                        .animation(.spring(response: 1), value: value)
                }
            }
            .frame(height: 8)
            
            Text("\(value)%")
                .font(Typography.callout.weight(.medium))
                .foregroundStyle(AppleColors.primaryText)
                .frame(width: 45, alignment: .trailing)
        }
    }
}

// MARK: - Recent Activity Section

struct RecentActivitySection: View {
    let activities = [
        ("Restaurant Ordering", "Today", "15 min", "B1"),
        ("Job Interview", "Yesterday", "20 min", "B2"),
        ("Hotel Check-in", "2 days ago", "12 min", "A2"),
        ("Airport Check-in", "3 days ago", "18 min", "B1")
    ]
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Text("Recent Activity")
                .font(Typography.title3)
                .foregroundStyle(AppleColors.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 0) {
                ForEach(Array(activities.enumerated()), id: \.offset) { index, activity in
                    ActivityRow(
                        scene: activity.0,
                        time: activity.1,
                        duration: activity.2,
                        level: activity.3
                    )
                    
                    if index < activities.count - 1 {
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

// MARK: - Activity Row

struct ActivityRow: View {
    let scene: String
    let time: String
    let duration: String
    let level: String
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(AppleColors.accent.opacity(0.1))
                    .frame(width: 36, height: 36)
                
                Image(systemName: "mic.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(AppleColors.accent)
            }
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(scene)
                    .font(Typography.body.weight(.medium))
                    .foregroundStyle(AppleColors.primaryText)
                
                Text(time)
                    .font(Typography.caption)
                    .foregroundStyle(AppleColors.secondaryText)
            }
            
            Spacer()
            
            HStack(spacing: Spacing.lg) {
                Text(duration)
                    .font(Typography.callout)
                    .foregroundStyle(AppleColors.secondaryText)
                
                DifficultyBadge(difficulty: level)
            }
        }
        .padding(.vertical, Spacing.sm)
    }
}

// MARK: - Models

enum MetricType: String, CaseIterable {
    case practiceTime = "Practice Time"
    case accuracy = "Accuracy"
    case fluency = "Fluency"
    
    var title: String {
        switch self {
        case .practiceTime: return "Minutes"
        case .accuracy: return "Accuracy (%)"
        case .fluency: return "Fluency (%)"
        }
    }
    
    var color: Color {
        switch self {
        case .practiceTime: return AppleColors.accent
        case .accuracy: return AppleColors.success
        case .fluency: return Color(hex: "5856D6")
        }
    }
    
    func value(for data: PracticeData) -> Int {
        switch self {
        case .practiceTime: return data.practiceMinutes
        case .accuracy: return data.accuracy
        case .fluency: return data.fluency
        }
    }
}

struct PracticeData: Identifiable {
    let id = UUID()
    let date: Date
    let practiceMinutes: Int
    let accuracy: Int
    let fluency: Int
    
    var dayLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
}
