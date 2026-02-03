import Foundation

/// Static rhyme word data for the game
enum RhymeData {
    /// All available word families
    static let wordFamilies = ["-at", "-an", "-op", "-ig", "-ot", "-un", "-et", "-in", "-ug", "-ed", "-ake", "-ing", "-ump", "-ick"]

    /// Difficulty level descriptions
    static let difficultyLevels: [Int: RhymeDifficultyLevel] = [
        1: RhymeDifficultyLevel(name: "Easy", description: "Simple CVC word families with clear rhyming patterns", targetAge: "3-4 years"),
        2: RhymeDifficultyLevel(name: "Medium", description: "More word families, some less common words", targetAge: "4-5 years"),
        3: RhymeDifficultyLevel(name: "Hard", description: "Blends, digraphs, and longer word families", targetAge: "5-6 years")
    ]

    /// All rhyme words organized by word family
    static let words: [RhymeWord] = [
        // -at family
        RhymeWord(id: "cat", word: "cat", wordFamily: "-at", difficulty: 1, image: "/assets/rhyme/cat.svg", emoji: "🐱", audio: "/assets/audio/cat.mp3"),
        RhymeWord(id: "hat", word: "hat", wordFamily: "-at", difficulty: 1, image: "/assets/rhyme/hat.svg", emoji: "🎩", audio: "/assets/audio/hat.mp3"),
        RhymeWord(id: "bat", word: "bat", wordFamily: "-at", difficulty: 1, image: "/assets/rhyme/bat.svg", emoji: "🦇", audio: "/assets/audio/bat.mp3"),
        RhymeWord(id: "mat", word: "mat", wordFamily: "-at", difficulty: 1, image: "/assets/rhyme/mat.svg", emoji: "🧹", audio: "/assets/audio/mat.mp3"),
        RhymeWord(id: "rat", word: "rat", wordFamily: "-at", difficulty: 1, image: "/assets/rhyme/rat.svg", emoji: "🐀", audio: "/assets/audio/rat.mp3"),
        RhymeWord(id: "sat", word: "sat", wordFamily: "-at", difficulty: 1, image: "/assets/rhyme/sat.svg", emoji: "🪑", audio: "/assets/audio/sat.mp3"),

        // -an family
        RhymeWord(id: "can", word: "can", wordFamily: "-an", difficulty: 1, image: "/assets/rhyme/can.svg", emoji: "🥫", audio: "/assets/audio/can.mp3"),
        RhymeWord(id: "fan", word: "fan", wordFamily: "-an", difficulty: 1, image: "/assets/rhyme/fan.svg", emoji: "🌀", audio: "/assets/audio/fan.mp3"),
        RhymeWord(id: "man", word: "man", wordFamily: "-an", difficulty: 1, image: "/assets/rhyme/man.svg", emoji: "👨", audio: "/assets/audio/man.mp3"),
        RhymeWord(id: "pan", word: "pan", wordFamily: "-an", difficulty: 1, image: "/assets/rhyme/pan.svg", emoji: "🍳", audio: "/assets/audio/pan.mp3"),
        RhymeWord(id: "ran", word: "ran", wordFamily: "-an", difficulty: 1, image: "/assets/rhyme/ran.svg", emoji: "🏃", audio: "/assets/audio/ran.mp3"),
        RhymeWord(id: "van", word: "van", wordFamily: "-an", difficulty: 1, image: "/assets/rhyme/van.svg", emoji: "🚐", audio: "/assets/audio/van.mp3"),

        // -op family
        RhymeWord(id: "hop", word: "hop", wordFamily: "-op", difficulty: 1, image: "/assets/rhyme/hop.svg", emoji: "🐰", audio: "/assets/audio/hop.mp3"),
        RhymeWord(id: "mop", word: "mop", wordFamily: "-op", difficulty: 1, image: "/assets/rhyme/mop.svg", emoji: "🧹", audio: "/assets/audio/mop.mp3"),
        RhymeWord(id: "pop", word: "pop", wordFamily: "-op", difficulty: 1, image: "/assets/rhyme/pop.svg", emoji: "🎈", audio: "/assets/audio/pop.mp3"),
        RhymeWord(id: "top", word: "top", wordFamily: "-op", difficulty: 1, image: "/assets/rhyme/top.svg", emoji: "🔝", audio: "/assets/audio/top.mp3"),
        RhymeWord(id: "cop", word: "cop", wordFamily: "-op", difficulty: 1, image: "/assets/rhyme/cop.svg", emoji: "👮", audio: "/assets/audio/cop.mp3"),
        RhymeWord(id: "stop", word: "stop", wordFamily: "-op", difficulty: 2, image: "/assets/rhyme/stop.svg", emoji: "🛑", audio: "/assets/audio/stop.mp3"),

        // -ig family
        RhymeWord(id: "big", word: "big", wordFamily: "-ig", difficulty: 1, image: "/assets/rhyme/big.svg", emoji: "🐘", audio: "/assets/audio/big.mp3"),
        RhymeWord(id: "dig", word: "dig", wordFamily: "-ig", difficulty: 1, image: "/assets/rhyme/dig.svg", emoji: "⛏️", audio: "/assets/audio/dig.mp3"),
        RhymeWord(id: "pig", word: "pig", wordFamily: "-ig", difficulty: 1, image: "/assets/rhyme/pig.svg", emoji: "🐷", audio: "/assets/audio/pig.mp3"),
        RhymeWord(id: "wig", word: "wig", wordFamily: "-ig", difficulty: 1, image: "/assets/rhyme/wig.svg", emoji: "💇", audio: "/assets/audio/wig.mp3"),
        RhymeWord(id: "fig", word: "fig", wordFamily: "-ig", difficulty: 2, image: "/assets/rhyme/fig.svg", emoji: "🫐", audio: "/assets/audio/fig.mp3"),

        // -ot family
        RhymeWord(id: "hot", word: "hot", wordFamily: "-ot", difficulty: 1, image: "/assets/rhyme/hot.svg", emoji: "🔥", audio: "/assets/audio/hot.mp3"),
        RhymeWord(id: "pot", word: "pot", wordFamily: "-ot", difficulty: 1, image: "/assets/rhyme/pot.svg", emoji: "🍲", audio: "/assets/audio/pot.mp3"),
        RhymeWord(id: "dot", word: "dot", wordFamily: "-ot", difficulty: 1, image: "/assets/rhyme/dot.svg", emoji: "⚫", audio: "/assets/audio/dot.mp3"),
        RhymeWord(id: "cot", word: "cot", wordFamily: "-ot", difficulty: 2, image: "/assets/rhyme/cot.svg", emoji: "🛏️", audio: "/assets/audio/cot.mp3"),
        RhymeWord(id: "got", word: "got", wordFamily: "-ot", difficulty: 1, image: "/assets/rhyme/got.svg", emoji: "🎁", audio: "/assets/audio/got.mp3"),
        RhymeWord(id: "lot", word: "lot", wordFamily: "-ot", difficulty: 2, image: "/assets/rhyme/lot.svg", emoji: "📦", audio: "/assets/audio/lot.mp3"),

        // -un family
        RhymeWord(id: "sun", word: "sun", wordFamily: "-un", difficulty: 2, image: "/assets/rhyme/sun.svg", emoji: "☀️", audio: "/assets/audio/sun.mp3"),
        RhymeWord(id: "run", word: "run", wordFamily: "-un", difficulty: 2, image: "/assets/rhyme/run.svg", emoji: "🏃", audio: "/assets/audio/run.mp3"),
        RhymeWord(id: "fun", word: "fun", wordFamily: "-un", difficulty: 2, image: "/assets/rhyme/fun.svg", emoji: "🎉", audio: "/assets/audio/fun.mp3"),
        RhymeWord(id: "bun", word: "bun", wordFamily: "-un", difficulty: 2, image: "/assets/rhyme/bun.svg", emoji: "🍔", audio: "/assets/audio/bun.mp3"),
        RhymeWord(id: "gun", word: "gun", wordFamily: "-un", difficulty: 2, image: "/assets/rhyme/gun.svg", emoji: "💧", audio: "/assets/audio/gun.mp3"),

        // -et family
        RhymeWord(id: "pet", word: "pet", wordFamily: "-et", difficulty: 2, image: "/assets/rhyme/pet.svg", emoji: "🐕", audio: "/assets/audio/pet.mp3"),
        RhymeWord(id: "wet", word: "wet", wordFamily: "-et", difficulty: 2, image: "/assets/rhyme/wet.svg", emoji: "💦", audio: "/assets/audio/wet.mp3"),
        RhymeWord(id: "net", word: "net", wordFamily: "-et", difficulty: 2, image: "/assets/rhyme/net.svg", emoji: "🥅", audio: "/assets/audio/net.mp3"),
        RhymeWord(id: "jet", word: "jet", wordFamily: "-et", difficulty: 2, image: "/assets/rhyme/jet.svg", emoji: "✈️", audio: "/assets/audio/jet.mp3"),
        RhymeWord(id: "bet", word: "bet", wordFamily: "-et", difficulty: 2, image: "/assets/rhyme/bet.svg", emoji: "🎲", audio: "/assets/audio/bet.mp3"),
        RhymeWord(id: "set", word: "set", wordFamily: "-et", difficulty: 2, image: "/assets/rhyme/set.svg", emoji: "🎯", audio: "/assets/audio/set.mp3"),

        // -in family
        RhymeWord(id: "pin", word: "pin", wordFamily: "-in", difficulty: 2, image: "/assets/rhyme/pin.svg", emoji: "📌", audio: "/assets/audio/pin.mp3"),
        RhymeWord(id: "win", word: "win", wordFamily: "-in", difficulty: 2, image: "/assets/rhyme/win.svg", emoji: "🏆", audio: "/assets/audio/win.mp3"),
        RhymeWord(id: "bin", word: "bin", wordFamily: "-in", difficulty: 2, image: "/assets/rhyme/bin.svg", emoji: "🗑️", audio: "/assets/audio/bin.mp3"),
        RhymeWord(id: "fin", word: "fin", wordFamily: "-in", difficulty: 2, image: "/assets/rhyme/fin.svg", emoji: "🦈", audio: "/assets/audio/fin.mp3"),
        RhymeWord(id: "tin", word: "tin", wordFamily: "-in", difficulty: 2, image: "/assets/rhyme/tin.svg", emoji: "🥫", audio: "/assets/audio/tin.mp3"),
        RhymeWord(id: "chin", word: "chin", wordFamily: "-in", difficulty: 3, image: "/assets/rhyme/chin.svg", emoji: "👦", audio: "/assets/audio/chin.mp3"),

        // -ug family
        RhymeWord(id: "bug", word: "bug", wordFamily: "-ug", difficulty: 2, image: "/assets/rhyme/bug.svg", emoji: "🐛", audio: "/assets/audio/bug.mp3"),
        RhymeWord(id: "mug", word: "mug", wordFamily: "-ug", difficulty: 2, image: "/assets/rhyme/mug.svg", emoji: "☕", audio: "/assets/audio/mug.mp3"),
        RhymeWord(id: "rug", word: "rug", wordFamily: "-ug", difficulty: 2, image: "/assets/rhyme/rug.svg", emoji: "🟫", audio: "/assets/audio/rug.mp3"),
        RhymeWord(id: "hug", word: "hug", wordFamily: "-ug", difficulty: 2, image: "/assets/rhyme/hug.svg", emoji: "🤗", audio: "/assets/audio/hug.mp3"),
        RhymeWord(id: "jug", word: "jug", wordFamily: "-ug", difficulty: 2, image: "/assets/rhyme/jug.svg", emoji: "🫗", audio: "/assets/audio/jug.mp3"),
        RhymeWord(id: "tug", word: "tug", wordFamily: "-ug", difficulty: 2, image: "/assets/rhyme/tug.svg", emoji: "🚢", audio: "/assets/audio/tug.mp3"),

        // -ed family
        RhymeWord(id: "bed", word: "bed", wordFamily: "-ed", difficulty: 2, image: "/assets/rhyme/bed.svg", emoji: "🛏️", audio: "/assets/audio/bed.mp3"),
        RhymeWord(id: "red", word: "red", wordFamily: "-ed", difficulty: 2, image: "/assets/rhyme/red.svg", emoji: "🔴", audio: "/assets/audio/red.mp3"),
        RhymeWord(id: "fed", word: "fed", wordFamily: "-ed", difficulty: 2, image: "/assets/rhyme/fed.svg", emoji: "🍼", audio: "/assets/audio/fed.mp3"),
        RhymeWord(id: "led", word: "led", wordFamily: "-ed", difficulty: 2, image: "/assets/rhyme/led.svg", emoji: "👉", audio: "/assets/audio/led.mp3"),
        RhymeWord(id: "shed", word: "shed", wordFamily: "-ed", difficulty: 3, image: "/assets/rhyme/shed.svg", emoji: "🏚️", audio: "/assets/audio/shed.mp3"),

        // -ake family
        RhymeWord(id: "cake", word: "cake", wordFamily: "-ake", difficulty: 3, image: "/assets/rhyme/cake.svg", emoji: "🎂", audio: "/assets/audio/cake.mp3"),
        RhymeWord(id: "lake", word: "lake", wordFamily: "-ake", difficulty: 3, image: "/assets/rhyme/lake.svg", emoji: "🏞️", audio: "/assets/audio/lake.mp3"),
        RhymeWord(id: "make", word: "make", wordFamily: "-ake", difficulty: 3, image: "/assets/rhyme/make.svg", emoji: "🛠️", audio: "/assets/audio/make.mp3"),
        RhymeWord(id: "take", word: "take", wordFamily: "-ake", difficulty: 3, image: "/assets/rhyme/take.svg", emoji: "✋", audio: "/assets/audio/take.mp3"),
        RhymeWord(id: "bake", word: "bake", wordFamily: "-ake", difficulty: 3, image: "/assets/rhyme/bake.svg", emoji: "🧁", audio: "/assets/audio/bake.mp3"),
        RhymeWord(id: "wake", word: "wake", wordFamily: "-ake", difficulty: 3, image: "/assets/rhyme/wake.svg", emoji: "⏰", audio: "/assets/audio/wake.mp3"),
        RhymeWord(id: "snake", word: "snake", wordFamily: "-ake", difficulty: 3, image: "/assets/rhyme/snake.svg", emoji: "🐍", audio: "/assets/audio/snake.mp3"),

        // -ing family
        RhymeWord(id: "king", word: "king", wordFamily: "-ing", difficulty: 3, image: "/assets/rhyme/king.svg", emoji: "👑", audio: "/assets/audio/king.mp3"),
        RhymeWord(id: "ring", word: "ring", wordFamily: "-ing", difficulty: 3, image: "/assets/rhyme/ring.svg", emoji: "💍", audio: "/assets/audio/ring.mp3"),
        RhymeWord(id: "sing", word: "sing", wordFamily: "-ing", difficulty: 3, image: "/assets/rhyme/sing.svg", emoji: "🎤", audio: "/assets/audio/sing.mp3"),
        RhymeWord(id: "wing", word: "wing", wordFamily: "-ing", difficulty: 3, image: "/assets/rhyme/wing.svg", emoji: "🦅", audio: "/assets/audio/wing.mp3"),
        RhymeWord(id: "thing", word: "thing", wordFamily: "-ing", difficulty: 3, image: "/assets/rhyme/thing.svg", emoji: "📦", audio: "/assets/audio/thing.mp3"),
        RhymeWord(id: "swing", word: "swing", wordFamily: "-ing", difficulty: 3, image: "/assets/rhyme/swing.svg", emoji: "🛝", audio: "/assets/audio/swing.mp3"),

        // -ump family
        RhymeWord(id: "jump", word: "jump", wordFamily: "-ump", difficulty: 3, image: "/assets/rhyme/jump.svg", emoji: "🦘", audio: "/assets/audio/jump.mp3"),
        RhymeWord(id: "bump", word: "bump", wordFamily: "-ump", difficulty: 3, image: "/assets/rhyme/bump.svg", emoji: "💥", audio: "/assets/audio/bump.mp3"),
        RhymeWord(id: "dump", word: "dump", wordFamily: "-ump", difficulty: 3, image: "/assets/rhyme/dump.svg", emoji: "🚚", audio: "/assets/audio/dump.mp3"),
        RhymeWord(id: "pump", word: "pump", wordFamily: "-ump", difficulty: 3, image: "/assets/rhyme/pump.svg", emoji: "⛽", audio: "/assets/audio/pump.mp3"),
        RhymeWord(id: "lump", word: "lump", wordFamily: "-ump", difficulty: 3, image: "/assets/rhyme/lump.svg", emoji: "🪨", audio: "/assets/audio/lump.mp3"),
        RhymeWord(id: "stump", word: "stump", wordFamily: "-ump", difficulty: 3, image: "/assets/rhyme/stump.svg", emoji: "🪵", audio: "/assets/audio/stump.mp3"),

        // -ick family
        RhymeWord(id: "kick", word: "kick", wordFamily: "-ick", difficulty: 3, image: "/assets/rhyme/kick.svg", emoji: "⚽", audio: "/assets/audio/kick.mp3"),
        RhymeWord(id: "pick", word: "pick", wordFamily: "-ick", difficulty: 3, image: "/assets/rhyme/pick.svg", emoji: "⛏️", audio: "/assets/audio/pick.mp3"),
        RhymeWord(id: "sick", word: "sick", wordFamily: "-ick", difficulty: 3, image: "/assets/rhyme/sick.svg", emoji: "🤒", audio: "/assets/audio/sick.mp3"),
        RhymeWord(id: "tick", word: "tick", wordFamily: "-ick", difficulty: 3, image: "/assets/rhyme/tick.svg", emoji: "✅", audio: "/assets/audio/tick.mp3"),
        RhymeWord(id: "trick", word: "trick", wordFamily: "-ick", difficulty: 3, image: "/assets/rhyme/trick.svg", emoji: "🎩", audio: "/assets/audio/trick.mp3"),
        RhymeWord(id: "stick", word: "stick", wordFamily: "-ick", difficulty: 3, image: "/assets/rhyme/stick.svg", emoji: "🪵", audio: "/assets/audio/stick.mp3")
    ]

