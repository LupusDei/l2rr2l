import Foundation

/// The rules of Word Machine, separate from sound and animation so they can
/// be tested on their own (design v2, 4.2). Every word runs:
///
///     idle -> building -> complete -> running -> reveal -> nextWord -> idle ...
///                                                       \-> scene (end of chain)
///
/// `nextWord` keeps the letters from the word before when the next word is the
/// same length (that's the "change one letter" step); otherwise the slots are
/// cleared. Each word gets its own tray: only the letters it needs plus a few
/// distractors, never the whole alphabet.
struct WordMachineEngine: Equatable {
    enum State: Equatable { case idle, building, complete, running, reveal, nextWord, scene }

    enum PlaceResult: Equatable { case accepted, completed, rejected, ignored }

    let chain: WordChain
    private(set) var index = 0
    private(set) var state: State = .idle
    /// Letter in each slot (nil = empty).
    private(set) var slots: [String?] = []
    /// Letters she can use for this word.
    private(set) var tray: [String] = []
    /// Words she has finished, in order.
    private(set) var built: [Word] = []

    init(chain: WordChain) {
        self.chain = chain
    }

    var word: Word { chain.words[min(index, chain.words.count - 1)] }
    var target: [String] { word.graphemes }
    var isLastWord: Bool { index == chain.words.count - 1 }
    /// True when the slots already hold the previous word (a "change one" step).
    var isChangeStep: Bool { index > 0 && slots.contains { $0 != nil } }

    /// Slots that don't hold the right letter yet.
    var wrongSlots: [Int] { slots.indices.filter { slots[$0] != target[$0] } }

    // MARK: Transitions

    /// idle or nextWord -> building.
    mutating func beginWord() {
        guard state == .idle || state == .nextWord else { return }
        if slots.count != target.count || index == 0 {
            slots = Array(repeating: nil, count: target.count)
        }
        tray = Self.makeTray(for: target, keeping: slots, chain: chain)
        state = .building
        if wrongSlots.isEmpty { state = .complete } // never happens in a real chain
    }

    /// Put a letter in a slot. Wrong letters are rejected (the slot keeps what it had).
    @discardableResult
    mutating func place(_ letter: String, at slot: Int) -> PlaceResult {
        guard state == .building, slots.indices.contains(slot) else { return .ignored }
        guard letter == target[slot] else { return .rejected }
        if slots[slot] == letter { return .ignored }
        slots[slot] = letter
        if wrongSlots.isEmpty {
            state = .complete
            return .completed
        }
        return .accepted
    }

    /// Hint level 4: the right letter goes in for her.
    mutating func autoFill(_ slot: Int) -> PlaceResult {
        guard state == .building, slots.indices.contains(slot) else { return .ignored }
        return place(target[slot], at: slot)
    }

    /// complete -> running (she pulled the lever).
    mutating func pullLever() -> Bool {
        guard state == .complete else { return false }
        state = .running
        return true
    }

    /// running -> reveal (the thing has come out of the chute).
    mutating func finishRun() {
        guard state == .running else { return }
        built.append(word)
        state = .reveal
    }

    /// reveal -> nextWord, or -> scene after the last word.
    mutating func finishReveal() {
        guard state == .reveal else { return }
        if isLastWord {
            state = .scene
        } else {
            index += 1
            state = .nextWord
        }
    }

    // MARK: Tray

    static func makeTray(for target: [String], keeping slots: [String?], chain: WordChain) -> [String] {
        // letters she still has to place
        var needed: [String] = []
        for (i, g) in target.enumerated() where slots.indices.contains(i) ? slots[i] != g : true {
            if !needed.contains(g) { needed.append(g) }
        }
        // distractors: letters from the rest of the chain first, then easy confusions
        let pool = chain.words.flatMap(\.graphemes) + chain.distractors + ["a", "i", "o", "e", "u", "s", "m", "t", "p", "n"]
        var extras: [String] = []
        for g in pool where !needed.contains(g) && !target.contains(g) && !extras.contains(g) {
            extras.append(g)
        }
        let extraCount = needed.count <= 1 ? 3 : 2
        // stable but not alphabetical, so the tray doesn't spell the answer
        var tray = needed + Array(extras.prefix(extraCount))
        tray.sort { Self.scramble($0) < Self.scramble($1) }
        return tray
    }

    private static func scramble(_ s: String) -> Int {
        s.unicodeScalars.reduce(17) { ($0 &* 131 &+ Int($1.value)) & 0xFFFF }
    }
}
