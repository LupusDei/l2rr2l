import Foundation

/// Static phonics word data for the game
enum PhonicsData {
    /// All available beginning sounds
    static let beginningSounds = ["b", "c", "d", "f", "g", "h", "m", "n", "p", "r", "s", "t"]

    /// All phonics words
    static let words: [PhonicsWord] = [
        PhonicsWord(id: "ball", word: "ball", beginningSound: "b", phonemes: ["b", "all"], difficulty: 1, image: "/assets/phonics/ball.svg", emoji: "soccer ball", audio: "/assets/audio/ball.mp3", category: "toys"),
        PhonicsWord(id: "bed", word: "bed", beginningSound: "b", phonemes: ["b", "e", "d"], difficulty: 1, image: "/assets/phonics/bed.svg", emoji: "bed", audio: "/assets/audio/bed.mp3", category: "home"),
        PhonicsWord(id: "bus", word: "bus", beginningSound: "b", phonemes: ["b", "u", "s"], difficulty: 1, image: "/assets/phonics/bus.svg", emoji: "bus", audio: "/assets/audio/bus.mp3", category: "vehicles"),
        PhonicsWord(id: "cat", word: "cat", beginningSound: "c", phonemes: ["c", "a", "t"], difficulty: 1, image: "/assets/phonics/cat.svg", emoji: "cat", audio: "/assets/audio/cat.mp3", category: "animals"),
        PhonicsWord(id: "cup", word: "cup", beginningSound: "c", phonemes: ["c", "u", "p"], difficulty: 1, image: "/assets/phonics/cup.svg", emoji: "cup with straw", audio: "/assets/audio/cup.mp3", category: "home"),
        PhonicsWord(id: "car", word: "car", beginningSound: "c", phonemes: ["c", "ar"], difficulty: 2, image: "/assets/phonics/car.svg", emoji: "automobile", audio: "/assets/audio/car.mp3", category: "vehicles"),
        PhonicsWord(id: "dog", word: "dog", beginningSound: "d", phonemes: ["d", "o", "g"], difficulty: 1, image: "/assets/phonics/dog.svg", emoji: "dog", audio: "/assets/audio/dog.mp3", category: "animals"),
        PhonicsWord(id: "duck", word: "duck", beginningSound: "d", phonemes: ["d", "u", "ck"], difficulty: 2, image: "/assets/phonics/duck.svg", emoji: "duck", audio: "/assets/audio/duck.mp3", category: "animals"),
        PhonicsWord(id: "fish", word: "fish", beginningSound: "f", phonemes: ["f", "i", "sh"], difficulty: 1, image: "/assets/phonics/fish.svg", emoji: "fish", audio: "/assets/audio/fish.mp3", category: "animals"),
        PhonicsWord(id: "fan", word: "fan", beginningSound: "f", phonemes: ["f", "a", "n"], difficulty: 2, image: "/assets/phonics/fan.svg", emoji: "cyclone", audio: "/assets/audio/fan.mp3", category: "home"),
        PhonicsWord(id: "fox", word: "fox", beginningSound: "f", phonemes: ["f", "o", "x"], difficulty: 2, image: "/assets/phonics/fox.svg", emoji: "fox", audio: "/assets/audio/fox.mp3", category: "animals"),
        PhonicsWord(id: "hat", word: "hat", beginningSound: "h", phonemes: ["h", "a", "t"], difficulty: 1, image: "/assets/phonics/hat.svg", emoji: "top hat", audio: "/assets/audio/hat.mp3", category: "clothing"),
        PhonicsWord(id: "hen", word: "hen", beginningSound: "h", phonemes: ["h", "e", "n"], difficulty: 2, image: "/assets/phonics/hen.svg", emoji: "chicken", audio: "/assets/audio/hen.mp3", category: "animals"),
        PhonicsWord(id: "house", word: "house", beginningSound: "h", phonemes: ["h", "ou", "se"], difficulty: 3, image: "/assets/phonics/house.svg", emoji: "house", audio: "/assets/audio/house.mp3", category: "home"),
        PhonicsWord(id: "map", word: "map", beginningSound: "m", phonemes: ["m", "a", "p"], difficulty: 1, image: "/assets/phonics/map.svg", emoji: "world map", audio: "/assets/audio/map.mp3", category: "objects"),
        PhonicsWord(id: "moon", word: "moon", beginningSound: "m", phonemes: ["m", "oo", "n"], difficulty: 2, image: "/assets/phonics/moon.svg", emoji: "crescent moon", audio: "/assets/audio/moon.mp3", category: "nature"),
        PhonicsWord(id: "net", word: "net", beginningSound: "n", phonemes: ["n", "e", "t"], difficulty: 2, image: "/assets/phonics/net.svg", emoji: "goal net", audio: "/assets/audio/net.mp3", category: "objects"),
        PhonicsWord(id: "nut", word: "nut", beginningSound: "n", phonemes: ["n", "u", "t"], difficulty: 2, image: "/assets/phonics/nut.svg", emoji: "peanuts", audio: "/assets/audio/nut.mp3", category: "food"),
        PhonicsWord(id: "pig", word: "pig", beginningSound: "p", phonemes: ["p", "i", "g"], difficulty: 1, image: "/assets/phonics/pig.svg", emoji: "pig face", audio: "/assets/audio/pig.mp3", category: "animals"),
        PhonicsWord(id: "pot", word: "pot", beginningSound: "p", phonemes: ["p", "o", "t"], difficulty: 2, image: "/assets/phonics/pot.svg", emoji: "pot of food", audio: "/assets/audio/pot.mp3", category: "home"),
        PhonicsWord(id: "sun", word: "sun", beginningSound: "s", phonemes: ["s", "u", "n"], difficulty: 1, image: "/assets/phonics/sun.svg", emoji: "sun", audio: "/assets/audio/sun.mp3", category: "nature"),
        PhonicsWord(id: "sock", word: "sock", beginningSound: "s", phonemes: ["s", "o", "ck"], difficulty: 2, image: "/assets/phonics/sock.svg", emoji: "socks", audio: "/assets/audio/sock.mp3", category: "clothing"),
        PhonicsWord(id: "star", word: "star", beginningSound: "s", phonemes: ["s", "t", "ar"], difficulty: 3, image: "/assets/phonics/star.svg", emoji: "star", audio: "/assets/audio/star.mp3", category: "nature"),
        PhonicsWord(id: "top", word: "top", beginningSound: "t", phonemes: ["t", "o", "p"], difficulty: 1, image: "/assets/phonics/top.svg", emoji: "TOP arrow", audio: "/assets/audio/top.mp3", category: "objects"),
        PhonicsWord(id: "ten", word: "ten", beginningSound: "t", phonemes: ["t", "e", "n"], difficulty: 2, image: "/assets/phonics/ten.svg", emoji: "keycap: 10", audio: "/assets/audio/ten.mp3", category: "numbers"),
        PhonicsWord(id: "tree", word: "tree", beginningSound: "t", phonemes: ["t", "r", "ee"], difficulty: 3, image: "/assets/phonics/tree.svg", emoji: "deciduous tree", audio: "/assets/audio/tree.mp3", category: "nature"),
        PhonicsWord(id: "rug", word: "rug", beginningSound: "r", phonemes: ["r", "u", "g"], difficulty: 2, image: "/assets/phonics/rug.svg", emoji: "brown square", audio: "/assets/audio/rug.mp3", category: "home"),
        PhonicsWord(id: "rain", word: "rain", beginningSound: "r", phonemes: ["r", "ai", "n"], difficulty: 3, image: "/assets/phonics/rain.svg", emoji: "cloud with rain", audio: "/assets/audio/rain.mp3", category: "nature"),
        PhonicsWord(id: "goat", word: "goat", beginningSound: "g", phonemes: ["g", "oa", "t"], difficulty: 2, image: "/assets/phonics/goat.svg", emoji: "goat", audio: "/assets/audio/goat.mp3", category: "animals"),
        PhonicsWord(id: "gift", word: "gift", beginningSound: "g", phonemes: ["g", "i", "f", "t"], difficulty: 3, image: "/assets/phonics/gift.svg", emoji: "wrapped gift", audio: "/assets/audio/gift.mp3", category: "objects")
    ]

    /// Get words filtered by difficulty
    static func words(forDifficulty difficulty: Int) -> [PhonicsWord] {
        words.filter { $0.difficulty <= difficulty }
    }

    /// Get words that start with a specific sound
    static func words(startingWith sound: String) -> [PhonicsWord] {
        words.filter { $0.beginningSound == sound }
    }

    /// Get random words from the pool
    static func randomWords(count: Int, maxDifficulty: Int = 3) -> [PhonicsWord] {
        let pool = words(forDifficulty: maxDifficulty)
        return Array(pool.shuffled().prefix(count))
    }
}
