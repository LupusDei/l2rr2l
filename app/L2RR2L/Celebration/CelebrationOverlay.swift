import SwiftUI

struct CelebrationOverlay: View {
    @Environment(CelebrationCenter.self) private var center

    var body: some View {
        ZStack {
            ForEach(center.bursts) { burst in
                switch burst.kind {
                case .sparkle:
                    ConfettiBurst(start: burst.start, origins: [UnitPoint(x: 0.5, y: 0.45)], count: 70, power: 0.9)
                case .fireworks:
                    ConfettiBurst(start: burst.start,
                                  origins: [UnitPoint(x: 0.2, y: 0.6), UnitPoint(x: 0.5, y: 0.35), UnitPoint(x: 0.8, y: 0.6)],
                                  count: 90, power: 1.3)
                case .sticker(let sticker):
                    ZStack {
                        ConfettiBurst(start: burst.start, origins: [UnitPoint(x: 0.5, y: 0.5)], count: 80, power: 1.1)
                        StickerReveal(sticker: sticker)
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
}

/// Particle confetti: stars, circles and ribbons with gravity and spin.
struct ConfettiBurst: View {
    let start: Date
    let origins: [UnitPoint]
    let count: Int
    let power: CGFloat

    private struct Particle {
        let origin: UnitPoint
        let vx, vy, spin, size: CGFloat
        let color: Color
        let shape: Int
        let delay: Double
    }

    private let particles: [Particle]

    init(start: Date, origins: [UnitPoint], count: Int, power: CGFloat) {
        self.start = start
        self.origins = origins
        self.count = count
        self.power = power
        var list: [Particle] = []
        for (i, origin) in origins.enumerated() {
            for _ in 0..<count {
                let angle = CGFloat.random(in: 0...(2 * .pi))
                let speed = CGFloat.random(in: 250...900) * power
                list.append(Particle(origin: origin,
                                     vx: cos(angle) * speed,
                                     vy: sin(angle) * speed - 350 * power,
                                     spin: .random(in: -8...8),
                                     size: .random(in: 8...20),
                                     color: Theme.confetti.randomElement()!,
                                     shape: .random(in: 0...2),
                                     delay: Double(i) * 0.35))
            }
        }
        particles = list
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            let elapsed = timeline.date.timeIntervalSince(start)
            Canvas { ctx, size in
                let star = ctx.resolveSymbol(id: 0)
                for p in particles {
                    let t = CGFloat(elapsed - p.delay)
                    guard t > 0 else { continue }
                    let drag: CGFloat = 1.6
                    let decay = (1 - exp(-drag * t)) / drag
                    let x = p.origin.x * size.width + p.vx * decay
                    let y = p.origin.y * size.height + p.vy * decay + 420 * t * t
                    let alpha = max(0, 1 - t / 2.6)
                    guard alpha > 0 else { continue }
                    var c = ctx
                    c.opacity = alpha
                    c.translateBy(x: x, y: y)
                    c.rotate(by: .radians(Double(p.spin * t)))
                    let r = CGRect(x: -p.size / 2, y: -p.size / 2, width: p.size, height: p.size)
                    switch p.shape {
                    case 0:
                        if let star {
                            c.addFilter(.colorMultiply(p.color))
                            c.draw(star, in: r)
                        }
                    case 1:
                        c.fill(Path(ellipseIn: r), with: .color(p.color))
                    default:
                        c.fill(Path(roundedRect: r.insetBy(dx: 0, dy: p.size * 0.3), cornerRadius: 2), with: .color(p.color))
                    }
                }
            } symbols: {
                Image(systemName: "star.fill").foregroundStyle(.white).tag(0)
            }
        }
    }
}

private struct StickerReveal: View {
    let sticker: Sticker
    @State private var shown = false

    var body: some View {
        VStack(spacing: 8) {
            WordPicture(word: sticker.word, emoji: sticker.emoji, size: 200)
            Text(sticker.name)
                .font(.playful(40))
                .foregroundStyle(.white)
                .glow(Theme.gold, radius: 8)
        }
        .padding(40)
        .background(Circle().fill(Theme.skyBottom.opacity(0.85)).glow(Theme.gold, radius: 30))
        .scaleEffect(shown ? 1 : 0.2)
        .rotationEffect(.degrees(shown ? 0 : -30))
        .opacity(shown ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.55)) { shown = true }
            withAnimation(.easeIn(duration: 0.4).delay(2.4)) { shown = false }
        }
    }
}
