import SwiftUI

/// The home sky: Cutisie big in the middle on her cloud, three game portals
/// floating around her, the star jar in the corner. Every touch answers:
/// tapping the sky plays a twinkle melody and scatters sparkles, tapping
/// Cutisie makes her react.
struct HomeView: View {
    @Environment(AppServices.self) private var services
    @Environment(ProgressStore.self) private var progress
    @Environment(\.metrics) private var m
    @Environment(\.zoomNamespace) private var zoom
    @State private var appeared = false
    @State private var greeted = false
    @State private var reactionIndex = 0

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let landscape = w > h
            let mascotSize = min(w, h) * (landscape ? 0.46 : 0.44)
            let orb = min(w, h) * (landscape ? 0.21 : 0.22)

            ZStack {
                SkyBackground(imageName: "bg-home")
                TouchSparkles()

                ChunkyTitle(text: "Cutisie's Sky", size: m.s(54), colors: [.white, Theme.pink, Theme.lilac])
                    .position(x: w / 2, y: h * (landscape ? 0.12 : 0.12))
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : -60)

                // the world she's in, for grown-ups glancing over
                Text(Curriculum.shared.stage(progress.data.stage)?.name ?? "")
                    .font(.playful(m.s(20), weight: .bold))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.horizontal, 14).padding(.vertical, 5)
                    .background(Capsule().fill(Theme.skyTop.opacity(0.45)))
                    .position(x: w / 2, y: h * 0.12 + m.s(48))
                    .opacity(progress.data.placementDone ? 1 : 0)

                CutisieActor(size: mascotSize)
                    .position(x: w / 2, y: h * (landscape ? 0.42 : 0.35))
                    .scaleEffect(appeared ? 1 : 0.3)
                    .offset(y: appeared ? 0 : -h * 0.5)

                ForEach(Array(GameID.allCases.enumerated()), id: \.element) { index, game in
                    let spot = portalSpot(index, landscape: landscape)
                    PortalOrb(game: game, size: orb, phase: Double(index) * 2.1) {
                        services.feedback.play(.whoosh)
                        services.router.open(.game(game))
                    }
                    .background { Circle().fill(.clear).frame(width: orb, height: orb).zoomSource(game, in: zoom).offset(y: -orb * 0.1) }
                    .position(x: w * spot.x, y: h * spot.y)
                    .scaleEffect(appeared ? 1 : 0.01)
                    .animation(.spring(response: 0.6, dampingFraction: 0.55).delay(0.35 + 0.12 * Double(index)),
                               value: appeared)
                }

                // one big obvious button: today's adventure (the Sparkle Check first time)
                PlayButton(size: m.s(130)) { play() }
                    .position(x: w / 2, y: h * (landscape ? 0.66 : 0.6))
                    .scaleEffect(appeared ? 1 : 0.01)
                    .animation(.spring(response: 0.6, dampingFraction: 0.5).delay(0.8), value: appeared)

                if progress.skyTrialReady {
                    SkyTrialOrb(size: orb * 0.8) {
                        services.feedback.play(.whoosh)
                        services.router.open(.skyTrial(progress.data.stage))
                    }
                    .background { Circle().fill(.clear).frame(width: orb * 0.8, height: orb * 0.8).zoomSource("special", in: zoom) }
                    .position(x: w * (landscape ? 0.86 : 0.84), y: h * (landscape ? 0.3 : 0.3))
                    .transition(.scale.combined(with: .opacity))
                }

                StarJar()
                    .background { Capsule().fill(.clear).zoomSource("stars", in: zoom) }
                    .position(x: w - m.s(110), y: m.s(70))

                ParentGateButton()
                    .position(x: w - 40, y: h - 40)
            }
            .animation(.spring(response: 0.9, dampingFraction: 0.7), value: appeared)
        }
        .ignoresSafeArea()
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            appeared = true
            #if DEBUG
            if let game = Autopilot.soloGame, Autopilot.sessionsPlayed == 0 {
                // `-autopilot -game readAlong`: play just that game, then stop at home
                Autopilot.after(3) {
                    Autopilot.sessionsPlayed += 1
                    services.router.open(.game(game))
                }
            } else if Autopilot.enabled && (!progress.data.placementDone || Autopilot.sessionsPlayed == 0) {
                Autopilot.after(4) {
                    if progress.data.placementDone { Autopilot.sessionsPlayed += 1 }
                    play()
                }
            }
            #endif
            guard !greeted else { return }
            greeted = true
            Task {
                try? await Task.sleep(for: .seconds(0.7))
                services.mascot.react(.hello)
                try? await Task.sleep(for: .seconds(0.5))
                let line: String
                if !services.progress.data.placementDone {
                    line = "Hello, star reader! I'm the Star Voice, and this is Cutisie. Press the big button to play!"
                } else if services.progress.skyTrialReady {
                    line = "Hello, star reader! A Sky Trial is waiting. Can you help Cutisie fly to a new world?"
                } else {
                    line = "Hello, star reader! Cutisie is so happy to see you. Ready for today's adventure?"
                }
                await services.voice.say(line)
            }
        }
    }

    private func portalSpot(_ index: Int, landscape: Bool) -> UnitPoint {
        let spots: [UnitPoint] = landscape
            ? [UnitPoint(x: 0.13, y: 0.64), UnitPoint(x: 0.37, y: 0.84), UnitPoint(x: 0.63, y: 0.84), UnitPoint(x: 0.87, y: 0.64)]
            : [UnitPoint(x: 0.18, y: 0.7), UnitPoint(x: 0.35, y: 0.86), UnitPoint(x: 0.65, y: 0.86), UnitPoint(x: 0.82, y: 0.7)]
        return spots[index]
    }

    private func play() {
        services.feedback.play(.whoosh)
        if progress.data.placementDone {
            services.router.startSession(warmUp: progress.nextWarmUp(), newSound: progress.nextNewSound())
        } else {
            services.router.open(.sparkleCheck)
        }
    }

    private func tapCutisie() {
        let reactions: [MascotClip] = [.cheer, .dance, .hello, .encourage]
        services.mascot.react(reactions[reactionIndex % reactions.count])
        services.celebration.fire(.sparkle)
        reactionIndex += 1
    }
}

