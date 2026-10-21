import SwiftUI

/// What the story stage shows right now.
enum StageShow: Equatable {
    case empty
    /// Things whose words are in the sentence so far, floating, not yet arranged.
    case loose([String])
    /// The scene a sentence makes, arranged and acting.
    case full(StoryScene)
}

/// The little theatre where sentences come true. Things are the art pack's
/// transparent word pictures, arranged from the sentence: the cat sits *on*
/// the mat, the pig peeks out *of* the pot, the hen *has* a hat on her head.
/// A bigger thing on a smaller one squashes it, which is where the giggles
/// come from. Behind it, the dream: the same kind of scene, ghostly, showing
/// what her words should make.
struct StoryStage: View {
    let show: StageShow
    var dream: StoryScene? = nil
    /// Bumped on a right answer: a sparkle ring bursts from the scene.
    var celebrate = 0
    let size: CGSize

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            ZStack {
                if let dream {
                    SceneLayer(placed: StageLayout.full(dream, in: size), scene: dream, t: t, ghost: true)
                        .transition(.opacity)
                }
                SceneLayer(placed: placed, scene: scene, t: t, ghost: false)
            }
            .frame(width: size.width, height: size.height)
        }
        .background { StageCard(dreaming: dream != nil) }
        .overlay { CelebrateRing(trigger: celebrate) }
        .animation(.spring(response: 0.55, dampingFraction: 0.62), value: show)
        .animation(.easeInOut(duration: 0.5), value: dream)
        .accessibilityElement()
        .accessibilityLabel("story picture")
    }

    private var scene: StoryScene? {
        if case .full(let s) = show { return s }
        return nil
    }

    private var placed: [Placed] {
        switch show {
        case .empty: []
        case .loose(let words): StageLayout.loose(words, in: size)
        case .full(let s): StageLayout.full(s, in: size)
        }
    }
}

// MARK: - Layout

/// One thing on the stage: its square picture frame, and how it sits.
struct Placed: Identifiable, Equatable {
    let word: String
    var center: CGPoint
    var side: CGFloat
    /// Pressed flat by something too big on top of it.
    var squashed = false
    /// Draw only the part below this local y (the front of a pot something is in).
    var clipTop: CGFloat? = nil
    var z: Double = 0
    var id: String { clipTop == nil ? word : word + "-front" }
}

enum StageLayout {
    static let creatures: Set<String> = [
        "cat", "dog", "pig", "man", "dad", "kid", "hen", "bug", "fox", "pup", "duck", "rat", "yak", "fish",
        "chick", "moth", "frog", "crab", "snake", "bee", "goat", "owl", "bat", "ram", "cub", "cow", "horse",
        "bird", "girl", "boy", "sheep", "shark", "snail", "rabbit", "kitten", "hen", "ox", "toy",
    ]
    static let wearables: Set<String> = ["hat", "cap", "wig", "cape"]

    /// How big a thing is next to others (1 = a cat).
    static func scale(_ word: String) -> CGFloat {
        switch word {
        case "bug", "pin", "nut", "egg", "gum", "coin", "ring", "chip", "bee", "moth", "plum", "leaf", "shell",
             "star", "bell", "lip", "fin", "bun", "jam", "gift", "bone", "cube", "zip": 0.45
        case "cup", "mug", "can", "tin", "cap", "hat", "wig", "pot", "pan", "sock", "chick", "rat", "fish",
             "dish", "frog", "crab", "bag", "kite", "cake", "drum", "map", "jug", "lid", "top", "kit", "mop",
             "pit", "hen", "duck", "cape", "sink", "bib": 0.65
        case "bed", "bus", "ship", "shed", "tree", "boat", "plane", "hill", "lake", "van", "jet", "tent",
             "cow", "horse", "yak", "gate", "bike", "house", "home", "train", "cloud", "moon", "sun", "sand",
             "bath", "tub", "slide", "sled": 1.25
        default: 1
        }
    }

