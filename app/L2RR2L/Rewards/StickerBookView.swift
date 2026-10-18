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
                    CollectionShelf(items: progress.data.collectibles + progress.data.hatched)
                    Button { services.router.open(.treasure(fromSession: false)) } label: {
                        Text("🍓 🥚")
                            .font(.system(size: m.s(44)))
                            .frame(width: m.s(180), height: m.s(90))
                    }
                    .buttonStyle(.chunky(Theme.pink, depth: m.s(8), cornerRadius: m.s(36)))

                    if progress.data.stickers.isEmpty {
                        VStack(spacing: m.s(12)) {
                            Text("📖").font(.system(size: m.s(100)))
                            Text("Read words to fill your book!")
                                .font(.playful(m.s(28), weight: .bold))
                                .foregroundStyle(.white.opacity(0.85))
                        }
                        .padding(.top, m.s(40))
                    } else {
                        ForEach(stickerGroups, id: \.stage) { group in
                            VStack(alignment: .leading, spacing: m.s(12)) {
                                Text(group.name)
                                    .font(.playful(m.s(26)))
                                    .foregroundStyle(.white)
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: m.s(150)), spacing: m.s(18))], spacing: m.s(18)) {
                                    ForEach(group.stickers) { sticker in
                                        Button {
                                            Task { await services.voice.sayWord(sticker.word) }
                                        } label: {
                                            VStack(spacing: 6) {
                                                WordPicture(word: sticker.word, emoji: sticker.emoji, size: m.s(90))
                                                Text(sticker.word)
                                                    .font(.reading(m.s(34)))
                                                    .foregroundStyle(Theme.skyTop)
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(m.s(14))
                                        }
                                        .buttonStyle(.chunky(.white, depth: m.s(8), cornerRadius: m.s(28)))
                                    }
                                }
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

    /// Stickers grouped by the world the word belongs to.
    private var stickerGroups: [(stage: Int, name: String, stickers: [Sticker])] {
        var byStage: [Int: [Sticker]] = [:]
        for sticker in progress.data.stickers {
            let stage = WordBank.pictures[sticker.word]?.stage
                ?? Curriculum.shared.stages.first { $0.heartWords.map { $0.lowercased() }.contains(sticker.word) }?.id ?? 1
            byStage[stage, default: []].append(sticker)
        }
        return byStage.keys.sorted().map { ($0, Curriculum.shared.stage($0)?.name ?? "Words", byStage[$0]!) }
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
