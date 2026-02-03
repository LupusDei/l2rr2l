import Foundation

/// Static data for the Word Builder game.
enum WordBuilderData {
    /// Word puzzles with emoji hints.
    static let puzzles: [WordPuzzle] = [
        WordPuzzle(word: "cat", emoji: "🐱", hint: "A furry pet that meows"),
        WordPuzzle(word: "dog", emoji: "🐕", hint: "A furry pet that barks"),
        WordPuzzle(word: "sun", emoji: "☀️", hint: "It shines in the sky"),
        WordPuzzle(word: "hat", emoji: "🎩", hint: "You wear it on your head"),
        WordPuzzle(word: "cup", emoji: "🥤", hint: "You drink from it"),
        WordPuzzle(word: "bed", emoji: "🛏️", hint: "You sleep on it"),
        WordPuzzle(word: "bus", emoji: "🚌", hint: "A big vehicle for people"),
        WordPuzzle(word: "car", emoji: "🚗", hint: "You drive it"),
        WordPuzzle(word: "pen", emoji: "🖊️", hint: "You write with it"),
        WordPuzzle(word: "pig", emoji: "🐷", hint: "A pink farm animal"),
        WordPuzzle(word: "box", emoji: "📦", hint: "You put things inside"),
        WordPuzzle(word: "fox", emoji: "🦊", hint: "A clever orange animal"),
        WordPuzzle(word: "red", emoji: "🔴", hint: "The color of apples"),
        WordPuzzle(word: "run", emoji: "🏃", hint: "Move fast with your legs"),
        WordPuzzle(word: "hop", emoji: "🐰", hint: "Jump like a bunny"),
        WordPuzzle(word: "fish", emoji: "🐟", hint: "It swims in water"),
        WordPuzzle(word: "bird", emoji: "🐦", hint: "It flies in the sky"),
        WordPuzzle(word: "star", emoji: "⭐", hint: "Twinkles at night"),
        WordPuzzle(word: "moon", emoji: "🌙", hint: "Shines at night"),
        WordPuzzle(word: "tree", emoji: "🌳", hint: "Has leaves and branches"),
    ]

    /// Extra distractor letters to add to puzzles.
    static let distractorPool: [Character] = Array("abcdefghijklmnopqrstuvwxyz")
}
