import Foundation

/// A skill in the learning path (e.g. "blend-cvc-a", "digraph-sh") with the
/// skills it builds on and a "bridge" activity. When the reader gets stuck,
/// the app steps down to a prerequisite, plays the bridge, then comes back up.
/// Content files will define the real graph; games look skills up by id.
struct Skill: Codable, Hashable, Identifiable {
    let id: String
    var stage: Int
    var prerequisites: [String] = []
    /// Activity id that links the prerequisite back to this skill
    /// (e.g. "stretchy-blend:oral-only" before "stretchy-blend:cvc").
    var bridge: String?
}

struct SkillRecord: Codable, Equatable {
    enum State: String, Codable { case new, learning, known, mastered }
    var state: State = .new
    var attempts = 0
    var correct = 0
    var missesInARow = 0
    /// How many times we stepped down from this skill to a prerequisite.
    var stepDowns = 0
}

/// Where to go when a skill isn't sticking.
struct StepDown: Equatable {
    let from: String
    let prerequisite: String
    let bridge: String?
}

struct SkillGraph {
    private(set) var skills: [String: Skill] = [:]

    init(_ skills: [Skill] = []) {
        for skill in skills { self.skills[skill.id] = skill }
    }

    subscript(id: String) -> Skill? { skills[id] }

    /// The prerequisite to step down to: the first one that isn't yet known,
    /// or the most basic one if they all are.
    func stepDown(from id: String, records: [String: SkillRecord]) -> StepDown? {
        guard let skill = skills[id], !skill.prerequisites.isEmpty else { return nil }
        let weakest = skill.prerequisites.first { records[$0]?.state != .known && records[$0]?.state != .mastered }
            ?? skill.prerequisites[0]
        return StepDown(from: id, prerequisite: weakest, bridge: skill.bridge)
    }
}
