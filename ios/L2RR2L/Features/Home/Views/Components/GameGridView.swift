import SwiftUI

/// Quick-access grid of available games.
struct GameGridView: View {
    let onGameSelected: (GameType) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: L2RTheme.Spacing.md),
        GridItem(.flexible(), spacing: L2RTheme.Spacing.md),
        GridItem(.flexible(), spacing: L2RTheme.Spacing.md)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: L2RTheme.Spacing.md) {
            ForEach(GameType.allCases) { game in
                GameTile(game: game) {
                    onGameSelected(game)
                }
            }
        }
    }
}

/// Individual game tile button
struct GameTile: View {
    let game: GameType
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: L2RTheme.Spacing.xs) {
                // Icon
                Image(systemName: game.icon)
                    .font(.system(size: 28))
                    .foregroundStyle(.white)
                    .wiggling()

                // Title
                Text(game.title)
                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.small, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 90)
            .background(game.gradient)
            .clipShape(RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.large))
            .shadow(
                color: game.shadowColor.opacity(0.4),
                radius: isPressed ? 2 : 4,
                x: 0,
                y: isPressed ? 2 : 4
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isPressed = false
                    }
                }
        )
    }
}

/// Available game types
enum GameType: String, CaseIterable, Identifiable {
    case spelling
    case memory
    case rhyme
    case wordBuilder
    case phonics
    case readAloud

    var id: String { rawValue }

    var title: String {
        switch self {
        case .spelling: return "Spelling"
        case .memory: return "Memory"
        case .rhyme: return "Rhyme"
        case .wordBuilder: return "Builder"
        case .phonics: return "Phonics"
        case .readAloud: return "Read"
        }
    }

    var icon: String {
        switch self {
        case .spelling: return "textformat.abc"
        case .memory: return "brain.head.profile"
        case .rhyme: return "music.note"
        case .wordBuilder: return "puzzlepiece.fill"
        case .phonics: return "waveform"
        case .readAloud: return "book.fill"
        }
    }

    var gradient: LinearGradient {
        switch self {
        case .spelling: return .spellingGame
        case .memory: return .memoryGame
        case .rhyme: return .rhymeGame
        case .wordBuilder: return .wordBuilder
        case .phonics: return .phonicsGame
        case .readAloud: return .readAloudGame
        }
    }

    var shadowColor: Color {
        switch self {
        case .spelling: return L2RTheme.Game.spellingShadow
        case .memory: return L2RTheme.Game.memoryShadow
        case .rhyme: return L2RTheme.Game.rhymeShadow
        case .wordBuilder: return L2RTheme.Game.builderShadow
        case .phonics: return L2RTheme.Game.phonicsShadow
        case .readAloud: return L2RTheme.Game.readAloudShadow
        }
    }
}

#Preview {
    ZStack {
        LinearGradient.homeBackground
            .ignoresSafeArea()

        GameGridView { game in
            print("Selected: \(game.title)")
        }
        .padding()
    }
}
