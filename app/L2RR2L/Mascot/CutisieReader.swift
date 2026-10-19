import SwiftUI

/// What Cutisie's reading face is doing: which mouth shape, where she's
/// looking, and her little reactions. Games move it in time with the sounds
/// they play, so she looks like she's sounding the words out herself.
@MainActor
@Observable
final class ReaderPuppet {
    private(set) var viseme: Viseme = .closed
    private(set) var open: Double = 0
    /// Bumps once per sound so the horn flashes and her head nods with it.
    private(set) var beat = 0
    private(set) var hops = 0
    private(set) var oopses = 0

    @ObservationIgnored private var trackTask: Task<Void, Never>?

    /// Hold the mouth shape for one sound (sounding out).
    func show(sound: String) {
        trackTask?.cancel()
        viseme = Viseme.of(sound)
        open = viseme == .closed ? 0.2 : 0.9
        beat += 1
    }

    func rest() {
        trackTask?.cancel()
        viseme = .closed
        open = 0
    }

    func hop() { hops += 1 }
    func oops() { oopses += 1 }

    /// Mouth a word along its recording's track, without sound (reading along
    /// with the child, or in sync with the Star Voice saying it).
    func mouth(_ word: Word) async {
        trackTask?.cancel()
        let frames = LipSync.track(for: word)
        beat += 1
        let task = Task { @MainActor [weak self] in
            let start = Date()
            for frame in frames {
                let wait = frame.time - Date().timeIntervalSince(start)
                if wait > 0 { try? await Task.sleep(for: .seconds(wait)) }
                if Task.isCancelled { return }
                self?.viseme = frame.open < 0.15 ? .closed : frame.viseme
                self?.open = frame.open
            }
        }
        trackTask = task
        await task.value
    }

    /// Say a word in the Star Voice while Cutisie's mouth follows it.
    func read(_ word: Word, voice: StarVoice) async {
        async let mouthing: Void = mouth(word)
        await voice.sayWord(word.text)
        await mouthing
        rest()
    }
}

/// Cutisie's reading rig: one still of her reading plus seven mouth patches
/// and a blink, layered in real time (see `art/cutisie/READER_RIG.md`).
/// Every word gets a lip-synced Cutisie from these few drawings, where
/// pre-rendered video would need a clip per word.
///
/// Without the rig art she uses her `read` pose, nodding and flashing her
/// horn on each sound. Big reactions crossfade to the art pack's video takes.
struct CutisieReader: View {
    let puppet: ReaderPuppet
    var size: CGFloat = 320
    var onTap: (() -> Void)? = nil

    @Environment(MascotDirector.self) private var mascot

    var body: some View {
        let reacting = mascot.clip != nil && MascotClip.hasClips
        ZStack {
            rig
                .opacity(reacting ? 0 : 1)
            if reacting {
                MascotView(size: size, style: .stage)
                    .transition(.opacity)
            }
        }
        .frame(width: size, height: size)
        .animation(.easeInOut(duration: 0.18), value: reacting)
        .contentShape(Rectangle())
        .onTapGesture { onTap?() }
        .accessibilityLabel("Cutisie")
        .accessibilityAddTraits(.isButton)
    }

