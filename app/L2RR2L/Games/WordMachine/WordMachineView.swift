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
            var chain: WordChain? = nil
            #if DEBUG
            if let i = CommandLine.arguments.firstIndex(of: "-uitestChain"), i + 1 < CommandLine.arguments.count,
               let n = Int(CommandLine.arguments[i + 1]) {
                let chains = WordBank.chains(for: 1)
                chain = chains[n % chains.count]
            }
            #endif
            let m = WordMachineModel(services: services, chain: chain)
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
            let machineW = min(w * 0.82, m.s(760))
            let box = min(m.s(150), machineW * 0.7 / CGFloat(n) - 16)
            let gap = box * 0.2
            let machineY = h * (landscape ? 0.45 : 0.42)
            let machineH = box * 2.0
            let boxCenter = { (i: Int) -> CGPoint in
                CGPoint(x: w / 2 - machineW * 0.06 + (CGFloat(i) - CGFloat(n - 1) / 2) * (box + gap), y: machineY + box * 0.08)
            }
            let benchY = h * (landscape ? 0.8 : 0.74)
            let benchW = min(w * 0.9, m.s(820))
            let tile = min(m.s(96), benchW / 5.2)

            ZStack {
                // things she has made in this chain, as pictures (never as text)
                ChainShelf(words: model.builtWords, reading: model.phase == .scene ? model.readingIndex : nil,
                           size: m.s(model.phase == .scene ? 120 : 64))
                    .position(x: w / 2, y: model.phase == .scene ? h * 0.72 : h * (landscape ? 0.95 : 0.93))

                PictureBubble(word: model.word, size: m.s(180))
                    .position(x: w / 2, y: h * (landscape ? 0.17 : 0.19))
                    .onTapGesture { model.hearAgain() }
                    .accessibilityIdentifier("bubble")
                    .opacity(model.phase == .scene ? 0 : 1)

                MachineBody(running: model.phase == .running, width: machineW, height: machineH)
                    .position(x: w / 2, y: machineY)
                    // once the word is built, the whole machine is the lever
                    .onTapGesture { if model.phase == .complete { model.pullLever() } }

                ForEach(0..<model.boxes.count, id: \.self) { i in
                    SoundBox(letter: model.boxes[i], size: box,
                             humming: model.humming == i || model.readingIndex == i && model.phase == .running,
                             reject: model.rejectBox == i ? model.rejectCount : 0,
                             snaps: model.snapBox == i ? model.snapCount : 0,
                             target: (dragging != nil && near(dragPoint, boxCenter(i), box)) || model.heldLetter != nil)
                        .position(boxCenter(i))
                        .onTapGesture { model.tapBox(i) }
                        .accessibilityElement()
                        .accessibilityIdentifier("box-\(i)")
                        .accessibilityAddTraits(.isButton)
                        .accessibilityAction { model.tapBox(i) }
                }

                Lever(ready: model.phase == .complete, pulled: model.runCount, height: machineH * 0.9) {
                    model.pullLever()
                }
                .position(x: w / 2 + machineW / 2 - machineW * 0.08, y: machineY - machineH * 0.05)
                .accessibilityIdentifier("lever")

                if model.phase == .building || model.phase == .complete || model.phase == .idle || model.phase == .nextWord {
                    Workbench(width: benchW, height: tile * 2.6)
                        .position(x: w / 2, y: benchY)
                    ForEach(Array(model.tray.enumerated()), id: \.element) { i, letter in
                        JellyTile(letter: letter, size: tile,
                                  glow: model.heldLetter == letter || model.glowLetter == letter,
                                  dimmed: dragging == letter,
                                  space: .named("machine"),
                                  onTap: { model.tapLetter(letter) },
                                  onDrag: { point in
                                      dragging = letter
                                      dragPoint = point
                                  },
                                  onDrop: { point in
                                      dragging = nil
                                      // magnetic: a tile dropped near a box is pulled into the nearest one
                                      let nearest = (0..<model.boxes.count).min { a, b in
                                          dist(point, boxCenter(a)) < dist(point, boxCenter(b))
                                      }
                                      if let nearest, near(point, boxCenter(nearest), box) {
                                          model.drop(letter, into: nearest)
                                      }
                                  })
                            .position(scatter(i, count: model.tray.count, center: CGPoint(x: w / 2, y: benchY),
                                              width: benchW, tile: tile))
                            .transition(.scale(scale: 0.3).combined(with: .opacity))
                    }
                    .id(model.engine.index)
                }

                if model.phase == .scene {
                    RoundDonePanel(onAgain: { model.playAgain() }, onHome: { services.router.goHome() })
                        .position(x: w / 2, y: h * 0.88)
                        .transition(.scale.combined(with: .opacity))
                }

                #if DEBUG
                // the answer, for UI tests only: never drawn
                if CommandLine.arguments.contains("-uitest") {
                    Color.clear.frame(width: 1, height: 1)
                        .accessibilityElement()
                        .accessibilityIdentifier("answer")
                        .accessibilityValue(model.phase == .building ? model.target.joined(separator: " ") : "\(model.phase)")
                }
                #endif
            }
            .coordinateSpace(.named("machine"))
            .animation(.spring(response: 0.45, dampingFraction: 0.7), value: model.phase)
        }
    }

    private func dist(_ a: CGPoint, _ b: CGPoint) -> CGFloat { hypot(a.x - b.x, a.y - b.y) }

    private func near(_ p: CGPoint, _ c: CGPoint, _ box: CGFloat) -> Bool {
        dist(p, c) < box * 1.15
    }

    /// Tiles lie scattered on the bench like toys, not in a keyboard grid.
    /// Positions are fixed per slot so nothing jumps around while she plays.
    private func scatter(_ i: Int, count: Int, center: CGPoint, width: CGFloat, tile: CGFloat) -> CGPoint {
        let perRow = min(count, 4)
        let rows = (count + perRow - 1) / perRow
        let row = i / perRow, col = i % perRow
        let inRow = row == rows - 1 ? count - row * perRow : perRow
        let spacing = min(tile * 1.45, width / CGFloat(max(perRow, 1)))
        var x = center.x + (CGFloat(col) - CGFloat(inRow - 1) / 2) * spacing
        var y = center.y + (CGFloat(row) - CGFloat(rows - 1) / 2) * tile * 1.3
        // a little jitter so it looks tossed on the bench
        var rng = SeededRandom(seed: UInt64(i * 31 + count))
        x += (rng.next() - 0.5) * tile * 0.3
        y += (rng.next() - 0.5) * tile * 0.25
        return CGPoint(x: x, y: y)
    }
}

