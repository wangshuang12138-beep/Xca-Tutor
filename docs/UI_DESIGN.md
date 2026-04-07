# Xca-Tutor UI 设计文档

> 版本：v0.1.0  
> 平台：macOS  
> 设计工具：SwiftUI

---

## 1. 设计原则

### 1.1 设计目标

- **简洁高效**：减少视觉噪音，让用户专注于练习
- **及时反馈**：每个操作都有明确的反馈
- **舒适阅读**：大量文本内容，确保可读性
- **沉浸体验**：练习时尽量减少干扰

### 1.2 设计参考

- **Apple 原生应用**：遵循 macOS 设计规范
- **语言学习应用**：参考 Duolingo、Babbel 的激励设计
- **对话应用**：参考 Messages、ChatGPT 的对话流

---

## 2. 色彩系统

### 2.1 主色调

```swift
struct AppColors {
    // 品牌色
    static let primary = Color.blue
    static let primaryLight = Color.blue.opacity(0.1)
    
    // 功能色
    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red
    static let info = Color.blue
    
    // 难度等级色
    static let levelA = Color.green      // A1-A2
    static let levelB = Color.blue       // B1-B2
    static let levelC = Color.purple     // C1-C2
    
    // 背景色
    static let background = Color(NSColor.windowBackgroundColor)
    static let secondaryBackground = Color(NSColor.controlBackgroundColor)
    
    // 文字色
    static let primaryText = Color(NSColor.labelColor)
    static let secondaryText = Color(NSColor.secondaryLabelColor)
    static let tertiaryText = Color(NSColor.tertiaryLabelColor)
}
```

### 2.2 暗黑模式适配

所有颜色使用系统动态颜色，自动适配 Light/Dark 模式。

---

## 3. 字体规范

```swift
struct AppFonts {
    // 标题
    static let largeTitle = Font.system(size: 32, weight: .bold)
    static let title = Font.system(size: 24, weight: .bold)
    static let title2 = Font.system(size: 20, weight: .semibold)
    static let title3 = Font.system(size: 18, weight: .semibold)
    
    // 正文
    static let body = Font.system(size: 14, weight: .regular)
    static let bodyLarge = Font.system(size: 16, weight: .regular)
    static let callout = Font.system(size: 13, weight: .regular)
    static let caption = Font.system(size: 12, weight: .regular)
    
    // 特殊
    static let mono = Font.system(.body, design: .monospaced)
}
```

---

## 4. 界面布局

### 4.1 主界面 (HomeView)

```
┌─────────────────────────────────────────────────────────────┐
│  [Sidebar]            │  [Main Content]                      │
│                       │                                      │
│  🏠 首页              │  👋 欢迎回来，xca                   │
│  📚 场景              │                                      │
│  📝 错题本 (12)       │  ┌───────────────────────────────┐  │
│  📊 学习统计          │  │ 🎯 继续上次练习                │  │
│                       │  │ 餐厅点餐 · 练习了 12 分钟      │  │
│  ⚙️ 设置              │  │ [继续练习]                     │  │
│                       │  └───────────────────────────────┘  │
│                       │                                      │
│                       │  📚 选择场景                        │  │
│                       │  ┌───────┐ ┌───────┐ ┌───────┐     │  │
│                       │  │ 🍽️    │ │ ✈️    │ │ 💼    │     │  │
│                       │  │ 餐厅  │ │ 机场  │ │ 面试  │     │  │
│                       │  └───────┘ └───────┘ └───────┘     │  │
│                       │  ┌───────┐ ┌───────┐ ┌───────┐     │  │
│                       │  │ 🏨    │ │ 🛒    │ │ ➕    │     │  │
│                       │  │ 酒店  │ │ 购物  │ │ 更多  │     │  │
│                       │  └───────┘ └───────┘ └───────┘     │  │
│                       │                                      │
│                       │  📊 本周学习                         │  │
│                       │  ┌───────────────────────────────┐  │
│                       │  │ 练习时长: 3.5 小时            │  │
│                       │  │ 新掌握词汇: 45 个             │  │
│                       │  │ 平均准确率: 82% ↑ 5%          │  │
│                       │  └───────────────────────────────┘  │
│                       │                                      │
└───────────────────────┴──────────────────────────────────────┘
```

**布局参数：**
- Sidebar 宽度：200pt
- 内容区最大宽度：800pt（居中）
- 场景卡片：120x100pt，圆角 12pt
- 间距：标准 16pt，紧凑 8pt

### 4.2 练习界面 (PracticeView)

