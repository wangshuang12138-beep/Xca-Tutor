# Xca-Tutor UI Redesign - Apple Design Language

> 版本：v2.0  
> 设计方向：Apple 官网极简主义  
> 目标平台：macOS 14+ (Sonoma+)

---

## 一、设计语言

### 1.1 核心原则

| 原则 | 描述 | 实现方式 |
|------|------|----------|
| **极简** | 少即是多 | 大量留白，单一焦点 |
| **层次** | 清晰的信息层级 | 字体大小、颜色深浅、间距 |
| **质感** | 玻璃拟态 + 精致阴影 | VisualEffectView, blur |
| **动效** |  purposeful animation | 弹簧动画，微交互 |
| **统一** | 一致的圆角和间距 | 设计系统 token |

### 1.2 色彩系统

```swift
// Color Palette
enum AppleColors {
    // 背景
    static let background = Color(NSColor.windowBackgroundColor)
    static let secondaryBackground = Color(NSColor.controlBackgroundColor)
    static let tertiaryBackground = Color(NSColor.tertiarySystemFill)
    
    // 文字
    static let primaryText = Color(NSColor.label)
    static let secondaryText = Color(NSColor.secondaryLabel)
    static let tertiaryText = Color(NSColor.tertiaryLabel)
    
    // 强调色 - Apple Blue
    static let accent = Color(hex: "007AFF")
    static let accentHover = Color(hex: "0066CC")
    static let accentPressed = Color(hex: "0055AA")
    
    // 功能色
    static let success = Color(hex: "34C759")
    static let warning = Color(hex: "FF9500")
    static let error = Color(hex: "FF3B30")
    
    // 玻璃效果
    static let glassBackground = Color.white.opacity(0.1)
    static let glassBorder = Color.white.opacity(0.2)
}
```

### 1.3 字体系统

使用 San Francisco（系统默认），遵循 Apple 的动态字体规范：

```swift
enum Typography {
    // 大标题 - 用于页面头部
    static let largeTitle = Font.system(size: 48, weight: .bold, design: .rounded)
    
    // 标题
    static let title1 = Font.system(size: 32, weight: .bold)
    static let title2 = Font.system(size: 24, weight: .semibold)
    static let title3 = Font.system(size: 20, weight: .semibold)
    
    // 正文
    static let body = Font.system(size: 15, weight: .regular)
    static let bodyLarge = Font.system(size: 17, weight: .regular)
    static let callout = Font.system(size: 14, weight: .regular)
    
    // 辅助
    static let caption = Font.system(size: 12, weight: .regular)
    static let caption2 = Font.system(size: 11, weight: .medium)
}
```

### 1.4 间距系统

```swift
enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
    static let xxxl: CGFloat = 64
}
```

### 1.5 圆角系统

```swift
enum CornerRadius {
    static let sm: CGFloat = 6
    static let md: CGFloat = 10
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let full: CGFloat = 9999
}
```

---

## 二、页面设计

### 2.1 主界面 - HomeView

**设计理念**：像 Apple Music 或 App Store 的 "Today" 页面，大卡片、沉浸式、聚焦内容

```
┌─────────────────────────────────────────────────────────────────┐
│  Xca-Tutor                                    ⚙️    👤         │  ← 极简工具栏
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Good evening, xca                                              │  ← 问候语（动态）
│  Ready to practice?                                             │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                                                         │   │
│  │              🎯 Continue Practice                       │   │  ← 大号主卡片
│  │                                                         │   │
│  │   Restaurant Ordering                                   │   │
│  │   12 min · B1 Level · In Progress                       │   │
│  │                                                         │   │
│  │   [ Resume Practice ]                                   │   │
│  │                                                         │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  Scenes                                                         │  ← 分类标题
│                                                                 │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌────────────┐│
│  │            │  │            │  │            │  │            ││
│  │    🍽️      │  │    ✈️      │  │    💼      │  │    🏨      ││
│  │            │  │            │  │            │  │            ││
│  │ Restaurant │  │   Airport  │  │ Interview  │  │   Hotel    ││
│  │   A2-B1    │  │   A2-B2    │  │   B1-C1    │  │   A1-B1    ││
│  └────────────┘  └────────────┘  └────────────┘  └────────────┘│
│                                                                 │
│  Stats                                                          │
│                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │   This Week     │  │   Streak        │  │   Accuracy      │ │
│  │                 │  │                 │  │                 │ │
│  │   3.5 hours     │  │   🔥 7 days     │  │   82%           │ │
│  │   ↑ 12%         │  │                 │  │   ↑ 5%          │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
│                                                                 │
│  Mistakes                                                       │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │   12 items waiting for review                           │   │
│  │   [ Review Now → ]                                      │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**SwiftUI 代码结构**：

```swift
struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: Spacing.xxl) {
                // 问候区域
                GreetingHeader()
                
                // 继续练习卡片（如果有进行中的练习）
                if let ongoing = viewModel.ongoingConversation {
                    ContinuePracticeCard(conversation: ongoing)
                }
                
                // 场景选择
                ScenesSection(scenes: viewModel.scenes)
                
                // 统计数据
                StatsSection(stats: viewModel.stats)
                
                // 错题本
                MistakesPreview(count: viewModel.mistakeCount)
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.vertical, Spacing.xxl)
        }
        .background(AppleColors.background)
        .navigationTitle("")
    }
}
```

**组件实现**：

```swift
// 继续练习卡片 - 带玻璃拟态效果
struct ContinuePracticeCard: View {
    let conversation: Conversation
    
