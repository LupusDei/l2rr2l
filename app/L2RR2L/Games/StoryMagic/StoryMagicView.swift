import SwiftUI

/// Story Magic: a story stage where Cutisie's dream turns real as the child's
/// words land in the sentence. See `StoryMagicModel` for the flow.
struct StoryMagicView: View {
    @Environment(AppServices.self) private var services
    @State private var model: StoryMagicModel?

    var body: some View {
        ZStack {
            Color.clear
            if let model { StoryMagicBoard(model: model) }
        }
        .task {
            var story: Story? = nil
            #if DEBUG
            // `-uitestStory cat-nap` picks the story
            let args = CommandLine.arguments
            if let i = args.firstIndex(of: "-uitestStory"), i + 1 < args.count {
                story = StoryContent.all.first { $0.id == args[i + 1] }
            }
            #endif
            let m = StoryMagicModel(services: services, story: story)
            model = m
            await m.start()
        }
        .onDisappear { model?.stop() }
    }
}

private struct StoryMagicBoard: View {
    let model: StoryMagicModel
    @Environment(AppServices.self) private var services
    @Environment(\.metrics) private var m
    @Namespace private var flight

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let landscape = w > h
            let stageSize = landscape ? CGSize(width: min(w * 0.56, h * 0.95), height: h * 0.42)
                                      : CGSize(width: w * 0.86, height: min(h * 0.32, w * 0.62))
            let stageCenter = CGPoint(x: landscape ? w * 0.56 : w / 2, y: landscape ? h * 0.32 : h * 0.29)
            let font = m.s(landscape ? 56 : 52)
            let sentenceY = landscape ? h * 0.635 : h * 0.555
            let controlsY = landscape ? h * 0.84 : h * 0.72
            let controlsX = landscape ? w * 0.58 : w / 2
            let controlsW = landscape ? w * 0.7 : w * 0.9

