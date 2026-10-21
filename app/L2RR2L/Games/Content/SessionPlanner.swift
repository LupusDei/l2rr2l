import Foundation

/// Picks what each game practises today from her current stage and saved
/// progress (learning path sections 5 and 6): about 70% review of words due
/// on the spaced schedule, 30% new or still-learning words from the current
/// stage, never anything that uses sounds she hasn't been taught.
@MainActor
struct SessionPlanner {
    let progress: ProgressStore

    var stage: Int { max(progress.data.stage, 1) }

    private var records: [String: WordRecord] { progress.data.words }

    /// Items for Stretchy Blend (and the word part of Star Catch).
    func pictureItems(_ count: Int, preferSeen: Bool = false) -> [BlendItem] {
        let current = WordBank.items(in: stage)
        let earlier = stage > 1 ? WordBank.items(upTo: stage - 1) : []
        let due = Set(progress.wordsDueForReview(limit: 60))
        var picked: [BlendItem] = []
        func add(_ items: [BlendItem]) {
            for item in items where picked.count < count && !picked.contains(item) { picked.append(item) }
        }

        let reviewTarget = Int((Double(count) * 0.7).rounded())
        add((current + earlier).filter { due.contains($0.word.text) }.shuffled().prefix(reviewTarget).map { $0 })

        // new or learning words from this stage, in curriculum order (easiest first)
        let learning = current.filter { !(records[$0.word.text]?.isMastered ?? false) }
        if preferSeen {
            add(learning.filter { records[$0.word.text] != nil }.shuffled())
        }
        add(Array(learning.prefix(count * 2)).shuffled())
        add(earlier.shuffled())
        add(current.shuffled())
        return picked.shuffled()
    }

    /// The Word Machine chain: one of this stage's chains, rotating.
    func chain() -> WordChain? {
        let chains = WordBank.chains(for: stage)
        guard !chains.isEmpty else { return nil }
        let index = (progress.data.games[GameID.wordMachine.rawValue]?.sessions ?? 0) % chains.count
        return chains[index]
    }

    /// Heart words taught so far, newest stage first.
    var heartWords: [String] {
        Curriculum.shared.stages.filter { $0.id <= stage }.reversed().flatMap(\.heartWords)
    }

    /// Star Catch: words to read alone, a heart word or two, and (from Stage
    /// 1's phrases on) a sentence to finish.
    func catchItems(_ count: Int) -> [CatchItem] {
        var items: [CatchItem] = pictureItems(count - 1, preferSeen: true).map { .word($0) }
        let hearts = heartWords.filter { !(records[$0.lowercased()]?.isMastered ?? false) }
        if let heart = hearts.first, heartWords.count >= 3 {
            let others = heartWords.filter { $0 != heart }.shuffled().prefix(2)
            items.insert(.heart(heart, choices: ([heart] + others).shuffled()), at: min(2, items.count))
        } else if let extra = pictureItems(1).first {
            items.append(.word(extra))
        }
        if let sentence = Curriculum.shared.stages.filter({ $0.id <= stage }).last(where: { !$0.sentences.isEmpty })?.sentences.randomElement() {
            items.append(.sentence(sentence))
        }
        return items
    }
}

/// One thing to catch in Star Catch.
enum CatchItem: Hashable {
    case word(BlendItem)
    /// The Star Voice says a heart word; she taps it among three.
    case heart(String, choices: [String])
    /// She reads a sentence and taps the matching scene.
    case sentence(Sentence)

    var text: String {
        switch self {
        case .word(let item): item.word.text
        case .heart(let word, _): word
        case .sentence(let s): s.text
        }
    }
}
