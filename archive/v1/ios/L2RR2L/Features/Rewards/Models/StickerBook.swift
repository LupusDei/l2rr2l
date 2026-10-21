import Foundation
import SwiftData

@MainActor
@Observable
class StickerBook {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Add a new sticker to the collection.
    func addSticker(type: StickerType, gameSource: GameType, displayName: String, emoji: String) {
        let sticker = Sticker(type: type, gameSource: gameSource, displayName: displayName, emoji: emoji)
        modelContext.insert(sticker)
        try? modelContext.save()
    }

    /// Get all stickers earned from a specific game, newest first.
    func stickers(for gameType: GameType) -> [Sticker] {
        let raw = gameType.rawValue
        let descriptor = FetchDescriptor<Sticker>(
            predicate: #Predicate { $0.gameSourceRaw == raw },
            sortBy: [SortDescriptor(\.dateEarned, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// All earned stickers, newest first.
    func allStickers() -> [Sticker] {
        let descriptor = FetchDescriptor<Sticker>(
            sortBy: [SortDescriptor(\.dateEarned, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Count of stickers earned from a specific game.
    func stickerCount(for gameType: GameType) -> Int {
        let raw = gameType.rawValue
        let descriptor = FetchDescriptor<Sticker>(
            predicate: #Predicate { $0.gameSourceRaw == raw }
        )
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    /// Total stickers earned across all games.
    func totalCount() -> Int {
        let descriptor = FetchDescriptor<Sticker>()
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    /// Check if a golden (perfect score) sticker has been earned for a game.
    func hasGoldenSticker(for gameType: GameType) -> Bool {
        let raw = gameType.rawValue
        let goldenRaw = StickerType.golden.rawValue
        let descriptor = FetchDescriptor<Sticker>(
            predicate: #Predicate { $0.gameSourceRaw == raw && $0.typeRaw == goldenRaw }
        )
        return ((try? modelContext.fetchCount(descriptor)) ?? 0) > 0
    }

    /// Awards an appropriate sticker based on game performance.
    /// Selects from the catalog: golden for perfect, special for streak, normal otherwise.
    /// - Returns: The awarded sticker, or nil if no catalog entry exists.
    @discardableResult
    func awardGameSticker(
        gameType: GameType,
        isPerfectScore: Bool,
        streakCount: Int
    ) -> Sticker? {
        let catalogEntries = StickerCatalog.entries(for: gameType)

        let entry: StickerCatalogEntry?

        if isPerfectScore {
            entry = catalogEntries.first { $0.type == .golden }
        } else if streakCount >= 3 {
            entry = catalogEntries.first { $0.type == .special }
        } else {
            let completionCount = stickerCount(for: gameType)
            let normalEntries = catalogEntries.filter { $0.type == .normal }
            entry = completionCount < 5 ? normalEntries.first : normalEntries.last
        }

        guard let entry else { return nil }

        let sticker = Sticker(
            type: entry.type,
            gameSource: entry.gameSource,
            displayName: entry.displayName,
            emoji: entry.emoji
        )
        modelContext.insert(sticker)
        try? modelContext.save()
        return sticker
    }

    /// Most recently earned sticker.
    func latestSticker() -> Sticker? {
        var descriptor = FetchDescriptor<Sticker>(
            sortBy: [SortDescriptor(\.dateEarned, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try? modelContext.fetch(descriptor).first
    }
}