    private static func base(_ size: CGSize) -> CGFloat { min(size.height * 0.62, size.width * 0.42) }
    private static func ground(_ size: CGSize) -> CGFloat { size.height * 0.9 }

    /// Words placed so far, floating in a row while the sentence is built.
    static func loose(_ words: [String], in size: CGSize) -> [Placed] {
        let n = CGFloat(max(words.count, 1))
        let side = min(base(size) * 0.7, size.width * 0.8 / n)
        return words.enumerated().map { i, w in
            Placed(word: w, center: CGPoint(x: size.width * (CGFloat(i) + 0.5) / n, y: size.height * 0.5), side: side)
        }
    }

    /// The scene arranged: positions in the stage's own coordinates.
    static func full(_ scene: StoryScene, in size: CGSize) -> [Placed] {
        let base = base(size), g = ground(size), mid = size.width / 2
        func side(_ w: String) -> CGFloat {
            base * scale(w) * (scene.look == "big" && w == scene.a ? 1.4 : 1)
        }
        var out: [Placed] = []
        let a = scene.a
        guard let b = scene.b, let rel = scene.rel else {
            out.append(stand(a, side: side(a), x: mid, bottom: g))
            return fit(out, in: size)
        }
        switch rel {
        case "and":
            out.append(stand(a, side: side(a), x: size.width * 0.32, bottom: g))
            out.append(stand(b, side: side(b), x: size.width * 0.68, bottom: g))
        case "has":
            if wearables.contains(b) || !creatures.contains(a) {
                out += onTop(b, of: a, sideTop: side(b), sideBottom: side(a), x: mid, ground: g)
            } else {
                let holder = stand(a, side: side(a), x: mid - side(a) * 0.12, bottom: g)
                let r = opaque(holder)
                var held = stand(b, side: min(side(b), side(a) * 0.55), x: r.maxX - r.width * 0.05, bottom: g)
                held.z = 1
                out += [holder, held]
            }
        case "in":
            let container = stand(b, side: side(b), x: mid, bottom: g)
            if scale(a) <= scale(b) * 1.1 {
                let r = opaque(container)
                var inside = stand(a, side: min(side(a), side(b) * 0.7), x: r.midX, bottom: r.minY + r.height * 0.62)
                inside.z = 1
                var front = container
                front.clipTop = r.minY + r.height * 0.4 - (container.center.y - container.side / 2)
                front.z = 2
                out += [container, inside, front]
            } else {
                // too big to fit: it just sits on top, squashing
                out += onTop(a, of: b, sideTop: side(a), sideBottom: side(b), x: mid, ground: g)
            }
        default: // "on"
            out += onTop(a, of: b, sideTop: side(a), sideBottom: side(b), x: mid, ground: g)
        }
        return fit(out, in: size)
    }

    /// `top` resting on `bottom`: hats go on heads, things on flat things sink in a little.
    private static func onTop(_ top: String, of bottom: String, sideTop: CGFloat, sideBottom: CGFloat,
                              x: CGFloat, ground: CGFloat) -> [Placed] {
        var under = stand(bottom, side: sideBottom, x: x, bottom: ground)
        let r = opaque(under)
        var over: Placed
        if wearables.contains(top) && creatures.contains(bottom) {
            let info = PictureShape.info(bottom)
            let headX = under.center.x - under.side / 2 + info.headX * under.side
            over = stand(top, side: sideBottom * 0.5, x: headX, bottom: r.minY + r.height * 0.16)
        } else {
            let flat = r.height / max(r.width, 1) < 0.55
            over = stand(top, side: sideTop * 0.9, x: r.midX, bottom: r.minY + r.height * (flat ? 0.5 : 0.14))
            // too big, or a thing plonked on an animal: squash (the silly sentences)
            if scale(top) > scale(bottom) * 1.15 || (creatures.contains(bottom) && !creatures.contains(top)) {
                under.squashed = true
            }
        }
        over.z = 1
        return [under, over]
    }

