import Foundation
import SwiftData

// MARK: - Sticker Type

enum StickerType: String, Codable, CaseIterable {
    case normal
    case golden
    case special
}

// MARK: - Sticker Model

@Model
final class Sticker {
    @Attribute(.unique) var id: String
    var typeRaw: String
    var gameSourceRaw: String
    var dateEarned: Date
    var displayName: String
    var emoji: String

    var type: StickerType {
        StickerType(rawValue: typeRaw) ?? .normal
    }

    var gameSource: GameType? {
        GameType(rawValue: gameSourceRaw)
    }

    init(
        id: String = UUID().uuidString,
        type: StickerType,
        gameSource: GameType,
        dateEarned: Date = Date(),
        displayName: String,
        emoji: String
    ) {
        self.id = id
        self.typeRaw = type.rawValue
        self.gameSourceRaw = gameSource.rawValue
        self.dateEarned = dateEarned
        self.displayName = displayName
        self.emoji = emoji
    }
}
