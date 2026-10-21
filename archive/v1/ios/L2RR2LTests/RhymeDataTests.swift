import XCTest
@testable import L2RR2L

final class RhymeDataTests: XCTestCase {

    // MARK: - Word Data Tests

    func testWordsNotEmpty() {
        XCTAssertFalse(RhymeData.words.isEmpty, "Should have rhyme words")
        XCTAssertGreaterThan(RhymeData.words.count, 50, "Should have at least 50 words")
    }

    func testWordFamiliesNotEmpty() {
        XCTAssertFalse(RhymeData.wordFamilies.isEmpty, "Should have word families")
        XCTAssertEqual(RhymeData.wordFamilies.count, 14, "Should have 14 word families")
    }

    func testDistractorsNotEmpty() {
        XCTAssertFalse(RhymeData.distractors.isEmpty, "Should have distractors")
        XCTAssertEqual(RhymeData.distractors.count, 20, "Should have 20 distractors")
    }

    func testAllWordsHaveValidFamily() {
        for word in RhymeData.words {
            XCTAssertTrue(
                RhymeData.wordFamilies.contains(word.wordFamily),
                "Word '\(word.word)' has invalid family '\(word.wordFamily)'"
            )
        }
    }

    func testAllWordsHaveValidDifficulty() {
        for word in RhymeData.words {
            XCTAssertTrue(
                (1...3).contains(word.difficulty),
                "Word '\(word.word)' has invalid difficulty \(word.difficulty)"
            )
        }
    }

    func testAllWordsHaveEmoji() {
        for word in RhymeData.words {
            XCTAssertFalse(word.emoji.isEmpty, "Word '\(word.word)' should have an emoji")
        }
    }

    // MARK: - Query Method Tests

    func testWordsForDifficulty() {
        let easyWords = RhymeData.words(forDifficulty: 1)
        let mediumWords = RhymeData.words(forDifficulty: 2)
        let hardWords = RhymeData.words(forDifficulty: 3)

        XCTAssertFalse(easyWords.isEmpty, "Should have easy words")
        XCTAssertTrue(mediumWords.count >= easyWords.count, "Medium should include easy")
        XCTAssertTrue(hardWords.count >= mediumWords.count, "Hard should include medium")
        XCTAssertEqual(hardWords.count, RhymeData.words.count, "Difficulty 3 should include all")

        for word in easyWords {
            XCTAssertEqual(word.difficulty, 1, "Easy words should have difficulty 1")
        }
    }

    func testWordsInFamily() {
        let atWords = RhymeData.words(inFamily: "-at")
        XCTAssertFalse(atWords.isEmpty, "Should have -at words")
        XCTAssertEqual(atWords.count, 6, "Should have 6 -at words")

        for word in atWords {
            XCTAssertEqual(word.wordFamily, "-at", "All should be -at family")
        }
    }

    func testGetRhymingPair() {
        for _ in 0..<10 {
            guard let (word1, word2) = RhymeData.getRhymingPair() else {
                XCTFail("Should be able to get a rhyming pair")
                return
            }

            XCTAssertEqual(word1.wordFamily, word2.wordFamily, "Pair should be in same family")
            XCTAssertNotEqual(word1.id, word2.id, "Pair should be different words")
        }
    }

    func testDoWordsRhyme() {
        let catWord = RhymeData.words.first { $0.word == "cat" }!
        let hatWord = RhymeData.words.first { $0.word == "hat" }!
        let dogDistractor = RhymeData.distractors.first { $0.word == "dog" }!

        XCTAssertTrue(RhymeData.doWordsRhyme(catWord, hatWord), "cat and hat should rhyme")

        let sunWord = RhymeData.words.first { $0.word == "sun" }!
        XCTAssertFalse(RhymeData.doWordsRhyme(catWord, sunWord), "cat and sun should not rhyme")
    }

    func testDistractorsForFamily() {
        let atDistractors = RhymeData.distractors(forFamily: "-at")
        XCTAssertFalse(atDistractors.isEmpty, "Should have distractors confused with -at")

        for distractor in atDistractors {
            XCTAssertTrue(
                distractor.confusedWith.contains("-at"),
                "Distractor should be confused with -at"
            )
        }
    }

    func testGenerateQuestion() {
        for difficulty in 1...3 {
            guard let question = RhymeData.generateQuestion(difficulty: difficulty) else {
                XCTFail("Should generate question for difficulty \(difficulty)")
                continue
            }

            XCTAssertEqual(
                question.targetWord.wordFamily,
                question.correctAnswer.wordFamily,
                "Target and answer should be in same family"
            )
            XCTAssertNotEqual(
                question.targetWord.id,
                question.correctAnswer.id,
                "Target and answer should be different"
            )
            XCTAssertFalse(question.allOptions.isEmpty, "Should have options")
            XCTAssertTrue(
                question.allOptions.contains { $0.id == question.correctAnswer.id },
                "Options should contain correct answer"
            )
        }
    }

    func testGetWordFamilyStats() {
        let stats = RhymeData.getWordFamilyStats()

        XCTAssertEqual(stats.count, RhymeData.wordFamilies.count, "Should have stats for all families")

        for stat in stats {
            XCTAssertTrue(RhymeData.wordFamilies.contains(stat.family), "Stats should be for valid family")
            XCTAssertGreaterThan(stat.count, 0, "Each family should have words")
            XCTAssertFalse(stat.difficulties.isEmpty, "Should have difficulties")
        }
    }

    // MARK: - Difficulty Level Tests

    func testDifficultyLevels() {
        XCTAssertEqual(RhymeData.difficultyLevels.count, 3, "Should have 3 difficulty levels")

        for level in 1...3 {
            guard let difficultyLevel = RhymeData.difficultyLevels[level] else {
                XCTFail("Should have difficulty level \(level)")
                continue
            }
            XCTAssertFalse(difficultyLevel.name.isEmpty, "Level should have name")
            XCTAssertFalse(difficultyLevel.description.isEmpty, "Level should have description")
            XCTAssertFalse(difficultyLevel.targetAge.isEmpty, "Level should have target age")
        }
    }
}