    var body: some View {
        ZStack {
            // 渐变背景
            RoundedRectangle(cornerRadius: CornerRadius.xl)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "5856D6").opacity(0.8),
                            Color(hex: "AF52DE").opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // 玻璃效果层
            RoundedRectangle(cornerRadius: CornerRadius.xl)
                .fill(.ultraThinMaterial)
            
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Text("In Progress")
                        .font(Typography.caption2)
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs)
                        .background(.white.opacity(0.2))
                        .clipShape(Capsule())
                }
                
                Spacer()
                
                Text(conversation.sceneName)
                    .font(Typography.title2)
                    .foregroundStyle(.white)
                
                Text("\(conversation.duration) min · \(conversation.difficulty) Level")
                    .font(Typography.callout)
                    .foregroundStyle(.white.opacity(0.8))
                
                Spacer()
                
                Button(action: { /* resume */ }) {
                    HStack {
                        Image(systemName: "arrow.right.circle.fill")
                        Text("Resume Practice")
                    }
                    .font(Typography.bodyLarge.weight(.medium))
                    .foregroundStyle(Color(hex: "5856D6"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                }
                .buttonStyle(.plain)
            }
            .padding(Spacing.xl)
        }
        .frame(height: 280)
    }
}

// 场景卡片 - 悬停效果
struct SceneCard: View {
    let scene: Scene
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(AppleColors.secondaryBackground)
                
                Text(scene.icon)
                    .font(.system(size: 48))
            }
            .frame(height: 120)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(AppleColors.glassBorder, lineWidth: isHovered ? 2 : 0)
            )
            
            VStack(spacing: Spacing.xs) {
                Text(scene.name)
                    .font(Typography.callout.weight(.medium))
                    .foregroundStyle(AppleColors.primaryText)
                
                Text(scene.difficultyRange)
                    .font(Typography.caption)
                    .foregroundStyle(AppleColors.secondaryText)
            }
        }
        .onHover { hovered in
            withAnimation(.spring(response: 0.3)) {
                isHovered = hovered
            }
        }
        .scaleEffect(isHovered ? 1.02 : 1.0)
    }
}

// 统计卡片
struct StatCard: View {
    let title: String
    let value: String
    let change: String?
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Spacer()
                if let change = change {
                    Text(change)
                        .font(Typography.caption2)
                        .foregroundStyle(AppleColors.success)
                }
            }
            
            Spacer()
            
            Text(value)
                .font(Typography.title3)
                .foregroundStyle(AppleColors.primaryText)
            
            Text(title)
                .font(Typography.caption)
                .foregroundStyle(AppleColors.secondaryText)
        }
        .padding(Spacing.lg)
        .frame(height: 120)
        .background(AppleColors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
    }
}
```

---

### 2.2 练习界面 - PracticeView

**设计理念**：像 FaceTime 一样沉浸式，全屏聚焦对话，最小化干扰

```
┌─────────────────────────────────────────────────────────────────┐
│  ←  Restaurant Ordering                              12:34     │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│                                                                 │
│                                                                 │
│              ┌─────────────────────────────────┐               │
│              │                                 │               │
│              │      [波形动画 - Agent 说话]     │               │
│              │                                 │               │
│              └─────────────────────────────────┘               │
│                                                                 │
│         "What would you like to order today?"                  │
│                                                                 │
│                         [Live Caption]                          │
│                                                                 │
│                                                                 │
│                                                                 │
│    ────────────────────────────────────────────────────────    │
│                                                                 │
│    You: I'd like a steak, please.                              │
│                                                         (2s)   │
│                                                                 │
│    Agent: How would you like it cooked?                        │
│                                                        (5s)    │
│                                                                 │
│    You: Medium rare.                                           │
│                                                        (12s)   │
│                                                                 │
│    ────────────────────────────────────────────────────────    │
│                                                                 │
│                                                                 │
│                         [ 🎙️ ]                                 │
│                      Hold to speak                             │
│                                                                 │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│  🎯 B1  │  Fluency 85%  │  Accuracy 82%  │  [ End ]            │
└─────────────────────────────────────────────────────────────────┘
```

**SwiftUI 实现**：

```swift
struct PracticeView: View {
    @StateObject private var viewModel: PracticeViewModel
    