/// A soft wooden-and-cloud workbench the letter toys sit on.
private struct Workbench: View {
    let width: CGFloat
    let height: CGFloat
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: height * 0.3, style: .continuous)
                .fill(Color(red: 0.55, green: 0.38, blue: 0.62).mixed(with: .black, by: 0.25))
                .offset(y: height * 0.08)
            RoundedRectangle(cornerRadius: height * 0.3, style: .continuous)
                .fill(LinearGradient(colors: [Color(red: 0.98, green: 0.86, blue: 0.95), Color(red: 0.86, green: 0.74, blue: 0.98)],
                                     startPoint: .top, endPoint: .bottom))
            RoundedRectangle(cornerRadius: height * 0.3, style: .continuous)
                .stroke(.white.opacity(0.8), lineWidth: 3)
        }
        .frame(width: width, height: height)
        .glow(Theme.lilac, radius: 12)
    }
}

/// The things made in this chain, as picture chips. At the end of the chain
/// they grow big and light up one by one as the Star Voice reads them back.
private struct ChainShelf: View {
    let words: [Word]
    let reading: Int?
    let size: CGFloat

    var body: some View {
        HStack(spacing: size * 0.15) {
            ForEach(Array(words.enumerated()), id: \.offset) { i, word in
                WordPicture(word: word.text, emoji: word.picture, size: size)
                    .padding(size * 0.08)
                    .background(Circle().fill(.white.opacity(reading == i ? 0.95 : 0.25)))
                    .scaleEffect(reading == i ? 1.25 : 1)
                    .glow(reading == i ? Theme.gold : .clear, radius: 12)
                    .transition(.scale(scale: 0.2).combined(with: .offset(y: -200)))
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.55), value: words.count)
        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: reading)
        .allowsHitTesting(false)
    }
}