            ZStack {
                PageDots(count: model.pages + 1, current: model.phase == .book || model.phase == .roundDone ? model.pages + 1 : model.page)
                    .position(x: w / 2, y: m.s(52))

                if model.phase != .book && model.phase != .roundDone {
                    StoryStage(show: model.show, dream: model.dream, celebrate: model.celebrate, size: stageSize)
                        .position(stageCenter)
                        .transition(.scale(scale: 0.8).combined(with: .opacity))

                    if [.pick, .make, .judge].contains(model.phase) {
                        HelpWing(size: m.s(84)) { model.askHelp() }
                            .accessibilityIdentifier("help")
                            .position(x: stageCenter.x + stageSize.width / 2 - m.s(10), y: stageCenter.y - stageSize.height / 2 + m.s(10))
                    }

                    sentence(font: font, width: landscape ? w * 0.86 : w * 0.94)
                        .position(x: w / 2, y: sentenceY)

                    controls(font: font * 0.92, width: controlsW)
                        .position(x: controlsX, y: controlsY)
                }

                if model.phase == .book || model.phase == .roundDone {
                    StoryBook(model: model, size: CGSize(width: landscape ? w * 0.74 : w * 0.92,
                                                         height: landscape ? h * 0.66 : h * 0.5),
                              font: font * 0.9)
                        .position(x: w / 2, y: landscape ? h * 0.46 : h * 0.42)
                        .transition(.scale(scale: 0.3).combined(with: .opacity))
                }

                if model.phase == .roundDone {
                    RoundDonePanel(onAgain: { model.playAgain() }, onHome: { services.router.goHome() })
                        .position(x: w / 2, y: landscape ? h * 0.88 : h * 0.8)
                        .transition(.scale.combined(with: .opacity))
                }

                #if DEBUG
                if CommandLine.arguments.contains("-uitest") {
                    Color.clear.frame(width: 1, height: 1)
                        .accessibilityElement()
                        .accessibilityIdentifier("storyState")
                        .accessibilityValue(model.testState)
                        .position(x: 1, y: 1)
                }
                #endif
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.75), value: model.phase)
            .animation(.spring(response: 0.5, dampingFraction: 0.75), value: model.page)
        }
    }

    // MARK: The sentence

    @ViewBuilder
    private func sentence(font: CGFloat, width: CGFloat) -> some View {
        WrapLayout(spacing: font * 0.26, lineSpacing: font * 0.35) {
            ForEach(model.tokens) { token in
                let i = token.id
                Group {
                    if model.mode == .make && (model.phase == .make || model.phase == .won) {
                        slot(i, font: font)
                    } else if model.phase == .pick && i == model.gapIndex {
                        gap(font: font)
                    } else {
                        WordCard(text: token.shown, heart: token.isHeart, font: font,
                                 look: model.litWord == i ? .lit : .plain)
                    }
                }
            }
            Text(model.tokens.last?.trailing ?? ".")
                .font(.reading(font))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.4), radius: 0, y: 2)
        }
        .frame(maxWidth: width)
        .padding(.vertical, font * 0.22)
        .padding(.horizontal, font * 0.3)
        .background {
            Capsule().fill(Theme.skyTop.opacity(0.5))
                .overlay(Capsule().stroke(.white.opacity(0.25), lineWidth: 2))
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.65), value: model.litWord)
    }

    @ViewBuilder
    private func slot(_ i: Int, font: CGFloat) -> some View {
        let token = model.tokens[i]
        if let placed = model.slots.indices.contains(i) ? model.slots[i] : nil {
            let t = model.tokens[placed]
            Button { model.tapSlot(i) } label: {
                WordCard(text: t.shown, heart: t.isHeart, font: font,
                         look: model.litWord == i ? .lit : model.locked.contains(i) ? .locked : .placed)
            }
            .buttonStyle(BouncyButtonStyle(pressedScale: 0.9, sound: nil))
            .matchedGeometryEffect(id: placed, in: flight)
            .accessibilityIdentifier("slot-\(i)")
        } else {
            // an empty glowing box the size of the word that belongs there
            Text(token.shown)
                .font(.reading(font))
                .opacity(0)
                .padding(.horizontal, font * 0.22)
                .padding(.vertical, font * 0.08)
                .background {
                    let shape = RoundedRectangle(cornerRadius: font * 0.28, style: .continuous)
                    let next = model.slots.firstIndex { $0 == nil } == i
                    shape.fill(.white.opacity(next ? 0.22 : 0.1))
                        .overlay(shape.stroke(next ? Theme.gold : .white.opacity(0.6),
                                              style: StrokeStyle(lineWidth: 3, dash: [9, 7])))
                        .glow(next ? Theme.gold : .clear, radius: 10)
                }
                .accessibilityIdentifier("slot-\(i)")
        }
    }

    private func gap(font: CGFloat) -> some View {
        let gapToken = model.gapIndex.map { model.tokens[$0] }
        return ZStack {
            Text(gapToken?.shown ?? "")
                .font(.reading(font))
                .opacity(0)
            if let filled = model.filled {
                WordCard(text: filled.text, heart: false, font: font,
                         look: model.litWord == model.gapIndex ? .lit : .placed)
                    .matchedGeometryEffect(id: "choice-\(filled.text)", in: flight)
            }
        }
        .padding(.horizontal, model.filled == nil ? font * 0.22 : 0)
        .padding(.vertical, model.filled == nil ? font * 0.08 : 0)
        .background {
            if model.filled == nil {
                let shape = RoundedRectangle(cornerRadius: font * 0.28, style: .continuous)
                shape.fill(.white.opacity(0.2))
                    .overlay(shape.stroke(Theme.gold, style: StrokeStyle(lineWidth: 3, dash: [9, 7])))
                    .glow(Theme.gold, radius: 10)
            }
        }
        .accessibilityIdentifier("gap")
    }

    // MARK: What she taps

    @ViewBuilder
    private func controls(font: CGFloat, width: CGFloat) -> some View {
        switch model.phase {
        case .make, .won where model.mode == .make:
            WrapLayout(spacing: font * 0.4, lineSpacing: font * 0.45) {
                ForEach(model.tray, id: \.self) { i in
                    let t = model.tokens[i]
                    CloudWord(text: t.shown, heart: t.isHeart, font: font, glow: model.hint == i, bob: Double(i)) {
                        model.tapTray(i)
                    }
                    .matchedGeometryEffect(id: i, in: flight)
                    .accessibilityIdentifier("tile-\(i)")
                }
            }
            .frame(maxWidth: width)
            .frame(minHeight: font * 1.8)
        case .pick:
            HStack(spacing: font * 0.5) {
                ForEach(Array(model.choices.enumerated()), id: \.element) { i, choice in
                    if model.filled?.text == choice.text {
                        Color.clear.frame(width: font * 2.4, height: font * 1.6)
                    } else {
                        CloudWord(text: choice.text, heart: false, font: font * 1.05, glow: model.hint == i, bob: Double(i),
                                  dimmed: model.tried.contains(choice.text)) {
                            model.pick(i)
                        }
                        .matchedGeometryEffect(id: "choice-\(choice.text)", in: flight)
                        .accessibilityIdentifier("choice-\(i)")
                    }
                }
            }
        case .judge:
            HStack(spacing: font * 1.2) {
                JudgeButton(silly: false, size: font * 2.3, chosen: model.answered == false) { model.judge(silly: false) }
                    .accessibilityIdentifier("judge-yes")
                JudgeButton(silly: true, size: font * 2.3, chosen: model.answered == true) { model.judge(silly: true) }
                    .accessibilityIdentifier("judge-silly")
            }
        default:
            Color.clear.frame(height: 1)
        }
    }
}