    var body: some View {
        ZStack {
            // 动态背景 - 根据对话情绪变化
            MeshGradientBackground()
            
            VStack(spacing: 0) {
                // 顶部导航
                PracticeNavigationBar(
                    sceneName: viewModel.sceneName,
                    duration: viewModel.duration
                )
                
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: Spacing.xxl) {
                            // Agent 当前说话区域
                            CurrentAgentMessage(
                                message: viewModel.currentAgentMessage,
                                isSpeaking: viewModel.isAgentSpeaking
                            )
                            
                            // 对话历史
                            ConversationHistory(messages: viewModel.messages)
                                .id("bottom")
                        }
                        .padding(.horizontal, Spacing.xxl)
                        .padding(.vertical, Spacing.xl)
                    }
                    .onChange(of: viewModel.messages.count) { _ in
                        withAnimation {
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                    }
                }
                
                Spacer()
                
                // 语音输入控制
                VoiceInputControl(
                    isRecording: viewModel.isRecording,
                    onPress: viewModel.startRecording,
                    onRelease: viewModel.stopRecording
                )
                .padding(.bottom, Spacing.xl)
                
                // 底部状态栏
                PracticeStatusBar(
                    level: viewModel.currentLevel,
                    fluency: viewModel.fluencyScore,
                    accuracy: viewModel.accuracyScore,
                    onEnd: viewModel.endPractice
                )
            }
        }
    }
}

// Agent 当前消息 - 带声波动画
struct CurrentAgentMessage: View {
    let message: String
    let isSpeaking: Bool
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            // 波形可视化
            WaveformVisualizer(isAnimating: isSpeaking)
                .frame(height: 100)
            
            // 当前语句
            Text(message)
                .font(Typography.title2)
                .foregroundStyle(AppleColors.primaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
    }
}

// 波形可视化组件
struct WaveformVisualizer: View {
    let isAnimating: Bool
    @State private var phase: CGFloat = 0
    
    var body: some View {
        Canvas { context, size in
            let barCount = 30
            let barWidth = size.width / CGFloat(barCount * 2)
            let centerY = size.height / 2
            
            for i in 0..<barCount {
                let x = CGFloat(i * 2 + 1) * barWidth
                let normalizedIndex = CGFloat(i) / CGFloat(barCount)
                let amplitude = isAnimating 
                    ? sin(phase + normalizedIndex * .pi * 4) * 0.5 + 0.5
                    : 0.1
                let barHeight = size.height * amplitude * 0.8
                
                let barRect = CGRect(
                    x: x - barWidth / 2,
                    y: centerY - barHeight / 2,
                    width: barWidth,
                    height: barHeight
                )
                
                let bar = Path(roundedRect: barRect, cornerRadius: barWidth / 2)
                context.fill(bar, with: .color(AppleColors.accent.opacity(0.6 + amplitude * 0.4)))
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 0.1).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
    }
}

// 语音输入按钮 - 带按住效果
struct VoiceInputControl: View {
    let isRecording: Bool
    let onPress: () -> Void
    let onRelease: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {}) {
            ZStack {
                // 外圈脉冲动画
                if isRecording {
                    PulseRing()
                }
                
                // 主按钮
                Circle()
                    .fill(isRecording ? AppleColors.error : AppleColors.accent)
                    .frame(width: 80, height: 80)
                    .shadow(
                        color: (isRecording ? AppleColors.error : AppleColors.accent).opacity(0.4),
                        radius: isPressed ? 20 : 10,
                        x: 0,
                        y: isPressed ? 10 : 5
                    )
                
                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
        .pressEvents {
            withAnimation(.spring(response: 0.3)) {
                isPressed = true
            }
            onPress()
        } onRelease: {
            withAnimation(.spring(response: 0.3)) {
                isPressed = false
            }
            onRelease()
        }
    }
}

// 脉冲动画
struct PulseRing: View {
    @State private var scale: CGFloat = 1
    @State private var opacity: Double = 0.6
    
