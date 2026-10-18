import AVFoundation
import SwiftUI

/// Full-screen milestone scene (12 s video). Tap to skip; closes itself at the end.
struct MilestoneSceneOverlay: View {
    @Environment(CelebrationCenter.self) private var center

    var body: some View {
        if let url = center.milestoneScene {
            ZStack {
                Color.black.ignoresSafeArea()
                ScenePlayer(url: url) { center.milestoneScene = nil }
                    .ignoresSafeArea()
            }
            .contentShape(Rectangle())
            .onTapGesture { center.milestoneScene = nil }
            .transition(.opacity.combined(with: .scale(scale: 1.1)))
        }
    }
}

struct ScenePlayer: UIViewRepresentable {
    let url: URL
    let onEnd: () -> Void

    func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        view.play(url, onEnd: onEnd)
        return view
    }

    func updateUIView(_ view: PlayerView, context: Context) {}

    final class PlayerView: UIView {
        override class var layerClass: AnyClass { AVPlayerLayer.self }
        private var observer: NSObjectProtocol?
        private let player = AVPlayer()

        func play(_ url: URL, onEnd: @escaping () -> Void) {
            let item = AVPlayerItem(url: url)
            player.replaceCurrentItem(with: item)
            (layer as! AVPlayerLayer).player = player
            (layer as! AVPlayerLayer).videoGravity = .resizeAspect
            observer = NotificationCenter.default.addObserver(forName: AVPlayerItem.didPlayToEndTimeNotification,
                                                              object: item, queue: .main) { _ in onEnd() }
            player.play()
        }

        deinit {
            player.pause()
            if let observer { NotificationCenter.default.removeObserver(observer) }
        }
    }
}
