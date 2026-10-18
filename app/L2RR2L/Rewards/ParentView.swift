import SwiftUI

/// The grown-ups' page (learning path section 11), behind a hold-to-open gate:
/// where she is, her sound map, words she reads alone, milestones, this
/// week's practice, what she's finding tricky, Sparkle Check and Sky Trial
/// results, and one tip to try at home for her stage.
struct ParentView: View {
    @Environment(AppServices.self) private var services
    @Environment(ProgressStore.self) private var progress
    @Environment(\.dismiss) private var dismiss
    @State private var confirmReset = false

    private var data: ProgressData { progress.data }
    private var stage: Stage? { Curriculum.shared.stage(data.stage) }

    var body: some View {
        NavigationStack {
            List {
                Section("Where she is") {
                    LabeledContent("World", value: "\(data.stage). \(stage?.name ?? "")")
                    LabeledContent("Words read alone", value: "\(progress.wordsReadAlone)")
                    LabeledContent("Words mastered (fast, 3 days)", value: "\(progress.masteredWords().count)")
                    LabeledContent("Known in this world", value: "\(Int(progress.knownShare(of: data.stage) * 100))%")
                    if progress.skyTrialReady {
                        Label("Sky Trial ready on the home screen", systemImage: "rainbow")
                    }
                }

                Section("Sound map") {
                    SoundMap(progress: progress)
                        .listRowInsets(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
                    HStack(spacing: 14) {
                        legend(.gray.opacity(0.35), "new")
                        legend(Theme.peach, "learning")
                        legend(Theme.sky, "known")
                        legend(Theme.mint, "mastered")
                    }
                    .font(.caption)
                }

                Section("Try this at home") {
                    Text(Self.tip(for: data.stage))
                    Text("After reading together, ask one question: who was in it, what happened, what might happen next? And read to her every day from books above her level.")
                        .foregroundStyle(.secondary)
                }

                Section("This week") {
                    let week = daysThisWeek
                    LabeledContent("Days played", value: "\(week)")
                    LabeledContent("Sessions finished (all time)", value: "\(data.sessionsCompleted)")
                    LabeledContent("Accuracy", value: accuracy)
                }

                if !tricky.isEmpty {
                    Section("Tricky right now") {
                        ForEach(tricky, id: \.self) { Text($0) }
                    }
                }

                Section("Milestones") {
                    if data.milestones.isEmpty {
                        Text("Her first word read alone is the first one!").foregroundStyle(.secondary)
                    }
                    ForEach(data.milestones.sorted(), id: \.self) { id in
                        Label(Self.milestoneName(id), systemImage: "star.fill")
                    }
                }

                if !readAlone.isEmpty {
                    Section("Words she reads alone") {
                        Text(readAlone.joined(separator: ", "))
                    }
                }

                if !data.assessments.isEmpty {
                    Section("Sparkle Checks and Sky Trials") {
                        ForEach(Array(data.assessments.enumerated().reversed()), id: \.offset) { _, a in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(a.kind == .placement ? "Sparkle Check: started at world \(a.stage)"
                                     : "Sky Trial world \(a.stage): \(a.passed ? "passed" : "needs more practice")")
                                    .font(.headline)
                                Text(a.date.formatted(date: .abbreviated, time: .omitted)).font(.caption).foregroundStyle(.secondary)
                                Text(a.parts.sorted { $0.key < $1.key }.map { "\($0.key) \($0.value[0])/\($0.value[1])" }.joined(separator: " · "))
                                    .font(.caption)
                                if !a.shakySounds.isEmpty {
                                    Text("Shaky sounds: \(a.shakySounds.joined(separator: " "))").font(.caption)
                                }
                            }
                        }
                    }
                }

                Section {
                    Button("Run the Sparkle Check again") {
                        dismiss()
                        services.router.open(.sparkleCheck)
                    }
                    Button("Reset all progress", role: .destructive) { confirmReset = true }
                }
            }
            .navigationTitle("Grown-ups")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
            .confirmationDialog("Erase all of her progress, stickers and treasures?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Erase everything", role: .destructive) {
                    progress.reset()
                    dismiss()
                }
            }
        }
        .preferredColorScheme(.light)
    }

    private func legend(_ color: Color, _ text: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 3).fill(color).frame(width: 12, height: 12)
            Text(text)
        }
    }

    private var daysThisWeek: Int {
        let cal = Calendar(identifier: .gregorian)
        let start = cal.date(byAdding: .day, value: -6, to: cal.startOfDay(for: .now))!
        let f = DateFormatter()
        f.calendar = cal
        f.dateFormat = "yyyy-MM-dd"
        return data.daysPlayed.compactMap { f.date(from: $0) }.filter { $0 >= start }.count
    }

    private var accuracy: String {
        let answers = data.games.values.reduce(0) { $0 + $1.answers }
        let correct = data.games.values.reduce(0) { $0 + $1.correct }
        return answers == 0 ? "–" : "\(Int(Double(correct) / Double(answers) * 100))% of \(answers) answers"
    }

    private var readAlone: [String] {
        data.words.filter { !$0.value.knownDays.isEmpty }.map(\.key).sorted()
    }

    private var tricky: [String] {
        progress.topErrorPatterns(3).compactMap { item in
            let parts = item.tag.split(separator: ":").map(String.init)
            guard parts.count == 2 else { return nil }
            switch parts[0] {
            case "vowel": return "Mixing up vowels (\(parts[1].replacingOccurrences(of: "-", with: " / "))), \(item.count) times"
            case "reversal": return "b / d swaps, \(item.count) times"
            case "guess": return "Guessing from the first letter, \(item.count) times"
            case "position": return "Misses the \(parts[1]) sound, \(item.count) times"
            default: return nil
            }
        }
    }

    static func milestoneName(_ id: String) -> String {
        switch id {
        case "first-word": "First word read alone"
        case "ten-words": "10 words read alone"
        case "fifty-words": "50 words read alone"
        case "hundred-words": "100 words read alone"
        default:
            if id.hasPrefix("stage-"), let n = Int(id.dropFirst(6)) {
                "Passed the \(Curriculum.shared.stage(n)?.name ?? "world \(n)") Sky Trial"
            } else { id }
        }
    }

    /// Learning path section 11: one plain tip per stage.
    static func tip(for stage: Int) -> String {
        switch stage {
        case 0: "Play I spy with sounds: \"I spy something that starts with /mmm/.\" Clap the syllables in family names."
        case 1: "Say a word slowly, /d/ /o/ /g/, and ask her to say it fast."
        case 2: "Swap one sound: cat, what if I change /c/ to /h/?"
        case 3: "Hunt for sh, ch and th on signs and cereal boxes. Look for sh words at dinner: fish, shell, dish."
        case 4: "Say a word and add a sound: top, now stop."
        case 5: "Write cap, then add an e. What happened?"
        default: "Read real early readers together and let her read the words she knows."
        }
    }
}

