import Foundation

/// Unicorn (nonsense) words get a silly meaning that Cutisie acts out
/// (game spec 3.3, "Unicorn Words"). Each word always gets the same one.
enum UnicornMeanings {
    struct Meaning { let clip: String; let phrase: String }

    static let all: [Meaning] = [
        Meaning(clip: "sneeze", phrase: "sneeze"),
        Meaning(clip: "spin", phrase: "spin around"),
        Meaning(clip: "bounce", phrase: "bounce"),
        Meaning(clip: "hiccup", phrase: "hiccup"),
        Meaning(clip: "wiggle_ears", phrase: "wiggle your ears"),
        Meaning(clip: "tail_chase", phrase: "chase your tail"),
        Meaning(clip: "upside_down", phrase: "upside down"),
        Meaning(clip: "puff_cheeks", phrase: "puff your cheeks"),
        Meaning(clip: "tiptoe", phrase: "tiptoe"),
        Meaning(clip: "snore", phrase: "snore"),
        Meaning(clip: "hop_one", phrase: "hop on one hoof"),
        Meaning(clip: "wing_flap", phrase: "flap your wings"),
    ]

    static func meaning(for word: String) -> Meaning {
        let hash = word.unicodeScalars.reduce(7) { ($0 &* 31 &+ Int($1.value)) & 0xFFFF }
        return all[hash % all.count]
    }
}
