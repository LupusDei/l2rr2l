import SwiftUI

/// The end-of-session treasure (learning path 9, game spec 5): a collectible
/// for every finished session, treats earned from stars to feed Cutisie, and
/// the mystery egg that hatches a surprise once she has been fed enough.
struct TreasureView: View {
    let fromSession: Bool

    @Environment(AppServices.self) private var services
    @Environment(ProgressStore.self) private var progress
    @Environment(\.metrics) private var m
    @State private var prize: String?
    @State private var showPrize = false
    @State private var flyingTreat: Int?
    @State private var hatched: String?
    @State private var eggWobble = 0
    @State private var leaving = false

    private let treatArt = ["🍓", "🧁", "🍪", "🌟", "🍬"]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                SkyBackground(tint: Theme.gold, imageName: "bg-treasure")
                TouchSparkles()

                CutisieActor(size: min(w, h) * 0.42)
                    .position(x: w * 0.5, y: h * 0.33)

                // the painted chests and egg in the background aren't
                // tappable, so dim the painting and let the real things pop
                Color.black.opacity(0.35).ignoresSafeArea().allowsHitTesting(false)

                // treats to feed her, or (with none left) how to earn the next one
                VStack(spacing: m.s(14)) {
                    if progress.data.treats == 0 {
                        TreatMeter(stars: progress.data.stars % ProgressStore.starsPerTreat,
                                   needed: ProgressStore.starsPerTreat, size: m.s(46))
                    } else {
                        HStack(spacing: m.s(18)) {
                            ForEach(0..<min(progress.data.treats, 8), id: \.self) { i in
                                Button { feed(i) } label: {
                                    Text(treatArt[i % treatArt.count])
                                        .font(.system(size: m.s(64)))
                                        .frame(width: m.s(100), height: m.s(100))
                                }
                                .buttonStyle(.chunky(Theme.pink, depth: m.s(8), cornerRadius: m.s(30)))
                                .opacity(flyingTreat == i ? 0 : 1)
                                .overlay(alignment: .bottomTrailing) {
                                    if i == 0 && flyingTreat == nil { TapHint(size: m.s(54)).offset(x: m.s(24), y: m.s(30)) }
                                }
                            }
                        }
                    }
                }
                .position(x: w / 2, y: h * 0.6)

                if let i = flyingTreat {
                    Text(treatArt[i % treatArt.count])
                        .font(.system(size: m.s(70)))
                        .position(x: w / 2, y: h * 0.36)
                        .transition(.asymmetric(insertion: .offset(y: h * 0.24).combined(with: .scale(scale: 1.4)),
                                                removal: .scale(scale: 0.1).combined(with: .opacity)))
                }

                // the mystery egg, with one warm dot per treat fed
                let eggReady = progress.data.eggProgress >= ProgressStore.treatsPerEgg
                VStack(spacing: m.s(10)) {
                    MysteryEgg(progress: progress.data.eggProgress, needed: ProgressStore.treatsPerEgg,
                               wobble: eggWobble, size: m.s(150)) { hatch() }
                        .overlay(alignment: .bottomTrailing) {
                            if eggReady { TapHint(size: m.s(54)).offset(x: m.s(20), y: m.s(20)) }
                        }
                    HStack(spacing: m.s(8)) {
                        ForEach(0..<ProgressStore.treatsPerEgg, id: \.self) { i in
                            Circle()
                                .fill(i < progress.data.eggProgress ? Theme.gold : .white.opacity(0.3))
                                .frame(width: m.s(16), height: m.s(16))
                                .glow(i < progress.data.eggProgress ? Theme.gold : .clear, radius: 5)
                        }
                    }
                }
                .padding(m.s(16))
                .background(Circle().fill(Theme.skyTop.opacity(0.55)).padding(-m.s(10)))
                .position(x: w * 0.82, y: h * 0.5)

                // her growing sky home
                CollectionShelf(items: progress.data.collectibles + progress.data.hatched)
                    .frame(width: w * 0.8)
                    .position(x: w / 2, y: h * 0.78)

                if showPrize, let prize {
                    PrizeReveal(emoji: prize)
                        .position(x: w / 2, y: h * 0.42)
                        .transition(.scale(scale: 0.2).combined(with: .opacity))
                        .onTapGesture { withAnimation { showPrize = false } }
                }
                if let hatched {
                    PrizeReveal(emoji: hatched)
                        .position(x: w / 2, y: h * 0.42)
                        .transition(.scale(scale: 0.2).combined(with: .opacity))
                        .onTapGesture { withAnimation { self.hatched = nil } }
                }

