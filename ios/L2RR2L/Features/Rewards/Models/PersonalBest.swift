import Foundation
import SwiftData

/// Persists personal best records per game type.
/// One record per game — upserted on each game completion.
@Model
final class PersonalBest {
    @Attribute(.unique) var gameTypeRaw: String
    var bestScore: Int
    var bestStreak: Int
    var bestMoves: Int?          // Memory game only (lower is better)
    var achievedDate: Date
    var gamesPlayed: Int

    init(
        gameType: GameType,
        bestScore: Int = 0,
        bestStreak: Int = 0,
        bestMoves: Int? = nil,
        achievedDate: Date = Date(),
        gamesPlayed: Int = 0
    ) {
        self.gameTypeRaw = gameType.rawValue
        self.bestScore = bestScore
        self.bestStreak = bestStreak
        self.bestMoves = bestMoves
        self.achievedDate = achievedDate
        self.gamesPlayed = gamesPlayed
    }

    var gameType: GameType? {
        GameType(rawValue: gameTypeRaw)
    }
}
