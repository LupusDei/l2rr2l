import SwiftUI

/// Word Machine: a glowing toy machine with sound boxes on its front. Hear
/// the word, drag letters into the boxes, pull the lever, then change one
/// letter to make the next word in the chain.
struct WordMachineView: View {
    @Environment(AppServices.self) private var services
    @State private var model: WordMachineModel?

    var body: some View {
        ZStack {
            Color.clear
            if let model { WordMachineBoard(model: model) }
        }
        .task {
            let m = WordMachineModel(services: services)
            model = m
            await m.start()
        }
        .onDisappear { model?.stop() }
    }
}

private struct WordMachineBoard: View {
    let model: WordMachineModel
    @Environment(AppServices.self) private var services
    @Environment(\.metrics) private var m
    @State private var dragging: String?
    @State private var dragPoint: CGPoint = .zero

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let landscape = w > h
            let n = max(model.boxes.count, 1)
            let machineW = min(w * 0.74, m.s(760))
            let box = min(m.s(150), machineW * 0.72 / CGFloat(n) - 18)
            let gap = box * 0.22
            let machineY = h * (landscape ? 0.47 : 0.44)
            let machineH = box * 2.0
            let boxCenter = { (i: Int) -> CGPoint in
                CGPoint(x: w / 2 - machineW * 0.06 + (CGFloat(i) - CGFloat(n - 1) / 2) * (box + gap), y: machineY + box * 0.08)
            }

            ZStack {
                ChainColumn(words: model.builtWords, reading: model.phase == .chainDone ? model.readingIndex : nil)
                    .position(x: w * 0.58, y: h * (landscape ? 0.94 : 0.9))

                PictureBubble(word: model.word, popped: model.poppedWord != nil, size: m.s(180))
                    .position(x: w / 2, y: h * (landscape ? 0.17 : 0.19))
                    .onTapGesture { model.hearAgain() }

                MachineBody(running: model.phase == .running, width: machineW, height: machineH)
                    .position(x: w / 2, y: machineY)
                    // once the word is built, the whole machine is the lever
                    .onTapGesture { if model.phase == .ready { model.pullLever() } }

                ForEach(0..<model.boxes.count, id: \.self) { i in
                    SoundBox(letter: model.boxes[i], size: box,
                             humming: model.humming == i || model.readingIndex == i && model.phase == .running,
                             reject: model.rejectBox == i ? model.rejectCount : 0,
                             snaps: model.snapCount,
                             target: (dragging != nil && hit(dragPoint, boxCenter(i), box)) || model.heldLetter != nil)
                        .position(boxCenter(i))
                        .onTapGesture { model.tapBox(i) }
                }

                // the finished word's picture shoots out of the machine's chute
                if let popped = model.poppedWord {
                    ChuteCard(word: popped, size: m.s(170), drop: machineH * 1.1)
                        .position(x: w / 2, y: machineY + machineH * 0.3)
                        .id(model.runCount)
                        .allowsHitTesting(false)
                }

                Lever(ready: model.phase == .ready, pulled: model.runCount, height: machineH * 0.9) {
                    model.pullLever()
                }
                .position(x: w / 2 + machineW / 2 - machineW * 0.08, y: machineY - machineH * 0.05)

                if model.phase != .chainDone {
                LetterTray(letters: model.chain.trayLetters, glow: model.heldLetter ?? model.glowLetter, tile: m.s(92),
                           maxWidth: w * 0.8, dragging: dragging,
                           onTap: { model.tapLetter($0) },
                           onDrag: { letter, point in
                               if dragging == nil { services.feedback.play(.pick) }
                               dragging = letter
                               dragPoint = point
                           },
                           onDrop: { letter, point in
                               dragging = nil
                               if let i = (0..<model.boxes.count).first(where: { hit(point, boxCenter($0), box) }) {
                                   model.drop(letter, into: i)
                               }
                           })
                    .position(x: w / 2, y: h * (landscape ? 0.8 : 0.74))
                }

                if let dragging {
                    TrayTile(letter: dragging, size: m.s(104), glow: true)
                        .position(dragPoint)
                        .allowsHitTesting(false)
                }

                if model.phase == .chainDone {
                    RoundDonePanel(onAgain: { model.playAgain() }, onHome: { services.router.goHome() })
                        .position(x: w / 2, y: h * 0.74)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .coordinateSpace(.named("machine"))
            .animation(.spring(response: 0.45, dampingFraction: 0.7), value: model.phase)
        }
    }