    /// A thing standing with its picture's bottom edge at `bottom`, centred on `x`.
    static func stand(_ word: String, side: CGFloat, x: CGFloat, bottom: CGFloat) -> Placed {
        let box = PictureShape.info(word).box
        return Placed(word: word,
                      center: CGPoint(x: x - (box.midX - 0.5) * side, y: bottom - (box.maxY - 0.5) * side),
                      side: side)
    }

    /// The drawn part of a placed picture, in stage coordinates.
    static func opaque(_ p: Placed) -> CGRect {
        let box = PictureShape.info(p.word).box
        return CGRect(x: p.center.x - p.side / 2 + box.minX * p.side, y: p.center.y - p.side / 2 + box.minY * p.side,
                      width: box.width * p.side, height: box.height * p.side)
    }

    /// Shrinks the whole scene about the ground's middle so it fits the stage.
    private static func fit(_ items: [Placed], in size: CGSize) -> [Placed] {
        guard let first = items.first else { return items }
        let bounds = items.dropFirst().reduce(opaque(first)) { $0.union(opaque($1)) }
        let k = min(1, size.width * 0.9 / bounds.width, size.height * 0.86 / bounds.height)
        let anchor = CGPoint(x: size.width / 2, y: ground(size))
        // and centre it sideways
        let dx = size.width / 2 - bounds.midX
        return items.map { p in
            var q = p
            q.center = CGPoint(x: anchor.x + (p.center.x + dx - anchor.x) * k, y: anchor.y + (p.center.y - anchor.y) * k)
            q.side = p.side * k
            q.clipTop = p.clipTop.map { $0 * k }
            return q
        }
    }
}

/// Where a word picture's drawing actually is inside its square, so things
/// can stand on each other: the opaque box, and where the top (the head) is.
enum PictureShape {
    struct Info { let box: CGRect; let headX: CGFloat }
    private static var cache: [String: Info] = [:]
    static let whole = Info(box: CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8), headX: 0.5)

    static func info(_ word: String) -> Info {
        if let hit = cache[word] { return hit }
        let info = WordPicture.card(word).flatMap(measure) ?? whole
        cache[word] = info
        return info
    }

    private static func measure(_ image: UIImage) -> Info? {
        guard let cg = image.cgImage else { return nil }
        let n = 64
        var pixels = [UInt8](repeating: 0, count: n * n * 4)
        guard let ctx = CGContext(data: &pixels, width: n, height: n, bitsPerComponent: 8, bytesPerRow: n * 4,
                                  space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: n, height: n))
        var minX = n, minY = n, maxX = -1, maxY = -1
        // rows come out top-first in memory
        for y in 0..<n { for x in 0..<n where pixels[(y * n + x) * 4 + 3] > 40 {
            minX = min(minX, x); maxX = max(maxX, x); minY = min(minY, y); maxY = max(maxY, y)
        } }
        guard maxX >= minX, maxY >= minY else { return nil }
        let headRows = minY...min(maxY, minY + max(2, (maxY - minY) / 5))
        var sum = 0, count = 0
        for y in headRows { for x in 0..<n where pixels[(y * n + x) * 4 + 3] > 40 { sum += x; count += 1 } }
        let f = CGFloat(n)
        return Info(box: CGRect(x: CGFloat(minX) / f, y: CGFloat(minY) / f,
                                width: CGFloat(maxX - minX + 1) / f, height: CGFloat(maxY - minY + 1) / f),
                    headX: count > 0 ? (CGFloat(sum) / CGFloat(count) + 0.5) / f : 0.5)
    }
}

// MARK: - Drawing

private struct SceneLayer: View {
    let placed: [Placed]
    let scene: StoryScene?
    let t: Double
    let ghost: Bool

    var body: some View {
        ZStack {
            ForEach(placed) { p in
                ThingView(placed: p, act: acting(p.word) ? scene?.act : nil,
                          look: acting(p.word) ? scene?.look : nil, t: t)
                    .frame(width: p.side, height: p.side)
                    .position(p.center)
                    .zIndex(p.z)
                    .transition(.scale(scale: 0.2).combined(with: .opacity))
            }
        }
        .modifier(GhostStyle(on: ghost, t: t))
        .allowsHitTesting(false)
    }

