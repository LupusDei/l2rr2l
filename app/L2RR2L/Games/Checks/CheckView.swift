import SwiftUI

/// Screen for the Sparkle Check and Sky Trials: a big prompt in the middle
/// (a word, a sentence, a heart, or a speaker for listening questions) and big
/// answer buttons below. Progress is a trail of sparkles, never a score.
struct CheckView: View {
    let kind: CheckModel.Kind
    @Environment(AppServices.self) private var services
    @Environment(\.metrics) private var m
    @State private var model: CheckModel?

    var body: some View {
        ZStack {
            SkyBackground(tint: Theme.gold, imageName: {
                switch kind {
                case .sparkleCheck: "bg-starfield"
                case .skyTrial: "bg-skymap"
                case .warmUp: "bg-home"
                }
            }())
            TouchSparkles()
            if let model { CheckBoard(model: model) }
            VStack {
                HStack {
                    BubbleIconButton(systemName: "house.fill", color: Theme.gold) {
                        services.voice.stop()
                        services.router.goHome()
                    }
                    Spacer()
                    if let model { SparkleTrail(done: model.asked, total: model.totalPlanned) }
                    Spacer()
                    StarJar()
                }
                Spacer()
                HStack {
                    CutisieActor(size: m.s(220))
                    Spacer()
                }
            }
            .padding(m.s(24))
        }
        .toolbar(.hidden, for: .navigationBar)
        .adaptiveMetrics()
        .task {
            let m = CheckModel(kind: kind, services: services)
            model = m
            await m.start()
        }
        .onDisappear { services.voice.stop() }
    }
}

private struct CheckBoard: View {
    let model: CheckModel
    @Environment(AppServices.self) private var services
    @Environment(\.metrics) private var m

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            VStack(spacing: m.s(40)) {
                Spacer(minLength: h * 0.12)
                if let q = model.question {
                    promptView(q)
                        .id(model.asked)
                        .transition(.scale(scale: 0.6).combined(with: .opacity))
                    answers(q, width: w)
                        .id("answers-\(model.asked)")
                } else if model.phase == .done {
                    VStack(spacing: m.s(24)) {
                        Image(systemName: model.passed ? "sparkles" : "wand.and.stars")
                            .font(.system(size: m.s(110)))
                            .foregroundStyle(Theme.gold)
                            .glow(Theme.gold, radius: 20)
                            .symbolEffect(.bounce, options: .repeat(3))
                        Text(model.resultLine)
                            .font(.playful(m.s(32), weight: .bold))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: w * 0.7)
                        Button { services.router.goHome() } label: {
                            Image(systemName: "house.fill")
                                .font(.system(size: m.s(48), weight: .black))
                                .foregroundStyle(.white)
                                .frame(width: m.s(170), height: m.s(120))
                        }
                        .buttonStyle(.chunky(Theme.lilac, depth: m.s(12), cornerRadius: m.s(40)))
                    }
                    .transition(.scale.combined(with: .opacity))
                }
                Spacer()
            }
            .frame(width: w)
            .animation(.spring(response: 0.45, dampingFraction: 0.7), value: model.asked)
            .animation(.spring(response: 0.45, dampingFraction: 0.7), value: model.phase)
        }
    }

    @ViewBuilder
    private func promptView(_ q: CheckModel.Question) -> some View {
        switch q {
        case .soundMatch, .oralBlend, .heart, .rhyme, .claps, .onset:
            Button { model.replay() } label: {
                Image(systemName: "ear.and.waveform")
                    .font(.system(size: m.s(80), weight: .bold))
                    .foregroundStyle(.white)
                    .symbolEffect(.variableColor.iterative, options: .repeating)
                    .frame(width: m.s(200), height: m.s(170))
            }
            .buttonStyle(.chunky(Theme.sky, depth: m.s(12), cornerRadius: m.s(50)))
        case .readWord(let b, _):
            bigWord(b.word.text)
        case .unicorn(let w):
            VStack(spacing: 12) {
                Image(systemName: "sparkles").font(.system(size: m.s(40))).foregroundStyle(Theme.pink)
                bigWord(w.text, color: Theme.pink)
            }
        case .sentence(let s):
            Text(s.text)
                .font(.reading(m.s(64)))
                .foregroundStyle(Theme.skyTop)
                .padding(.horizontal, m.s(36)).padding(.vertical, m.s(18))
                .background(RoundedRectangle(cornerRadius: m.s(30), style: .continuous).fill(.white))
                .glow(Theme.gold, radius: 14)
        }
    }

    private func bigWord(_ text: String, color: Color = Theme.gold) -> some View {
        Text(text)
            .font(.reading(m.s(120)))
            .foregroundStyle(Theme.skyTop)
            .padding(.horizontal, m.s(46)).padding(.vertical, m.s(10))
            .background(RoundedRectangle(cornerRadius: m.s(36), style: .continuous).fill(.white))
            .glow(color, radius: 18)
    }

    @ViewBuilder
    private func answers(_ q: CheckModel.Question, width: CGFloat) -> some View {
        switch q {
        case .unicorn:
            // a grown-up listens and taps; scoring never comes from the child tapping here
            VStack(spacing: m.s(14)) {
                Text("Grown-up: read right?")
                    .font(.playful(m.s(20), weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
                HStack(spacing: m.s(20)) {
                    grownUpButton("checkmark", Theme.mint) { model.grownUp(true) }
                    grownUpButton("xmark", Theme.peach) { model.grownUp(false) }
                    grownUpButton("forward.fill", Theme.lilac) { model.grownUp(nil) }
                }
            }
        default:
            HStack(spacing: m.s(26)) {
                ForEach(model.choiceOrder, id: \.self) { choice in
                    Button { model.answer(choice) } label: {
                        choiceLabel(q, choice)
                            .frame(width: m.s(190), height: m.s(180))
                    }
                    .buttonStyle(.chunky(model.picked == choice ? Theme.gold : .white, depth: m.s(10), cornerRadius: m.s(36)))
                    .disabled(model.phase != .asking)
                }
            }
        }
    }

    @ViewBuilder
    private func choiceLabel(_ q: CheckModel.Question, _ choice: String) -> some View {
        let shown = model.choiceDisplay[choice] ?? choice
        if model.choicesAreText {
            Text(shown).font(.reading(m.s(q.part == "heart" ? 56 : 90))).foregroundStyle(Theme.skyTop)
        } else if model.choicesAreWordPictures {
            WordPicture(word: choice, emoji: shown, size: m.s(140))
        } else {
            Text(shown)
                .font(.system(size: m.s(shown.count > 1 ? 52 : 96)))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
    }

    private func grownUpButton(_ symbol: String, _ color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: m.s(34), weight: .black))
                .foregroundStyle(.white)
                .frame(width: m.s(100), height: m.s(80))
        }
        .buttonStyle(.chunky(color, depth: m.s(8), cornerRadius: m.s(28)))
    }
}

/// A trail of little stars that fill as questions are answered.
private struct SparkleTrail: View {
    let done: Int
    let total: Int

    var body: some View {
        let shown = min(total, 12)
        let filled = total == 0 ? 0 : Int((Double(done) / Double(total) * Double(shown)).rounded(.down))
        HStack(spacing: 6) {
            ForEach(0..<shown, id: \.self) { i in
                Image(systemName: "sparkle")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(i < filled ? Theme.gold : .white.opacity(0.3))
                    .glow(i < filled ? Theme.gold : .clear, radius: 6)
            }
        }
        .animation(.spring, value: filled)
    }
}