    private func hit(_ p: CGPoint, _ c: CGPoint, _ box: CGFloat) -> Bool {
        abs(p.x - c.x) < box * 0.75 && abs(p.y - c.y) < box * 0.9
    }
}

/// The word's picture floating in a bubble. Tap to hear the word again.
private struct PictureBubble: View {
    let word: Word
    let popped: Bool
    let size: CGFloat

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            VStack(spacing: 8) {
                ZStack {
                    Circle().fill(RadialGradient(colors: [.white.opacity(0.35), Theme.sky.opacity(0.25)],
                                                 center: UnitPoint(x: 0.35, y: 0.3), startRadius: 0, endRadius: size * 0.6))
                    Circle().stroke(.white.opacity(0.7), lineWidth: 3)
                    Ellipse().fill(.white.opacity(0.5))
                        .frame(width: size * 0.35, height: size * 0.16)
                        .offset(x: -size * 0.18, y: -size * 0.3)
                    if word.picture != nil || WordPicture.card(word.text) != nil {
                        WordPicture(word: word.text, emoji: word.picture, size: size * 0.66)
                    } else {
                        Image(systemName: "sparkles").font(.system(size: size * 0.4)).foregroundStyle(Theme.gold)
                    }
                }
                .frame(width: size, height: size)
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: size * 0.14, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(size * 0.06)
                        .background(Circle().fill(Theme.sky))
                }
                if popped {
                    Text(word.text)
                        .font(.reading(size * 0.42))
                        .foregroundStyle(.white)
                        .glow(Theme.gold, radius: 10)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .scaleEffect(popped ? 1.2 : 1)
            .offset(y: 8 * sin(t * 1.4))
            .glow(Theme.sky, radius: 14)
            .animation(.spring(response: 0.45, dampingFraction: 0.55), value: popped)
        }
        .id(word.text)
        .transition(.scale.combined(with: .opacity))
    }
}

/// The machine: a candy-colored body with rivets, spinning gears and a chute.
private struct MachineBody: View {
    let running: Bool
    let width: CGFloat
    let height: CGFloat
    @State private var spin = 0.0

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: height * 0.22, style: .continuous)
        TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            ZStack {
                shape.fill(Theme.lilac.mix(with: .black, by: 0.4)).offset(y: height * 0.07)
                shape.fill(LinearGradient(colors: [Theme.mint.mix(with: .white, by: 0.2), Theme.sky, Theme.lilac],
                                          startPoint: .topLeading, endPoint: .bottomTrailing))
                shape.fill(LinearGradient(colors: [.white.opacity(0.45), .clear], startPoint: .top, endPoint: .center))
                    .padding(6)
                shape.stroke(.white.opacity(0.8), lineWidth: 4)
                // rivets
                ForEach(0..<4, id: \.self) { i in
                    Circle().fill(.white.opacity(0.8))
                        .frame(width: 10, height: 10)
                        .offset(x: (i % 2 == 0 ? -1 : 1) * (width / 2 - 22), y: (i < 2 ? -1 : 1) * (height / 2 - 22))
                }
                // gears on top
                ForEach(0..<2, id: \.self) { i in
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: height * (i == 0 ? 0.42 : 0.3)))
                        .foregroundStyle(i == 0 ? Theme.gold : Theme.pink)
                        .rotationEffect(.degrees(t * (running ? 400 : 30) * (i == 0 ? 1 : -1.4)))
                        .offset(x: (i == 0 ? -1 : -0.62) * width * 0.36, y: -height * 0.58)
                }
                // lights along the top
                HStack(spacing: width * 0.05) {
                    ForEach(0..<6, id: \.self) { i in
                        Circle()
                            .fill(Theme.confetti[i % Theme.confetti.count])
                            .frame(width: 14, height: 14)
                            .opacity(running ? (Int(t * 12) % 6 == i ? 1 : 0.3) : 0.4 + 0.6 * (0.5 + 0.5 * sin(t * 2 + Double(i))))
                            .glow(Theme.confetti[i % Theme.confetti.count], radius: 4)
                    }
                }
                .offset(x: width * 0.12, y: -height * 0.4)
            }
            .frame(width: width, height: height)
            .offset(x: running ? 3 * sin(t * 60) : 0)
            .glow(Theme.sky, radius: running ? 30 : 16)
        }
    }
}

