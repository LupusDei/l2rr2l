import SwiftUI

/// Read Along: Cutisie sits beside a storybook line, her horn shining a beam
/// on the word she's reading, and sounds it out with the child.
struct ReadAlongView: View {
    @Environment(AppServices.self) private var services
    @State private var model: ReadAlongModel?

    var body: some View {
        ZStack {
            Color.clear
            if let model {
                ReadAlongBoard(model: model)
            }
        }
        .task {
            let m = ReadAlongModel(services: services)
            model = m
            await m.start()
        }
        .onDisappear { model?.stop() }
    }
}

private struct ReadAlongBoard: View {
    let model: ReadAlongModel
    @Environment(AppServices.self) private var services
    @Environment(\.metrics) private var m

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let landscape = w > h
            let readerSize = landscape ? min(h * 0.62, w * 0.36) : min(w * 0.62, h * 0.4)
            let pageWidth = landscape ? w * 0.56 : w * 0.88
            let font = m.s(landscape ? 78 : 72)

            ZStack {
                CutisieReader(puppet: model.puppet, size: readerSize) { model.askCutisie() }
                    .anchorPreference(key: ReadAnchorsKey.self, value: .point(ReaderRig.hornTip)) { ReadAnchors(horn: $0) }
                    .position(x: landscape ? w * 0.22 : w * 0.5,
                              y: landscape ? h * 0.52 : h * 0.3)

                StoryPage(model: model, font: font, width: pageWidth)
                    .id(model.index)
                    .transition(.asymmetric(insertion: .scale(scale: 0.6).combined(with: .opacity),
                                            removal: .move(edge: .leading).combined(with: .opacity)))
                    .position(x: landscape ? w * 0.66 : w * 0.5,
                              y: landscape ? h * 0.42 : h * 0.64)

                if model.phase == .roundDone {
                    RoundDonePanel(onAgain: { model.playAgain() },
                                   onHome: { services.router.goHome() })
                        .position(x: w / 2, y: h * 0.8)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .overlayPreferenceValue(ReadAnchorsKey.self) { anchors in
                // the reading beam from her horn to the word she's on
                GeometryReader { proxy in
                    if let horn = anchors.horn, let active = model.activeWord, let word = anchors.words[active] {
                        ReadingBeam(from: proxy[horn], to: proxy[word])
                            .transition(.opacity)
                    }
                }
                .allowsHitTesting(false)
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.75), value: model.index)
            .animation(.spring(response: 0.45, dampingFraction: 0.7), value: model.phase)
        }
    }
}

/// The sentence on a glowing page: one big word card per word, wrapping onto
/// a second line on small screens.
private struct StoryPage: View {
    let model: ReadAlongModel
    let font: CGFloat
    let width: CGFloat
    @Environment(\.metrics) private var m

    var body: some View {
        WrapLayout(spacing: font * 0.32, lineSpacing: font * 0.5) {
            ForEach(model.tokens) { token in
                let i = token.id
                ReadWordView(token: token,
                             font: font,
                             state: state(of: i),
                             litPiece: model.activeWord == i ? model.litPiece : nil,
                             hint: model.hintWord == i,
                             fixed: model.fixedWord == i,
                             wiggle: model.wiggleWord == i ? model.wiggleCount : 0) {
                    model.tap(i)
                }
                .anchorPreference(key: ReadAnchorsKey.self, value: .bounds) { ReadAnchors(words: [i: $0]) }
            }
        }
        .padding(.horizontal, font * 0.5)
        .padding(.vertical, font * 0.45)
        .frame(maxWidth: width)
        .background {
            RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous)
                .fill(LinearGradient(colors: [Color(red: 1, green: 0.98, blue: 0.93), Color(red: 1, green: 0.93, blue: 0.86)],
                                     startPoint: .top, endPoint: .bottom))
                .overlay(RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous)
                    .stroke(.white, lineWidth: 4))
                .glow(model.phase == .yourTurn ? Theme.gold : Theme.aurora3, radius: 20)
        }
    }

    private func state(of i: Int) -> ReadWordView.Look {
        switch model.phase {
        case .yourTurn:
            if model.readWords.contains(i) { return model.activeWord == i ? .active : .done }
            return model.nextWord == i ? .next : .waiting
        case .won:
            return .done
        default:
            return model.activeWord == i ? .active : .waiting
        }
    }
}