    private var rig: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            // a blink every few seconds, 120 ms long
            let blinking = t.truncatingRemainder(dividingBy: 4.3) < 0.12
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [Theme.aurora3.opacity(0.45), Theme.aurora1.opacity(0.2), .clear],
                                         center: .center, startRadius: 0, endRadius: size * 0.55))
                    .scaleEffect(1 + 0.04 * sin(t * 1.4))
                ZStack {
                    if let base = ReaderRig.base {
                        Image(uiImage: base).resizable().scaledToFit()
                    }
                    if ReaderRig.hasMouths, let mouth = ReaderRig.mouth(puppet.viseme) {
                        Image(uiImage: mouth).resizable().scaledToFit()
                    }
                    if blinking, let blink = ReaderRig.blink {
                        Image(uiImage: blink).resizable().scaledToFit()
                    }
                    HornGlow(beat: puppet.beat, size: size)
                        .position(x: size * ReaderRig.hornTip.x, y: size * ReaderRig.hornTip.y)
                }
                .frame(width: size, height: size)
                // without mouth art, her head nods a touch on every sound
                .scaleEffect(x: 1, y: ReaderRig.hasMouths ? 1 : 1 + 0.02 * puppet.open, anchor: .bottom)
                .offset(y: 5 * sin(t * 1.2))
                .shadow(color: Theme.aurora2.opacity(0.5), radius: 16)
                .keyframeAnimator(initialValue: Bounce(), trigger: puppet.hops) { view, b in
                    view.scaleEffect(x: b.sx, y: b.sy, anchor: .bottom).offset(y: b.y)
                } keyframes: { _ in
                    KeyframeTrack(\.y) {
                        CubicKeyframe(6, duration: 0.08)
                        CubicKeyframe(-size * 0.16, duration: 0.2)
                        SpringKeyframe(0, duration: 0.45, spring: .bouncy)
                    }
                    KeyframeTrack(\.sy) {
                        CubicKeyframe(0.88, duration: 0.08)
                        SpringKeyframe(1.06, duration: 0.2, spring: .bouncy)
                        SpringKeyframe(1, duration: 0.4)
                    }
                    KeyframeTrack(\.sx) {
                        CubicKeyframe(1.1, duration: 0.08)
                        SpringKeyframe(0.96, duration: 0.2, spring: .bouncy)
                        SpringKeyframe(1, duration: 0.4)
                    }
                }
                // the oops: she wobbles like she nearly tipped off her cloud
                .keyframeAnimator(initialValue: 0.0, trigger: puppet.oopses) { view, angle in
                    view.rotationEffect(.degrees(angle), anchor: .bottom)
                } keyframes: { _ in
                    CubicKeyframe(-14, duration: 0.16)
                    CubicKeyframe(11, duration: 0.18)
                    CubicKeyframe(-5, duration: 0.16)
                    SpringKeyframe(0, duration: 0.4)
                }
            }
        }
    }

    private struct Bounce {
        var y: CGFloat = 0
        var sx: CGFloat = 1
        var sy: CGFloat = 1
    }
}

/// A flash of light on the tip of her horn, once per sound she reads.
private struct HornGlow: View {
    let beat: Int
    let size: CGFloat

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Circle()
                .fill(RadialGradient(colors: [.white, Theme.gold.opacity(0.7), .clear],
                                     center: .center, startRadius: 0, endRadius: size * 0.07))
                .frame(width: size * 0.14, height: size * 0.14)
                .scaleEffect(0.7 + 0.1 * sin(t * 3))
        }
        .keyframeAnimator(initialValue: 1.0, trigger: beat) { view, s in
            view.scaleEffect(s)
        } keyframes: { _ in
            CubicKeyframe(1.9, duration: 0.08)
            SpringKeyframe(1, duration: 0.35)
        }
        .allowsHitTesting(false)
    }
}

/// The reading rig's art in `Media/mascot/reader/`: `base.png`, one
/// `mouth_<viseme>.png` per shape and `blink.png`, all the same size and
/// lined up, with only the changed pixels opaque in the patches. `rig.json`
/// gives the horn tip as a fraction of the image. Made by
/// tools/make_reader_rig.py.
enum ReaderRig {
    private static let folder = "Media/mascot/reader"

    private struct Info: Decodable { let hornTip: [Double] }

    static let base: UIImage? = image("base") ?? MascotStill.image("read")
    static let blink: UIImage? = image("blink")
    static let hasMouths = image("mouth_closed") != nil
    private static let mouths: [Viseme: UIImage] = {
        var out: [Viseme: UIImage] = [:]
        for v in Viseme.allCases { out[v] = image("mouth_\(v.rawValue)") }
        return out
    }()

    static func mouth(_ viseme: Viseme) -> UIImage? { mouths[viseme] ?? mouths[.small] }

    /// Where her horn tip sits in the art (0...1), for the glow and the
    /// reading beam. The default fits the `read` pose still.
    static let hornTip: UnitPoint = {
        if let url = Bundle.main.url(forResource: "rig", withExtension: "json", subdirectory: folder),
           let data = try? Data(contentsOf: url),
           let info = try? JSONDecoder().decode(Info.self, from: data), info.hornTip.count == 2 {
            return UnitPoint(x: info.hornTip[0], y: info.hornTip[1])
        }
        return UnitPoint(x: 0.508, y: 0.09)
    }()

    private static func image(_ name: String) -> UIImage? {
        Bundle.main.path(forResource: name, ofType: "png", inDirectory: folder).flatMap(UIImage.init(contentsOfFile:))
    }
}
