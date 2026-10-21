import Foundation
import SwiftData

/// Result of a personal best check after game completion.
struct PersonalBestResult {
    let isNewBestScore: Bool
    let isNewBestStreak: Bool
    let isNewBestMoves: Bool
    let previousBestScore: Int?
    let previousBestStreak: Int?
    let previousBestMoves: Int?

    var isNewRecord: Bool {
        isNewBestScore || isNewBestStreak || isNewBestMoves
    }
}

/// Tracks and persists personal best records per game.
/// Follows the same pattern as StickerBook: @MainActor + @Observable + ModelContext.
@MainActor
@Observable
class PersonalBestTracker {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Checks current game result against stored best and updates if new record.
    /// - Returns: Result describing which records (if any) were broken.
    @discardableResult
    func checkAndUpdate(
        gameType: GameType,
        score: Int,
        streak: Int,
        moves: Int? = nil
    ) -> PersonalBestResult {
        let existing = fetchBest(for: gameType)

        let previousScore = existing?.bestScore
        let previousStreak = existing?.bestStreak
        let previousMoves = existing?.bestMoves

        let isNewScore = score > (previousScore ?? 0)
        let isNewStreak = streak > (previousStreak ?? 0)
        let isNewMoves: Bool = {
            guard let m = moves else { return false }
            guard let prev = previousMoves else { return true } // First game
            return m < prev // Lower moves is better
        }()

        if let record = existing {
            record.gamesPlayed += 1
            if isNewScore {
                record.bestScore = score
                record.achievedDate = Date()
            }
            if isNewStreak {
                record.bestStreak = streak
                record.achievedDate = Date()
            }
            if isNewMoves, let m = moves {
                record.bestMoves = m
                record.achievedDate = Date()
            }
        } else {
            let record = PersonalBest(
                gameType: gameType,
                bestScore: score,
                bestStreak: streak,
                bestMoves: moves,
                gamesPlayed: 1
            )
            modelContext.insert(record)
        }

        try? modelContext.save()

        return PersonalBestResult(
            isNewBestScore: isNewScore,
            isNewBestStreak: isNewStreak,
            isNewBestMoves: isNewMoves,
            previousBestScore: previousScore,
            previousBestStreak: previousStreak,
            previousBestMoves: previousMoves
        )
    }

    /// Fetches the stored personal best for a game type.
    func fetchBest(for gameType: GameType) -> PersonalBest? {
        let raw = gameType.rawValue
        let descriptor = FetchDescriptor<PersonalBest>(
            predicate: #Predicate { $0.gameTypeRaw == raw }
        )
        return try? modelContext.fetch(descriptor).first
    }
}
