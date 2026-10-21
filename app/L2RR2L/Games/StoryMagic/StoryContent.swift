import Foundation

/// What a sentence makes happen on the story stage: who (`a`), where it is
/// (`on`, `in`, `has`, `and` with `b`), and what it does or looks like.
struct StoryScene: Codable, Hashable {
    var a: String
    var rel: String?
    var b: String?
    var act: String?
    var look: String?

    /// The words that are things on the stage.
    var things: [String] { [a] + (b.map { [$0] } ?? []) }

    /// The same scene with one word swapped for another ("bed" for "bud").
    func replacing(_ old: String, with new: String) -> StoryScene {
        var s = self
        if s.a == old { s.a = new }
        if s.b == old { s.b = new }
        if s.act == old { s.act = new }
        if s.look == old { s.look = new }
        return s
    }

    /// The two things swapped round ("The mat is on the cat.").
    var swapped: StoryScene? {
        guard let b else { return nil }
        var s = self
        s.a = b
        s.b = a
        return s
    }
}

/// One sentence of a story with the scene it makes.
struct StoryLine: Codable, Hashable {
    let text: String
    let scene: StoryScene
    /// Only for the meaning check: true when the sentence is silly.
    var silly: Bool?
}

/// A tiny story: three pages and a "silly or not?" check.
struct Story: Codable, Identifiable, Hashable {
    let id: String
    let stage: Int
    let pages: [StoryLine]
    let check: StoryLine
}

/// Story Magic content from `Media/content/stories.json` (design/story-magic.md).
enum StoryContent {
    private struct File: Decodable {
        struct Tiles: Decodable { let graphemes: [String]; let sounds: [String]? }
        let stories: [Story]
        let words: [String: Tiles]
    }

    private static let file: File? = {
        guard let url = Bundle.main.url(forResource: "stories", withExtension: "json", subdirectory: "Media/content"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(File.self, from: data) else {
            assertionFailure("stories.json missing or invalid")
            return nil
        }
        return file
    }()

    static var all: [Story] { file?.stories ?? [] }

    /// A word with its tiles: the curriculum's, else the stories file's own table.
    static func word(_ text: String) -> Word {
        let key = text.lowercased()
        let known = ReadAlongContent.curriculumWords[key]
        if let tiles = file?.words[key] {
            return Word(key, known?.picture, graphemes: tiles.graphemes, sounds: tiles.sounds)
        }
        return known ?? Word(key, nil)
    }

    /// A sentence cut into word tokens (heart words marked for its stage).
    static func tokens(_ text: String, stage: Int) -> [ReadToken] {
        let hearts = ReadAlongContent.heartWords(upTo: stage)
        return text.split(separator: " ").enumerated().map { i, raw in
            let shown = String(raw.prefix { $0.isLetter || $0 == "'" })
            return ReadToken(id: i, shown: shown, trailing: String(raw.dropFirst(shown.count)),
                             word: word(shown), isHeart: hearts.contains(shown.lowercased()))
        }
    }

    /// Today's story: one she hasn't finished yet from her stage (newest stage
    /// first), else any at or below her stage, never one just played.
    static func pick(stage: Int, read: [String], skipping recent: Set<String> = []) -> Story? {
        let s = max(stage, 1)
        let usable = all.filter { $0.stage <= s && !recent.contains($0.id) }
        let fresh = usable.filter { !read.contains($0.id) }
        if let story = fresh.filter({ $0.stage == s }).randomElement() ?? fresh.max(by: { $0.stage < $1.stage }) {
            return story
        }
        // all read: the ones read longest ago come round again
        let byAge = usable.sorted { (read.lastIndex(of: $0.id) ?? -1) < (read.lastIndex(of: $1.id) ?? -1) }
        return byAge.first ?? all.filter { $0.stage <= s }.randomElement()
    }

    // MARK: Decodability

    /// Every tile and sound taught by `stage` (double endings come with Stage 2's set).
    static func taught(upTo stage: Int) -> Set<String> {
        var out: Set<String> = ["ck", "ff", "ll", "ss"]
        for st in Curriculum.shared.stages where st.id <= stage { out.formUnion(st.graphemes) }
        return out
    }

    static func isDecodable(_ word: Word, stage: Int, taught: Set<String>? = nil) -> Bool {
        let set = taught ?? self.taught(upTo: stage)
        return zip(word.graphemes, word.soundKeys).allSatisfy { g, sound in
            sound.isEmpty || set.contains(g) || set.contains(sound)
                || (sound == "ow_cow" && set.contains("ow")) || (g == "s" && sound == "z")
        }
    }

    // MARK: Pick It

    /// Recorded words she can decode that differ from `word` by one tile:
    /// pictured ones first, since a wrong pick then makes a funny scene.
    static func neighbours(of word: Word, stage: Int) -> [Word] {
        let set = taught(upTo: stage)
        let hearts = ReadAlongContent.heartWords(upTo: 7)
        var pool = Array(ReadAlongContent.curriculumWords.values)
        for key in Array(file?.words.keys ?? [String: File.Tiles]().keys) where ReadAlongContent.curriculumWords[key] == nil {
            pool.append(self.word(key))
        }
        let options = pool.filter { other in
            other.text != word.text && other.graphemes.count == word.graphemes.count
                && zip(other.graphemes, word.graphemes).filter { $0 != $1 }.count == 1
                && !hearts.contains(other.text)
                && isDecodable(other, stage: stage, taught: set)
                && Speaker.url(other.text, in: "Media/words") != nil
        }
        let pictured = options.filter { WordPicture.card($0.text) != nil || StoryStage.knownActs.contains($0.text) }.shuffled()
        let plain = options.filter { !pictured.contains($0) }.shuffled()
        return pictured + plain
    }

    /// The word to leave out on a Pick It page and the three words to choose
    /// from: the place word first (bed), then the doing word (nap), then who.
    static func gap(for line: StoryLine, stage: Int) -> (index: Int, choices: [Word])? {
        let tokens = tokens(line.text, stage: stage)
        let s = line.scene
        let order = [s.b, s.act, s.look, s.a].compactMap { $0 }
        for target in order {
            guard let token = tokens.first(where: { $0.shown.lowercased() == target && !$0.isHeart }) else { continue }
            // never a word that's already in the sentence ("The cat is on the cat")
            let inSentence = Set(tokens.map { $0.word.text })
            let near = neighbours(of: token.word, stage: stage).filter { !inSentence.contains($0.text) }
            guard near.count >= 2 else { continue }
            return (token.id, ([token.word] + near.prefix(2)).shuffled())
        }
        return nil
    }
}