// MARK: - Pieces

/// A word on a soft card: plain in a sentence, glowing when the Star Voice reads it.
struct WordCard: View {
    enum Look { case plain, placed, locked, lit }
    let text: String
    let heart: Bool
    let font: CGFloat
    var look: Look = .plain

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: font * 0.28, style: .continuous)
        Text(text)
            .font(.reading(font))
            .foregroundStyle(Theme.skyTop)
            .fixedSize()
            .padding(.horizontal, font * 0.22)
            .padding(.vertical, font * 0.08)
            .background {
                ZStack {
                    shape.fill(fill.mixed(with: .black, by: 0.2)).offset(y: font * 0.06)
                    shape.fill(LinearGradient(colors: [.white, fill], startPoint: .top, endPoint: .bottom))
                    shape.stroke(look == .lit ? Theme.gold : .white, lineWidth: look == .lit ? 4 : 2)
                }
            }
            .overlay(alignment: .topTrailing) {
                if heart {
                    Image(systemName: "heart.fill")
                        .font(.system(size: font * 0.28))
                        .foregroundStyle(Theme.pink)
                        .offset(x: font * 0.08, y: -font * 0.12)
                }
            }
            .scaleEffect(look == .lit ? 1.12 : 1)
            .glow(look == .lit ? Theme.gold : look == .locked ? Theme.mint : .clear, radius: look == .plain || look == .placed ? 0 : 12)
    }

    private var fill: Color {
        switch look {
        case .plain: Color(red: 1, green: 0.97, blue: 0.9)
        case .placed: Color(red: 0.93, green: 0.9, blue: 1)
        case .locked: Color(red: 0.8, green: 1, blue: 0.9)
        case .lit: Color(red: 1, green: 0.92, blue: 0.62)
        }
    }
}

/// A word riding a little cloud. Bobs gently; squishes when pressed.
private struct CloudWord: View {
    let text: String
    let heart: Bool
    let font: CGFloat
    var glow = false
    var bob = 0.0
    var dimmed = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                WordCard(text: text, heart: heart, font: font, look: glow ? .lit : .plain)
                    .padding(.horizontal, font * 0.35)
                    .padding(.vertical, font * 0.3)
                    .background {
                        CloudShape()
                            .fill(LinearGradient(colors: [.white.opacity(0.95), Theme.lilac.opacity(0.75)],
                                                 startPoint: .top, endPoint: .bottom))
                            .shadow(color: Theme.aurora3.opacity(0.5), radius: 10)
                            .padding(.horizontal, -font * 0.15)
                            .padding(.bottom, -font * 0.12)
                    }
                    .offset(y: 5 * sin(t * 1.8 + bob * 1.3))
                    .rotationEffect(.degrees(glow ? 4 * sin(t * 8) : 1.5 * sin(t * 1.2 + bob)))
            }
        }
        .buttonStyle(BouncyButtonStyle(pressedScale: 0.86, sound: .pick))
        .opacity(dimmed ? 0.35 : 1)
        .disabled(dimmed)
        .accessibilityLabel(text)
    }
}

/// A puffy cloud: a flat-bottomed capsule with three bumps on top.
struct CloudShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let h = r.height, w = r.width
        p.addRoundedRect(in: CGRect(x: r.minX, y: r.minY + h * 0.3, width: w, height: h * 0.7), cornerSize: CGSize(width: h * 0.35, height: h * 0.35))
        p.addEllipse(in: CGRect(x: r.minX + w * 0.08, y: r.minY + h * 0.12, width: w * 0.38, height: h * 0.6))
        p.addEllipse(in: CGRect(x: r.minX + w * 0.32, y: r.minY, width: w * 0.42, height: h * 0.7))
        p.addEllipse(in: CGRect(x: r.minX + w * 0.58, y: r.minY + h * 0.16, width: w * 0.34, height: h * 0.55))
        return p
    }
}