/// The word's picture floating in a bubble (tap to hear it again). Words
/// that can't be pictured show a big ear: the word is spoken, never written,
/// so she builds it from its sounds.
private struct PictureBubble: View {
    let word: Word
    let size: CGFloat

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            ZStack {
                Circle().fill(RadialGradient(colors: [.white.opacity(0.35), Theme.sky.opacity(0.25)],
                                             center: UnitPoint(x: 0.35, y: 0.3), startRadius: 0, endRadius: size * 0.6))
                Circle().stroke(.white.opacity(0.7), lineWidth: 3)
                Ellipse().fill(.white.opacity(0.5))
                    .frame(width: size * 0.35, height: size * 0.16)
                    .offset(x: -size * 0.18, y: -size * 0.3)
                if word.art != "weak", WordPicture.card(word.text) != nil || (word.picture != nil && word.picture != "🖼️") {
                    WordPicture(word: word.text, emoji: word.picture, size: size * 0.7)
                } else {
                    Image(systemName: "ear.and.waveform")
                        .font(.system(size: size * 0.38, weight: .bold))
                        .foregroundStyle(.white)
                        .symbolEffect(.variableColor.iterative, options: .repeating)
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
            .offset(y: 8 * sin(t * 1.4))
            .glow(Theme.sky, radius: 14)
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
                shape.fill(Theme.lilac.mixed(with: .black, by: 0.4)).offset(y: height * 0.07)
                shape.fill(LinearGradient(colors: [Theme.mint.mixed(with: .white, by: 0.2), Theme.sky, Theme.lilac],
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
                .foregroundStyle(target || letter == nil ? Theme.gold : .white.opacity(0.6))
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
        // an empty box glows softly: that's where the new sound goes
        .glow(humming ? Theme.gold : (letter == nil ? Theme.gold.opacity(0.55) : .clear), radius: 18)
        .keyframeAnimator(initialValue: CGFloat(0), trigger: reject) { view, x in
            view.offset(x: x)
        } keyframes: { _ in
            CubicKeyframe(-12, duration: 0.07)
            CubicKeyframe(10, duration: 0.08)
            CubicKeyframe(-6, duration: 0.08)
            SpringKeyframe(0, duration: 0.2)
        }
        // a tile landing: squash flat, spring back, with a ring of sparkles
        .keyframeAnimator(initialValue: CGFloat(1), trigger: snaps) { view, s in
            view.scaleEffect(x: 2 - s, y: s, anchor: .bottom)
        } keyframes: { _ in
            CubicKeyframe(0.72, duration: 0.07)
            SpringKeyframe(1.12, duration: 0.14)
            SpringKeyframe(1.0, duration: 0.3, spring: .bouncy)
        }
        .overlay {
            SnapRing(trigger: snaps, size: size)
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



/// A burst of little sparkles around a box when a tile lands in it.
private struct SnapRing: View {
    let trigger: Int
    let size: CGFloat
    @State private var start: Date?

    var body: some View {
        TimelineView(.animation(paused: start == nil)) { timeline in
            let t = start.map { timeline.date.timeIntervalSince($0) } ?? 1
            ZStack {
                if t < 0.5 {
                    ForEach(0..<8, id: \.self) { i in
                        let a = Double(i) / 8 * 2 * .pi
                        Image(systemName: "sparkle")
                            .font(.system(size: size * 0.14))
                            .foregroundStyle(Theme.confetti[i % Theme.confetti.count])
                            .offset(x: cos(a) * size * (0.4 + t * 1.2), y: sin(a) * size * (0.4 + t * 1.2))
                            .opacity(1 - t * 2)
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .onChange(of: trigger) { _, v in if v > 0 { start = .now } }
    }
}
