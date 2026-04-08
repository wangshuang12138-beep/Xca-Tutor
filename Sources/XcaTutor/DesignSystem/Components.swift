import SwiftUI

// MARK: - Button Styles

struct AppleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Primary Button

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

// MARK: - Secondary Button

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

// MARK: - Glass Card

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

// MARK: - Hover Scale Modifier

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

extension View {
    func hoverScale() -> some View {
        modifier(HoverScaleModifier())
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(Typography.title3)
                .foregroundStyle(AppleColors.primaryText)
            Spacer()
        }
    }
}

// MARK: - Gradient Background

struct GradientBackground: View {
    let colors: [Color]
    
    var body: some View {
        LinearGradient(
            colors: colors.map { $0.opacity(0.15) },
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

// MARK: - Mesh Gradient Background (for Practice View)

struct MeshGradientBackground: View {
    @State private var phase: CGFloat = 0
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 1/30, paused: false)) { _ in
            Canvas { context, size in
                let gradient = Gradient(colors: [
                    Color(hex: "5856D6").opacity(0.3),
                    Color(hex: "007AFF").opacity(0.2),
                    Color(hex: "AF52DE").opacity(0.3),
                    Color(hex: "34C759").opacity(0.1)
                ])
                
                context.fill(
                    Path(CGRect(origin: .zero, size: size)),
                    with: .linearGradient(
                        gradient,
                        startPoint: CGPoint(
                            x: size.width * (0.3 + 0.2 * sin(phase)),
                            y: size.height * (0.3 + 0.2 * cos(phase))
                        ),
                        endPoint: CGPoint(
                            x: size.width * (0.7 + 0.2 * sin(phase + .pi)),
                            y: size.height * (0.7 + 0.2 * cos(phase + .pi))
                        )
                    )
                )
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 10).repeatForever(autoreverses: true)) {
                phase = .pi * 2
            }
        }
        .background(AppleColors.background)
    }
}
