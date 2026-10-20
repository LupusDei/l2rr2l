import SwiftUI

/// The living night sky every screen sits in. Layers, back to front, each
/// moving with its own depth as the iPad tilts (see `ParallaxMotion`):
/// aurora mesh, far stars, crescent moon, twinkling near stars, shooting stars,
/// rising sparkles, and soft cloud banks along the bottom.
struct SkyBackground: View {
    var tint: Color = Theme.aurora1
    var imageName: String? = nil
    var showsClouds = true

    @Environment(ParallaxMotion.self) private var motion

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let p = motion.offset
                let painted = imageName.flatMap(SkyBackground.painting)
                ZStack {
                    if let painted {
                        // painted scene from the art pack, slightly oversized so it can drift
                        Image(uiImage: painted).resizable().scaledToFill()
                            .frame(width: size.width, height: size.height)
                            .scaleEffect(1.08)
                            .offset(x: p.width * 12, y: p.height * 12)
                            .clipped()
                    } else {
                        AuroraMesh(t: t, tint: tint)
                            .scaleEffect(1.15)
                            .offset(x: p.width * 8, y: p.height * 8)
                    }

                    StarField(t: t, layer: .far)
                        .offset(x: p.width * 14, y: p.height * 14)

                    if painted == nil {
                    Moon()
                        .frame(width: size.width * 0.14, height: size.width * 0.14)
                        .position(x: size.width * 0.12, y: size.height * 0.2)
                        .offset(x: p.width * 20, y: p.height * 20)
                    }

                    StarField(t: t, layer: .near)
                        .offset(x: p.width * 30, y: p.height * 30)

                    ShootingStars(t: t)

                    RisingSparkles(t: t)
                        .offset(x: p.width * 45, y: p.height * 45)

                    if showsClouds && painted == nil {
                        CloudBank(t: t, color: Theme.lilac.opacity(0.35), height: 0.30, phase: 0)
                            .offset(x: p.width * 50, y: p.height * 20)
                        CloudBank(t: t, color: Theme.pink.opacity(0.28), height: 0.22, phase: 2)
                            .offset(x: p.width * 70, y: p.height * 28)
                        CloudBank(t: t, color: Color.white.opacity(0.18), height: 0.14, phase: 4)
                            .offset(x: p.width * 95, y: p.height * 36)
                    }
                }
                .frame(width: size.width, height: size.height)
                .drawingGroup()
            }
        }
        .ignoresSafeArea()
    }
}

extension SkyBackground {
    private static var cache: [String: UIImage] = [:]

    /// Background paintings live in `Media/backgrounds/<name>.jpg`.
    static func painting(_ name: String) -> UIImage? {
        if let hit = cache[name] { return hit }
        guard let path = Bundle.main.path(forResource: name, ofType: "jpg", inDirectory: "Media/backgrounds"),
              let image = UIImage(contentsOfFile: path) else { return nil }
        cache[name] = image
        return image
    }
}

/// Slowly breathing aurora from a 3x3 mesh gradient.
private struct AuroraMesh: View {
    let t: Double
    let tint: Color

    var body: some View {
        let w1 = Float(sin(t * 0.21) * 0.18)
        let w2 = Float(cos(t * 0.17) * 0.16)
        let w3 = Float(sin(t * 0.13 + 1) * 0.2)
        if #available(iOS 18.0, *) {
            mesh(w1, w2, w3)
        } else {
            // iOS 17: a vertical sky with two drifting glows standing in for the mesh
            GeometryReader { g in
                ZStack {
                    LinearGradient(colors: [Theme.skyTop, Theme.aurora2.mixed(with: Theme.skyTop, by: 0.6), Theme.skyBottom],
                                   startPoint: .top, endPoint: .bottom)
                    RadialGradient(colors: [tint.mixed(with: Theme.skyTop, by: 0.45), .clear], center: .center,
                                   startRadius: 0, endRadius: g.size.width * 0.6)
                        .offset(x: g.size.width * CGFloat(w1), y: -g.size.height * 0.3)
                    RadialGradient(colors: [Theme.aurora3.mixed(with: Theme.skyTop, by: 0.5), .clear], center: .center,
                                   startRadius: 0, endRadius: g.size.width * 0.5)
                        .offset(x: g.size.width * CGFloat(w3), y: g.size.height * CGFloat(0.05 + w2))
                }
            }
        }
    }

    @available(iOS 18.0, *)
    private func mesh(_ w1: Float, _ w2: Float, _ w3: Float) -> some View {
        MeshGradient(width: 3, height: 3, points: [
            [0, 0], [0.5 + w1 * 0.5, 0], [1, 0],
            [0, 0.45 + w2], [0.5 + w3, 0.5 + w1], [1, 0.4 - w2],
            [0, 1], [0.5 - w1 * 0.5, 1], [1, 1],
        ], colors: [
            Theme.skyTop, tint.mixed(with: Theme.skyTop, by: 0.55), Theme.skyTop,
            Theme.aurora2.mixed(with: Theme.skyTop, by: 0.6), tint.mixed(with: Theme.skyBottom, by: 0.35), Theme.aurora3.mixed(with: Theme.skyTop, by: 0.6),
            Theme.skyBottom, Theme.skyBottom.mixed(with: Theme.aurora3, by: 0.2), Theme.skyBottom,
        ])
    }
}

