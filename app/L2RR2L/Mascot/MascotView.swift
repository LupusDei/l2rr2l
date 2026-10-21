import AVFoundation
import SwiftUI

/// Cutisie on screen. Plays the current clip from `MascotDirector` when the
/// video exists, otherwise animates her still art with body language for each
/// reaction (hop, spin, wiggle, nod) so the app is alive before videos land.
///
/// `.stage`: big and free-standing on a cloud (home screen).
/// `.window`: inside a round "magic window" (corner of game screens).
struct MascotView: View {
    enum Style { case stage, window }

    var size: CGFloat = 220
    var style: Style = .window

    @Environment(MascotDirector.self) private var mascot

    var body: some View {
        switch style {
        case .stage: stage
        case .window: window
        }
    }

    private var stage: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            ZStack {
                // aura
                Circle()
                    .fill(RadialGradient(colors: [Theme.aurora3.opacity(0.55), Theme.aurora1.opacity(0.25), .clear],
                                         center: .center, startRadius: 0, endRadius: size * 0.62))
                    .scaleEffect(1 + 0.05 * sin(t * 1.4))
                OrbitingSparkles(t: t, radius: size * 0.48, size: size * 0.05)
                if !MascotClip.hasClips {
                FluffyCloud()
                    .frame(width: size * 1.35, height: size * 0.5)
                    .offset(y: size * 0.42)
                    .offset(y: 4 * sin(t * 1.1 + 0.5))
                }
                artwork
                    .frame(width: size * 0.95, height: size * 0.95)
                    .offset(y: -size * 0.02 + 7 * sin(t * 1.1))
                    .scaleEffect(x: 1 + 0.012 * sin(t * 2.2), y: 1 - 0.012 * sin(t * 2.2), anchor: .bottom)
                    .shadow(color: Theme.aurora2.opacity(0.6), radius: 18)
            }
            .frame(width: size, height: size * 1.1)
        }
    }

    private var window: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [Theme.aurora1.opacity(0.9), Theme.skyTop],
                                     center: .center, startRadius: 0, endRadius: size * 0.6))
            artwork
                .padding(size * 0.08)
                .clipShape(Circle())
        }
        .frame(width: size, height: size)
        .overlay(Circle().stroke(AngularGradient(colors: [Theme.pink, Theme.gold, Theme.mint, Theme.sky, Theme.pink],
                                                 center: .center),
                                 lineWidth: max(5, size * 0.045)))
        .glow(Theme.pink, radius: size * 0.08)
    }

    @ViewBuilder private var artwork: some View {
        if MascotClip.hasClips {
            let take = mascot.take ?? mascot.idleTake
            let count = mascot.playCount
            if let url = MascotClip.clipURL(take) {
                // Clips frame her small and low with room to move; enlarge and
                // lift so she fills the space at rest.
                GeometryReader { geo in
                    let side = min(geo.size.width, geo.size.height)
                    MascotVideoPlayer(url: url, idle: mascot.clip == nil, token: mascot.clip == nil ? -count - 1 : count) {
                        mascot.finished(count)
                    }
                    .frame(width: side * 1.6, height: side * 1.6)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2 - side * 0.24)
                }
            }
        } else {
            Image(uiImage: MascotStill.image(mascot.clip?.poseName ?? "idle") ?? UIImage())
                .resizable()
                .scaledToFit()
                .modifier(MascotMotion(clip: mascot.clip, playCount: mascot.playCount))
        }
    }
}

enum MascotStill {
    /// Pose stills from the art pack, bundled in `Media/mascot/poses`.
    static func image(_ name: String) -> UIImage? {
        for ext in ["png", "jpg", "heic"] {
            if let path = Bundle.main.path(forResource: name, ofType: ext, inDirectory: "Media/mascot/poses") {
                return UIImage(contentsOfFile: path)
            }
        }
        return nil
    }
}

private struct OrbitingSparkles: View {
    let t: Double
    let radius: CGFloat
    let size: CGFloat

    var body: some View {
        ZStack {
            ForEach(0..<7, id: \.self) { i in
                let angle = Double(i) / 7 * 2 * .pi + t * 0.45
                Image(systemName: i.isMultiple(of: 2) ? "sparkle" : "star.fill")
                    .font(.system(size: size * (i.isMultiple(of: 3) ? 1.3 : 0.8)))
                    .foregroundStyle(Theme.confetti[i % Theme.confetti.count])
                    .glow(Theme.confetti[i % Theme.confetti.count], radius: 4)
                    .offset(x: cos(angle) * radius, y: sin(angle) * radius * 0.55 - radius * 0.1)
                    .opacity(0.4 + 0.6 * (0.5 + 0.5 * sin(t * 2.5 + Double(i))))
                    .scaleEffect(0.7 + 0.3 * sin(angle))
            }
        }
    }
}