/// Every grapheme taught so far, colored by how well she knows words that use it.
private struct SoundMap: View {
    let progress: ProgressStore

    var body: some View {
        let stages = Curriculum.shared.stages.filter { $0.id <= max(progress.data.stage, 1) + 1 && !$0.graphemes.isEmpty }
        VStack(alignment: .leading, spacing: 10) {
            ForEach(stages) { stage in
                VStack(alignment: .leading, spacing: 4) {
                    Text(stage.name).font(.caption).foregroundStyle(.secondary)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44), spacing: 6)], spacing: 6) {
                        ForEach(stage.graphemes, id: \.self) { g in
                            Text(g.replacingOccurrences(of: "_", with: "-"))
                                .font(.system(.body, design: .rounded).weight(.bold))
                                .frame(width: 44, height: 36)
                                .background(RoundedRectangle(cornerRadius: 8).fill(color(for: g)))
                        }
                    }
                }
            }
        }
    }

    private func color(for grapheme: String) -> Color {
        let records = Curriculum.shared.stages.flatMap(\.words)
            .filter { $0.soundKeys.contains(grapheme) || $0.graphemes.contains(grapheme) }
            .compactMap { progress.data.words[$0.text] }
        if records.filter(\.isMastered).count >= 2 { return Theme.mint }
        if records.filter(\.isKnown).count >= 2 { return Theme.sky }
        if !records.isEmpty { return Theme.peach }
        return .gray.opacity(0.35)
    }
}

/// Small grown-ups button: hold for 2 seconds to open, so taps from little
/// fingers don't get in.
struct ParentGateButton: View {
    @Environment(AppServices.self) private var services
    @State private var showing = false
    @State private var holding = false

    var body: some View {
        Image(systemName: "person.2.circle")
            .font(.system(size: 30))
            .foregroundStyle(.white.opacity(holding ? 0.95 : 0.45))
            .padding(10)
            .scaleEffect(holding ? 1.3 : 1)
            .animation(.easeInOut(duration: 2), value: holding)
            .onLongPressGesture(minimumDuration: 2, pressing: { holding = $0 }) { showing = true }
            .sheet(isPresented: $showing) { ParentView().withServices(services) }
            .accessibilityLabel("Grown-ups (hold to open)")
    }
}
