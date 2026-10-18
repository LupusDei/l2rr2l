import SwiftUI

/// The Star Voice: the warm off-screen narrator who gives every instruction,
/// says every word and letter sound, and gives praise. Cutisie never talks;
/// she reacts (see `MascotDirector`).
///
/// Lines are interruptible: a new line cuts off the old one so the narrator
/// always matches what's on screen. The current line is published as
/// `caption` for an optional on-screen subtitle.
@MainActor
@Observable
final class StarVoice {
    private(set) var caption: String?

    @ObservationIgnored let speaker: Speaker
    @ObservationIgnored private var lineID = 0

    init(speaker: Speaker) { self.speaker = speaker }

    /// Speak a narrator line (instruction or praise) and wait for it to finish.
    func say(_ line: String) async {
        lineID += 1
        let id = lineID
        speaker.stop()
        caption = line
        await speaker.say(line)
        if id == lineID { caption = nil }
    }

    /// Fire-and-forget version for UI handlers.
    func announce(_ line: String) {
        Task { await say(line) }
    }

    func sayWord(_ word: String) async { await speaker.sayWord(word) }
    func sayLetterSound(_ grapheme: String, stretched: Bool = false) async {
        await speaker.sayLetterSound(grapheme, stretched: stretched)
    }
    func sayBlend(_ graphemes: [String], word: String) async {
        await speaker.sayBlend(graphemes, word: word)
    }

    func stop() {
        lineID += 1
        caption = nil
        speaker.stop()
    }
}

/// Subtitle for the Star Voice: a little glowing star and the line, shown at
/// the bottom of the screen while it speaks.
struct StarVoiceCaption: View {
    @Environment(StarVoice.self) private var voice
    @Environment(\.metrics) private var m

    var body: some View {
        VStack {
            Spacer()
            if let caption = voice.caption {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(Theme.gold)
                    Text(caption)
                        .foregroundStyle(.white)
                }
                .font(.playful(m.s(24), weight: .bold))
                .padding(.horizontal, 24).padding(.vertical, 12)
                .background(Capsule().fill(Theme.skyTop.opacity(0.75)))
                .overlay(Capsule().stroke(Theme.gold.opacity(0.6), lineWidth: 2))
                .glow(Theme.gold, radius: 6)
                .padding(.bottom, m.s(16))
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: voice.caption)
        .adaptiveMetrics()
    }
}

/// The Star Voice lives in the sky as one special star that pulses and sends
/// out rings while it talks, so the child knows where the voice comes from.
struct StarVoiceBeacon: View {
    @Environment(StarVoice.self) private var voice
    var size: CGFloat = 54

    var body: some View {
        let speaking = voice.caption != nil
        TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            ZStack {
                if speaking {
                    ForEach(0..<3, id: \.self) { i in
                        let p = (t * 0.8 + Double(i) / 3).truncatingRemainder(dividingBy: 1)
                        Circle()
                            .stroke(Theme.gold.opacity(0.7 * (1 - p)), lineWidth: 3)
                            .frame(width: size * (0.8 + 1.8 * p), height: size * (0.8 + 1.8 * p))
                    }
                }
                Image(systemName: "sparkle")
                    .font(.system(size: size, weight: .bold))
                    .foregroundStyle(LinearGradient(colors: [.white, Theme.gold], startPoint: .top, endPoint: .bottom))
                    .scaleEffect(speaking ? 1 + 0.15 * sin(t * 9) : 0.85 + 0.05 * sin(t * 1.5))
                    .rotationEffect(.degrees(t * 12))
                    .glow(Theme.gold, radius: speaking ? 16 : 8)
            }
            .frame(width: size * 2.8, height: size * 2.8)
        }
        .animation(.easeInOut(duration: 0.3), value: speaking)
    }
}