/// One word card. Under each tile is a "sound button": a dot for a one-letter
/// sound, a dash for a team of letters (sh, ee), nothing for a silent e, and
/// a heart over words to learn by heart.
private struct ReadWordView: View {
    enum Look { case waiting, next, active, done }

    let token: ReadToken
    let font: CGFloat
    let state: Look
    let litPiece: Int?
    let hint: Bool
    let fixed: Bool
    let wiggle: Int
    let action: () -> Void

    var body: some View {
        let pieces = token.pieces
        let sounds = token.word.soundKeys
        Button(action: action) {
            VStack(spacing: font * 0.06) {
                Image(systemName: "heart.fill")
                    .font(.system(size: font * 0.26))
                    .foregroundStyle(Theme.pink)
                    .opacity(token.isHeart ? 1 : 0)
                HStack(alignment: .lastTextBaseline, spacing: 0) {
                    ForEach(Array(pieces.enumerated()), id: \.offset) { p, piece in
                        VStack(spacing: font * 0.08) {
                            Text(piece)
                                .font(.reading(font))
                                .foregroundStyle(litPiece == p ? Theme.pink : ink)
                                .scaleEffect(litPiece == p ? 1.18 : 1, anchor: .bottom)
                            SoundButton(kind: token.isHeart ? .none : buttonKind(piece: piece, sound: p < sounds.count ? sounds[p] : ""),
                                        lit: litPiece == p, size: font)
                        }
                    }
                    Text(token.trailing)
                        .font(.reading(font))
                        .foregroundStyle(ink.opacity(0.7))
                }
            }
            .padding(.horizontal, font * 0.12)
            .background {
                RoundedRectangle(cornerRadius: font * 0.25, style: .continuous)
                    .fill(fill)
                    .padding(.horizontal, -font * 0.05)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(state == .active ? 1.1 : 1)
        .glow(glowColor, radius: state == .active || hint ? 18 : 0)
        .overlay(alignment: .top) {
            if state == .next {
                // a little star bobs over the word she's on
                BobbingStar(size: font * 0.38).offset(y: -font * 0.55)
            }
        }
        .keyframeAnimator(initialValue: CGFloat(0), trigger: wiggle) { view, x in
            view.offset(x: x)
        } keyframes: { _ in
            CubicKeyframe(-12, duration: 0.07)
            CubicKeyframe(10, duration: 0.09)
            CubicKeyframe(-6, duration: 0.09)
            SpringKeyframe(0, duration: 0.2)
        }
        .keyframeAnimator(initialValue: CGFloat(1), trigger: fixed) { view, s in
            view.scaleEffect(s)
        } keyframes: { _ in
            SpringKeyframe(1.35, duration: 0.25, spring: .bouncy)
            SpringKeyframe(1, duration: 0.4)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: state)
        .animation(.spring(response: 0.25, dampingFraction: 0.55), value: litPiece)
        .accessibilityLabel(token.word.text)
    }

    private var ink: Color {
        switch state {
        case .waiting: Theme.skyTop.opacity(0.88)
        case .next, .active: Theme.skyTop
        case .done: Color(red: 0.42, green: 0.25, blue: 0.75)
        }
    }

    private var fill: Color {
        if fixed { return Theme.mint.opacity(0.45) }
        switch state {
        case .active: return Theme.gold.opacity(0.35)
        case .done: return Theme.lilac.opacity(0.2)
        default: return hint ? Theme.gold.opacity(0.25) : .clear
        }
    }

    private var glowColor: Color { state == .active || hint ? Theme.gold : .clear }

    private func buttonKind(piece: String, sound: String) -> SoundButton.Kind {
        if sound.isEmpty { return .none }
        return piece.count > 1 ? .dash : .dot
    }
}

private struct SoundButton: View {
    enum Kind { case dot, dash, none }
    let kind: Kind
    let lit: Bool
    let size: CGFloat

    var body: some View {
        let color = lit ? Theme.pink : Theme.lilac.opacity(0.7)
        Group {
            switch kind {
            case .dot: Circle().fill(color).frame(width: size * 0.13, height: size * 0.13)
            case .dash: Capsule().fill(color).frame(width: size * 0.5, height: size * 0.1)
            case .none: Color.clear.frame(width: size * 0.13, height: size * 0.13)
            }
        }
        .scaleEffect(lit ? 1.5 : 1)
        .glow(lit ? Theme.pink : .clear, radius: 6)
    }
}

private struct BobbingStar: View {
    let size: CGFloat
    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Image(systemName: "star.fill")
                .font(.system(size: size))
                .foregroundStyle(LinearGradient(colors: [.white, Theme.gold], startPoint: .top, endPoint: .bottom))
                .glow(Theme.gold, radius: 8)
                .offset(y: -6 * abs(sin(t * 3)))
                .rotationEffect(.degrees(8 * sin(t * 2)))
        }
        .allowsHitTesting(false)
    }
}

