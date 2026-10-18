import SwiftUI

/// Stretchy Blend: a glowing rainbow slide with the word's sound tiles on it.
/// Drag Cutisie along it; each tile sings its sound for as long as she's on it.
struct StretchyBlendView: View {
    @Environment(AppServices.self) private var services
    @State private var model: StretchyBlendModel?

    var body: some View {
        ZStack {
            Color.clear
            if let model {
                StretchyBlendBoard(model: model)
            }
        }
        .task {
            let m = StretchyBlendModel(services: services)
            model = m
            await m.start()
        }
        .onDisappear { model?.stop() }
    }
}

private struct StretchyBlendBoard: View {
    @Bindable var model: StretchyBlendModel
    @Environment(AppServices.self) private var services
    @Environment(\.metrics) private var m

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let landscape = w > h
            let slideX0 = w * 0.1, slideX1 = w * 0.9
            let slideY = h * (landscape ? 0.4 : 0.38)
            let n = model.graphemes.count
            let usable = (slideX1 - slideX0) * (1 - StretchyBlendModel.pad)
            let tile = min(m.s(170), usable / CGFloat(n) - 18)

            ZStack {
                RainbowSlide(lit: model.phase == .zooming)
                    .frame(width: slideX1 - slideX0 + tile * 0.6, height: tile * 0.55)
                    .position(x: (slideX0 + slideX1) / 2, y: slideY + tile * 0.62)

                ForEach(Array(model.graphemes.enumerated()), id: \.offset) { i, g in
                    let center = StretchyBlendModel.pad + (1 - StretchyBlendModel.pad) * (CGFloat(i) + 0.5) / CGFloat(n)
                    SoundTile(grapheme: g, size: tile, lit: model.litTile == i, pulse: model.pulseTile == i,
                              bounce: model.tilesBounce, delay: Double(i) * 0.06)
                        .position(x: slideX0 + (slideX1 - slideX0) * center, y: slideY)
                }
                .id(model.index)
                .transition(.scale.combined(with: .opacity))

                SlideRider(zooming: model.phase == .zooming, size: tile * 0.95)
                    .position(x: slideX0 + (slideX1 - slideX0) * model.position, y: slideY - tile * 0.95)

                if model.phase == .zoomReady {
                    ZoomSparkle(size: tile * 0.7)
                        .position(x: slideX0, y: slideY + tile * 0.1)
                        .allowsHitTesting(false)
                }

                HStack(spacing: m.s(28)) {
                    ForEach(Array(model.cards.enumerated()), id: \.element) { i, card in
                        PictureCard(word: card, size: m.s(200),
                                    wiggle: model.wiggleCard == card ? model.wiggleCount : 0,
                                    glow: model.glowCard == card,
                                    burst: model.burstCard == card,
                                    dimmed: model.burstCard != nil && model.burstCard != card) {
                            model.pick(card)
                        }
                        .transition(.asymmetric(insertion: .scale(scale: 0.2).combined(with: .offset(y: 200)),
                                                removal: .opacity))
                        .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(Double(i) * 0.08), value: model.cards)
                    }
                }
                .position(x: w / 2, y: h * (landscape ? 0.74 : 0.68))

                if model.phase == .roundDone {
                    RoundDonePanel(onAgain: { model.playAgain() },
                                   onHome: { services.router.goHome() })
                        .position(x: w / 2, y: h * 0.7)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        // only touches on the slide band move Cutisie
                        guard abs(value.startLocation.y - slideY) < tile * 1.6 else { return }
                        model.slideChanged(to: (value.location.x - slideX0) / (slideX1 - slideX0))
                    }
                    .onEnded { value in
                        guard abs(value.startLocation.y - slideY) < tile * 1.6 else { return }
                        model.slideEnded()
                    }
            )
            .animation(.spring(response: 0.45, dampingFraction: 0.7), value: model.phase)
        }
    }
}

/// The glowing rainbow the tiles sit on.
private struct RainbowSlide: View {
    let lit: Bool
    private let bands: [Color] = [.red, .orange, .yellow, .green, .cyan, .blue, .purple]

    var body: some View {
        ZStack {
            Capsule()
                .fill(LinearGradient(colors: bands.map { $0.mix(with: .white, by: 0.35) }, startPoint: .top, endPoint: .bottom))
            Capsule()
                .fill(LinearGradient(colors: [.white.opacity(0.6), .clear], startPoint: .top, endPoint: .center))
                .padding(4)
        }
        .overlay(Capsule().stroke(.white.opacity(0.8), lineWidth: 3))
        .glow(lit ? .white : Theme.pink, radius: lit ? 26 : 14)
    }
}

/// One sound on the slide: a chunky cream tile that swells and glows while
/// its sound plays. Digraphs ("sh") get a mint tile.
private struct SoundTile: View {
    let grapheme: String
    let size: CGFloat
    let lit: Bool
    let pulse: Bool
    let bounce: Int
    let delay: Double

