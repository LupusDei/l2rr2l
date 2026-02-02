import SwiftUI

// MARK: - Tile State

enum TileState: Equatable {
    case available
    case dragging
    case placed
    case correct
    case incorrect
}

// MARK: - Letter Tile

struct LetterTile: View {
    let letter: Character
    let state: TileState
    var color: Color = L2RTheme.primary
    var onTap: (() -> Void)?
    var onDragChanged: ((CGPoint) -> Void)?
    var onDragEnded: (() -> Void)?

    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false
    @State private var shakeOffset: CGFloat = 0

    private let tileSize: CGFloat = 56
    private let cornerRadius: CGFloat = L2RTheme.CornerRadius.medium

    var body: some View {
        Text(String(letter).uppercased())
            .font(L2RTheme.Typography.playful(size: 28, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: tileSize, height: tileSize)
            .background(tileBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(
                color: shadowColor.opacity(shadowOpacity),
                radius: shadowRadius,
                x: 0,
                y: shadowY
            )
            .scaleEffect(scaleEffect)
            .offset(x: dragOffset.width + shakeOffset, y: dragOffset.height)
            .zIndex(isDragging ? 100 : 0)
            .gesture(dragGesture)
            .onTapGesture {
                triggerHaptic(.light)
                onTap?()
            }
            .onChange(of: state) { oldState, newState in
                if newState == .incorrect {
                    playShakeAnimation()
                }
                if newState == .correct {
                    triggerHaptic(.success)
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: state)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)
    }

    // MARK: - Background

    private var tileBackground: some View {
        Group {
            switch state {
            case .available, .dragging:
                LinearGradient(
                    colors: [color.opacity(0.9), color],
                    startPoint: .top,
                    endPoint: .bottom
                )
            case .placed:
                LinearGradient(
                    colors: [color.opacity(0.7), color.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            case .correct:
                LinearGradient(
                    colors: [L2RTheme.Status.success.opacity(0.9), L2RTheme.Status.success],
                    startPoint: .top,
                    endPoint: .bottom
                )
            case .incorrect:
                LinearGradient(
                    colors: [L2RTheme.Status.error.opacity(0.9), L2RTheme.Status.error],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }

    // MARK: - Shadow Properties

    private var shadowColor: Color {
        switch state {
        case .available, .dragging, .placed:
            return color
        case .correct:
            return L2RTheme.Status.success
        case .incorrect:
            return L2RTheme.Status.error
        }
    }

    private var shadowOpacity: Double {
        switch state {
        case .available:
            return 0.4
        case .dragging:
            return 0.5
        case .placed:
            return 0.3
        case .correct, .incorrect:
            return 0.5
        }
    }

    private var shadowRadius: CGFloat {
        switch state {
        case .available:
            return 4
        case .dragging:
            return 8
        case .placed:
            return 2
        case .correct, .incorrect:
            return 4
        }
    }

    private var shadowY: CGFloat {
        switch state {
        case .available:
            return 4
        case .dragging:
            return 8
        case .placed:
            return 2
        case .correct, .incorrect:
            return 4
        }
    }

    // MARK: - Scale Effect

    private var scaleEffect: CGFloat {
        switch state {
        case .available:
            return 1.0
        case .dragging:
            return 1.1
        case .placed:
            return 0.95
        case .correct:
            return 1.05
        case .incorrect:
            return 1.0
        }
    }

    // MARK: - Gestures

    private var dragGesture: some Gesture {
        DragGesture(coordinateSpace: .global)
            .onChanged { value in
                if !isDragging {
                    isDragging = true
                    triggerHaptic(.medium)
                }
                dragOffset = value.translation
                onDragChanged?(value.location)
            }
            .onEnded { _ in
                isDragging = false
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    dragOffset = .zero
                }
                onDragEnded?()
            }
    }

    // MARK: - Animations

    private func playShakeAnimation() {
        triggerHaptic(.error)
        withAnimation(.linear(duration: 0.08)) {
            shakeOffset = 8
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(.linear(duration: 0.08)) {
                shakeOffset = -8
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            withAnimation(.linear(duration: 0.08)) {
                shakeOffset = 6
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
            withAnimation(.linear(duration: 0.08)) {
                shakeOffset = -6
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                shakeOffset = 0
            }
        }
    }

    // MARK: - Haptics

    private func triggerHaptic(_ type: HapticType) {
        switch type {
        case .light:
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        case .medium:
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        case .success:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        case .error:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
    }

    private enum HapticType {
        case light
        case medium
        case success
        case error
    }
}

// MARK: - Letter Bank

struct LetterBank: View {
    let letters: [Character]
    let selectedLetters: Set<Int>
    var onLetterTapped: ((Int) -> Void)?
    var onLetterDragged: ((Int, CGPoint) -> Void)?
    var onLetterDropped: ((Int) -> Void)?

    private let columns = [
        GridItem(.adaptive(minimum: 56, maximum: 70), spacing: L2RTheme.Spacing.sm)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: L2RTheme.Spacing.sm) {
            ForEach(Array(letters.enumerated()), id: \.offset) { index, letter in
                LetterTile(
                    letter: letter,
                    state: selectedLetters.contains(index) ? .placed : .available,
                    color: tileColor(for: index),
                    onTap: {
                        onLetterTapped?(index)
                    },
                    onDragChanged: { point in
                        onLetterDragged?(index, point)
                    },
                    onDragEnded: {
                        onLetterDropped?(index)
                    }
                )
                .opacity(selectedLetters.contains(index) ? 0.3 : 1.0)
            }
        }
        .padding(L2RTheme.Spacing.md)
        .background(Color.white.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.large))
    }

    private func tileColor(for index: Int) -> Color {
        L2RTheme.Logo.all[index % L2RTheme.Logo.all.count]
    }
}

// MARK: - Preview

#Preview("Letter Tile States") {
    VStack(spacing: L2RTheme.Spacing.xl) {
        HStack(spacing: L2RTheme.Spacing.md) {
            LetterTile(letter: "A", state: .available)
            LetterTile(letter: "B", state: .dragging)
            LetterTile(letter: "C", state: .placed)
        }

        HStack(spacing: L2RTheme.Spacing.md) {
            LetterTile(letter: "D", state: .correct)
            LetterTile(letter: "E", state: .incorrect)
        }

        LetterBank(
            letters: Array("HELLO"),
            selectedLetters: [1, 3]
        )
    }
    .padding()
    .background(L2RTheme.background)
}
