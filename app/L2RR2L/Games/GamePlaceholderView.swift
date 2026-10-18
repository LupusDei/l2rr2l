import SwiftUI

/// Stand-in for a game that isn't built yet. Doubles as a playground for the
/// shared systems: tap letters for their pure sounds, tap the speaker to hear
/// the word blended, and try the right / oops / round-complete moments.
struct GamePlaceholderView: View {
    let game: GameID

    @Environment(AppServices.self) private var services
    @Environment(\.metrics) private var m
    @State private var shownAt = Date()
    @State private var appeared = false

    private let word = "mat"

    var body: some View {
        VStack(spacing: m.s(34)) {
            ChunkyTitle(text: game.title, size: m.s(72), colors: [.white, game.colors[0]],
                        extrude: game.colors[1].mix(with: .black, by: 0.5))
                .scaleEffect(appeared ? 1 : 0.4)
                .opacity(appeared ? 1 : 0)

            HStack(spacing: m.s(22)) {
                ForEach(Array(word.enumerated()), id: \.offset) { index, letter in
                    LetterTile(letter: String(letter), color: game.colors[0]) {
                        Task { await services.voice.sayLetterSound(String(letter), stretched: true) }
                    }
                    .offset(y: appeared ? 0 : 300)
                    .animation(.spring(response: 0.55, dampingFraction: 0.6).delay(0.2 + 0.1 * Double(index)), value: appeared)
                }
            }

            Button {
                Task { await services.voice.sayBlend(word.map(String.init), word: word) }
            } label: {
                Image(systemName: "speaker.wave.3.fill")
                    .font(.system(size: m.s(44), weight: .black))
                    .foregroundStyle(.white)
                    .symbolEffect(.variableColor.iterative, options: .repeating)
                    .frame(width: m.s(150), height: m.s(96))
            }
            .buttonStyle(.chunky(game.colors[1], depth: m.s(10), cornerRadius: m.s(48)))

            HStack(spacing: m.s(20)) {
                demoButton("checkmark", Theme.mint) {
                    services.celebrateCorrect(game: game, word: word,
                                              responseTime: Date().timeIntervalSince(shownAt))
                    shownAt = .now
                }
                demoButton("arrow.uturn.backward", Theme.peach) {
                    services.encourageRetry(game: game, word: word)
                }
                demoButton("party.popper.fill", Theme.gold) {
                    services.celebrateRoundComplete(game: game)
                }
            }
            .padding(.top, m.s(10))

            Text("Coming soon · tap things to try the sounds and celebrations")
                .font(.playful(m.s(17), weight: .semibold))
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(m.s(40))
        .onAppear { appeared = true }
        .animation(.spring(response: 0.6, dampingFraction: 0.6), value: appeared)
    }

    private func demoButton(_ symbol: String, _ color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: m.s(34), weight: .black))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.2), radius: 0, y: 2)
                .frame(width: m.s(100), height: m.s(84))
        }
        .buttonStyle(.chunky(color, depth: m.s(8), cornerRadius: m.s(28)))
    }
}

/// Big chunky letter tile, the basic building block of the reading games:
/// a cream face on a colored base that sinks when pressed and glows.
struct LetterTile: View {
    let letter: String
    var color: Color = Theme.pink
    let action: () -> Void
    @Environment(\.metrics) private var m

    var body: some View {
        Button(action: action) {
            Text(letter)
                .font(.reading(m.s(96)))
                .foregroundStyle(Theme.skyTop)
                .frame(width: m.s(140), height: m.s(150))
        }
        .buttonStyle(ChunkyButtonStyle(color: Color(red: 1, green: 0.97, blue: 0.92),
                                       depth: m.s(14), cornerRadius: m.s(34), sound: .pick))
        .background {
            RoundedRectangle(cornerRadius: m.s(34), style: .continuous)
                .fill(color)
                .offset(y: m.s(14))
                .blur(radius: 18)
                .opacity(0.7)
        }
    }
}
