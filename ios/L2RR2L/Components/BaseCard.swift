import SwiftUI

/// A reusable card container with consistent styling and press animation.
struct BaseCard<Content: View>: View {
    let content: Content
    var backgroundColor: Color = .white
    var gradient: LinearGradient?
    var cornerRadius: CGFloat = L2RTheme.CornerRadius.large
    var shadowColor: Color = .black.opacity(0.1)
    var shadowRadius: CGFloat = 4
    var shadowY: CGFloat = 2
    var borderColor: Color?
    var borderWidth: CGFloat = 1
    var padding: CGFloat = L2RTheme.Spacing.md
    var action: (() -> Void)?

    @State private var isPressed = false

    init(
        backgroundColor: Color = .white,
        gradient: LinearGradient? = nil,
        cornerRadius: CGFloat = L2RTheme.CornerRadius.large,
        shadowColor: Color = .black.opacity(0.1),
        shadowRadius: CGFloat = 4,
        shadowY: CGFloat = 2,
        borderColor: Color? = nil,
        borderWidth: CGFloat = 1,
        padding: CGFloat = L2RTheme.Spacing.md,
        action: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.backgroundColor = backgroundColor
        self.gradient = gradient
        self.cornerRadius = cornerRadius
        self.shadowColor = shadowColor
        self.shadowRadius = shadowRadius
        self.shadowY = shadowY
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.padding = padding
        self.action = action
    }

    var body: some View {
        Group {
            if let action = action {
                Button(action: action) {
                    cardContent
                }
                .buttonStyle(CardButtonStyle())
            } else {
                cardContent
            }
        }
    }

    private var cardContent: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(cardBorder)
            .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowY)
    }

    @ViewBuilder
    private var cardBackground: some View {
        if let gradient = gradient {
            gradient
        } else {
            backgroundColor
        }
    }

    @ViewBuilder
    private var cardBorder: some View {
        if let borderColor = borderColor {
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(borderColor, lineWidth: borderWidth)
        }
    }
}

/// Button style with press animation for cards.
struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(L2RTheme.Animation.bounce, value: configuration.isPressed)
    }
}

#Preview("Base Card - Default") {
    VStack(spacing: 20) {
        BaseCard {
            Text("Simple Card")
                .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body))
        }

        BaseCard(
            gradient: .spellingGame,
            shadowColor: L2RTheme.Game.spellingShadow.opacity(0.4)
        ) {
            Text("Gradient Card")
                .foregroundStyle(.white)
                .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body, weight: .semibold))
        }

        BaseCard(
            borderColor: L2RTheme.primary,
            action: { print("Tapped!") }
        ) {
            Text("Tappable Card with Border")
                .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body))
        }
    }
    .padding()
    .background(L2RTheme.background)
}