    /// Distractor words that may be confused with rhyming words
    static let distractors: [RhymeDistractor] = [
        RhymeDistractor(id: "dog", word: "dog", confusedWith: ["-og", "-ot"], difficulty: 1, emoji: "🐕"),
        RhymeDistractor(id: "log", word: "log", confusedWith: ["-og", "-ot"], difficulty: 1, emoji: "🪵"),
        RhymeDistractor(id: "fog", word: "fog", confusedWith: ["-og", "-op"], difficulty: 2, emoji: "🌫️"),
        RhymeDistractor(id: "cup", word: "cup", confusedWith: ["-up", "-ump"], difficulty: 1, emoji: "🥤"),
        RhymeDistractor(id: "pup", word: "pup", confusedWith: ["-up", "-ump"], difficulty: 1, emoji: "🐶"),
        RhymeDistractor(id: "box", word: "box", confusedWith: ["-ox", "-op"], difficulty: 1, emoji: "📦"),
        RhymeDistractor(id: "fox", word: "fox", confusedWith: ["-ox", "-op"], difficulty: 2, emoji: "🦊"),
        RhymeDistractor(id: "bag", word: "bag", confusedWith: ["-ag", "-at"], difficulty: 1, emoji: "👜"),
        RhymeDistractor(id: "tag", word: "tag", confusedWith: ["-ag", "-at"], difficulty: 2, emoji: "🏷️"),
        RhymeDistractor(id: "ten", word: "ten", confusedWith: ["-en", "-et"], difficulty: 1, emoji: "🔟"),
        RhymeDistractor(id: "hen", word: "hen", confusedWith: ["-en", "-et"], difficulty: 2, emoji: "🐔"),
        RhymeDistractor(id: "pen", word: "pen", confusedWith: ["-en", "-in"], difficulty: 1, emoji: "🖊️"),
        RhymeDistractor(id: "ham", word: "ham", confusedWith: ["-am", "-an"], difficulty: 2, emoji: "🍖"),
        RhymeDistractor(id: "jam", word: "jam", confusedWith: ["-am", "-an"], difficulty: 2, emoji: "🍯"),
        RhymeDistractor(id: "bit", word: "bit", confusedWith: ["-it", "-ig"], difficulty: 2, emoji: "🔢"),
        RhymeDistractor(id: "sit", word: "sit", confusedWith: ["-it", "-ig"], difficulty: 1, emoji: "🪑"),
        RhymeDistractor(id: "hit", word: "hit", confusedWith: ["-it", "-ig"], difficulty: 2, emoji: "👊"),
        RhymeDistractor(id: "cub", word: "cub", confusedWith: ["-ub", "-ug"], difficulty: 2, emoji: "🐻"),
        RhymeDistractor(id: "tub", word: "tub", confusedWith: ["-ub", "-ug"], difficulty: 2, emoji: "🛁"),
        RhymeDistractor(id: "rub", word: "rub", confusedWith: ["-ub", "-ug"], difficulty: 2, emoji: "✋")
    ]

