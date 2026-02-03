import SwiftUI

/// Configuration for a game card.
struct GameInfo: Identifiable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let gradient: LinearGradient
    let shadowColor: Color

    static let phonics = GameInfo(
        id: "phonics",
        name: "Phonics Fun",
        description: "Learn letter sounds",
        icon: "ear.fill",
        gradient: .phonicsGame,
        shadowColor: L2RTheme.Game.phonicsShadow
    )

    static let spelling = GameInfo(
        id: "spelling",
        name: "Spelling Bee",
        description: "Practice spelling words",
        icon: "textformat.abc",
        gradient: .spellingGame,
        shadowColor: L2RTheme.Game.spellingShadow
    )

    static let memory = GameInfo(
        id: "memory",
        name: "Memory Match",
        description: "Match word pairs",
        icon: "square.grid.2x2.fill",
        gradient: .memoryGame,
        shadowColor: L2RTheme.Game.memoryShadow
    )

    static let rhyme = GameInfo(
        id: "rhyme",
        name: "Rhyme Time",
        description: "Find rhyming words",
        icon: "music.note.list",
        gradient: .rhymeGame,
        shadowColor: L2RTheme.Game.rhymeShadow
    )

    static let wordBuilder = GameInfo(
        id: "wordBuilder",
        name: "Word Builder",
        description: "Build words from letters",
        icon: "puzzlepiece.fill",
        gradient: .wordBuilder,
        shadowColor: L2RTheme.Game.builderShadow
    )

    static let readAloud = GameInfo(
        id: "readAloud",
        name: "Read Aloud",
        description: "Practice reading out loud",
        icon: "speaker.wave.3.fill",
        gradient: .readAloudGame,
        shadowColor: L2RTheme.Game.readAloudShadow
    )

    static let all: [GameInfo] = [phonics, spelling, memory, rhyme, wordBuilder, readAloud]
}

/// A playful card component for displaying game selection.
struct GameCard: View {
    let game: GameInfo
    var showPlayButton: Bool = true
    var onTap: (() -> Void)?

    @State private var isWiggling = false

    var body: some View {
        BaseCard(
            gradient: game.gradient,
            shadowColor: game.shadowColor.opacity(0.4),
            shadowRadius: 4,
            shadowY: 4,
            padding: L2RTheme.Spacing.lg,
            action: onTap
        ) {
            VStack(spacing: L2RTheme.Spacing.sm) {
                gameIcon
                gameName
                gameDescription

                if showPlayButton {
                    playButton
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(game.name). \(game.description)")
        .accessibilityHint("Double tap to play")
        .accessibilityAddTraits(.isButton)
    }

    private var gameIcon: some View {
        Image(systemName: game.icon)
            .font(.system(size: 40))
            .foregroundStyle(.white)
            .rotationEffect(.degrees(isWiggling ? 5 : -5))
            .animation(L2RTheme.Animation.wiggle, value: isWiggling)
            .onAppear {
                isWiggling = true
            }
    }

    private var gameName: some View {
        Text(game.name)
            .font(L2RTheme.Typography.playful(size: L2RTheme.Typography.Size.large, weight: .bold))
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
    }

    private var gameDescription: some View {
        Text(game.description)
            .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.small))
            .foregroundStyle(.white.opacity(0.9))
            .multilineTextAlignment(.center)
    }

    private var playButton: some View {
        HStack(spacing: L2RTheme.Spacing.xxs) {
            Image(systemName: "play.fill")
                .font(.system(size: 12))
            Text("Play")
                .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.small, weight: .semibold))
        }
        .foregroundStyle(game.shadowColor)
        .padding(.horizontal, L2RTheme.Spacing.md)
        .padding(.vertical, L2RTheme.Spacing.xs)
        .background(.white)
        .clipShape(Capsule())
    }
}

/// A compact version of GameCard for grid layouts.
struct CompactGameCard: View {
    let game: GameInfo
    var onTap: (() -> Void)?

    var body: some View {
        BaseCard(
            gradient: game.gradient,
            shadowColor: game.shadowColor.opacity(0.4),
            shadowRadius: 4,
            shadowY: 4,
            padding: L2RTheme.Spacing.md,
            action: onTap
        ) {
            VStack(spacing: L2RTheme.Spacing.sm) {
                Image(systemName: game.icon)
                    .font(.system(size: 36))
                    .foregroundStyle(.white)

                Text(game.name)
                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body, weight: .semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
            }
            .frame(height: 100)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(game.name)
        .accessibilityHint("Double tap to play")
        .accessibilityAddTraits(.isButton)
    }
}

#Preview("Game Cards") {
    ScrollView {
        VStack(spacing: L2RTheme.Spacing.lg) {
            Text("Full Game Cards")
                .font(L2RTheme.Typography.playful(size: L2RTheme.Typography.Size.title2, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(GameInfo.all.prefix(3)) { game in
                GameCard(game: game) {
                    print("Play \(game.name)")
                }
            }

            Text("Compact Grid Cards")
                .font(L2RTheme.Typography.playful(size: L2RTheme.Typography.Size.title2, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: L2RTheme.Spacing.md),
                    GridItem(.flexible(), spacing: L2RTheme.Spacing.md)
                ],
                spacing: L2RTheme.Spacing.md
            ) {
                ForEach(GameInfo.all) { game in
                    CompactGameCard(game: game) {
                        print("Play \(game.name)")
                    }
                }
            }
        }
        .padding()
    }
    .background(L2RTheme.background)
}