    var body: some View {
        Circle()
            .stroke(AppleColors.error.opacity(opacity), lineWidth: 2)
            .frame(width: 120, height: 120)
            .scaleEffect(scale)
            .onAppear {
                withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
                    scale = 1.5
                    opacity = 0
                }
            }
    }
}

// 自定义按压事件修饰符
struct PressEventsModifier: ViewModifier {
    var onPress: () -> Void
    var onRelease: () -> Void
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in onPress() }
                    .onEnded { _ in onRelease() }
            )
    }
}

extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        modifier(PressEventsModifier(onPress: onPress, onRelease: onRelease))
    }
}
```

---

### 2.3 报告界面 - ReportView

**设计理念**：像 Apple Health 一样，数据可视化，鼓励进步

```
┌─────────────────────────────────────────────────────────────────┐
│  ←  Practice Report                                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│                      ┌─────────────┐                           │
│                      │             │                           │
│                      │     B1      │                           │  ← 等级徽章
│                      │   Level     │                           │
│                      │             │                           │
│                      └─────────────┘                           │
│                                                                 │
│                   Overall Score                                │
│                                                                 │
│   ┌───────────────────────────────────────────────────────┐    │
│   │                                                       │    │
│   │              [环形进度图 - 82%]                       │    │
│   │                                                       │    │
│   │                    82                                 │    │
│   │                   /100                              │    │
│   │                                                       │    │
│   └───────────────────────────────────────────────────────┘    │
│                                                                 │
│   Detailed Breakdown                                           │
│                                                                 │
│   ┌───────────────────────────────────────────────────────┐    │
│   │  Task Completion    ████████████░░░    80%           │    │
│   │  Grammar Accuracy   █████████████░░░    85%           │    │
│   │  Fluency            ███████████░░░░░    78%           │    │
│   │  Vocabulary         ████████████░░░░    82%           │    │
│   └───────────────────────────────────────────────────────┘    │
│                                                                 │
│   Mistakes (2)                                                 │
│                                                                 │
│   ┌───────────────────────────────────────────────────────┐    │
│   │  🔴 I'd like vs I want                                │    │
│   │     "I want a steak" → "I'd like a steak, please"     │    │
│   │     [ Practice → ]                                    │    │
│   ├───────────────────────────────────────────────────────┤    │
│   │  🔴 Without vs No                                     │    │
│   │     "No vegetables" → "Without vegetables, please"    │    │
│   │     [ Practice → ]                                    │    │
│   └───────────────────────────────────────────────────────┘    │
│                                                                 │
│   Vocabulary Highlights                                        │
│                                                                 │
│   ┌───────────────────────────────────────────────────────┐    │
│   │  ✅ recommend  ✅ specialty  ✅ check, please         │    │
│   └───────────────────────────────────────────────────────┘    │
│                                                                 │
│   [  Replay Conversation  ]  [  Practice Mistakes  ]          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**SwiftUI 实现**：