    // MARK: - Query Methods

    /// Get words filtered by maximum difficulty
    static func words(forDifficulty difficulty: Int) -> [RhymeWord] {
        words.filter { $0.difficulty <= difficulty }
    }

    /// Get words in a specific word family
    static func words(inFamily family: String) -> [RhymeWord] {
        words.filter { $0.wordFamily == family }
    }

    /// Get words filtered by both family and difficulty
    static func words(inFamily family: String, maxDifficulty: Int) -> [RhymeWord] {
        words.filter { $0.wordFamily == family && $0.difficulty <= maxDifficulty }
    }

    /// Get random words from the pool
    static func randomWords(count: Int, maxDifficulty: Int = 3) -> [RhymeWord] {
        let pool = words(forDifficulty: maxDifficulty)
        return Array(pool.shuffled().prefix(count))
    }

    /// Get a rhyming pair (two words from the same family)
    static func getRhymingPair(maxDifficulty: Int = 3) -> (RhymeWord, RhymeWord)? {
        let shuffledFamilies = wordFamilies.shuffled()

        for family in shuffledFamilies {
            let wordsInFamily = words(inFamily: family, maxDifficulty: maxDifficulty)
            if wordsInFamily.count >= 2 {
                let shuffled = wordsInFamily.shuffled()
                return (shuffled[0], shuffled[1])
            }
        }

        return nil
    }