/// A soft, sparkly beam from Cutisie's horn to the top of the word she's on.
private struct ReadingBeam: View {
    let from: CGPoint
    let to: CGRect

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { ctx, _ in
                let end = CGPoint(x: to.midX, y: to.minY + to.height * 0.12)
                var path = Path()
                path.move(to: from)
                path.addQuadCurve(to: end, control: CGPoint(x: (from.x + end.x) / 2, y: min(from.y, end.y) - 60))
                var glow = ctx
                glow.addFilter(.blur(radius: 8))
                glow.stroke(path, with: .color(Theme.gold.opacity(0.5)), style: StrokeStyle(lineWidth: 16, lineCap: .round))
                ctx.stroke(path, with: .color(.white.opacity(0.85)),
                           style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [2, 14], dashPhase: CGFloat(-t * 50)))
                let r = 10 + 3 * sin(t * 6)
                ctx.fill(Path(ellipseIn: CGRect(x: end.x - r, y: end.y - r, width: r * 2, height: r * 2)),
                         with: .color(.white.opacity(0.9)))
            }
        }
    }
}

/// Where Cutisie's horn and each word are, gathered so the beam can join them.
private struct ReadAnchors {
    var horn: Anchor<CGPoint>?
    var words: [Int: Anchor<CGRect>] = [:]
}

private struct ReadAnchorsKey: PreferenceKey {
    static let defaultValue = ReadAnchors()
    static func reduce(value: inout ReadAnchors, nextValue: () -> ReadAnchors) {
        let next = nextValue()
        if let horn = next.horn { value.horn = horn }
        value.words.merge(next.words) { $1 }
    }
}

/// Lays words out left to right, wrapping to a new centred line when full.
private struct WrapLayout: Layout {
    var spacing: CGFloat
    var lineSpacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let lines = arrange(subviews, width: proposal.width ?? .infinity)
        let width = lines.map(\.width).max() ?? 0
        let height = lines.map(\.height).reduce(0, +) + lineSpacing * CGFloat(max(lines.count - 1, 0))
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for line in arrange(subviews, width: bounds.width) {
            var x = bounds.midX - line.width / 2
            for i in line.items {
                let size = subviews[i].sizeThatFits(.unspecified)
                subviews[i].place(at: CGPoint(x: x, y: y + line.height - size.height), proposal: .unspecified)
                x += size.width + spacing
            }
            y += line.height + lineSpacing
        }
    }

    private struct Line { var items: [Int] = []; var width: CGFloat = 0; var height: CGFloat = 0 }

    private func arrange(_ subviews: Subviews, width: CGFloat) -> [Line] {
        var lines: [Line] = [Line()]
        for i in subviews.indices {
            let size = subviews[i].sizeThatFits(.unspecified)
            let extra = lines[lines.count - 1].items.isEmpty ? size.width : spacing + size.width
            if lines[lines.count - 1].width + extra > width, !lines[lines.count - 1].items.isEmpty {
                lines.append(Line())
            }
            var line = lines[lines.count - 1]
            line.width += line.items.isEmpty ? size.width : spacing + size.width
            line.height = max(line.height, size.height)
            line.items.append(i)
            lines[lines.count - 1] = line
        }
        return lines
    }
}
