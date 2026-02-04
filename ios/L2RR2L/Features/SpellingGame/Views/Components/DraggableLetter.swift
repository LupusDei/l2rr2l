import SwiftUI

// MARK: - Letter Tile State

enum LetterTileState {
    case idle
    case dragging
    case dropped
}

// MARK: - Draggable Letter

/// A draggable letter tile for spelling games.
/// Uses drag gesture with visual feedback and haptic responses.
struct DraggableLetter: View {
    let letter: Character
    let onDragStarted: (() -> Void)?
    let onDragEnded: ((Bool) -> Void)?

    @State private var state: LetterTileState = .idle
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false

    init(
        letter: Character,
        onDragStarted: (() -> Void)? = nil,
        onDragEnded: ((Bool) -> Void)? = nil
    ) {
        self.letter = letter
        self.onDragStarted = onDragStarted
        self.onDragEnded = onDragEnded
    }

    var body: some View {
        letterTile
            .offset(dragOffset)
            .scaleEffect(isDragging ? 1.15 : 1.0)
            .shadow(
                color: isDragging ? L2RTheme.primary.opacity(0.4) : Color.black.opacity(0.15),
                radius: isDragging ? 12 : 4,
                x: 0,
                y: isDragging ? 8 : 3
            )
            .zIndex(isDragging ? 100 : 0)
            .animation(L2RTheme.Animation.bounce, value: isDragging)
            .gesture(dragGesture)
            .onDrag {
                // For system drag-and-drop compatibility with DropZone
                NSItemProvider(object: String(letter) as NSString)
            }
    }

    // MARK: - Letter Tile View

    private var letterTile: some View {
        ZStack {
            // Background with 3D effect
            tileBackground

            // Letter
            Text(String(letter).uppercased())
                .font(L2RTheme.Typography.playful(size: L2RTheme.Typography.Size.title2, weight: .bold))
                .foregroundStyle(L2RTheme.textPrimary)
        }
        .frame(width: 52, height: 60)
    }

    private var tileBackground: some View {
        ZStack {
            // Bottom layer (shadow/depth)
            RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.medium)
                .fill(L2RTheme.primary.opacity(0.3))
                .offset(y: isDragging ? 0 : 4)

            // Top layer (main tile)
            RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.medium)
                .fill(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.medium)
                        .stroke(isDragging ? L2RTheme.primary : L2RTheme.border, lineWidth: isDragging ? 3 : 2)
                )
        }
    }

    // MARK: - Drag Gesture

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 5)
            .onChanged { value in
                if !isDragging {
                    // Drag started
                    isDragging = true
                    triggerHaptic(.light)
                    onDragStarted?()
                }
                dragOffset = value.translation
            }
            .onEnded { value in
                isDragging = false

                // Check if dropped far enough to be considered a drop attempt
                let dropDistance = sqrt(pow(value.translation.width, 2) + pow(value.translation.height, 2))
                let wasDropped = dropDistance > 50

                // Animate back to original position
                withAnimation(L2RTheme.Animation.bounce) {
                    dragOffset = .zero
                }

                triggerHaptic(.medium)
                onDragEnded?(wasDropped)
            }
    }

    // MARK: - Haptic Feedback

    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}

// MARK: - Draggable Letter Bank

/// A horizontal bank of draggable letter tiles.
struct DraggableLetterBank: View {
    let letters: [Character]
    let usedIndices: Set<Int>
    let onLetterDragStarted: ((Int) -> Void)?
    let onLetterDragEnded: ((Int, Bool) -> Void)?

    init(
        letters: [Character],
        usedIndices: Set<Int> = [],
        onLetterDragStarted: ((Int) -> Void)? = nil,
        onLetterDragEnded: ((Int, Bool) -> Void)? = nil
    ) {
        self.letters = letters
        self.usedIndices = usedIndices
        self.onLetterDragStarted = onLetterDragStarted
        self.onLetterDragEnded = onLetterDragEnded
    }

    var body: some View {
        HStack(spacing: L2RTheme.Spacing.sm) {
            ForEach(Array(letters.enumerated()), id: \.offset) { index, letter in
                if !usedIndices.contains(index) {
                    DraggableLetter(
                        letter: letter,
                        onDragStarted: { onLetterDragStarted?(index) },
                        onDragEnded: { wasDropped in onLetterDragEnded?(index, wasDropped) }
                    )
                    .transition(.scale.combined(with: .opacity))
                } else {
                    // Placeholder for used letter
                    letterPlaceholder
                }
            }
        }
        .padding(L2RTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.large)
                .fill(L2RTheme.background)
                .shadow(color: Color.black.opacity(0.1), radius: 4, y: 2)
        )
        .animation(L2RTheme.Animation.bounce, value: usedIndices)
    }

    private var letterPlaceholder: some View {
        RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.medium)
            .fill(L2RTheme.border.opacity(0.5))
            .frame(width: 52, height: 60)
    }
}

// MARK: - Haptic Manager

/// Centralized haptic feedback for spelling games.
enum SpellingHaptics {
    static func letterPickup() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    static func letterDrop() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    static func correctPlacement() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    static func incorrectPlacement() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    static func wordComplete() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // Additional celebratory haptic
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            let impact = UIImpactFeedbackGenerator(style: .heavy)
            impact.impactOccurred()
        }
    }
}

// MARK: - Preview

#Preview("Draggable Letter") {
    VStack(spacing: L2RTheme.Spacing.xxl) {
        Text("Draggable Letter")
            .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.title3, weight: .bold))

        DraggableLetter(letter: "A")

        Text("Try dragging the letter!")
            .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body))
            .foregroundStyle(L2RTheme.textSecondary)
    }
    .padding()
    .background(L2RTheme.background)
}

// Previews removed due to type incompatibility
