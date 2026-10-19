import SwiftUI

/// Star Catch: a word rides a star drifting down the night sky; she reads it
/// and taps the cloud holding its picture. No timer, no fail: an uncaught
/// star just floats back up.
struct StarCatchView: View {
    @Environment(AppServices.self) private var services
    @State private var model: StarCatchModel?

    var body: some View {
        ZStack {
            Color.clear
            if let model { StarCatchBoard(model: model) }
        }
        .task {
            let m = StarCatchModel(services: services)
            model = m
            await m.start()
        }
        .onDisappear { model?.stop() }
    }
}

private struct StarCatchBoard: View {
    let model: StarCatchModel
    @Environment(AppServices.self) private var services
    @Environment(\.metrics) private var m
    @State private var drag: CGSize = .zero

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let landscape = w > h
            let cloudY = h * (landscape ? 0.8 : 0.76)
            let cloudW = min(m.s(260), w * 0.27)
            let cloudX = { (i: Int) -> CGFloat in w * [0.3, 0.58, 0.86][i] - (landscape ? w * 0.04 : 0) }

            ZStack {
                Constellation(filled: model.catches, total: model.total,
                              complete: model.phase == .roundDone)
                    .frame(width: min(w * 0.5, 460), height: h * 0.13)
                    .position(x: w / 2, y: h * 0.13)

                WanderingCutisie(size: m.s(130), bounds: CGSize(width: w, height: h))
                    .allowsHitTesting(false)

                ForEach(Array(model.choices.enumerated()), id: \.element) { i, choice in
                    PictureCloud(choice: choice, width: cloudW,
                                 wiggle: model.wiggleChoice == choice ? model.wiggleCount : 0,
                                 glow: model.glowChoice == choice,
                                 caught: model.caughtChoice == choice,
                                 dimmed: model.caughtChoice != nil && model.caughtChoice != choice)
                        .position(x: cloudX(i), y: cloudY)
                        .onTapGesture { model.tap(choice) }
                        .transition(.scale.combined(with: .opacity))
                }

                if model.phase == .falling || model.phase == .caught {
                    TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
                        let t = timeline.date.timeIntervalSince(model.starStart)
                        // slow ping-pong fall: no visible time pressure, never a fail
                        let fall = 0.5 - 0.5 * cos(.pi * t / 11)
                        let lane = [0.38, 0.62, 0.5, 0.45, 0.58][model.index % 5]
                        let caughtAt = model.caughtChoice.flatMap { c in model.choices.firstIndex(of: c) }
                        let x = caughtAt.map(cloudX) ?? w * lane + 20 * sin(t * 0.9)
                        let y = caughtAt != nil ? cloudY - cloudW * 0.25 : h * (0.24 + 0.3 * fall)
                        WordStar(item: model.item, lit: model.litLetter, helped: model.helpUsed,
                                 size: m.s(250), caught: caughtAt != nil)
                            .position(x: x, y: y)
                            .offset(caughtAt == nil ? drag : .zero)
                            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: caughtAt)
                            // tap for a help stretch, or drag the star into a cloud
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { v in
                                        if hypot(v.translation.width, v.translation.height) > 10 { drag = v.translation }
                                    }
                                    .onEnded { v in
                                        let moved = hypot(v.translation.width, v.translation.height)
                                        if moved <= 10 {
                                            model.tapStar()
                                        } else {
                                            let drop = CGPoint(x: x + v.translation.width, y: y + v.translation.height)
                                            if let i = model.choices.indices.first(where: {
                                                abs(cloudX($0) - drop.x) < cloudW * 0.6 && abs(cloudY - drop.y) < cloudW * 0.55
                                            }) {
                                                model.tap(model.choices[i])
                                            }
                                        }
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { drag = .zero }
                                    }
                            )
                    }
                    .id(model.index)
                    .transition(.asymmetric(insertion: .move(edge: .top).combined(with: .opacity), removal: .opacity))
                }

                if model.phase == .roundDone {
                    RoundDonePanel(onAgain: { model.playAgain() }, onHome: { services.router.goHome() })
                        .position(x: w / 2, y: h * 0.45)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: model.phase)
        }
    }
}

/// A big glowing four-point star with the word across it. Letters light up
/// during a help stretch.
private struct WordStar: View {
    let item: CatchItem
    let lit: Int?
    let helped: Bool
    let size: CGFloat
    let caught: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            ZStack {
                // trail
                Capsule()
                    .fill(LinearGradient(colors: [.clear, Theme.gold.opacity(0.5)], startPoint: .top, endPoint: .bottom))
                    .frame(width: size * 0.12, height: size * 0.9)
                    .offset(y: -size * 0.55)
                    .blur(radius: 6)
                    .opacity(caught ? 0 : 1)
                SparkleStar()
                    .fill(RadialGradient(colors: [.white, Theme.gold, Theme.peach], center: .center, startRadius: 0, endRadius: size * 0.5))
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(6 * sin(t * 1.5)))
                    .scaleEffect(helped ? 0.85 : 1 + 0.04 * sin(t * 3))
                    .glow(Theme.gold, radius: size * (helped ? 0.06 : 0.12))
                Group {
                    switch item {
                    case .word(let b):
                        HStack(spacing: 2) {
                            ForEach(Array(b.word.graphemes.enumerated()), id: \.offset) { i, g in
                                Text(g)
                                    .foregroundStyle(lit == i ? Theme.pink : Theme.skyTop)
                                    .scaleEffect(lit == i ? 1.25 : 1)
                            }
                        }
                        .font(.reading(size * 0.26))
                    case .heart:
                        Image(systemName: "heart.fill")
                            .font(.system(size: size * 0.22))
                            .foregroundStyle(Theme.pink)
                            .padding(.vertical, size * 0.02)
                    case .sentence(let s):
                        Text(s.text)
                            .font(.reading(size * 0.17))
                            .foregroundStyle(Theme.skyTop)
                            .fixedSize()
                    }
                }
                .padding(.horizontal, size * 0.08).padding(.vertical, size * 0.02)
                .background(Capsule().fill(.white.opacity(0.92)))
                .animation(.spring(response: 0.25, dampingFraction: 0.5), value: lit)
            }
            .scaleEffect(caught ? 0.45 : 1)
        }
        .accessibilityLabel("Star: \(item.text)")
    }
}