    /// Doing words and looks belong to who the sentence is about (both, for "and").
    private func acting(_ word: String) -> Bool {
        guard let scene else { return false }
        return word == scene.a || (scene.rel == "and" && word == scene.b)
    }
}

private struct GhostStyle: ViewModifier {
    let on: Bool
    let t: Double
    func body(content: Content) -> some View {
        if on {
            content
                .saturation(0)
                .brightness(0.18)
                .opacity(0.46 + 0.07 * sin(t * 2))
                .blur(radius: 1)
        } else {
            content
        }
    }
}

/// One picture, alive: idle breathing plus whatever the sentence says it does.
private struct ThingView: View {
    let placed: Placed
    let act: String?
    let look: String?
    let t: Double

    var body: some View {
        let s = placed.side
        let phase = Double(placed.word.unicodeScalars.reduce(0) { $0 + Int($1.value) } % 7)
        let m = motion(t: t + phase, side: s)
        picture
            .colorMultiply(tint)
            .scaleEffect(x: m.flip * (placed.squashed ? 1.18 + 0.04 * sin(t * 9) : 1) * m.sx,
                         y: (placed.squashed ? 0.68 + 0.04 * sin(t * 9) : 1) * m.sy, anchor: .bottom)
            .rotationEffect(.degrees(m.angle), anchor: .bottom)
            .offset(x: m.dx, y: m.dy)
            .shadow(color: look == "hot" ? Theme.peach.opacity(0.9) : .clear, radius: s * 0.08)
            .overlay { Effects(act: act, look: look, t: t + phase, side: s).offset(x: m.dx, y: m.dy) }
    }

    @ViewBuilder private var picture: some View {
        if let top = placed.clipTop {
            WordPicture(word: placed.word, size: placed.side)
                .mask(alignment: .top) { Rectangle().padding(.top, max(0, top)) }
        } else {
            WordPicture(word: placed.word, size: placed.side)
        }
    }

    private var tint: Color {
        switch look {
        case "red": Color(red: 1, green: 0.45, blue: 0.45)
        case "sad": Color(red: 0.72, green: 0.8, blue: 1)
        case "mad": Color(red: 1, green: 0.62 + 0.15 * sin(t * 10), blue: 0.6)
        case "hot": Color(red: 1, green: 0.85, blue: 0.7)
        default: .white
        }
    }

    private struct Motion { var dx = 0.0, dy = 0.0, angle = 0.0, sx = 1.0, sy = 1.0, flip = 1.0 }

    private func motion(t: Double, side s: CGFloat) -> Motion {
        var m = Motion()
        let breathe = 1 + 0.02 * sin(t * 2.2)
        m.sx = breathe; m.sy = 2 - breathe
        switch act {
        case "nap":
            m.angle = -9; m.sy = 1 + 0.035 * sin(t * 1.6)
        case "sit":
            m.sy = 0.93; m.sx = 1.04
        case "dig":
            m.angle = 7 * sin(t * 14); m.dy = 2 * abs(sin(t * 14))
        case "sip":
            m.angle = -6 + 3 * sin(t * 3)
        case "hop", "jump":
            let hop = abs(sin(t * (act == "jump" ? 3.2 : 4.2)))
            m.dy = -hop * s * (act == "jump" ? 0.4 : 0.22)
            if hop < 0.15 { m.sx = 1.12; m.sy = 0.86 }
        case "run":
            m.dx = sin(t * 1.4) * s * 0.55
            m.flip = cos(t * 1.4) >= 0 ? 1 : -1
            m.dy = -abs(sin(t * 12)) * s * 0.04
            m.angle = 4 * m.flip
        case "sing":
            m.angle = 8 * sin(t * 3)
        case "swim":
            m.dy = sin(t * 2.5) * s * 0.05; m.angle = 6 * sin(t * 2.5)
        case "clap":
            let p = 1 + 0.07 * abs(sin(t * 7)); m.sx = p; m.sy = p
        default: break
        }
        if look == "mad" { m.dx += 3 * sin(t * 40) }
        if look == "big" { m.sx *= 1 + 0.03 * sin(t * 3); m.sy *= 1 + 0.03 * sin(t * 3) }
        return m
    }
}