                VStack {
                    HStack {
                        BubbleIconButton(systemName: "house.fill", color: Theme.gold) { goodbye() }
                        Spacer()
                        StarJar()
                    }
                    Spacer()
                }
                .padding(m.s(24))
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showPrize)
            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: hatched)
            .animation(.easeInOut(duration: 0.55), value: flyingTreat)
        }
        .toolbar(.hidden, for: .navigationBar)
        .adaptiveMetrics()
        .task { await open() }
    }

    private func open() async {
        services.mascot.react(.hello)
        if fromSession {
            prize = services.progress.completeSession()
            try? await Task.sleep(for: .seconds(0.8))
            services.feedback.play(.sticker)
            services.celebration.fire(.fireworks)
            showPrize = true
            await services.voice.say("You finished today's adventure! Here's a treasure for Cutisie's sky!")
            try? await Task.sleep(for: .seconds(1.0))
            showPrize = false // it flies onto her shelf
        }
        if services.progress.data.treats > 0 {
            await services.voice.say("Cutisie is hungry. Tap a treat to feed her!")
        } else if services.progress.data.eggProgress < ProgressStore.treatsPerEgg {
            await services.voice.say("Every five stars makes a treat. Feed Cutisie treats to hatch the egg!")
        }
        if services.progress.data.eggProgress >= ProgressStore.treatsPerEgg { eggWobble += 1 }
        #if DEBUG
        if Autopilot.enabled {
            while services.progress.data.treats > 0 {
                try? await Task.sleep(for: .seconds(2.5))
                feed(0)
            }
            try? await Task.sleep(for: .seconds(3))
            hatch()
            try? await Task.sleep(for: .seconds(4))
            goodbye()
        }
        #endif
    }

    private func feed(_ i: Int) {
        guard flyingTreat == nil, services.progress.data.treats > 0 else { return }
        flyingTreat = i
        services.feedback.play(.whoosh)
        Task {
            try? await Task.sleep(for: .seconds(0.55))
            let ready = services.progress.feedTreat()
            flyingTreat = nil
            services.mascot.react(.eatTreat)
            services.sounds.playPack("munch")
            services.celebration.fire(.sparkle)
            if ready {
                try? await Task.sleep(for: .seconds(1.2))
                eggWobble += 1
                services.sounds.playPack("egg_wobble")
                services.voice.announce("The egg is wiggling! Tap it!")
            }
        }
    }

    private func hatch() {
        guard services.progress.data.eggProgress >= ProgressStore.treatsPerEgg else {
            services.sounds.playPack("egg_wobble")
            eggWobble += 1
            services.voice.announce("Feed Cutisie to warm up the egg!")
            return
        }
        let surprise = Collectibles.eggSurprises.randomElement()!
        services.mascot.react(.openEgg)
        services.sounds.playPack("egg_pop")
        services.progress.hatchEgg(into: surprise)
        services.celebration.fire(.fireworks)
        hatched = surprise
        services.voice.announce("A new friend for Cutisie!")
        Task {
            try? await Task.sleep(for: .seconds(3.5))
            hatched = nil
        }
    }

    private func goodbye() {
        guard !leaving else { return }
        leaving = true
        services.mascot.react(.goodbye)
        Task {
            await services.voice.say(fromSession ? "Bye bye, star reader! See you tomorrow!" : "Bye bye!")
            services.router.goHome()
        }
    }
}

/// No treats yet: stars filling toward the next treat (5 stars = 1 treat).
private struct TreatMeter: View {
    let stars: Int
    let needed: Int
    let size: CGFloat

    var body: some View {
        HStack(spacing: size * 0.18) {
            ForEach(0..<needed, id: \.self) { i in
                Image(systemName: "star.fill")
                    .font(.system(size: size * 0.7))
                    .foregroundStyle(i < stars ? Theme.gold : .white.opacity(0.3))
                    .glow(i < stars ? Theme.gold : .clear, radius: 6)
            }
            Image(systemName: "arrow.right")
                .font(.system(size: size * 0.5, weight: .heavy))
                .foregroundStyle(.white.opacity(0.8))
            Text("🍓")
                .font(.system(size: size))
                .opacity(0.5)
        }
        .padding(.horizontal, size * 0.5)
        .padding(.vertical, size * 0.3)
        .background(Capsule().fill(Theme.skyTop.opacity(0.6)))
        .overlay(Capsule().stroke(.white.opacity(0.4), lineWidth: 2))
    }
}

/// A bobbing pointing hand that says "tap this".
private struct TapHint: View {
    let size: CGFloat

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Image(systemName: "hand.point.up.left.fill")
                .font(.system(size: size))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.4), radius: 4)
                .offset(x: -6 * abs(sin(t * 3)), y: -8 * abs(sin(t * 3)))
        }
        .allowsHitTesting(false)
    }
}

/// The egg: fills with warmth as Cutisie is fed; wobbles when ready.
private struct MysteryEgg: View {
    let progress: Int
    let needed: Int
    let wobble: Int
    let size: CGFloat
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .trim(from: 0, to: CGFloat(min(progress, needed)) / CGFloat(needed))
                    .stroke(Theme.gold, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: size * 1.15, height: size * 1.15)
                    .glow(Theme.gold, radius: 8)
                Text("🥚")
                    .font(.system(size: size * 0.75))
            }
        }
        .buttonStyle(BouncyButtonStyle(pressedScale: 0.9, sound: .pop))
        .keyframeAnimator(initialValue: 0.0, trigger: wobble) { view, angle in
            view.rotationEffect(.degrees(angle))
        } keyframes: { _ in
            CubicKeyframe(-14, duration: 0.1)
            CubicKeyframe(12, duration: 0.12)
            CubicKeyframe(-10, duration: 0.12)
            CubicKeyframe(8, duration: 0.12)
            SpringKeyframe(0, duration: 0.3)
        }
    }
}

private struct PrizeReveal: View {
    let emoji: String
    var body: some View {
        Text(emoji)
            .font(.system(size: 180))
            .padding(50)
            .background(Circle().fill(Theme.skyBottom.opacity(0.85)))
            .overlay(Circle().stroke(Theme.gold, lineWidth: 6))
            .glow(Theme.gold, radius: 30)
    }
}

/// Everything she has collected, on a glowing shelf of cloud.
struct CollectionShelf: View {
    let items: [String]
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    Text(item).font(.system(size: 48))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(Capsule().fill(.white.opacity(0.18)))
        .overlay(Capsule().stroke(.white.opacity(0.4), lineWidth: 2))
        .opacity(items.isEmpty ? 0 : 1)
    }
}
