import SwiftUI

/// A draggable letter tile for the spelling game.
struct LetterTile: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let tile: LetterTileModel
    var isHinted: Bool = false
    let onTap: () -> Void

    @State private var isDragging = false
    @State private var hintPulse = false

    var body: some View {
        Text(String(tile.letter).uppercased())
            .font(L2RTheme.Typography.Scaled.playful(relativeTo: .title2, weight: .bold))
            .foregroundStyle(L2RTheme.textPrimary)
            .frame(width: 52, height: 60)
            .background(
                RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.medium)
                    .fill(.white)
                    .shadow(
                        color: isDragging ? L2RTheme.primary.opacity(0.4) : Color.black.opacity(0.15),
                        radius: isDragging ? 8 : 4,
                        y: isDragging ? 6 : 3
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.medium)
                    .stroke(isDragging ? L2RTheme.primary : L2RTheme.border, lineWidth: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.medium)
                    .stroke(L2RTheme.Logo.yellow, lineWidth: 3)
                    .scaleEffect(hintPulse ? 1.08 : 1.0)
                    .opacity(isHinted ? 1.0 : 0)
            )
            .onChange(of: isHinted) { _, hinted in
                if hinted && !reduceMotion {
                    withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                        hintPulse = true
                    }
                } else {
                    withAnimation(.easeOut(duration: 0.2)) {
                        hintPulse = false
                    }
                }
            }
            .scaleEffect(isDragging ? 1.1 : 1.0)
            .opacity(tile.isPlaced ? 0.3 : 1.0)
            .animation(reduceMotion ? nil : L2RTheme.Animation.bounce, value: isDragging)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: tile.isPlaced)
            .juicyTap {
                guard !tile.isPlaced else { return }
                onTap()
            }
            .onDrag {
                isDragging = true
                return NSItemProvider(object: String(tile.letter) as NSString)
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { _ in
                        isDragging = false
                    }
            )
            .disabled(tile.isPlaced)
            .accessibilityLabel("Letter \(String(tile.letter).uppercased())")
            .accessibilityHint(tile.isPlaced ? "Already placed" : "Double tap to place in word")
            .accessibilityAddTraits(.isButton)
    }
}

/// A row of letter tiles for the letter bank.
struct LetterBank: View {
    let tiles: [LetterTileModel]
    var hintedTileId: String? = nil
    let onTileTap: (LetterTileModel) -> Void

    var body: some View {
        HStack(spacing: L2RTheme.Spacing.sm) {
            ForEach(tiles) { tile in
                LetterTile(tile: tile, isHinted: tile.id == hintedTileId) {
                    onTileTap(tile)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Letter Tiles") {
    VStack(spacing: L2RTheme.Spacing.xl) {
        Text("Letter Tiles")
            .font(L2RTheme.Typography.Scaled.system(.title3, weight: .bold))

        HStack(spacing: L2RTheme.Spacing.md) {
            LetterTile(
                tile: LetterTileModel(letter: "C"),
                onTap: {}
            )
            LetterTile(
                tile: LetterTileModel(letter: "A"),
                onTap: {}
            )
            LetterTile(
                tile: LetterTileModel(letter: "T", isPlaced: true),
                onTap: {}
            )
        }

        Divider()

        Text("Letter Bank")
            .font(L2RTheme.Typography.Scaled.system(.title3, weight: .bold))

        LetterBank(
            tiles: [
                LetterTileModel(letter: "C"),
                LetterTileModel(letter: "A"),
                LetterTileModel(letter: "T"),
            ],
            onTileTap: { _ in }
        )
    }
    .padding()
    .background(L2RTheme.background)
}
