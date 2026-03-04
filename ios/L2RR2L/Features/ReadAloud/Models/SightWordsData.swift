import Foundation

/// Difficulty levels for the Read Aloud game based on Dolch sight word lists.
enum ReadAloudLevel: String, CaseIterable, Identifiable {
    case prePrimer = "pre-primer"
    case primer = "primer"
    case grade1 = "grade1"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .prePrimer: return "Small Words"
        case .primer: return "Medium Words"
        case .grade1: return "Big Words"
        }
    }

    var description: String {
        switch self {
        case .prePrimer: return "Short, simple words to start with"
        case .primer: return "A little bit harder words"
        case .grade1: return "Longer words for big readers"
        }
    }

    var emoji: String {
        switch self {
        case .prePrimer: return "\u{2B50}"
        case .primer: return "\u{1F31F}"
        case .grade1: return "\u{1F4AB}"
        }
    }

    var words: [String] {
        switch self {
        case .prePrimer: return SightWordsData.prePrimerWords
        case .primer: return SightWordsData.primerWords
        case .grade1: return SightWordsData.grade1Words
        }
    }
}

/// Dolch sight word lists for the Read Aloud game.
enum SightWordsData {
    /// Pre-Primer words (40 words, ages 3-4)
    static let prePrimerWords: [String] = [
        "a", "and", "away", "big", "blue", "can", "come", "down",
        "find", "for", "funny", "go", "help", "here", "I", "in",
        "is", "it", "jump", "little", "look", "make", "me", "my",
        "not", "one", "play", "red", "run", "said", "see", "the",
        "three", "to", "two", "up", "we", "where", "yellow", "you"
    ]

    /// Primer words (52 words, ages 4-5)
    static let primerWords: [String] = [
        "all", "am", "are", "at", "ate", "be", "black", "brown",
        "but", "came", "did", "do", "eat", "four", "get", "good",
        "have", "he", "into", "like", "must", "new", "no", "now",
        "on", "our", "out", "please", "pretty", "ran", "ride", "saw",
        "say", "she", "so", "soon", "that", "there", "they", "this",
        "too", "under", "want", "was", "well", "went", "what", "white",
        "who", "will", "with", "yes"
    ]

    /// Grade 1 words (41 words, ages 5-6)
    static let grade1Words: [String] = [
        "after", "again", "an", "any", "as", "ask", "by", "could",
        "every", "fly", "from", "give", "giving", "had", "has", "her",
        "him", "his", "how", "just", "know", "let", "live", "may",
        "of", "old", "once", "open", "over", "put", "round", "some",
        "stop", "take", "thank", "them", "then", "think", "walk", "were",
        "when"
    ]

    /// Returns a random set of words from the specified level.
    static func randomWords(level: ReadAloudLevel, count: Int) -> [String] {
        Array(level.words.shuffled().prefix(count))
    }
}
