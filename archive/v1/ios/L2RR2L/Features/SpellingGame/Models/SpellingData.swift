import Foundation

/// Static data for spelling game words
/// Ported from src/game/words.ts
enum SpellingData {

    /// 3-letter CVC words for spelling game
    /// Sorted roughly by difficulty - start with common, phonetically simple words
    static let words: [SpellingWord] = [
        SpellingWord(word: "cat", hint: "\u{1F431}"),
        SpellingWord(word: "dog", hint: "\u{1F415}"),
        SpellingWord(word: "sun", hint: "\u{2600}\u{FE0F}"),
        SpellingWord(word: "hat", hint: "\u{1F3A9}"),
        SpellingWord(word: "bug", hint: "\u{1F41B}"),
        SpellingWord(word: "cup", hint: "\u{1F964}"),
        SpellingWord(word: "bed", hint: "\u{1F6CF}\u{FE0F}"),
        SpellingWord(word: "pig", hint: "\u{1F437}"),
        SpellingWord(word: "fox", hint: "\u{1F98A}"),
        SpellingWord(word: "hen", hint: "\u{1F414}"),
        SpellingWord(word: "bat", hint: "\u{1F987}"),
        SpellingWord(word: "bus", hint: "\u{1F68C}"),
        SpellingWord(word: "map", hint: "\u{1F5FA}\u{FE0F}"),
        SpellingWord(word: "web", hint: "\u{1F578}\u{FE0F}"),
        SpellingWord(word: "jam", hint: "\u{1F353}"),
        SpellingWord(word: "log", hint: "\u{1FAB5}"),
        SpellingWord(word: "pot", hint: "\u{1F372}"),
        SpellingWord(word: "rug", hint: "\u{1F7EB}"),
        SpellingWord(word: "net", hint: "\u{1F945}"),
        SpellingWord(word: "box", hint: "\u{1F4E6}"),
    ]

    /// Get words for a specific difficulty (word length)
    static func words(forLength length: Int) -> [SpellingWord] {
        words.filter { $0.length == length }
    }

    /// Get all 3-letter words (default for beginners)
    static var beginnerWords: [SpellingWord] {
        words(forLength: 3)
    }

    /// Get a random word from the word list
    static func randomWord() -> SpellingWord {
        words.randomElement() ?? words[0]
    }

    /// Shuffle an array of characters
    static func shuffle(_ letters: [Character]) -> [Character] {
        var result = letters
        for i in stride(from: result.count - 1, through: 1, by: -1) {
            let j = Int.random(in: 0...i)
            result.swapAt(i, j)
        }
        return result
    }
}
