import SwiftUI

struct PracticeView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel: PracticeViewModel
    
    init(conversation: Conversation) {
        _viewModel = StateObject(wrappedValue: PracticeViewModel(conversation: conversation))
    }
    
    var body: some View {
        ZStack {
            // Dynamic background
            MeshGradientBackground()
            
            VStack(spacing: 0) {
                // Navigation bar
                PracticeNavigationBar(
                    sceneName: viewModel.scene?.name ?? "Practice",
                    duration: viewModel.elapsedTimeString,
                    onEnd: endPractice
                )
                
                // Main content - minimalist, voice-only interface
                Spacer()
                
                // Current agent message (voice only, no text history)
                CurrentAgentMessage(
                    message: viewModel.currentAgentMessage,
                    isSpeaking: viewModel.isAgentSpeaking
                )
                
                Spacer()
                
                // Recording indicator (subtle)
                if viewModel.isRecording {
                    RecordingIndicator()
                        .padding(.bottom, Spacing.lg)
                }
                
                // Voice input control
                VoiceInputControl(
                    isRecording: viewModel.isRecording,
                    onPress: { viewModel.startRecording() },
                    onRelease: { viewModel.stopRecording() }
                )
                .padding(.bottom, Spacing.xl)
                
                // Status bar
                PracticeStatusBar(
                    level: viewModel.currentLevel,
                    fluency: viewModel.fluencyScore,
                    accuracy: viewModel.accuracyScore,
                    onEnd: endPractice
                )
            }
        }
        .sheet(isPresented: $viewModel.showReport) {
            if let report = viewModel.report {
                ReportView(report: report, conversation: viewModel.conversation)
            }
        }
    }
    
    private func endPractice() {
        viewModel.endPractice()
        appState.endPractice()
    }
}

// MARK: - Navigation Bar

struct PracticeNavigationBar: View {
    let sceneName: String
    let duration: String
    let onEnd: () -> Void
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            Text(sceneName)
                .font(Typography.title3)
                .foregroundStyle(AppleColors.primaryText)
            
            Spacer()
            
            Text(duration)
                .font(Typography.callout)
                .foregroundStyle(AppleColors.secondaryText)
                .monospacedDigit()
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, Spacing.md)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Current Agent Message

struct CurrentAgentMessage: View {
    let message: String
    let isSpeaking: Bool
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Large waveform visualization
            WaveformVisualizer(isAnimating: isSpeaking)
                .frame(height: 120)
            
            // Current statement (minimal, fades when not speaking)
            if !message.isEmpty {
                Text(message)
                    .font(Typography.title2)
                    .foregroundStyle(AppleColors.primaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
                    .opacity(isSpeaking ? 1 : 0.6)
                    .animation(.easeInOut(duration: 0.3), value: isSpeaking)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
    }
}

// MARK: - Waveform Visualizer

struct WaveformVisualizer: View {
    let isAnimating: Bool
    @State private var phase: CGFloat = 0
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 1/60, paused: !isAnimating)) { _ in
            Canvas { context, size in
                let barCount = 48
                let barWidth: CGFloat = 3
                let spacing: CGFloat = 4
                let totalWidth = CGFloat(barCount) * (barWidth + spacing) - spacing
                let startX = (size.width - totalWidth) / 2
                let centerY = size.height / 2
                
                for i in 0..<barCount {
                    let x = startX + CGFloat(i) * (barWidth + spacing)
                    let normalizedIndex = CGFloat(i) / CGFloat(barCount)
                    
                    // Create organic wave pattern
                    let baseAmplitude = isAnimating
                        ? (sin(phase + normalizedIndex * .pi * 8) * 0.3 + 0.5)
                        : 0.15
                    
                    let randomFactor = isAnimating ? CGFloat.random(in: 0.9...1.1) : 1.0
                    let amplitude = min(1.0, baseAmplitude * randomFactor)
                    
                    let barHeight = size.height * amplitude
                    let barRect = CGRect(
                        x: x,
                        y: centerY - barHeight / 2,
                        width: barWidth,
                        height: barHeight
                    )
                    
                    let bar = Path(roundedRect: barRect, cornerRadius: barWidth / 2)
                    
                    // Gradient based on position
                    let hue = 0.6 + normalizedIndex * 0.1 // Blue to purple
                    let color = Color(hue: hue, saturation: 0.8, brightness: 0.9)
                        .opacity(0.4 + amplitude * 0.6)
                    context.fill(bar, with: .color(color))
                }
            }
        }
        .onAppear {
            if isAnimating {
                withAnimation(.linear(duration: 0.1).repeatForever(autoreverses: false)) {
                    phase += .pi * 2
                }
            }
        }
        .onChange(of: isAnimating) { newValue in
            if newValue {
                withAnimation(.linear(duration: 0.1).repeatForever(autoreverses: false)) {
                    phase += .pi * 2
                }
            }
        }
    }
}

