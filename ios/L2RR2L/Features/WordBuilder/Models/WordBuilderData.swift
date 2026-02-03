import Foundation

/// Static data for Word Builder game puzzles
enum WordBuilderData {

    /// 15 puzzle words with emoji hints for a game session
    /// Simple 3-4 letter words appropriate for early readers
    static let puzzles: [WordPuzzle] = [
        WordPuzzle(word: "cat", emoji: "🐱", hint: "A furry pet that meows"),
        WordPuzzle(word: "dog", emoji: "🐕", hint: "A pet that barks"),
        WordPuzzle(word: "sun", emoji: "☀️", hint: "Bright in the sky"),
        WordPuzzle(word: "hat", emoji: "🎩", hint: "Wear it on your head"),
        WordPuzzle(word: "cup", emoji: "🥤", hint: "Drink from this"),
        WordPuzzle(word: "bed", emoji: "🛏️", hint: "Sleep here"),
        WordPuzzle(word: "pig", emoji: "🐷", hint: "Pink farm animal"),
        WordPuzzle(word: "bus", emoji: "🚌", hint: "Ride to school"),
        WordPuzzle(word: "map", emoji: "🗺️", hint: "Shows places"),
        WordPuzzle(word: "box", emoji: "📦", hint: "Put things inside"),
        WordPuzzle(word: "frog", emoji: "🐸", hint: "Hops and says ribbit"),
        WordPuzzle(word: "tree", emoji: "🌳", hint: "Has leaves and branches"),
        WordPuzzle(word: "fish", emoji: "🐟", hint: "Swims in water"),
        WordPuzzle(word: "star", emoji: "⭐", hint: "Twinkles at night"),
        WordPuzzle(word: "moon", emoji: "🌙", hint: "Shines at night"),
    ]

    /// Get a shuffled copy of the puzzles for a new game session
    static func shuffledPuzzles() -> [WordPuzzle] {
        puzzles.shuffled()
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
