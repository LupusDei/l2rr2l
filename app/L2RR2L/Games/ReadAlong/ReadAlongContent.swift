import Foundation

/// One word of a Read Along sentence as it sits on the page.
struct ReadToken: Identifiable, Hashable {
    let id: Int
    /// The word's letters as written in the sentence ("Sam", "The").
    let shown: String
    /// Punctuation that follows it ("." "!" ",").
    let trailing: String
    let word: Word
    /// Heart words are read whole, never sounded out.
    let isHeart: Bool

    /// The shown letters cut into the word's tiles, keeping capitals:
    /// "Ship" -> ["Sh", "i", "p"].
    var pieces: [String] {
        var out: [String] = []
        var rest = Substring(shown)
        for g in word.graphemes {
            out.append(String(rest.prefix(g.count)))
            rest = rest.dropFirst(g.count)
        }
        if !rest.isEmpty { out.append(String(rest)) }
        return out
    }
}

/// A sentence (or string of words) to read along with Cutisie.
struct ReadSentence: Identifiable, Hashable {
    let stage: Int
    let text: String
    let tokens: [ReadToken]
    var id: String { text }

    /// The thing that comes alive when she's read it: the last word with a picture.
    var star: Word? {
        tokens.last { !$0.isHeart && $0.word.picture != nil }?.word
    }
}

/// Read Along content from `Media/content/readalong.json`. Words resolve to
/// their curriculum tiles and sounds; words the curriculum doesn't have get
/// them from the file's `words` table.
enum ReadAlongContent {
    private struct File: Decodable {
        struct Line: Decodable { let stage: Int; let text: String }
        struct Tiles: Decodable { let graphemes: [String]; let sounds: [String]? }
        let sentences: [Line]
        let words: [String: Tiles]
    }

    static let all: [ReadSentence] = {
        guard let url = Bundle.main.url(forResource: "readalong", withExtension: "json", subdirectory: "Media/content"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(File.self, from: data) else {
            assertionFailure("readalong.json missing or invalid")
            return []
        }
        let known = curriculumWords
        return file.sentences.map { line in
            let hearts = heartWords(upTo: line.stage)
            var tokens: [ReadToken] = []
            for (i, raw) in line.text.split(separator: " ").enumerated() {
                let shown = String(raw.prefix { $0.isLetter || $0 == "'" })
                let key = shown.lowercased()
                let word: Word
                if let tiles = file.words[key] {
                    word = Word(key, known[key]?.picture, graphemes: tiles.graphemes, sounds: tiles.sounds)
                } else {
                    word = known[key] ?? Word(key, nil)
                }
                tokens.append(ReadToken(id: i, shown: shown, trailing: String(raw.dropFirst(shown.count)),
                                        word: word, isHeart: hearts.contains(key)))
            }
            return ReadSentence(stage: line.stage, text: line.text, tokens: tokens)
        }
    }()

    /// Sentences for a round at `stage`: mostly this stage, topped up with
    /// earlier ones, never anything from a later stage.
    static func round(stage: Int, count: Int, skipping recent: Set<String> = []) -> [ReadSentence] {
        let s = max(stage, 1)
        let usable = all.filter { $0.stage <= s && !recent.contains($0.id) }
        let current = usable.filter { $0.stage == s }.shuffled()
        let earlier = usable.filter { $0.stage < s }.shuffled()
        var picked = Array(current.prefix(max(count - 1, 1)))
        for sentence in earlier + current where picked.count < count && !picked.contains(sentence) {
            picked.append(sentence)
        }
        if picked.count < count, !recent.isEmpty { return round(stage: stage, count: count) }
        return picked.shuffled()
    }

    /// A word that differs from `word` by one tile, for Cutisie to misread
    /// ("cat" -> "cot"). Only recorded words, so the Star Voice can say it.
    static func nearMiss(for word: Word) -> Word? {
        guard word.graphemes.count >= 3 else { return nil }
        let options = curriculumWords.values.filter { other in
            other.text != word.text && other.graphemes.count == word.graphemes.count
                && zip(other.graphemes, word.graphemes).filter { $0 != $1 }.count == 1
                && Speaker.url(other.text, in: "Media/words") != nil
        }
        return options.randomElement()
    }

    static func heartWords(upTo stage: Int) -> Set<String> {
        Set(Curriculum.shared.stages.filter { $0.id <= stage }.flatMap(\.heartWords).map { $0.lowercased() })
    }

    /// Every curriculum word by its text.
    static let curriculumWords: [String: Word] = {
        var out: [String: Word] = [:]
        let c = Curriculum.shared
        for w in c.stages.flatMap({ $0.words + $0.chains.flatMap { $0 } }) + (c.pictureWords ?? []) where out[w.text] == nil {
            out[w.text] = w
        }
        return out
    }()
}