/// A plump cloud with a lit top and pink underglow, for Cutisie to sit on.
struct FluffyCloud: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            var path = Path()
            let puffs: [(CGFloat, CGFloat, CGFloat)] = [
                (0.18, 0.62, 0.20), (0.34, 0.42, 0.26), (0.52, 0.34, 0.30),
                (0.70, 0.44, 0.25), (0.85, 0.62, 0.18), (0.5, 0.7, 0.32),
            ]
            for (x, y, r) in puffs {
                path.addEllipse(in: CGRect(x: x * w - r * w * 0.6, y: y * h - r * h * 1.3,
                                           width: r * w * 1.2, height: r * h * 2.6))
            }
            // puffs overhang the nominal box; shrink into the canvas so nothing clips
            ctx.translateBy(x: w * 0.12, y: h * 0.08)
            ctx.scaleBy(x: 0.76, y: 0.72)
            ctx.drawLayer { layer in
                layer.addFilter(.shadow(color: Theme.pink.opacity(0.7), radius: 18, y: 10))
                layer.fill(path, with: .linearGradient(Gradient(colors: [.white, Color(red: 0.86, green: 0.82, blue: 1.0), Theme.pink.opacity(0.85)]),
                                                       startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: 0, y: h)))
            }
        }
    }
}

/// Body language on the still art per reaction, standing in for video.
private struct MascotMotion: ViewModifier {
    let clip: MascotClip?
    let playCount: Int
    @State private var trigger = 0

    func body(content: Content) -> some View {
        content
            .keyframeAnimator(initialValue: Pose(), trigger: trigger) { view, pose in
                view
                    .scaleEffect(x: pose.scaleX, y: pose.scaleY, anchor: .bottom)
                    .rotationEffect(.degrees(pose.angle))
                    .offset(y: pose.lift)
            } keyframes: { _ in
                KeyframeTrack(\.lift) {
                    switch clip {
                    case .cheer, .dance:
                        CubicKeyframe(10, duration: 0.12)
                        CubicKeyframe(-90, duration: 0.3)
                        SpringKeyframe(0, duration: 0.5, spring: .bouncy)
                        CubicKeyframe(-40, duration: 0.25)
                        SpringKeyframe(0, duration: 0.4, spring: .bouncy)
                    case .hello:
                        CubicKeyframe(-25, duration: 0.25)
                        SpringKeyframe(0, duration: 0.4, spring: .bouncy)
                    case .encourage:
                        CubicKeyframe(8, duration: 0.2)
                        CubicKeyframe(-12, duration: 0.2)
                        SpringKeyframe(0, duration: 0.4)
                    default:
                        CubicKeyframe(-10, duration: 0.2)
                        SpringKeyframe(0, duration: 0.3)
                    }
                }
                KeyframeTrack(\.angle) {
                    switch clip {
                    case .dance:
                        CubicKeyframe(0, duration: 0.12)
                        CubicKeyframe(360, duration: 0.6)
                        CubicKeyframe(350, duration: 0.15)
                        CubicKeyframe(370, duration: 0.15)
                        SpringKeyframe(360, duration: 0.3)
                        MoveKeyframe(0)
                    case .hello:
                        CubicKeyframe(-10, duration: 0.2)
                        CubicKeyframe(10, duration: 0.2)
                        CubicKeyframe(-8, duration: 0.2)
                        SpringKeyframe(0, duration: 0.3)
                    case .encourage:
                        // the oops gag: a wobble like she nearly tipped off her cloud
                        CubicKeyframe(-16, duration: 0.18)
                        CubicKeyframe(12, duration: 0.2)
                        CubicKeyframe(-6, duration: 0.18)
                        SpringKeyframe(0, duration: 0.4)
                    case .think:
                        CubicKeyframe(12, duration: 0.4)
                        SpringKeyframe(8, duration: 0.4)
                    default:
                        CubicKeyframe(0, duration: 0.1)
                    }
                }
                KeyframeTrack(\.scaleY) {
                    CubicKeyframe(0.86, duration: 0.12)   // squash before the move
                    SpringKeyframe(1.08, duration: 0.25, spring: .bouncy)
                    SpringKeyframe(1.0, duration: 0.5, spring: .bouncy)
                }
                KeyframeTrack(\.scaleX) {
                    CubicKeyframe(1.12, duration: 0.12)
                    SpringKeyframe(0.95, duration: 0.25, spring: .bouncy)
                    SpringKeyframe(1.0, duration: 0.5, spring: .bouncy)
                }
            }
            .onChange(of: playCount) { trigger += 1 }
    }

