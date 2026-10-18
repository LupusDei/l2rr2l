import SwiftUI

/// "New thing" (learning path section 5): one new sound, introduced with a
/// short story clip in which the Star Voice explains it while Cutisie acts it
/// out. Then she taps the big tile to hear the sound herself.
struct NewThingView: View {
    let grapheme: String

    @Environment(AppServices.self) private var services
    @Environment(\.metrics) private var m
    @State private var shown = false
    @State private var taps = 0

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                SkyBackground(tint: Theme.pink, imageName: "bg-story")
                TouchSparkles()
                MascotView(size: min(w, h) * 0.5, style: .stage)
                    .position(x: w / 2, y: h * 0.34)

                Button {
                    taps += 1
                    Task { await services.phonemes.tap(grapheme, holdFor: 0.8) }
                } label: {
                    Text(grapheme.replacingOccurrences(of: "_", with: "-"))
                        .font(.reading(m.s(150)))
                        .foregroundStyle(Theme.skyTop)
                        .frame(minWidth: m.s(220), minHeight: m.s(200))
                        .padding(.horizontal, m.s(20))
                }
                .buttonStyle(.chunky(Color(red: 1, green: 0.97, blue: 0.92), depth: m.s(16), cornerRadius: m.s(44)))
                .glow(Theme.gold, radius: 20)
                .scaleEffect(shown ? 1 : 0.2)
                .position(x: w / 2, y: h * 0.72)

                if taps > 0 {
                    Button { services.router.advance() } label: {
                        Image(systemName: "arrow.right")
                            .font(.system(size: m.s(54), weight: .black))
                            .foregroundStyle(.white)
                            .frame(width: m.s(170), height: m.s(110))
                    }
                    .buttonStyle(.chunky(Theme.gold, depth: m.s(10), cornerRadius: m.s(40)))
                    .position(x: w - m.s(140), y: h - m.s(110))
                    .transition(.scale.combined(with: .opacity))
                }

                VStack {
                    HStack {
                        BubbleIconButton(systemName: "house.fill", color: Theme.pink) { services.router.goHome() }
                        Spacer()
                    }
                    Spacer()
                }
                .padding(m.s(24))
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: shown)
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: taps)
        }
        .toolbar(.hidden, for: .navigationBar)
        .adaptiveMetrics()
        .task {
            await services.phonemes.prepare([grapheme])
            services.progress.markIntroduced(grapheme)
            try? await Task.sleep(for: .seconds(0.6))
            shown = true
            if let clip = NewThing.clipName(for: grapheme) {
                services.mascot.play(take: clip, as: .read)
                // the clip carries the Star Voice's story; give it room
                try? await Task.sleep(for: .seconds(8.5))
            }
            await services.voice.say("Tap it and say the sound!")
            #if DEBUG
            if Autopilot.enabled {
                taps += 1
                await services.phonemes.tap(grapheme, holdFor: 0.8)
                try? await Task.sleep(for: .seconds(2))
                services.router.advance()
            }
            #endif
        }
    }
}

enum NewThing {
    /// `new_thing_<g>` clip for a grapheme, if the art pack has one.
    static func clipName(for grapheme: String) -> String? {
        let key = grapheme.hasSuffix("_e") ? "magic_e" : grapheme
        let name = "new_thing_\(key)"
        return MascotClip.clipURL(name) != nil ? name : nil
    }
}