private struct StarField: View {
    enum Layer { case far, near }
    let t: Double
    let layer: Layer

    private static let far = makeStars(count: 160, seed: 3, size: 0.4...1.3)
    private static let near = makeStars(count: 45, seed: 11, size: 1.2...2.8)

    private static func makeStars(count: Int, seed: UInt64, size: ClosedRange<CGFloat>) -> [(CGPoint, CGFloat, Double)] {
        var rng = SeededRandom(seed: seed)
        return (0..<count).map { _ in
            (CGPoint(x: rng.next() * 1.1 - 0.05, y: rng.next() * 0.9),
             size.lowerBound + rng.next() * (size.upperBound - size.lowerBound),
             Double(rng.next()) * .pi * 2)
        }
    }

    var body: some View {
        Canvas { ctx, size in
            let stars = layer == .far ? Self.far : Self.near
            for (p, r, phase) in stars {
                let speed = layer == .far ? 0.9 : 2.2
                let twinkle = 0.35 + 0.65 * (0.5 + 0.5 * sin(t * speed + phase))
                let c = CGPoint(x: p.x * size.width, y: p.y * size.height)
                ctx.fill(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)),
                         with: .color(.white.opacity(twinkle)))
                if layer == .near && r > 2.2 {
                    // little four-point glint on the brightest stars
                    let g = r * 3 * twinkle
                    var cross = Path()
                    cross.move(to: CGPoint(x: c.x - g, y: c.y)); cross.addLine(to: CGPoint(x: c.x + g, y: c.y))
                    cross.move(to: CGPoint(x: c.x, y: c.y - g)); cross.addLine(to: CGPoint(x: c.x, y: c.y + g))
                    ctx.stroke(cross, with: .color(.white.opacity(0.5 * twinkle)), lineWidth: 1)
                }
            }
        }
    }
}

private struct Moon: View {
    var body: some View {
        Canvas { ctx, size in
            let r = min(size.width, size.height) / 2
            let disc = Path(ellipseIn: CGRect(x: size.width / 2 - r, y: size.height / 2 - r, width: r * 2, height: r * 2))
            let bite = Path(ellipseIn: CGRect(x: size.width / 2 - r * 0.62, y: size.height / 2 - r * 1.12, width: r * 1.9, height: r * 1.9))
            let crescent = disc.subtracting(bite)
            ctx.drawLayer { layer in
                layer.addFilter(.shadow(color: Color(red: 1, green: 0.88, blue: 0.6).opacity(0.9), radius: r * 0.5))
                layer.fill(crescent, with: .linearGradient(Gradient(colors: [Color(red: 1, green: 0.98, blue: 0.88), Color(red: 1, green: 0.85, blue: 0.6)]),
                                                           startPoint: .zero, endPoint: CGPoint(x: size.width, y: size.height)))
            }
        }
        .rotationEffect(.degrees(-20))
    }
}

private struct ShootingStars: View {
    let t: Double