```swift
struct ReportView: View {
    let report: PracticeReport
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: Spacing.xxl) {
                // 等级徽章
                LevelBadge(level: report.overallLevel)
                
                // 总分圆环
                OverallScoreCircle(score: report.overallScore)
                
                // 详细得分
                DetailedScores(scores: [
                    ("Task Completion", report.taskCompletion, "checkmark.circle"),
                    ("Grammar Accuracy", report.grammarAccuracy, "textformat"),
                    ("Fluency", report.fluency, "waveform"),
                    ("Vocabulary", report.vocabulary, "character.book.closed")
                ])
                
                // 错误列表
                if !report.mistakes.isEmpty {
                    MistakesSection(mistakes: report.mistakes)
                }
                
                // 词汇亮点
                if !report.vocabularyHighlights.isEmpty {
                    VocabularyHighlights(words: report.vocabularyHighlights)
                }
                
                // 操作按钮
                ActionButtons()
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.vertical, Spacing.xxl)
        }
        .background(AppleColors.background)
        .navigationTitle("Practice Report")
    }
}

// 等级徽章
struct LevelBadge: View {
    let level: String
    
    var body: some View {
        ZStack {
            // 渐变背景
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "FF6B35"), Color(hex: "F7931E")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 120)
            
            // 内圈
            Circle()
                .fill(.white.opacity(0.2))
                .frame(width: 100, height: 100)
            
            VStack(spacing: Spacing.xs) {
                Text(level)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.white)
                
                Text("Level")
                    .font(Typography.caption2)
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
        .shadow(color: Color(hex: "FF6B35").opacity(0.3), radius: 20, x: 0, y: 10)
    }
}

// 总分圆环
struct OverallScoreCircle: View {
    let score: Int
    
    var body: some View {
        ZStack {
            // 背景圆环
            Circle()
                .stroke(AppleColors.secondaryBackground, lineWidth: 12)
                .frame(width: 200, height: 200)
            
            // 进度圆环
            Circle()
                .trim(from: 0, to: CGFloat(score) / 100)
                .stroke(
                    AngularGradient(
                        colors: [AppleColors.accent, Color(hex: "5856D6")],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 200, height: 200)
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 1, dampingFraction: 0.8), value: score)
            
            VStack(spacing: Spacing.xs) {
                Text("\(score)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(AppleColors.primaryText)
                
                Text("/100")
                    .font(Typography.title3)
                    .foregroundStyle(AppleColors.secondaryText)
            }
        }
        .frame(height: 240)
    }
}

// 详细得分
struct DetailedScores: View {
    let scores: [(name: String, value: Int, icon: String)]
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            ForEach(scores, id: \.name) { item in
                ScoreRow(
                    name: item.name,
                    value: item.value,
                    icon: item.icon
                )
            }
        }
        .padding(Spacing.lg)
        .background(AppleColors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
    }
}

struct ScoreRow: View {
    let name: String
    let value: Int
    let icon: String
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(AppleColors.accent)
                .frame(width: 32)
            
            Text(name)
                .font(Typography.body)
                .foregroundStyle(AppleColors.primaryText)
            
            Spacer()
            
            // 进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppleColors.tertiaryBackground)
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(value >= 80 ? AppleColors.success : value >= 60 ? AppleColors.warning : AppleColors.error)
                        .frame(width: geometry.size.width * CGFloat(value) / 100, height: 8)
                        .animation(.spring(response: 1), value: value)
                }
            }
            .frame(width: 100, height: 8)
            
            Text("\(value)%")
                .font(Typography.callout.weight(.medium))
                .foregroundStyle(AppleColors.primaryText)
                .frame(width: 40, alignment: .trailing)
        }
    }
}

// 错误项
struct MistakeRow: View {
    let mistake: Mistake
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(AppleColors.error)
                
                Text(mistake.title)
                    .font(Typography.body.weight(.medium))
                    .foregroundStyle(AppleColors.primaryText)
                
                Spacer()
            }
            
            HStack(spacing: Spacing.xs) {
                Text("\"")
                    .foregroundStyle(AppleColors.error)
                + Text(mistake.original)
                    .foregroundStyle(AppleColors.error)
                + Text("\"")
                    .foregroundStyle(AppleColors.error)
                
                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundStyle(AppleColors.secondaryText)
                
                Text("\"")
                    .foregroundStyle(AppleColors.success)
                + Text(mistake.correction)
                    .foregroundStyle(AppleColors.success)
                + Text("\"")
                    .foregroundStyle(AppleColors.success)
            }
            .font(Typography.callout)
            
            Button(action: { /* practice */ }) {
                HStack {
                    Text("Practice")
                    Image(systemName: "arrow.right")
                }
                .font(Typography.caption2.weight(.medium))
                .foregroundStyle(AppleColors.accent)
            }
            .buttonStyle(.plain)
        }
        .padding(Spacing.lg)
        .background(AppleColors.tertiaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
    }
}
```

---

### 2.4 设置界面 - SettingsView

**设计理念**：像 macOS 系统设置一样，简洁、清晰、分组明确