```
┌─────────────────────────────────────────────────────────────┐
│  ← 餐厅点餐                              ⏸️ 暂停  🎙️ 设置  │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│                         [波形动画]                          │
│                         ○ ○ ○ ● ● ○ ○                       │
│                                                              │
│                                                              │
│            "What would you like to order?"                  │
│                       Agent 说                              │
│                                                              │
│  ─────────────────────────────────────────────────────────  │
│                                                              │
│                         你：                                │
│            "I'd like a steak, please."                      │
│                     （刚刚）                                │
│                                                              │
│                         Agent：                             │
│          "How would you like it cooked?"                    │
│                     （5秒前）                               │
│                                                              │
│                         你：                                │
│              "Medium rare."                                 │
│                    （12秒前）                               │
│                                                              │
├─────────────────────────────────────────────────────────────┤
│  🎯 B1 │ 流利度 85% │ 准确度 82%  │  💡 点击波形或按空格说话  │
└─────────────────────────────────────────────────────────────┘
```

**布局参数：**
- 波形动画区域：200pt 高度
- 对话气泡：最大宽度 70%，圆角 16pt
- 用户气泡：右对齐，蓝色背景
- Agent 气泡：左对齐，灰色背景
- 底部状态栏：60pt 高度

**交互说明：**
- 点击波形或按空格键开始/停止录音
- 对话历史可滚动查看
- 长按消息可复制文本

### 4.3 报告界面 (ReportView)

```
┌─────────────────────────────────────────────────────────────┐
│  ← 练习报告                               📤 分享  💾 保存  │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│                    餐厅点餐                                 │
│                 2024.04.07  14:32                          │
│                                                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                                                     │   │
│  │                    B1                               │   │
│  │                  (中级)                             │   │
│  │                                                     │   │
│  │            任务完成度 80%                           │   │
│  │                                                     │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                              │
│  详细得分                                                    │
│  任务完成  ████████░░  80%                                  │
│  语法准确  ████████░░░  85%                                  │
│  流利度    ███████░░░░  78%                                  │
│  词汇丰富  ████████░░░  82%                                  │
│                                                              │
│  ─────────────────────────────────────────────────────────  │
│                                                              │
│  错误分析（2）                              [开始重练]      │
│                                                              │
│  🔴 语法错误                                                │
│  "I want a steak" → "I'd like a steak"                    │
│  点餐时用 "I'd like" 更礼貌                                │
│                                                              │
│  🔴 语法错误                                                │
│  "No vegetables" → "Without vegetables"                   │
│  否定可用 "without" 更自然                                 │
│                                                              │
│  ─────────────────────────────────────────────────────────  │
│                                                              │
│  词汇亮点（3）                                              │
│  ✅ recommend    ✅ specialty    ✅ check, please          │
│                                                              │
│  ─────────────────────────────────────────────────────────  │
│                                                              │
│  [回放完整对话]                                             │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

**布局参数：**
- 评分卡片：圆角 20pt，阴影
- 进度条高度：8pt，圆角 4pt
- 错误项：左侧红色竖线标识
- 词汇标签：圆角 8pt，浅绿色背景

### 4.4 回放界面 (PlaybackView)

```
┌─────────────────────────────────────────────────────────────┐
│  ← 对话回放                                      0:34 / 5:23 │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  [━━━━━━━━━━━━━●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━] 拖动时间轴   │
│                                                              │
│     ⏮️  ⏪  ▶️  ⏩  ⏭️  速度: 1.0x                     │
│                                                              │
│  ─────────────────────────────────────────────────────────  │
│                                                              │
│                         Agent：                             │
│          "What would you like to order?"                    │
│                     00:12                                  │
│                                                              │
│  ⏵ 点击播放此句                                            │
│                                                              │
│                         你：                                │
│            "I'd like a steak, please."                      │
│                     00:15                                  │
│                                                              │
│                         Agent：                             │
│          "How would you like it cooked?"                    │
│                     00:18                                  │
│                                                              │
│                         你：                                │
│              "Medium rare."                                 │
│                     00:21                                  │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### 4.5 设置界面 (SettingsView)

