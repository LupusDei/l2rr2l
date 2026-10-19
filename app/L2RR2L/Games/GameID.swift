import SwiftUI

/// The reading games. Specs live in the project's design notes
/// (`design/reading-games.md`). To build one: create its folder under
/// `Games/<Name>/`, write its root view, and return it from `makeView()`.
enum GameID: String, CaseIterable, Identifiable, Codable {
    case stretchyBlend
    case wordMachine
    case starCatch
    case readAlong

    var id: String { rawValue }

    var title: String {
        switch self {
        case .stretchyBlend: "Stretchy Blend"
        case .wordMachine: "Word Machine"
        case .starCatch: "Star Catch"
        case .readAlong: "Read Along"
        }
    }

    var tagline: String {
        switch self {
        case .stretchyBlend: "Slide to stretch the sounds"
        case .wordMachine: "Build words with the magic machine"
        case .starCatch: "Read it, then catch it!"
        case .readAlong: "Read a story line with Cutisie"
        }
    }

    var symbol: String {
        switch self {
        case .stretchyBlend: "rainbow"
        case .wordMachine: "gearshape.2.fill"
        case .starCatch: "star.fill"
        case .readAlong: "book.fill"
        }
    }

    var colors: [Color] {
        switch self {
        case .stretchyBlend: [Theme.pink, Theme.lilac]
        case .wordMachine: [Theme.mint, Theme.sky]
        case .starCatch: [Theme.gold, Theme.peach]
        case .readAlong: [Theme.peach, Theme.pink]
        }
    }

    /// Painted backgrounds from the art brief (`bg-blend.png` etc.).
    var backgroundImage: String {
        switch self {
        case .stretchyBlend: "bg-blend"
        case .wordMachine: "bg-build"
        case .starCatch: "bg-catch"
        case .readAlong: "bg-story"
        }
    }

    /// Cutisie's opening line when the game starts.
    var introLine: String {
        switch self {
        case .stretchyBlend: "Let's stretch sounds with Cutisie!"
        case .wordMachine: "Let's build words with my magic machine!"
        case .starCatch: "Read the word, then catch the star!"
        case .readAlong: "Story time! Let's read with Cutisie."
        }
    }

    var isReady: Bool { true }

    /// Read Along has its own big reading Cutisie, so the scene one stays away.
    var showsActor: Bool { self != .readAlong }

    // MARK: Game slots

    @MainActor @ViewBuilder
    func makeView() -> some View {
        switch self {
        case .stretchyBlend:
            StretchyBlendView()
        case .wordMachine:
            WordMachineView()
        case .starCatch:
            StarCatchView()
        case .readAlong:
            ReadAlongView()
        }
    }
}