// MARK: - Recording Indicator

struct RecordingIndicator: View {
    @State private var pulse = false
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            Circle()
                .fill(AppleColors.error)
                .frame(width: 8, height: 8)
                .opacity(pulse ? 1 : 0.5)
            
            Text("Listening...")
                .font(Typography.caption)
                .foregroundStyle(AppleColors.secondaryText)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                pulse.toggle()
            }
        }
    }
}

// MARK: - Voice Input Control

struct VoiceInputControl: View {
    let isRecording: Bool
    let onPress: () -> Void
    let onRelease: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {}) {
            ZStack {
                // Pulse rings when recording
                if isRecording {
                    PulseRing()
                        .frame(width: 140, height: 140)
                    PulseRing(delay: 0.4)
                        .frame(width: 140, height: 140)
                }
                
                // Main button
                Circle()
                    .fill(isRecording ? AppleColors.error : AppleColors.accent)
                    .frame(width: 80, height: 80)
                    .shadow(
                        color: (isRecording ? AppleColors.error : AppleColors.accent).opacity(0.4),
                        radius: isPressed ? 25 : (isRecording ? 20 : 10),
                        x: 0,
                        y: isPressed ? 15 : (isRecording ? 10 : 5)
                    )
                
                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(.white)
                    .scaleEffect(isPressed ? 0.9 : 1.0)
            }
        }
        .buttonStyle(.plain)
        .pressEvents {
            withAnimation(.spring(response: 0.2)) {
                isPressed = true
            }
            onPress()
        } onRelease: {
            withAnimation(.spring(response: 0.2)) {
                isPressed = false
            }
            onRelease()
        }
    }
}

// MARK: - Pulse Ring

struct PulseRing: View {
    var delay: Double = 0
    @State private var scale: CGFloat = 1
    @State private var opacity: Double = 0.5
    
    var body: some View {
        Circle()
            .stroke(AppleColors.error.opacity(opacity), lineWidth: 2)
            .scaleEffect(scale)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
                        scale = 1.6
                        opacity = 0
                    }
                }
            }
    }
}

// MARK: - Practice Status Bar

struct PracticeStatusBar: View {
    let level: String
    let fluency: Int
    let accuracy: Int
    let onEnd: () -> Void
    
    var body: some View {
        HStack(spacing: Spacing.lg) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "chart.bar.fill")
                    .font(.caption)
                Text(level)
                    .font(Typography.caption2.weight(.medium))
            }
            .foregroundStyle(AppleColors.accent)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(AppleColors.accent.opacity(0.1))
            .clipShape(Capsule())
            
            Divider()
                .frame(height: 20)
            
            HStack(spacing: Spacing.xs) {
                Text("Fluency")
                    .font(Typography.caption2)
                    .foregroundStyle(AppleColors.secondaryText)
                Text("\(fluency)%")
                    .font(Typography.caption2.weight(.medium))
                    .foregroundStyle(AppleColors.primaryText)
            }
            
            Divider()
                .frame(height: 20)
            
            HStack(spacing: Spacing.xs) {
                Text("Accuracy")
                    .font(Typography.caption2)
                    .foregroundStyle(AppleColors.secondaryText)
                Text("\(accuracy)%")
                    .font(Typography.caption2.weight(.medium))
                    .foregroundStyle(AppleColors.primaryText)
            }
            
            Spacer()
            
            Button(action: onEnd) {
                Text("End")
                    .font(Typography.caption2.weight(.medium))
                    .foregroundStyle(AppleColors.error)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.xs)
                    .background(AppleColors.error.opacity(0.1))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, Spacing.md)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Press Events Modifier

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

// MARK: - Preview

#Preview {
    PracticeView()
        .environmentObject(AppState())
        .frame(width: 900, height: 700)
}