    var body: some View {
        let base = grapheme.count > 1 ? Theme.mint : Color(red: 1, green: 0.97, blue: 0.92)
        let face = RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
        Text(grapheme)
            .font(.reading(size * 0.62))
            .foregroundStyle(lit ? Theme.pink : Theme.skyTop)
            .frame(width: size, height: size * 1.05)
            .background {
                ZStack {
                    face.fill(base.mix(with: .black, by: 0.3)).offset(y: size * 0.08)
                    face.fill(LinearGradient(colors: [.white, base], startPoint: .top, endPoint: .bottom))
                    face.stroke(lit ? Theme.gold : .white, lineWidth: lit ? 6 : 3)
                }
            }
            .scaleEffect(lit ? 1.12 : (pulse ? 1.08 : 1))
            .glow(lit ? Theme.gold : (pulse ? Theme.pink : .clear), radius: lit ? 22 : 14)
            .keyframeAnimator(initialValue: CGFloat(0), trigger: bounce) { view, lift in
                view.offset(y: lift)
            } keyframes: { _ in
                CubicKeyframe(0, duration: delay + 0.01)
                CubicKeyframe(-30, duration: 0.15)
                SpringKeyframe(0, duration: 0.45, spring: .bouncy)
            }
            .animation(.spring(response: 0.25, dampingFraction: 0.5), value: lit)
            .animation(pulse ? .easeInOut(duration: 0.4).repeatForever() : .default, value: pulse)
    }
}

/// Cutisie riding the slide (her hover pose), tilting forward when zooming.
private struct SlideRider: View {
    let zooming: Bool
    let size: CGFloat

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Image(uiImage: MascotStill.image(zooming ? "fly" : "hover") ?? UIImage())
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .rotationEffect(.degrees(zooming ? 18 : 4 * sin(t * 2)))
                .offset(y: 5 * sin(t * 3))
                .shadow(color: Theme.aurora2.opacity(0.8), radius: 14)
        }
        .allowsHitTesting(false)
    }
}

private struct ZoomSparkle: View {
    let size: CGFloat
    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Image(systemName: "sparkles")
                .font(.system(size: size, weight: .bold))
                .foregroundStyle(LinearGradient(colors: [.white, Theme.gold], startPoint: .top, endPoint: .bottom))
                .scaleEffect(1 + 0.15 * sin(t * 6))
                .glow(Theme.gold, radius: 14)
        }
    }
}

/// A picture answer: big emoji on a chunky card. Wiggles on a miss, glows as a
/// hint, bursts on the right answer.
struct PictureCard: View {
    let word: Word
    let size: CGFloat
    let wiggle: Int
    let glow: Bool
    let burst: Bool
    let dimmed: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            WordPicture(word: word.text, emoji: word.picture, size: size * 0.8)
                .frame(width: size, height: size * 1.05)
                .scaleEffect(burst ? 1.25 : 1)
                .rotationEffect(.degrees(burst ? 8 : 0))
        }
        .buttonStyle(ChunkyButtonStyle(color: glow ? Theme.gold : .white, depth: size * 0.06,
                                       cornerRadius: size * 0.2, sound: .pick))
        .glow(glow || burst ? Theme.gold : .clear, radius: 24)
        .scaleEffect(burst ? 1.12 : 1)
        .opacity(dimmed ? 0.35 : 1)
        .keyframeAnimator(initialValue: CGFloat(0), trigger: wiggle) { view, x in
            view.offset(x: x)
        } keyframes: { _ in
            CubicKeyframe(-16, duration: 0.07)
            CubicKeyframe(14, duration: 0.09)
            CubicKeyframe(-10, duration: 0.09)
            CubicKeyframe(6, duration: 0.08)
            SpringKeyframe(0, duration: 0.2)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.45), value: burst)
        .accessibilityLabel(word.text)
    }
}

/// End of round: play again or go home; inside today's session, one big
/// arrow to the next step instead.
struct RoundDonePanel: View {
    let onAgain: () -> Void
    let onHome: () -> Void
    @Environment(Router.self) private var router
    @Environment(\.metrics) private var m

    var body: some View {
        HStack(spacing: m.s(30)) {
            if router.inSession {
                Button { router.advance() } label: {
                    Image(systemName: "arrow.right")
                        .font(.system(size: m.s(64), weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: m.s(220), height: m.s(140))
                        .symbolEffect(.bounce, options: .repeating.speed(0.5))
                }
                .buttonStyle(.chunky(Theme.gold, depth: m.s(12), cornerRadius: m.s(44)))
            } else {
                Button(action: onAgain) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: m.s(54), weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: m.s(170), height: m.s(130))
                }
                .buttonStyle(.chunky(Theme.mint, depth: m.s(12), cornerRadius: m.s(40)))
                Button(action: onHome) {
                    Image(systemName: "house.fill")
                        .font(.system(size: m.s(54), weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: m.s(170), height: m.s(130))
                }
                .buttonStyle(.chunky(Theme.lilac, depth: m.s(12), cornerRadius: m.s(40)))
            }
        }
    }
}
