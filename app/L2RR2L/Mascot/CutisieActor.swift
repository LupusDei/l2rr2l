import SwiftUI

/// Where the child's finger is, shared so Cutisie can react to it
/// (design v2, 3.4). Fed by a root-level gesture that never blocks taps.
@MainActor
@Observable
final class Attention {
    /// Last touch point in global coordinates (nil when nothing is touched).
    private(set) var point: CGPoint?
    private(set) var lastTouch = Date()
    /// Bumps on every new touch.
    private(set) var touches = 0

    func touched(at p: CGPoint) {
        if point == nil { touches += 1 }
        point = p
        lastTouch = .now
    }

    func released() {
        point = nil
        lastTouch = .now
    }
}

/// Cutisie living in the scene instead of in a corner window: she leans and
/// turns toward the finger, perks up when touched near, hops when tapped,
/// and dozes off if nobody touches the screen for 20 seconds. Her body is
/// the transparent video rig (idle loop plus reaction takes); the lean,
/// turn, squash and hop are layered on top in real time.
struct CutisieActor: View {
    var size: CGFloat = 220

    @Environment(AppServices.self) private var services
    @Environment(MascotDirector.self) private var mascot
    @State private var frame: CGRect = .zero
    @State private var hop = 0
    @State private var sleeping = false

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let attention = services.attention
            let target = attention.point
            let dx = target.map { $0.x - frame.midX } ?? 0
            let dy = target.map { $0.y - frame.midY } ?? 0
            let distance = hypot(dx, dy)
            let interest = target == nil ? 0 : max(0, 1 - distance / 900)
            // lean toward the finger (head-turn stand-in), with a little bob
            let lean = Double(max(-1, min(1, dx / 300))) * 12 * Double(interest)
            let facingLeft = dx < -40 && interest > 0.05
            let perk = 1 + 0.06 * interest
            ZStack {
                Ellipse()
                    .fill(Theme.skyTop.opacity(0.35))
                    .frame(width: size * 0.55, height: size * 0.1)
                    .offset(y: size * 0.46)
                    .blur(radius: 6)
                MascotView(size: size, style: .stage)
                    .scaleEffect(x: facingLeft ? -perk : perk, y: perk, anchor: .bottom)
                    .rotationEffect(.degrees(lean + 2 * sin(t * 1.3)), anchor: .bottom)
                    .offset(x: CGFloat(lean) * 1.5, y: -CGFloat(max(0, -dy / 30)) * CGFloat(interest))
                if sleeping {
                    Text("z z z")
                        .font(.playful(size * 0.12))
                        .foregroundStyle(.white.opacity(0.8))
                        .offset(x: size * 0.25, y: -size * 0.35 + CGFloat(6 * sin(t * 2)))
                        .transition(.opacity)
                }
            }
            .keyframeAnimator(initialValue: CGFloat(0), trigger: hop) { view, y in
                view.offset(y: y)
            } keyframes: { _ in
                CubicKeyframe(8, duration: 0.08)
                CubicKeyframe(-size * 0.25, duration: 0.2)
                SpringKeyframe(0, duration: 0.45, spring: .bouncy)
            }
            .onChange(of: Int(t)) { _, _ in checkNap() }
        }
        .frame(width: size, height: size * 1.1)
        .background(GeometryReader { g in
            Color.clear.onAppear { frame = g.frame(in: .global) }
                .onChange(of: g.frame(in: .global)) { _, f in frame = f }
        })
        .contentShape(Rectangle())
        .onTapGesture {
            hop += 1
            services.sounds.playPack(["giggle", "squeak_happy", "coo"].randomElement()!)
            if sleeping { wake() } else { mascot.react([.cheer, .hello, .encourage].randomElement()!) }
        }
        .onChange(of: services.attention.touches) { _, _ in if sleeping { wake() } }
        .onChange(of: services.celebration.bursts.count) { old, new in if new > old { hop += 1 } }
        .accessibilityLabel("Cutisie")
        .accessibilityAddTraits(.isButton)
    }

    /// Nap after 20 s with no touches (design v2, 3.4).
    private func checkNap() {
        guard !sleeping, mascot.clip == nil,
              Date().timeIntervalSince(services.attention.lastTouch) > 20 else { return }
        withAnimation { sleeping = true }
        mascot.play(take: "idle_sleepy", as: .sleepy)
        services.sounds.playPack("yawn")
    }

    private func wake() {
        withAnimation { sleeping = false }
        hop += 1
        mascot.react(.hello)
    }
}

/// Installs a window-level recognizer that only watches touches: it never
/// recognizes, never cancels or delays them, so buttons and drags work as
/// normal. (A SwiftUI root gesture with minimumDistance 0 swallowed taps.)
struct TouchWatcher: UIViewRepresentable {
    let attention: Attention

    func makeUIView(context: Context) -> WatcherView {
        let view = WatcherView()
        view.attention = attention
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ view: WatcherView, context: Context) {}

    final class WatcherView: UIView {
        weak var attention: Attention?
        private var recognizer: Recognizer?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard let window, recognizer == nil else { return }
            let r = Recognizer()
            r.onTouch = { [weak self] p in self?.attention?.touched(at: p) }
            r.onEnd = { [weak self] in self?.attention?.released() }
            window.addGestureRecognizer(r)
            recognizer = r
        }
    }

    final class Recognizer: UIGestureRecognizer {
        var onTouch: ((CGPoint) -> Void)?
        var onEnd: (() -> Void)?

        override init(target: Any?, action: Selector?) {
            super.init(target: target, action: action)
            cancelsTouchesInView = false
            delaysTouchesBegan = false
            delaysTouchesEnded = false
        }

        convenience init() { self.init(target: nil, action: nil) }

        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
            if let t = touches.first { report(t) }
        }

        override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
            if let t = touches.first { report(t) }
        }

        override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
            onEnd.map { end in Task { @MainActor in end() } }
            state = .failed
        }

        override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
            onEnd.map { end in Task { @MainActor in end() } }
            state = .failed
        }

        override func reset() {}

        override func canPrevent(_ preventedGestureRecognizer: UIGestureRecognizer) -> Bool { false }
        override func canBePrevented(by preventingGestureRecognizer: UIGestureRecognizer) -> Bool { false }

        private func report(_ touch: UITouch) {
            let p = touch.location(in: nil)
            onTouch.map { f in Task { @MainActor in f(p) } }
        }
    }
}