```swift
struct SettingsView: View {
    @StateObject private var settings = SettingsManager.shared
    
    var body: some View {
        Form {
            // API 配置
            Section {
                Picker("ASR Provider", selection: $settings.asrProvider) {
                    Text("豆包").tag(ASRProvider.doubao)
                    Text("阿里云").tag(ASRProvider.qwen)
                    Text("OpenAI").tag(ASRProvider.openai)
                }
                .pickerStyle(.segmented)
                
                SecureField("API Key", text: $settings.apiKey)
                    .textFieldStyle(.roundedBorder)
            } header: {
                Text("Service Configuration")
                    .font(Typography.caption2.weight(.medium))
                    .textCase(.uppercase)
            }
            
            // 模型参数
            Section {
                Picker("Chat Model", selection: $settings.chatModel) {
                    Text("GPT-4o").tag("gpt-4o")
                    Text("GPT-4o-mini").tag("gpt-4o-mini")
                }
                
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Temperature: \(String(format: "%.1f", settings.temperature))")
                        .font(Typography.callout)
                    
                    Slider(value: $settings.temperature, in: 0...2, step: 0.1)
                        .tint(AppleColors.accent)
                }
                
                Picker("Voice", selection: $settings.voiceName) {
                    Text("Alloy").tag("alloy")
                    Text("Echo").tag("echo")
                    Text("Fable").tag("fable")
                    Text("Onyx").tag("onyx")
                    Text("Nova").tag("nova")
                    Text("Shimmer").tag("shimmer")
                }
            } header: {
                Text("Model Parameters")
                    .font(Typography.caption2.weight(.medium))
                    .textCase(.uppercase)
            }
            
            // 练习偏好
            Section {
                Picker("Default Difficulty", selection: $settings.defaultDifficulty) {
                    Text("A1").tag("A1")
                    Text("A2").tag("A2")
                    Text("B1").tag("B1")
                    Text("B2").tag("B2")
                    Text("C1").tag("C1")
                    Text("C2").tag("C2")
                }
                
                Toggle("Auto Upgrade Difficulty", isOn: $settings.autoUpgrade)
            } header: {
                Text("Practice Preferences")
                    .font(Typography.caption2.weight(.medium))
                    .textCase(.uppercase)
            }
            
            // 关于
            Section {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("2.0.0")
                        .foregroundStyle(AppleColors.secondaryText)
                }
            } header: {
                Text("About")
                    .font(Typography.caption2.weight(.medium))
                    .textCase(.uppercase)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
    }
}
```

---

## 三、动效设计

### 3.1 页面转场

```swift
// 自定义转场
extension AnyTransition {
    static var appleSlide: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }
    
    static var appleScale: AnyTransition {
        .scale(scale: 0.95, anchor: .center)
            .combined(with: .opacity)
    }
}
```

### 3.2 微交互

```swift
// 按钮点击反馈
struct AppleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
    }
}

// 卡片悬停效果
struct HoverScaleModifier: ViewModifier {
    @State private var isHovered = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovered ? 1.02 : 1)
            .shadow(
                color: .black.opacity(isHovered ? 0.1 : 0.05),
                radius: isHovered ? 20 : 10,
                x: 0,
                y: isHovered ? 10 : 5
            )
            .onHover { hovered in
                withAnimation(.spring(response: 0.3)) {
                    isHovered = hovered
                }
            }
    }
}
```

---

## 四、组件库

### 4.1 主按钮

```swift
struct PrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .font(Typography.bodyLarge.weight(.medium))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(AppleColors.accent)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        }
        .buttonStyle(AppleButtonStyle())
    }
}
```

### 4.2 次按钮

```swift
struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Typography.bodyLarge.weight(.medium))
                .foregroundStyle(AppleColors.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(AppleColors.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        }
        .buttonStyle(AppleButtonStyle())
    }
}
```

### 4.3 玻璃卡片

```swift
struct GlassCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(.ultraThinMaterial)
            
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(AppleColors.glassBorder, lineWidth: 1)
            
            content
                .padding(Spacing.lg)
        }
    }
}
```

---

## 五、文件结构

```
XcaTutor/
├── Views/
│   ├── Home/
│   │   ├── HomeView.swift
│   │   ├── ContinuePracticeCard.swift
│   │   ├── SceneCard.swift
│   │   └── StatCard.swift
│   ├── Practice/
│   │   ├── PracticeView.swift
│   │   ├── WaveformVisualizer.swift
│   │   ├── VoiceInputControl.swift
│   │   └── ConversationBubble.swift
│   ├── Report/
│   │   ├── ReportView.swift
│   │   ├── LevelBadge.swift
│   │   ├── OverallScoreCircle.swift
│   │   └── MistakeRow.swift
│   └── Settings/
│       └── SettingsView.swift
├── DesignSystem/
│   ├── Colors.swift
│   ├── Typography.swift
│   ├── Spacing.swift
│   └── Components/
│       ├── PrimaryButton.swift
│       ├── SecondaryButton.swift
│       └── GlassCard.swift
└── Utilities/
    └── ViewExtensions.swift
```

---

## 六、参考

- [Apple Design Resources](https://developer.apple.com/design/resources/)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [SF Symbols](https://developer.apple.com/sf-symbols/)

