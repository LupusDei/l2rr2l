import Foundation

/// A level configuration for the Sight Words Memory Game.
/// Each level contains a set of Dolch sight words and grid dimensions.
struct SightWordLevel: Identifiable {
    let id: Int
    let name: String
    let words: [String]
    let gridColumns: Int
    let gridRows: Int

    /// Total number of cards (each word appears twice for matching)
    var cardCount: Int {
        words.count * 2
    }
}

/// Static sight word data for the Memory Game.
/// Uses Dolch Sight Words (Pre-Primer through First Grade).
enum SightWordData {

    /// All available sight word levels
    static let levels: [SightWordLevel] = [
        // Level 1: Pre-Primer basics (4 words = 8 cards, 2x4 grid)
        SightWordLevel(
            id: 1,
            name: "Starter",
            words: ["a", "the", "I", "is"],
            gridColumns: 4,
            gridRows: 2
        ),

        // Level 2: Pre-Primer expanded (8 words = 16 cards, 4x4 grid)
        SightWordLevel(
            id: 2,
            name: "Beginner",
            words: ["a", "the", "I", "is", "it", "and", "to", "we"],
            gridColumns: 4,
            gridRows: 4
        ),

        // Level 3: Pre-Primer + Primer mix (16 words = 32 cards, 4x8 grid)
        SightWordLevel(
            id: 3,
            name: "Explorer",
            words: [
                "a", "the", "I", "is",
                "it", "and", "to", "we",
                "can", "you", "see", "my",
                "like", "go", "up", "in"
            ],
            gridColumns: 4,
            gridRows: 8
        )
    ]

    /// Get a level by its ID
    static func level(_ id: Int) -> SightWordLevel? {
        levels.first { $0.id == id }
    }

    /// Generate shuffled card pairs for a level.
    /// Each word appears twice and cards are shuffled.
    static func generateCards(for level: SightWordLevel) -> [MemoryCard] {
        var cards: [MemoryCard] = []
        let pairId = { UUID().uuidString }

        for word in level.words {
            let pair = pairId()
            // Create two cards with the same word and pairId
            cards.append(MemoryCard(word: word, pairId: pair))
            cards.append(MemoryCard(word: word, pairId: pair))
        }

        return cards.shuffled()
    }
}

/// A single card in the memory game
struct MemoryCard: Identifiable, Equatable {
    let id: String
    let word: String
    let pairId: String
    var isFlipped: Bool
    var isMatched: Bool

    init(word: String, pairId: String) {
        self.id = UUID().uuidString
        self.word = word
        self.pairId = pairId
        self.isFlipped = false
        self.isMatched = false
    }

    /// Check if this card matches another (same pairId, different id)
    func matches(_ other: MemoryCard) -> Bool {
        pairId == other.pairId && id != other.id
    }
}

/// Game state for the memory game
enum MemoryGameState: Equatable {
    case notStarted
    case playing
    case checking
    case levelComplete
}
