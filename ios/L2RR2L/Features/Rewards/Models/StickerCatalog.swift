import Foundation

/// A catalog entry defining an earnable sticker.
struct StickerCatalogEntry {
    let displayName: String
    let emoji: String
    let type: StickerType
    let gameSource: GameType
}

/// Full catalog of earnable stickers across all games.
enum StickerCatalog {

    /// All available stickers (30 total).
    static let entries: [StickerCatalogEntry] = {
        var catalog: [StickerCatalogEntry] = []
        catalog.append(contentsOf: spelling)
        catalog.append(contentsOf: memory)
        catalog.append(contentsOf: phonics)
        catalog.append(contentsOf: rhyme)
        catalog.append(contentsOf: wordBuilder)
        catalog.append(contentsOf: readAloud)
        return catalog
    }()

    /// Stickers available for a specific game.
    static func entries(for gameType: GameType) -> [StickerCatalogEntry] {
        entries.filter { $0.gameSource == gameType }
    }

    // MARK: - Spelling

    static let spelling: [StickerCatalogEntry] = [
        .init(displayName: "Letter Learner", emoji: "\u{270F}\u{FE0F}", type: .normal, gameSource: .spelling),
        .init(displayName: "Word Wizard", emoji: "\u{1FA84}", type: .normal, gameSource: .spelling),
        .init(displayName: "Spelling Star", emoji: "\u{2B50}", type: .golden, gameSource: .spelling),
        .init(displayName: "Streak Speller", emoji: "\u{1F525}", type: .special, gameSource: .spelling),
        .init(displayName: "Super Speller", emoji: "\u{1F3C6}", type: .special, gameSource: .spelling),
    ]

    // MARK: - Memory Match

    static let memory: [StickerCatalogEntry] = [
        .init(displayName: "Card Flipper", emoji: "\u{1F0CF}", type: .normal, gameSource: .memory),
        .init(displayName: "Match Maker", emoji: "\u{1F3AF}", type: .normal, gameSource: .memory),
        .init(displayName: "Memory Master", emoji: "\u{1F9E0}", type: .golden, gameSource: .memory),
        .init(displayName: "Speed Matcher", emoji: "\u{26A1}", type: .special, gameSource: .memory),
        .init(displayName: "Perfect Memory", emoji: "\u{1F48E}", type: .special, gameSource: .memory),
    ]

    // MARK: - Phonics

    static let phonics: [StickerCatalogEntry] = [
        .init(displayName: "Sound Seeker", emoji: "\u{1F50D}", type: .normal, gameSource: .phonics),
        .init(displayName: "Phonics Fan", emoji: "\u{1F3B5}", type: .normal, gameSource: .phonics),
        .init(displayName: "Sound Master", emoji: "\u{1F3A4}", type: .golden, gameSource: .phonics),
        .init(displayName: "Sound Streak", emoji: "\u{1F525}", type: .special, gameSource: .phonics),
        .init(displayName: "Phonics Pro", emoji: "\u{1F31F}", type: .special, gameSource: .phonics),
    ]

    // MARK: - Rhyme Time

    static let rhyme: [StickerCatalogEntry] = [
        .init(displayName: "Rhyme Finder", emoji: "\u{1F514}", type: .normal, gameSource: .rhyme),
        .init(displayName: "Rhyme Rocker", emoji: "\u{1F3B8}", type: .normal, gameSource: .rhyme),
        .init(displayName: "Rhyme Champion", emoji: "\u{1F451}", type: .golden, gameSource: .rhyme),
        .init(displayName: "Rhyme Streak", emoji: "\u{1F525}", type: .special, gameSource: .rhyme),
        .init(displayName: "Rhyme King", emoji: "\u{1F981}", type: .special, gameSource: .rhyme),
    ]

    // MARK: - Word Builder

    static let wordBuilder: [StickerCatalogEntry] = [
        .init(displayName: "Word Starter", emoji: "\u{1F9E9}", type: .normal, gameSource: .wordBuilder),
        .init(displayName: "Builder Buddy", emoji: "\u{1F528}", type: .normal, gameSource: .wordBuilder),
        .init(displayName: "Master Builder", emoji: "\u{1F3D7}\u{FE0F}", type: .golden, gameSource: .wordBuilder),
        .init(displayName: "Build Streak", emoji: "\u{1F525}", type: .special, gameSource: .wordBuilder),
        .init(displayName: "Word Architect", emoji: "\u{1F3DB}\u{FE0F}", type: .special, gameSource: .wordBuilder),
    ]

    // MARK: - Read Aloud

    static let readAloud: [StickerCatalogEntry] = [
        .init(displayName: "Voice Starter", emoji: "\u{1F5E3}\u{FE0F}", type: .normal, gameSource: .readAloud),
        .init(displayName: "Read Runner", emoji: "\u{1F4D6}", type: .normal, gameSource: .readAloud),
        .init(displayName: "Reading Star", emoji: "\u{1F320}", type: .golden, gameSource: .readAloud),
        .init(displayName: "Voice Streak", emoji: "\u{1F525}", type: .special, gameSource: .readAloud),
        .init(displayName: "Super Reader", emoji: "\u{1F4DA}", type: .special, gameSource: .readAloud),
    ]
}
