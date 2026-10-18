import SwiftUI

/// The sticker word book: every mastered word becomes a sticker. Also shows
/// treats waiting for Cutisie and the mystery egg. The session-end ritual
/// (feeding treats, hatching the egg) will build on this screen.
struct StickerBookView: View {
    @Environment(AppServices.self) private var services
    @Environment(ProgressStore.self) private var progress
    @Environment(\.metrics) private var m

    var body: some View {
        ZStack {
            SkyBackground(tint: Theme.gold, imageName: "bg-treasure")
            ScrollView {
                VStack(spacing: m.s(24)) {
                    HStack {
                        BubbleIconButton(systemName: "chevron.backward", color: Theme.gold) {
                            services.feedback.play(.whoosh)
                            services.router.back()
                        }
                        Spacer()
                        StarJar()
                    }

                    ChunkyTitle(text: "My Sticker Words", size: m.s(56), colors: [.white, Theme.gold])

                    HStack(spacing: m.s(20)) {
                        rewardPill("🍪", "\(progress.data.treats) treats")
                        rewardPill("🥚", "egg \(progress.data.eggProgress)/\(ProgressStore.treatsPerEgg)")
                        rewardPill("📖", "\(progress.data.stickers.count) words")
                    }

                    if progress.data.stickers.isEmpty {
                        VStack(spacing: m.s(12)) {
                            Text("📖").font(.system(size: m.s(100)))
                            Text("Read words to fill your book!")
                                .font(.playful(m.s(28), weight: .bold))
                                .foregroundStyle(.white.opacity(0.85))
                        }
                        .padding(.top, m.s(40))
                    } else {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: m.s(160)), spacing: m.s(20))], spacing: m.s(20)) {
                            ForEach(progress.data.stickers) { sticker in
                                Button {
                                    services.feedback.play(.pop)
                                    Task { await services.voice.sayWord(sticker.word) }
                                } label: {
                                    VStack(spacing: 6) {
                                        Text(sticker.emoji).font(.system(size: m.s(70)))
                                        Text(sticker.word)
                                            .font(.reading(m.s(36)))
                                            .foregroundStyle(Theme.skyTop)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(m.s(18))
                                    .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(.white))
                                    .glow(Theme.gold, radius: 8)
                                }
                                .buttonStyle(.bouncy)
                            }
                        }
                    }
                }
                .padding(m.s(32))
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .adaptiveMetrics()
    }

    private func rewardPill(_ emoji: String, _ text: String) -> some View {
        HStack(spacing: 8) {
            Text(emoji)
            Text(text)
        }
        .font(.playful(m.s(22), weight: .bold))
        .foregroundStyle(.white)
        .padding(.horizontal, m.s(18)).padding(.vertical, m.s(10))
        .background(Capsule().fill(.white.opacity(0.15)))
    }
}