/// The big gold play button for today's adventure. Breathes gently so it's
/// the obvious thing to press.
struct PlayButton: View {
    let size: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "play.fill")
                .font(.system(size: size * 0.45, weight: .black))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.25), radius: 0, y: 3)
                .frame(width: size * 1.5, height: size)
        }
        .buttonStyle(.chunky(Theme.gold, depth: size * 0.1, cornerRadius: size * 0.5))
        .phaseAnimator([1.0, 1.06]) { view, scale in
            view.scaleEffect(scale)
        } animation: { _ in .easeInOut(duration: 1.1) }
        .accessibilityLabel("Play today's adventure")
    }
}

/// Appears when the current world's Sky Trial is ready.
struct SkyTrialOrb: View {
    let size: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle().fill(RadialGradient(colors: [.white, Theme.gold, Theme.peach], center: UnitPoint(x: 0.35, y: 0.3),
                                             startRadius: 0, endRadius: size * 0.6))
                Image(systemName: "rainbow")
                    .font(.system(size: size * 0.42, weight: .bold))
                    .symbolRenderingMode(.multicolor)
            }
            .frame(width: size, height: size)
            .glow(Theme.gold, radius: 20)
            .phaseAnimator([0.0, 1.0]) { view, p in
                view.rotationEffect(.degrees(-6 + 12 * p)).scaleEffect(1 + 0.05 * p)
            } animation: { _ in .easeInOut(duration: 0.9) }
        }
        .buttonStyle(BouncyButtonStyle(pressedScale: 0.88, sound: .pick))
        .accessibilityLabel("Sky Trial")
    }
}

/// A floating, glossy bubble-world for one game: candy orb with a spinning
/// rainbow rim, the game's icon bouncing inside, and its name on a ribbon.
/// Bobs on its own phase and tilts with the iPad.
struct PortalOrb: View {
    let game: GameID
    let size: CGFloat
    let phase: Double
    let action: () -> Void

    @Environment(ParallaxMotion.self) private var motion
    @State private var bounce = 0