    var body: some View {
        Canvas { ctx, size in
            let period = 7.0
            for lane in 0..<2 {
                let local = (t + Double(lane) * 3.7).truncatingRemainder(dividingBy: period)
                let cycle = Int((t + Double(lane) * 3.7) / period)
                guard local < 1.1 else { continue }
                var rng = SeededRandom(seed: UInt64(cycle * 7 + lane + 1))
                let start = CGPoint(x: size.width * (0.3 + rng.next() * 0.7), y: size.height * (0.03 + rng.next() * 0.25))
                let progress = local / 1.1
                let dx = -size.width * 0.35 * progress
                let dy = size.height * 0.18 * progress
                let head = CGPoint(x: start.x + dx, y: start.y + dy)
                let tail = CGPoint(x: head.x + size.width * 0.08, y: head.y - size.height * 0.04)
                let fade = sin(.pi * progress)
                var path = Path()
                path.move(to: tail); path.addLine(to: head)
                ctx.stroke(path, with: .linearGradient(Gradient(colors: [.clear, .white.opacity(fade)]),
                                                       startPoint: tail, endPoint: head),
                           style: StrokeStyle(lineWidth: 3, lineCap: .round))
                ctx.fill(Path(ellipseIn: CGRect(x: head.x - 3, y: head.y - 3, width: 6, height: 6)),
                         with: .color(.white.opacity(fade)))
            }
        }
    }
}

/// Soft glowing motes drifting upward, like the sky is breathing magic.
private struct RisingSparkles: View {
    let t: Double
    private static let motes: [(x: CGFloat, speed: Double, size: CGFloat, phase: Double, color: Int)] = {
        var rng = SeededRandom(seed: 21)
        return (0..<36).map { i in (rng.next(), 0.02 + Double(rng.next()) * 0.05, 2 + rng.next() * 4, Double(rng.next()), i % 5) }
    }()

    var body: some View {
        Canvas { ctx, size in
            ctx.addFilter(.blur(radius: 1.2))
            for m in Self.motes {
                let y = 1.1 - (t * m.speed + m.phase).truncatingRemainder(dividingBy: 1.2)
                let x = m.x + 0.03 * CGFloat(sin(t * 0.8 + m.phase * 10))
                let p = CGPoint(x: x * size.width, y: y * size.height)
                let alpha = min(1, max(0, (1.1 - y) * 2)) * min(1, max(0, y * 3))
                let color = [Theme.gold, Theme.pink, Theme.mint, Theme.sky, Color.white][m.color]
                ctx.fill(Path(ellipseIn: CGRect(x: p.x - m.size, y: p.y - m.size, width: m.size * 2, height: m.size * 2)),
                         with: .color(color.opacity(0.8 * alpha)))
            }
        }
    }
}

/// A row of puffy cloud tops along the bottom edge, gently drifting.
struct CloudBank: View {
    let t: Double
    let color: Color
    let height: CGFloat
    let phase: Double

    var body: some View {
        Canvas { ctx, size in
            let baseY = size.height * (1 - height)
            var path = Path()
            path.move(to: CGPoint(x: -100, y: size.height))
            let puffs = 9
            let drift = CGFloat(sin(t * 0.05 + phase)) * 40
            for i in 0...puffs {
                let x = CGFloat(i) / CGFloat(puffs) * (size.width + 200) - 100 + drift
                let r = size.height * height * (0.35 + 0.15 * CGFloat(sin(Double(i) * 1.7 + phase)))
                path.addEllipse(in: CGRect(x: x - r, y: baseY - r * 0.5, width: r * 2, height: r * 2))
            }
            path.addRect(CGRect(x: -100, y: baseY + size.height * height * 0.2, width: size.width + 200, height: size.height))
            ctx.fill(path, with: .linearGradient(Gradient(colors: [color, color.opacity(0.6)]),
                                                 startPoint: CGPoint(x: 0, y: baseY - 80),
                                                 endPoint: CGPoint(x: 0, y: size.height)))
        }
        .blur(radius: 2)
    }
}

/// Tiny deterministic RNG so the star field is the same every launch.
struct SeededRandom {
    private var state: UInt64
    init(seed: UInt64) { state = (seed &+ 1) &* 0x9E3779B97F4A7C15 }
    mutating func next() -> CGFloat {
        state ^= state << 13; state ^= state >> 7; state ^= state << 17
        return CGFloat(state % 10_000) / 10_000
    }
}

#Preview {
    SkyBackground().environment(ParallaxMotion())
}