/// One sound box: a dark slot with a dotted outline that hums (glows) its
/// sound; holds a letter tile once filled.
private struct SoundBox: View {
    let letter: String?
    let size: CGFloat
    let humming: Bool
    let reject: Int
    let snaps: Int
    let target: Bool

    var body: some View {
        let slot = RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
        ZStack {
            slot.fill(Theme.skyTop.opacity(0.75))
            slot.strokeBorder(style: StrokeStyle(lineWidth: 4, dash: [10, 8]))
                .foregroundStyle(target ? Theme.gold : .white.opacity(0.6))
            if let letter {
                TrayTile(letter: letter, size: size * 0.9, glow: humming)
                    .transition(.scale(scale: 1.4).combined(with: .opacity))
                    .id(letter)
            } else {
                Circle().fill(.white.opacity(humming ? 0.9 : 0.35))
                    .frame(width: size * 0.16, height: size * 0.16)
            }
        }
        .frame(width: size, height: size * 1.05)
        .scaleEffect(humming ? 1.1 : (target ? 1.06 : 1))
        .glow(humming ? Theme.gold : .clear, radius: 18)
        .keyframeAnimator(initialValue: CGFloat(0), trigger: reject) { view, x in
            view.offset(x: x)
        } keyframes: { _ in
            CubicKeyframe(-12, duration: 0.07)
            CubicKeyframe(10, duration: 0.08)
            CubicKeyframe(-6, duration: 0.08)
            SpringKeyframe(0, duration: 0.2)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: humming)
        .animation(.spring(response: 0.35, dampingFraction: 0.55), value: letter)
    }
}

/// A cream letter tile, used in the tray, in boxes and under the finger.
struct TrayTile: View {
    let letter: String
    let size: CGFloat
    var glow = false

    var body: some View {
        let face = RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
        Text(letter)
            .font(.reading(size * 0.62))
            .foregroundStyle(Theme.skyTop)
            .frame(width: size, height: size)
            .background {
                ZStack {
                    face.fill(Color(red: 0.85, green: 0.78, blue: 0.7)).offset(y: size * 0.07)
                    face.fill(LinearGradient(colors: [.white, Color(red: 1, green: 0.95, blue: 0.88)], startPoint: .top, endPoint: .bottom))
                    face.stroke(glow ? Theme.gold : .white, lineWidth: glow ? 5 : 2)
                }
            }
            .glow(glow ? Theme.gold : .clear, radius: 16)
    }
}

/// The letter stamps: tap to drop into the next empty box, or drag to a box.
private struct LetterTray: View {
    let letters: [String]
    let glow: String?
    let tile: CGFloat
    let maxWidth: CGFloat
    let dragging: String?
    let onTap: (String) -> Void
    let onDrag: (String, CGPoint) -> Void
    let onDrop: (String, CGPoint) -> Void

    var body: some View {
        let perRow = max(1, Int(maxWidth / (tile + 18)))
        let rows = stride(from: 0, to: letters.count, by: perRow).map { Array(letters[$0..<min($0 + perRow, letters.count)]) }
        VStack(spacing: 20) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 18) {
                    ForEach(row, id: \.self) { letter in
                        TrayTile(letter: letter, size: tile, glow: glow == letter)
                            .opacity(dragging == letter ? 0.4 : 1)
                            .scaleEffect(glow == letter ? 1.08 : 1)
                            .gesture(
                                DragGesture(minimumDistance: 0, coordinateSpace: .named("machine"))
                                    .onChanged { value in
                                        if hypot(value.translation.width, value.translation.height) > 8 {
                                            onDrag(letter, value.location)
                                        }
                                    }
                                    .onEnded { value in
                                        if hypot(value.translation.width, value.translation.height) > 8 {
                                            onDrop(letter, value.location)
                                        } else {
                                            onTap(letter)
                                        }
                                    }
                            )
                    }
                }
            }
        }
        .padding(22)
        .background(RoundedRectangle(cornerRadius: 36, style: .continuous).fill(Theme.skyTop.opacity(0.45)))
        .overlay(RoundedRectangle(cornerRadius: 36, style: .continuous).stroke(.white.opacity(0.25), lineWidth: 2))
    }
}