    var body: some View {
        Button(action: action) {
            TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                VStack(spacing: -size * 0.08) {
                    orb(t: t)
                    ChunkyTitle(text: game.title, size: size * 0.17, colors: [.white, game.colors[0]],
                                extrude: game.colors[1].mixed(with: .black, by: 0.5))
                        .fixedSize()
                }
                .offset(y: 10 * sin(t * 1.3 + phase))
                .rotationEffect(.degrees(3 * sin(t * 0.9 + phase)))
                .offset(x: motion.offset.width * 22, y: motion.offset.height * 14)
            }
        }
        .buttonStyle(BouncyButtonStyle(pressedScale: 0.86, sound: .pick))
        .task {
            // the icon hops every few seconds so the portals feel alive
            try? await Task.sleep(for: .seconds(1.5 + phase))
            while !Task.isCancelled {
                bounce += 1
                try? await Task.sleep(for: .seconds(4.5))
            }
        }
    }

    private func orb(t: Double) -> some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [game.colors[0].mixed(with: .white, by: 0.25), game.colors[1], game.colors[1].mixed(with: Theme.skyTop, by: 0.5)],
                                     center: UnitPoint(x: 0.35, y: 0.3), startRadius: 0, endRadius: size * 0.7))
            // inner swirl
            Circle()
                .fill(AngularGradient(colors: [.white.opacity(0), .white.opacity(0.25), .white.opacity(0)], center: .center))
                .rotationEffect(.degrees(t * 25))
                .padding(size * 0.08)
            Image(systemName: game.symbol)
                .font(.system(size: size * 0.42, weight: .bold))
                .symbolRenderingMode(game == .stretchyBlend ? .multicolor : .hierarchical)
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.25), radius: 0, y: 4)
                .symbolEffect(.bounce, value: bounce)
            // glossy highlight
            Ellipse()
                .fill(LinearGradient(colors: [.white.opacity(0.75), .white.opacity(0)], startPoint: .top, endPoint: .bottom))
                .frame(width: size * 0.55, height: size * 0.28)
                .offset(x: -size * 0.12, y: -size * 0.27)
                .rotationEffect(.degrees(-15))
        }
        .frame(width: size, height: size)
        .overlay(
            Circle().stroke(AngularGradient(colors: [Theme.pink, Theme.gold, Theme.mint, Theme.sky, Theme.lilac, Theme.pink],
                                            center: .center), lineWidth: size * 0.05)
                .rotationEffect(.degrees(t * 40))
        )
        .background(Circle().fill(game.colors[0].opacity(0.6)).blur(radius: size * 0.12).scaleEffect(1.1))
    }
}

/// Star count in a chunky glowing jar-pill; opens the sticker word book.
struct StarJar: View {
    @Environment(AppServices.self) private var services
    @Environment(ProgressStore.self) private var progress
    @Environment(\.metrics) private var m

    var body: some View {
        Button {
            services.router.open(.stickerBook)
        } label: {
            HStack(spacing: m.s(10)) {
                Image(systemName: "star.fill")
                    .foregroundStyle(Theme.gold)
                    .shadow(color: Theme.gold, radius: 8)
                    .symbolEffect(.bounce, value: progress.data.stars)
                Text("\(progress.data.stars)")
                    .contentTransition(.numericText())
                    .animation(.spring, value: progress.data.stars)
                    .foregroundStyle(.white)
            }
            .font(.system(size: m.s(38), weight: .black, design: .rounded))
            .shadow(color: .black.opacity(0.3), radius: 0, y: 2)
            .padding(.horizontal, m.s(26))
            .frame(height: m.s(80))
        }
        .buttonStyle(.chunky(Theme.lilac, depth: m.s(8), cornerRadius: m.s(40)))
    }
}

/// Tap the sky and it answers: sparkles burst where the finger lands and
/// each tap plays the next note of a twinkly pentatonic tune.
struct TouchSparkles: View {
    @Environment(AppServices.self) private var services
    @State private var bursts: [(id: UUID, at: CGPoint, start: Date)] = []

    var body: some View {
        TimelineView(.animation(paused: bursts.isEmpty)) { timeline in
            Canvas { ctx, _ in
                let now = timeline.date
                for burst in bursts {
                    let t = now.timeIntervalSince(burst.start)
                    guard t < 0.9 else { continue }
                    let progress = t / 0.9
                    for i in 0..<10 {
                        let angle = Double(i) / 10 * 2 * .pi
                        let dist = 70 * (1 - pow(1 - progress, 3))
                        let p = CGPoint(x: burst.at.x + cos(angle) * dist, y: burst.at.y + sin(angle) * dist)
                        let r = 6 * (1 - progress) + 1
                        ctx.fill(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)),
                                 with: .color(Theme.confetti[i % Theme.confetti.count].opacity(1 - progress)))
                    }
                    let ring = 90 * progress
                    ctx.stroke(Path(ellipseIn: CGRect(x: burst.at.x - ring, y: burst.at.y - ring, width: ring * 2, height: ring * 2)),
                               with: .color(.white.opacity(0.6 * (1 - progress))), lineWidth: 2)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(coordinateSpace: .local) { point in
            services.feedback.play(.twinkle)
            let now = Date()
            bursts.removeAll { now.timeIntervalSince($0.start) > 1 }
            bursts.append((UUID(), point, now))
        }
    }
}

#Preview {
    NavigationStack { HomeView() }.withServices(.preview())
}
