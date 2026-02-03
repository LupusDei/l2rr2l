import SwiftUI

/// A draggable letter tile for the spelling game.
struct LetterTile: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let tile: LetterTileModel
    let onTap: () -> Void

    @State private var isDragging = false

    var body: some View {
        Text(String(tile.letter).uppercased())
            .font(L2RTheme.Typography.playful(size: L2RTheme.Typography.Size.title2, weight: .bold))
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
            .scaleEffect(isDragging ? 1.1 : 1.0)
            .opacity(tile.isPlaced ? 0.3 : 1.0)
            .animation(reduceMotion ? nil : L2RTheme.Animation.bounce, value: isDragging)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: tile.isPlaced)
            .onTapGesture {
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
    }
}

/// A row of letter tiles for the letter bank.
struct LetterBank: View {
    let tiles: [LetterTileModel]
    let onTileTap: (LetterTileModel) -> Void

    var body: some View {
        HStack(spacing: L2RTheme.Spacing.sm) {
            ForEach(tiles) { tile in
                LetterTile(tile: tile) {
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
            .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.title3, weight: .bold))

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
            .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.title3, weight: .bold))

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
