import SwiftUI

/// The core payoff (design v2, 3.1): the letters of the word she just read
/// jump up, swirl together and puff into the thing they spell, which pops,
/// wiggles, makes its sound and then floats away to her star jar. About 1.8 s;
/// a tap skips it.
struct WordAliveOverlay: View {
    @Environment(CelebrationCenter.self) private var center
    @Environment(AppServices.self) private var services

    var body: some View {
        ZStack {
            if let alive = center.alive {
                AliveAnimation(word: alive.word) {
                    if center.alive?.id == alive.id { center.alive = nil }
                }
                .id(alive.id)
                .contentShape(Rectangle())
                .onTapGesture { center.alive = nil }
            }
        }
        .allowsHitTesting(center.alive != nil)
    }
}

private struct AliveAnimation: View {
    let word: Word
    let done: () -> Void

    @Environment(AppServices.self) private var services
    @State private var start = Date()
    @State private var popped = false

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let center = CGPoint(x: w / 2, y: h * 0.42)
            let letterSize = min(w, h) * 0.16
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSince(start)
                ZStack {
                    // 1. letters hop up, then spiral into the middle and shrink (0 - 0.75 s)
                    let n = max(word.graphemes.count, 1)
                    ForEach(Array(word.graphemes.enumerated()), id: \.offset) { i, g in
                        let startX = center.x + (CGFloat(i) - CGFloat(n - 1) / 2) * letterSize * 1.1
                        let hop = t < 0.25 ? -sin(t / 0.25 * .pi) * letterSize * 0.6 : 0
                        let s = max(0, min(1, (t - 0.25) / 0.5))
                        let ease = s * s * (3 - 2 * s)
                        let angle = Double(ease) * .pi * 2.5 + Double(i)
                        let radius = (1 - ease) * abs(startX - center.x) + (1 - ease) * 4
                        let x = startX + (center.x - startX) * ease + cos(angle) * radius * 0.3 * ease
                        let y = center.y + hop + sin(angle) * radius * 0.3 * ease
                        Text(g)
                            .font(.reading(letterSize * 0.8))
                            .foregroundStyle(Theme.skyTop)
                            .frame(width: letterSize, height: letterSize)
                            .background(RoundedRectangle(cornerRadius: letterSize * 0.3, style: .continuous).fill(.white))
                            .glow(Theme.gold, radius: 10)
                            .scaleEffect(1 - 0.85 * ease)
                            .rotationEffect(.degrees(Double(ease) * 540))
                            .position(x: x, y: y)
                            .opacity(t < 0.75 ? 1 : 0)
                    }

                    // 2. the puff (0.7 - 1.1 s)
                    if t > 0.7 && t < 1.2 {
                        let p = (t - 0.7) / 0.5
                        ForEach(0..<14, id: \.self) { i in
                            let a = Double(i) / 14 * 2 * .pi
                            Circle()
                                .fill(Theme.confetti[i % Theme.confetti.count].opacity(1 - p))
                                .frame(width: letterSize * 0.3 * (1 - p) + 4, height: letterSize * 0.3 * (1 - p) + 4)
                                .position(x: center.x + cos(a) * letterSize * 1.6 * p, y: center.y + sin(a) * letterSize * 1.6 * p)
                        }
                        Circle()
                            .fill(.white.opacity(0.8 * (1 - p)))
                            .frame(width: letterSize * 2.5 * p, height: letterSize * 2.5 * p)
                            .position(center)
                    }

                    // 3. the thing pops out, wiggles, then floats to the star jar (0.75 - 2.0 s)
                    if t > 0.75 {
                        let q = t - 0.75
                        let fly = max(0, min(1, (q - 0.85) / 0.4))
                        let pop = q < 0.25 ? q / 0.25 * 1.25 : 1.25 - 0.25 * min(1, (q - 0.25) / 0.2)
                        let wiggle = q > 0.3 && q < 0.85 ? sin(q * 30) * 10 : 0
                        let target = CGPoint(x: w - 70, y: 60)
                        WordPicture(word: word.text, emoji: word.picture, size: min(w, h) * 0.42)
                            .scaleEffect(pop * (1 - 0.8 * fly))
                            .rotationEffect(.degrees(wiggle))
                            .position(x: center.x + (target.x - center.x) * fly * fly,
                                      y: center.y + (target.y - center.y) * fly - sin(fly * .pi) * 80)
                            .opacity(1 - fly * 0.6)
                            .shadow(color: Theme.gold.opacity(0.8), radius: 30)
                    }
                }
                .onChange(of: t > 0.75) { _, now in
                    if now && !popped {
                        popped = true
                        services.sounds.play(.pop)
                        services.sounds.playPack("swoosh_in")
                        services.haptics.play(.success)
                    }
                }
                .onChange(of: t > 2.1) { _, now in if now { done() } }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            start = .now
            services.sounds.playPack("magic_zap")
        }
    }
}