/// Little drawn extras for doing words and looks: z's, music notes, rain, dirt, steam.
private struct Effects: View {
    let act: String?
    let look: String?
    let t: Double
    let side: CGFloat

    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            func float(_ symbol: String, count: Int, color: Color, from: CGPoint, rise: CGFloat, drift: CGFloat, font: CGFloat) {
                for i in 0..<count {
                    let p = (t * 0.5 + Double(i) / Double(count)).truncatingRemainder(dividingBy: 1)
                    let pt = CGPoint(x: from.x + drift * CGFloat(p) + 6 * CGFloat(sin(p * 9 + Double(i))),
                                     y: from.y - rise * CGFloat(p))
                    var c = ctx
                    c.opacity = 1 - p
                    c.draw(Text(symbol).font(.system(size: font * (0.7 + 0.5 * CGFloat(p)), weight: .black, design: .rounded))
                        .foregroundStyle(color), at: pt)
                }
            }
            switch act {
            case "nap":
                float("z", count: 3, color: .white, from: CGPoint(x: w * 0.7, y: h * 0.3), rise: h * 0.4, drift: w * 0.2, font: side * 0.12)
            case "sing":
                float("♪", count: 2, color: Theme.pink, from: CGPoint(x: w * 0.7, y: h * 0.35), rise: h * 0.45, drift: w * 0.15, font: side * 0.14)
                float("♫", count: 2, color: Theme.gold, from: CGPoint(x: w * 0.3, y: h * 0.4), rise: h * 0.45, drift: -w * 0.15, font: side * 0.13)
            case "dig":
                for i in 0..<8 {
                    let p = (t * 1.6 + Double(i) / 8).truncatingRemainder(dividingBy: 1)
                    let dir: CGFloat = i % 2 == 0 ? -1 : 1
                    let pt = CGPoint(x: w * 0.5 + dir * w * 0.35 * CGFloat(p), y: h * 0.95 - h * 0.4 * CGFloat(sin(p * .pi)))
                    let r = side * 0.025
                    ctx.fill(Path(ellipseIn: CGRect(x: pt.x - r, y: pt.y - r, width: r * 2, height: r * 2)),
                             with: .color(Color(red: 0.55, green: 0.36, blue: 0.2).opacity(1 - p * 0.5)))
                }
            case "sip":
                float("o", count: 3, color: Theme.sky, from: CGPoint(x: w * 0.5, y: h * 0.35), rise: h * 0.3, drift: 0, font: side * 0.07)
            case "run":
                float("💨", count: 2, color: .white, from: CGPoint(x: w * 0.5, y: h * 0.9), rise: h * 0.1, drift: 0, font: side * 0.1)
            case "swim":
                for k in 0..<2 {
                    var wave = Path()
                    let y = h * (0.82 + 0.08 * CGFloat(k))
                    wave.move(to: CGPoint(x: 0, y: y))
                    for x in stride(from: 0, through: w, by: 6) {
                        wave.addLine(to: CGPoint(x: x, y: y + 5 * CGFloat(sin(Double(x) / 14 + t * 4 + Double(k)))))
                    }
                    ctx.stroke(wave, with: .color(Theme.sky.opacity(0.85)), lineWidth: 4)
                }
            case "clap", "hop", "jump":
                float("✦", count: 2, color: Theme.gold, from: CGPoint(x: w * 0.5, y: h * 0.25), rise: h * 0.2, drift: w * 0.2, font: side * 0.1)
            default: break
            }
            switch look {
            case "sad":
                let cloud = CGRect(x: w * 0.3, y: h * 0.0, width: w * 0.4, height: h * 0.14)
                ctx.fill(Path(roundedRect: cloud, cornerRadius: cloud.height / 2), with: .color(Color(white: 0.75)))
                for i in 0..<5 {
                    let p = (t * 1.2 + Double(i) / 5).truncatingRemainder(dividingBy: 1)
                    let x = cloud.minX + cloud.width * (0.15 + 0.18 * CGFloat(i))
                    let y = cloud.maxY + h * 0.3 * CGFloat(p)
                    ctx.fill(Path(ellipseIn: CGRect(x: x - 3, y: y, width: 6, height: 11)), with: .color(Theme.sky.opacity(1 - p)))
                }
            case "hot":
                for k in 0..<3 {
                    var heat = Path()
                    let x0 = w * (0.3 + 0.2 * CGFloat(k))
                    heat.move(to: CGPoint(x: x0, y: h * 0.25))
                    for y in stride(from: h * 0.25, through: h * 0.02, by: -4) {
                        heat.addLine(to: CGPoint(x: x0 + 6 * CGFloat(sin(Double(y) / 9 + t * 5 + Double(k))), y: y))
                    }
                    ctx.stroke(heat, with: .color(Theme.peach.opacity(0.8)), lineWidth: 3)
                }
            case "mad":
                float("💢", count: 1, color: .red, from: CGPoint(x: w * 0.72, y: h * 0.25), rise: h * 0.08, drift: 0, font: side * 0.13)
            default: break
            }
        }
        .allowsHitTesting(false)
    }
}