    struct Pose {
        var lift: CGFloat = 0
        var angle: Double = 0
        var scaleX: CGFloat = 1
        var scaleY: CGFloat = 1
    }
}

/// Bare AVPlayerLayer (no controls) that renders Cutisie's HEVC-with-alpha
/// clips over whatever is behind her. Idle takes loop silently; reaction takes
/// play once with their squeaks and call `onFinish`.
struct MascotVideoPlayer: UIViewRepresentable {
    let url: URL
    let idle: Bool
    let token: Int
    let onFinish: () -> Void

    func makeUIView(context: Context) -> PlayerView { PlayerView() }

    func updateUIView(_ view: PlayerView, context: Context) {
        view.onFinish = onFinish
        view.play(url: url, idle: idle, token: token)
    }

    final class PlayerView: UIView {
        override class var layerClass: AnyClass { AVPlayerLayer.self }
        private var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
        private let player = AVQueuePlayer()
        private var looper: AVPlayerLooper?
        private var token = Int.min
        private var endObserver: NSObjectProtocol?
        private var timeObserver: Any?
        /// The take's first frame, shown until the video draws so swaps never flash empty.
        private let poster = UIImageView()
        var onFinish: (() -> Void)?

        override init(frame: CGRect) {
            super.init(frame: frame)
            player.preventsDisplaySleepDuringVideoPlayback = false
            // alpha video needs a BGRA pixel buffer and a clear, non-opaque layer
            // (set before attaching the player) to stay transparent
            playerLayer.pixelBufferAttributes = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            playerLayer.backgroundColor = UIColor.clear.cgColor
            playerLayer.isOpaque = false
            playerLayer.videoGravity = .resizeAspect
            playerLayer.player = player
            backgroundColor = .clear
            isOpaque = false
            poster.contentMode = .scaleAspectFit
            poster.frame = bounds
            poster.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            addSubview(poster)
            timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(value: 1, timescale: 30), queue: .main) { [weak self] time in
                guard let self, self.poster.alpha > 0, time.seconds > 0.05, self.playerLayer.isReadyForDisplay else { return }
                UIView.animate(withDuration: 0.08) { self.poster.alpha = 0 }
            }
        }

        required init?(coder: NSCoder) { fatalError() }

        deinit {
            if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
            if let timeObserver { player.removeTimeObserver(timeObserver) }
        }

        func play(url: URL, idle: Bool, token: Int) {
            guard token != self.token else { return }
            self.token = token
            looper?.disableLooping()
            looper = nil
            if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
            endObserver = nil
            let name = url.deletingPathExtension().lastPathComponent
            if let path = Bundle.main.path(forResource: name, ofType: "png", inDirectory: "Media/mascot/posters") {
                poster.layer.removeAllAnimations()
                poster.image = UIImage(contentsOfFile: path)
                poster.alpha = 1
            }
            player.removeAllItems()
            let item = AVPlayerItem(url: url)
            // The pack's alpha clips store straight (unpremultiplied) color, which
            // the layer would show as a pale box; premultiply each frame.
            item.videoComposition = AVVideoComposition(asset: item.asset) { request in
                request.finish(with: request.sourceImage.premultiplyingAlpha(), context: nil)
            }
            player.isMuted = idle
            if idle {
                looper = AVPlayerLooper(player: player, templateItem: item)
            } else {
                player.insert(item, after: nil)
                endObserver = NotificationCenter.default.addObserver(
                    forName: AVPlayerItem.didPlayToEndTimeNotification, object: item, queue: .main
                ) { [weak self] _ in self?.onFinish?() }
            }
            player.play()
        }
    }
}

#Preview {
    let services = AppServices.preview()
    return ZStack {
        SkyBackground()
        MascotView(size: 420, style: .stage)
    }
    .withServices(services)
    .onAppear { services.mascot.react(.dance) }
}