    /// Check if two words rhyme (same word family)
    static func doWordsRhyme(_ word1: RhymeWord, _ word2: RhymeWord) -> Bool {
        word1.wordFamily == word2.wordFamily && word1.id != word2.id
    }

    /// Get distractors that might be confused with a word family
    static func distractors(forFamily family: String, maxDifficulty: Int = 3) -> [RhymeDistractor] {
        distractors.filter { d in
            d.confusedWith.contains(family) && d.difficulty <= maxDifficulty
        }
    }

    /// Generate a rhyme question with options
    static func generateQuestion(difficulty: Int = 1, distractorCount: Int = 2) -> RhymeQuestion? {
        guard let (targetWord, correctAnswer) = getRhymingPair(maxDifficulty: difficulty) else {
            return nil
        }

        // Gather distractor options
        var availableDistractors: [RhymeOptionItem] = []

        // Add words from other families
        let otherFamilyWords = words.filter { w in
            w.wordFamily != targetWord.wordFamily && w.difficulty <= difficulty
        }
        availableDistractors.append(contentsOf: otherFamilyWords.map { .word($0) })

        // Add confusing distractors
        let confusingDistractors = distractors(forFamily: targetWord.wordFamily, maxDifficulty: difficulty)
        availableDistractors.append(contentsOf: confusingDistractors.map { .distractor($0) })

        // Shuffle and select
        let selectedDistractors = Array(availableDistractors.shuffled().prefix(distractorCount))

        // Combine all options
        var allOptions = selectedDistractors
        allOptions.append(.word(correctAnswer))
        allOptions.shuffle()

        return RhymeQuestion(
            targetWord: targetWord,
            correctAnswer: correctAnswer,
            distractors: selectedDistractors,
            allOptions: allOptions
        )
    }

    /// Get statistics for each word family
    static func getWordFamilyStats() -> [(family: String, count: Int, difficulties: [Int])] {
        wordFamilies.map { family in
            let wordsInFamily = words(inFamily: family)
            let difficulties = Array(Set(wordsInFamily.map { $0.difficulty })).sorted()
            return (family: family, count: wordsInFamily.count, difficulties: difficulties)
        }
    }
}
