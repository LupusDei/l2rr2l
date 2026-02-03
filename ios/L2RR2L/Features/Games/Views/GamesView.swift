import SwiftUI

struct GamesView: View {
    @ObservedObject var router = NavigationRouter.shared

    private let games: [(GameDestination, String, String, LinearGradient, Color)] = [
        (.phonics, "Phonics Fun", "ear.fill", .phonicsGame, L2RTheme.Game.phonicsShadow),
        (.spelling, "Spelling Bee", "textformat.abc", .spellingGame, L2RTheme.Game.spellingShadow),
        (.memory, "Memory Match", "square.grid.2x2.fill", .memoryGame, L2RTheme.Game.memoryShadow),
        (.rhyme, "Rhyme Time", "music.note.list", .rhymeGame, L2RTheme.Game.rhymeShadow),
        (.wordBuilder, "Word Builder", "puzzlepiece.fill", .wordBuilder, L2RTheme.Game.builderShadow),
        (.readAloud, "Read Aloud", "speaker.wave.3.fill", .readAloudGame, L2RTheme.Game.readAloudShadow)
    ]

    let columns = [
        GridItem(.flexible(), spacing: L2RTheme.Spacing.md),
        GridItem(.flexible(), spacing: L2RTheme.Spacing.md)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: L2RTheme.Spacing.lg) {
                headerSection

                LazyVGrid(columns: columns, spacing: L2RTheme.Spacing.md) {
                    ForEach(games, id: \.0) { game in
                        gameCard(
                            destination: game.0,
                            title: game.1,
                            icon: game.2,
                            gradient: game.3,
                            shadowColor: game.4
                        )
                    }
                }
            }
            .padding(L2RTheme.Spacing.lg)
        }
        .background(L2RTheme.background)
        .navigationTitle("Games")
        .navigationBarTitleDisplayMode(.large)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: L2RTheme.Spacing.sm) {
            Text("Let's Play!")
                .font(L2RTheme.Typography.playful(size: L2RTheme.Typography.Size.title2, weight: .bold))
                .foregroundStyle(L2RTheme.textPrimary)

            Text("Choose a game to practice your skills")
                .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body))
                .foregroundStyle(L2RTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func gameCard(
        destination: GameDestination,
        title: String,
        icon: String,
        gradient: LinearGradient,
        shadowColor: Color
    ) -> some View {
        Button {
            router.gamesPath.append(destination)
        } label: {
            VStack(spacing: L2RTheme.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 36))
                    .foregroundStyle(.white)

                Text(title)
                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body, weight: .semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(gradient)
            .clipShape(RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.large))
            .shadow(color: shadowColor.opacity(0.4), radius: 4, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityHint("Double tap to play")
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    NavigationStack {
        GamesView()
    }
}
