import Foundation

/// Static data for word builder puzzles
enum WordBuilderData {

    /// 15 simple words with emoji hints for word building
    static let puzzles: [WordPuzzle] = [
        WordPuzzle(word: "apple", emoji: "🍎", hint: "A red fruit"),
        WordPuzzle(word: "house", emoji: "🏠", hint: "Where you live"),
        WordPuzzle(word: "happy", emoji: "😊", hint: "Feeling good"),
        WordPuzzle(word: "water", emoji: "💧", hint: "You drink it"),
        WordPuzzle(word: "phone", emoji: "📱", hint: "You call people"),
        WordPuzzle(word: "green", emoji: "💚", hint: "Color of grass"),
        WordPuzzle(word: "mouse", emoji: "🐭", hint: "Small squeaky animal"),
        WordPuzzle(word: "clock", emoji: "🕐", hint: "Tells the time"),
        WordPuzzle(word: "bread", emoji: "🍞", hint: "Made from wheat"),
        WordPuzzle(word: "train", emoji: "🚂", hint: "Rides on tracks"),
        WordPuzzle(word: "tiger", emoji: "🐯", hint: "Striped big cat"),
        WordPuzzle(word: "smile", emoji: "😄", hint: "Show your teeth"),
        WordPuzzle(word: "beach", emoji: "🏖️", hint: "Sand and ocean"),
        WordPuzzle(word: "cloud", emoji: "☁️", hint: "White and fluffy"),
        WordPuzzle(word: "pizza", emoji: "🍕", hint: "Cheesy dinner"),
    ]

    /// Get a random puzzle from the list
    static func randomPuzzle() -> WordPuzzle {
        puzzles.randomElement() ?? puzzles[0]
    }

    /// Shuffle an array of characters, ensuring it differs from original
    static func scramble(_ letters: [Character]) -> [Character] {
        var result = letters
        var attempts = 0
        repeat {
            result.shuffle()
            attempts += 1
        } while result == letters && attempts < 10 && letters.count > 1
        return result
    }
}