/// Pull it to run the machine. Glows and bobs when the word is ready.
private struct Lever: View {
    let ready: Bool
    let pulled: Int
    let height: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .top) {
                Capsule().fill(Color.white.opacity(0.85))
                    .frame(width: height * 0.09, height: height * 0.75)
                Circle()
                    .fill(RadialGradient(colors: [.white, ready ? Theme.pink : Theme.lilac], center: UnitPoint(x: 0.35, y: 0.3),
                                         startRadius: 0, endRadius: height * 0.15))
                    .frame(width: height * 0.26, height: height * 0.26)
                    .offset(y: -height * 0.1)
                    .glow(ready ? Theme.pink : .clear, radius: 16)
            }
            .frame(width: max(height * 0.3, 88), height: max(height, 110))
            .contentShape(Rectangle())
            .keyframeAnimator(initialValue: 0.0, trigger: pulled) { view, angle in
                view.rotationEffect(.degrees(angle), anchor: .bottom)
            } keyframes: { _ in
                CubicKeyframe(55, duration: 0.25)
                SpringKeyframe(0, duration: 0.6, spring: .bouncy)
            }
            .phaseAnimator([false, true], trigger: ready) { view, up in
                view.offset(y: ready && up ? -10 : 0)
            }
        }
        .buttonStyle(BouncyButtonStyle(pressedScale: 0.92, sound: .drop))
        .disabled(!ready)
    }
}

/// Words built so far in this chain, stacked; read back at the end.
private struct ChainColumn: View {
    let words: [Word]
    let reading: Int?

    var body: some View {
        HStack(spacing: 10) {
            ForEach(Array(words.enumerated()), id: \.offset) { i, word in
                Text(word.text)
                    .font(.reading(30))
                    .foregroundStyle(reading == i ? Theme.skyTop : .white)
                    .padding(.horizontal, 16).padding(.vertical, 6)
                    .background(Capsule().fill(reading == i ? Theme.gold : Theme.skyTop.opacity(0.75)))
                    .overlay(Capsule().stroke(.white.opacity(0.5), lineWidth: 2))
                    .scaleEffect(reading == i ? 1.15 : 1)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: words)
        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: reading)
    }
}

/// The machine's output: the word's picture card pops out of the chute,
/// spins up big for a moment, then floats down into the chain row.
private struct ChuteCard: View {
    let word: Word
    let size: CGFloat
    let drop: CGFloat
    @State private var go = false

    struct Pop { var y: CGFloat = 0; var scale: CGFloat = 0.2; var angle: Double = 0; var opacity: Double = 0 }

    var body: some View {
        WordPicture(word: word.text, emoji: word.picture, size: size)
            .padding(size * 0.12)
            .background(RoundedRectangle(cornerRadius: size * 0.25, style: .continuous).fill(.white))
            .glow(Theme.gold, radius: 18)
            .keyframeAnimator(initialValue: Pop(), trigger: go) { view, p in
                view.offset(y: p.y).scaleEffect(p.scale).rotationEffect(.degrees(p.angle)).opacity(p.opacity)
            } keyframes: { _ in
                KeyframeTrack(\.y) {
                    CubicKeyframe(drop * 0.35, duration: 0.35)
                    SpringKeyframe(drop * 0.15, duration: 0.5, spring: .bouncy)
                    CubicKeyframe(drop * 0.15, duration: 0.6)
                    CubicKeyframe(drop, duration: 0.45)
                }
                KeyframeTrack(\.scale) {
                    SpringKeyframe(1.15, duration: 0.45, spring: .bouncy)
                    CubicKeyframe(1.0, duration: 0.9)
                    CubicKeyframe(0.3, duration: 0.45)
                }
                KeyframeTrack(\.angle) {
                    CubicKeyframe(360, duration: 0.5)
                    CubicKeyframe(360, duration: 1.25)
                }
                KeyframeTrack(\.opacity) {
                    CubicKeyframe(1, duration: 0.15)
                    CubicKeyframe(1, duration: 1.4)
                    CubicKeyframe(0, duration: 0.3)
                }
            }
            .onAppear { go = true }
    }
}