```
┌─────────────────────────────────────────────────────────────┐
│  ⚙️ 设置                                                   │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  API 配置                                                   │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ OpenAI API Key                                      │   │
│  │ ┌───────────────────────────────────────────────┐   │   │
│  │ │ sk-••••••••••••••••••••••••••••••••••••      │   │   │
│  │ └───────────────────────────────────────────────┘   │   │
│  │                              [显示] [验证]          │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                              │
│  模型参数 ⚙️                                                │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 对话模型                                            │   │
│  │ ┌───────────────────────────────────────────────┐   │   │
│  │ │ GPT-4o                              ▼         │   │   │
│  │ └───────────────────────────────────────────────┘   │   │
│  │                                                     │   │
│  │ Temperature: 0.7                                    │   │
│  │ [━━━━━━━●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]   │   │
│  │ 稳定 ← 创造性                                       │   │
│  │                                                     │   │
│  │ Max Tokens: 2000                                    │   │
│  │ [━━━━━━━━━━━━●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]   │   │
│  │                                                     │   │
│  │ 语音音色                                            │   │
│  │ ┌───────────────────────────────────────────────┐   │   │
│  │ │ Nova (女性)                         ▼         │   │   │
│  │ └───────────────────────────────────────────────┘   │   │
│  │                                                     │   │
│  │ [🔊 试听]                                           │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                              │
│  练习偏好                                                   │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 默认难度: B1                                        │   │
│  │ 自动升级难度: [✓]                                   │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### 4.6 错题本界面 (MistakeBookView)

```
┌─────────────────────────────────────────────────────────────┐
│  📝 错题本                                    共 23 条错误  │
├─────────────────────────────────────────────────────────────┤
│  [全部] [语法 8] [词汇 10] [发音 5] [未掌握 15]             │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  🔴 语法错误                                                │
│  "I want a steak"                                           │
│  应改为: "I'd like a steak"                                │
│  来自: 餐厅点餐 · 2024.04.07                               │
│  练习次数: 2/3  [继续练习]  [标记掌握]                      │
│                                                              │
│  ─────────────────────────────────────────────────────────  │
│                                                              │
│  🔴 语法错误                                                │
│  "No vegetables"                                            │
│  应改为: "Without vegetables"                              │
│  来自: 餐厅点餐 · 2024.04.07                               │
│  练习次数: 0/3  [开始练习]                                  │
│                                                              │
│  ─────────────────────────────────────────────────────────  │
│                                                              │
│  🟡 词汇错误                                                │
│  "How much is the bill?"                                    │
│  更地道: "Could I have the check?"                         │
│  来自: 餐厅点餐 · 2024.04.05                               │
│  练习次数: 3/3  ✅ 已掌握                                   │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 5. 组件规范

### 5.1 按钮

```swift
// 主按钮
Button("开始练习") {}
    .buttonStyle(.primary)

// 次按钮
Button("取消") {}
    .buttonStyle(.secondary)

// 文字按钮
Button("了解更多") {}
    .buttonStyle(.text)
```

**样式定义：**
```swift
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.blue)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
    }
}
```

### 5.2 卡片

```swift
// 场景卡片
SceneCard(icon: "🍽️", name: "餐厅", description: "点餐对话")

// 数据卡片
StatsCard(title: "本周学习", value: "3.5小时", trend: "+12%")
```

### 5.3 波形动画

```swift
struct WaveformView: View {
    @State private var phase = 0.0
    var isActive: Bool
    
    var body: some View {
        Canvas { context, size in
            // 绘制波形
            var path = Path()
            let width = size.width
            let height = size.height
            let midHeight = height / 2
            
            for x in stride(from: 0, to: width, by: 2) {
                let relativeX = x / width
                let amplitude = isActive ? 20 : 5
                let frequency = 4.0
                let y = midHeight + sin(relativeX * .pi * frequency + phase) * amplitude
                
                if x == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            
            context.stroke(path, with: .color(.blue), lineWidth: 3)
        }
        .onAppear {
            withAnimation(.linear(duration: 0.1).repeatForever(autoreverses: false)) {
                phase += .pi
            }
        }
    }
}
```

---

## 6. 动画规范

### 6.1 转场动画

```swift
// 页面切换
.transition(.asymmetric(
    insertion: .move(edge: .trailing).combined(with: .opacity),
    removal: .move(edge: .leading).combined(with: .opacity)
))

// 弹窗
.transition(.scale(scale: 0.9).combined(with: .opacity))
```

### 6.2 微交互动画

```swift
// 按钮点击
.animation(.easeOut(duration: 0.15), value: isPressed)

// 波形波动
.animation(.linear(duration: 0.1).repeatForever(), value: phase)

// 进度条
.animation(.easeInOut(duration: 0.5), value: progress)
```

---

## 7. 响应式适配

### 7.1 窗口尺寸

| 尺寸 | 布局 |
|------|------|
| < 800pt | 单列，Sidebar 收起为汉堡菜单 |
| 800-1200pt | Sidebar 展开，内容居中 |
| > 1200pt | Sidebar 展开，内容最大宽度 1000pt |

### 7.2 字体缩放

支持系统字体缩放设置，不使用固定字号。

---

## 8. 图标系统

使用 SF Symbols，部分自定义图标：

| 功能 | 图标 |
|------|------|
| 首页 | house.fill |
| 场景 | book.fill |
| 错题本 | bookmark.fill |
| 统计 | chart.bar.fill |
| 设置 | gear |
| 麦克风 | mic.fill |
| 播放 | play.fill |
| 暂停 | pause.fill |
| 分享 | square.and.arrow.up |
| 删除 | trash |
| 编辑 | pencil |
| 完成 | checkmark.circle.fill |

---

## 9. 待补充

- [ ] 暗黑模式截图
- [ ] 空状态设计
- [ ] 加载状态设计
- [ ] 错误提示设计
- [ ] 引导页设计