/// The two answers for "silly or not?": a smiling sun-face and a giggly face.
private struct JudgeButton: View {
    let silly: Bool
    let size: CGFloat
    let chosen: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(silly ? "🤪" : "😊")
                    .font(.system(size: size * 0.55))
                Image(systemName: silly ? "questionmark" : "checkmark")
                    .font(.system(size: size * 0.18, weight: .black))
                    .foregroundStyle(.white)
            }
            .frame(width: size * 1.25, height: size)
        }
        .buttonStyle(.chunky(silly ? Theme.pink : Theme.mint, depth: size * 0.08, cornerRadius: size * 0.3))
        .scaleEffect(chosen ? 1.12 : 1)
        .phaseAnimator([0.0, 1.0]) { view, p in
            view.rotationEffect(.degrees(silly ? -3 + 6 * p : 0))
        } animation: { _ in .easeInOut(duration: 0.6) }
        .accessibilityLabel(silly ? "Silly" : "Makes sense")
    }
}

/// Cutisie's help wing: a little bat wing with a sparkle. Replays the sentence.
private struct HelpWing: View {
    let size: CGFloat
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle().fill(RadialGradient(colors: [.white, Theme.lilac], center: .topLeading, startRadius: 0, endRadius: size))
                Image(systemName: "ear.and.waveform")
                    .font(.system(size: size * 0.42, weight: .bold))
                    .foregroundStyle(Theme.skyTop.opacity(0.8))
            }
            .frame(width: size, height: size)
            .glow(Theme.lilac, radius: 8)
        }
        .buttonStyle(BouncyButtonStyle(pressedScale: 0.85, sound: .pop))
        .accessibilityLabel("Hear it")
    }
}

/// Little page markers: a dot per page and a star for the meaning check.
private struct PageDots: View {
    let count: Int
    let current: Int
    @Environment(\.metrics) private var m

    var body: some View {
        HStack(spacing: m.s(14)) {
            ForEach(0..<count, id: \.self) { i in
                let done = i < current
                Image(systemName: i == count - 1 ? "star.fill" : "book.pages.fill")
                    .font(.system(size: m.s(i == current ? 30 : 22), weight: .bold))
                    .foregroundStyle(done ? Theme.gold : i == current ? .white : .white.opacity(0.35))
                    .glow(i == current ? Theme.gold : .clear, radius: 8)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: current)
    }
}

/// The finished story as a book: the scene on the left page, the sentence on
/// the right, turning as the Star Voice reads. "The end" when it's done.
private struct StoryBook: View {
    let model: StoryMagicModel
    let size: CGSize
    let font: CGFloat

    var body: some View {
        let pageW = size.width / 2
        let done = model.bookPage >= model.story.pages.count
        ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(LinearGradient(colors: [Theme.lilac, Theme.pink.mixed(with: Theme.lilac, by: 0.5)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: size.width + 28, height: size.height + 28)
                .glow(Theme.aurora3, radius: 18)
            HStack(spacing: 0) {
                paper {
                    if done {
                        StoryStage(show: .full(model.story.pages.last!.scene), size: CGSize(width: pageW * 0.9, height: size.height * 0.8))
                    } else {
                        StoryStage(show: .full(model.story.pages[model.bookPage].scene),
                                   size: CGSize(width: pageW * 0.9, height: size.height * 0.8))
                            .id(model.bookPage)
                            .transition(.asymmetric(insertion: .scale(scale: 0.7).combined(with: .opacity), removal: .opacity))
                    }
                }
                paper {
                    if done {
                        VStack(spacing: font * 0.3) {
                            Text("The end!")
                                .font(.playful(font * 1.2))
                                .foregroundStyle(Theme.pink)
                            Image(systemName: "heart.fill").font(.system(size: font)).foregroundStyle(Theme.pink)
                        }
                    } else {
                        WrapLayout(spacing: font * 0.25, lineSpacing: font * 0.4) {
                            ForEach(model.tokens) { token in
                                Text(token.shown + token.trailing)
                                    .font(.reading(font))
                                    .foregroundStyle(model.litWord == token.id ? Theme.pink : Theme.skyTop)
                                    .scaleEffect(model.litWord == token.id ? 1.15 : 1)
                                    .fixedSize()
                            }
                        }
                        .padding(font * 0.4)
                        .id(model.bookPage)
                        .transition(.opacity)
                    }
                }
                .rotation3DEffect(.degrees(0), axis: (x: 0, y: 1, z: 0))
            }
            .frame(width: size.width, height: size.height)
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.65), value: model.litWord)
    }

    private func paper<C: View>(@ViewBuilder _ content: () -> C) -> some View {
        ZStack { content() }
            .frame(width: size.width / 2, height: size.height)
            .background(Color(red: 1, green: 0.98, blue: 0.93))
            .overlay(Rectangle().stroke(Theme.lilac.opacity(0.4), lineWidth: 1))
    }
}