/// Four-point twinkle star.
struct SparkleStar: Shape {
    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        let inner = r * 0.32
        var p = Path()
        for i in 0..<8 {
            let angle = CGFloat(i) * .pi / 4 - .pi / 2
            let radius = i.isMultiple(of: 2) ? r : inner
            let pt = CGPoint(x: c.x + cos(angle) * radius, y: c.y + sin(angle) * radius)
            if i == 0 { p.move(to: pt) } else {
                let mid = CGFloat(i) * .pi / 4 - .pi / 2 - .pi / 8
                let ctrl = CGPoint(x: c.x + cos(mid) * inner * 0.9, y: c.y + sin(mid) * inner * 0.9)
                p.addQuadCurve(to: pt, control: ctrl)
            }
        }
        p.addQuadCurve(to: CGPoint(x: c.x, y: c.y - r),
                       control: CGPoint(x: c.x + cos(-.pi / 2 - .pi / 8) * inner * 0.9, y: c.y + sin(-.pi / 2 - .pi / 8) * inner * 0.9))
        p.closeSubpath()
        return p
    }
}

/// A puffy cloud holding a picture. Wiggles on a miss, glows as a hint,
/// bursts into its picture when the star lands in it.
private struct PictureCloud: View {
    let choice: StarCatchModel.Choice
    let width: CGFloat
    let wiggle: Int
    let glow: Bool
    let caught: Bool
    let dimmed: Bool

    var body: some View {
        ZStack {
            FluffyCloud()
                .frame(width: width * 1.25, height: width * 0.75)
            Group {
                if choice.isWordPicture {
                    WordPicture(word: choice.id, emoji: choice.display, size: width * 0.5)
                } else {
                    Text(choice.display)
                        .font(choice.isText ? .reading(width * 0.2) : .system(size: width * (choice.display.count > 1 ? 0.24 : 0.36)))
                        .foregroundStyle(Theme.skyTop)
                }
            }
                .offset(y: -width * 0.04)
                .scaleEffect(caught ? 1.5 : 1)
                .rotationEffect(.degrees(caught ? -8 : 0))
        }
        .contentShape(Rectangle())
        .glow(glow || caught ? Theme.gold : .clear, radius: 26)
        .opacity(dimmed ? 0.4 : 1)
        .keyframeAnimator(initialValue: CGFloat(0), trigger: wiggle) { view, x in
            view.offset(x: x).rotationEffect(.degrees(Double(x) * 0.4))
        } keyframes: { _ in
            CubicKeyframe(-16, duration: 0.07)
            CubicKeyframe(14, duration: 0.09)
            CubicKeyframe(-10, duration: 0.09)
            SpringKeyframe(0, duration: 0.25)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.45), value: caught)
        .accessibilityLabel(choice.id)
        .accessibilityAddTraits(.isButton)
    }
}

/// Five stars in the sky that light as she catches; lines join them and the
/// whole shape sparkles when the round is done.
private struct Constellation: View {
    let filled: Int
    let total: Int
    let complete: Bool
    private var points: [UnitPoint] {
        (0..<max(total, 1)).map { i in
            let x = total > 1 ? 0.05 + 0.9 * Double(i) / Double(total - 1) : 0.5
            return UnitPoint(x: x, y: i.isMultiple(of: 2) ? 0.68 : 0.22)
        }
    }

    var body: some View {
        GeometryReader { geo in
            let pts = points.map { CGPoint(x: $0.x * geo.size.width, y: $0.y * geo.size.height) }
            ZStack {
                Path { p in
                    guard filled > 1 else { return }
                    p.move(to: pts[0])
                    for i in 1..<min(filled, total) { p.addLine(to: pts[i]) }
                }
                .stroke(Theme.gold.opacity(0.8), style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: complete ? [] : [6, 6]))
                .glow(Theme.gold, radius: complete ? 12 : 4)
                ForEach(0..<total, id: \.self) { i in
                    Image(systemName: "star.fill")
                        .font(.system(size: i < filled ? 34 : 22))
                        .foregroundStyle(i < filled ? Theme.gold : .white.opacity(0.3))
                        .glow(i < filled ? Theme.gold : .clear, radius: 10)
                        .symbolEffect(.bounce, value: filled > i)
                        .position(pts[i])
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.5), value: filled)
    }
}

/// Cutisie fluttering around the sky trying to catch stars.
private struct WanderingCutisie: View {
    let size: CGFloat
    let bounds: CGSize

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let x = bounds.width * (0.5 + 0.38 * sin(t * 0.21))
            let y = bounds.height * (0.42 + 0.08 * sin(t * 0.53))
            let facingLeft = cos(t * 0.21) < 0
            Image(uiImage: MascotStill.image("fly") ?? UIImage())
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .scaleEffect(x: facingLeft ? -1 : 1, y: 1)
                .rotationEffect(.degrees(6 * sin(t * 2)))
                .shadow(color: Theme.aurora2.opacity(0.7), radius: 12)
                .position(x: x, y: y)
                .opacity(0.95)
        }
    }
}