/// The glassy stage panel. While dreaming it has a dashed, twinkling edge.
private struct StageCard: View {
    let dreaming: Bool
    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous)
        ZStack {
            shape.fill(LinearGradient(colors: [Theme.skyTop.opacity(0.62), Theme.skyBottom.opacity(0.55)],
                                      startPoint: .top, endPoint: .bottom))
            // a soft floor glow where things stand
            Ellipse()
                .fill(RadialGradient(colors: [.white.opacity(0.35), .clear], center: .center, startRadius: 0, endRadius: 200))
                .scaleEffect(x: 1.6, y: 0.35)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, -30)
                .clipShape(shape)
            if dreaming {
                shape.stroke(.white.opacity(0.75), style: StrokeStyle(lineWidth: 4, dash: [4, 14], dashPhase: 0))
            } else {
                shape.stroke(Theme.gold.opacity(0.85), lineWidth: 4)
            }
        }
        .glow(dreaming ? Theme.aurora3 : Theme.gold, radius: 14)
    }
}

/// A burst of sparkles round the stage on a right answer.
private struct CelebrateRing: View {
    let trigger: Int
    @State private var start: Date?

    var body: some View {
        TimelineView(.animation(paused: start == nil)) { timeline in
            Canvas { ctx, size in
                guard let start else { return }
                let p = timeline.date.timeIntervalSince(start) / 1.1
                guard p < 1 else { return }
                let c = CGPoint(x: size.width / 2, y: size.height / 2)
                for i in 0..<24 {
                    let a = Double(i) / 24 * 2 * .pi
                    let r = (0.3 + 0.6 * (1 - pow(1 - p, 3))) * Double(max(size.width, size.height)) * 0.55
                    let pt = CGPoint(x: c.x + CGFloat(cos(a) * r), y: c.y + CGFloat(sin(a) * r * 0.6))
                    let s = 9 * (1 - p) + 2
                    ctx.fill(Path(ellipseIn: CGRect(x: pt.x - s, y: pt.y - s, width: s * 2, height: s * 2)),
                             with: .color(Theme.confetti[i % Theme.confetti.count].opacity(1 - p)))
                }
            }
        }
        .allowsHitTesting(false)
        .onChange(of: trigger) { _, _ in start = .now }
    }
}

extension StoryStage {
    /// Doing and look words the stage can act out.
    static let knownActs: Set<String> = ["nap", "sit", "dig", "sip", "hop", "jump", "run", "sing", "swim", "clap",
                                         "sad", "mad", "red", "hot", "big"]
}
