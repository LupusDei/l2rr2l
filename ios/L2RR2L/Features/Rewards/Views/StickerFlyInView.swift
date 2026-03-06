import SwiftUI

/// Overlay that animates a sticker flying from the results area to a target
/// (sticker-book icon) with a sparkle trail and "New Sticker!" pop-up.
///
/// Usage: Apply `.stickerFlyIn(sticker:)` on any game completion view.
struct StickerFlyInView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let sticker: Sticker
    let onComplete: (() -> Void)?

    @State private var flyProgress: CGFloat = 0
    @State private var showLabel = false
    @State private var labelScale: CGFloat = 0.3
    @State private var labelOpacity: Double = 0
    @State private var trailParticles: [TrailParticle] = []
    @State private var stickerScale: CGFloat = 1.5
    @State private var stickerOpacity: Double = 1
    @State private var startTime: Date?

    /// Source: lower center (results area). Destination: upper-right (trophy icon area).
    private let sourcePoint = CGPoint(x: 0.5, y: 0.7)
    private let destinationPoint = CGPoint(x: 0.85, y: 0.08)

    init(sticker: Sticker, onComplete: (() -> Void)? = nil) {
        self.sticker = sticker
        self.onComplete = onComplete
    }

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let start = CGPoint(x: size.width * sourcePoint.x, y: size.height * sourcePoint.y)
            let end = CGPoint(x: size.width * destinationPoint.x, y: size.height * destinationPoint.y)
            let current = interpolatedPosition(from: start, to: end, progress: flyProgress)

            ZStack {
                // Trail particles
                if !reduceMotion {
                    trailLayer
                }

                // Flying sticker emoji
                Text(sticker.emoji)
                    .font(.system(size: 48))
                    .scaleEffect(stickerScale)
                    .opacity(stickerOpacity)
                    .position(current)
                    .shadow(color: trailColor.opacity(0.5), radius: 8)

                // "New Sticker!" label
                if showLabel {
                    newStickerLabel
                        .position(x: size.width * 0.5, y: size.height * 0.4)
                }
            }
            .onAppear {
                startAnimation(containerSize: size, from: start, to: end)
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Trail Layer

    private var trailLayer: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, _ in
                let now = timeline.date.timeIntervalSinceReferenceDate
                for particle in trailParticles {
                    let elapsed = now - particle.spawnTime
                    guard elapsed >= 0, elapsed < particle.lifetime else { continue }

                    let fade = 1.0 - (elapsed / particle.lifetime)
                    let shrink = max(0.2, 1.0 - elapsed / particle.lifetime)
                    let driftX = particle.driftX * elapsed
                    let driftY = particle.driftY * elapsed

                    context.opacity = fade * 0.8
                    let x = particle.x + driftX
                    let y = particle.y + driftY
                    let s = particle.size * shrink

                    let rect = CGRect(x: x - s / 2, y: y - s / 2, width: s, height: s)

                    switch particle.shape {
                    case .circle:
                        context.fill(Path(ellipseIn: rect), with: .color(particle.color))
                    case .star:
                        context.fill(miniStarPath(in: rect), with: .color(particle.color))
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Label

    private var newStickerLabel: some View {
        VStack(spacing: L2RTheme.Spacing.xs) {
            Text("New Sticker!")
                .font(L2RTheme.Typography.Scaled.playful(relativeTo: .title2, weight: .bold))
                .foregroundStyle(.white)

            Text(sticker.displayName)
                .font(L2RTheme.Typography.Scaled.playful(relativeTo: .headline, weight: .bold))
                .foregroundStyle(.white.opacity(0.9))

            badgeView
        }
        .padding(.horizontal, L2RTheme.Spacing.xl)
        .padding(.vertical, L2RTheme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.large)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.large)
                        .stroke(.white.opacity(0.3), lineWidth: 1)
                )
        )
        .scaleEffect(labelScale)
        .opacity(labelOpacity)
    }

    private var badgeView: some View {
        Group {
            if sticker.type != .normal {
                Text(sticker.type == .golden ? "GOLDEN" : "SPECIAL")
                    .font(L2RTheme.Typography.Scaled.system(.caption, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, L2RTheme.Spacing.sm)
                    .padding(.vertical, L2RTheme.Spacing.xxs)
                    .background(
                        Capsule()
                            .fill(sticker.type == .golden
                                  ? L2RTheme.Logo.yellow
                                  : L2RTheme.Logo.purple)
                    )
            }
        }
    }

    // MARK: - Animation

    private func startAnimation(containerSize: CGSize, from start: CGPoint, to end: CGPoint) {
        HapticService.shared.levelComplete()
        SoundEffectService.shared.play(.levelComplete)

        if reduceMotion {
            showLabel = true
            labelScale = 1.0
            labelOpacity = 1.0
            stickerOpacity = 0

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                onComplete?()
            }
            return
        }

        let now = Date().timeIntervalSinceReferenceDate
        startTime = Date()

        // Phase 1: Fly sticker along curved path (0.8s)
        let flyDuration = 0.8
        let trailInterval = 0.03
        var trailTimer: Timer?

        trailTimer = Timer.scheduledTimer(withTimeInterval: trailInterval, repeats: true) { timer in
            let elapsed = Date().timeIntervalSinceReferenceDate - now
            let progress = min(elapsed / flyDuration, 1.0)
            let pos = interpolatedPosition(from: start, to: end, progress: CGFloat(progress))

            for _ in 0..<2 {
                let particle = TrailParticle(
                    x: pos.x + CGFloat.random(in: -4...4),
                    y: pos.y + CGFloat.random(in: -4...4),
                    size: CGFloat.random(in: 4...10),
                    color: trailColors.randomElement() ?? L2RTheme.Logo.yellow,
                    shape: Bool.random() ? .circle : .star,
                    driftX: Double.random(in: -20...20),
                    driftY: Double.random(in: -30...10),
                    lifetime: Double.random(in: 0.4...0.8),
                    spawnTime: Date().timeIntervalSinceReferenceDate
                )
                trailParticles.append(particle)
            }

            if progress >= 1.0 {
                timer.invalidate()
            }
        }

        withAnimation(.easeInOut(duration: flyDuration)) {
            flyProgress = 1.0
        }

        withAnimation(.easeIn(duration: flyDuration)) {
            stickerScale = 0.5
        }

        // Phase 2: Pop sticker away, show label
        DispatchQueue.main.asyncAfter(deadline: .now() + flyDuration + 0.1) {
            trailTimer?.invalidate()

            withAnimation(.easeOut(duration: 0.2)) {
                stickerOpacity = 0
            }

            showLabel = true
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                labelScale = 1.0
                labelOpacity = 1.0
            }

            HapticService.shared.correctAnswer()
        }

        // Phase 3: Clean up trail
        DispatchQueue.main.asyncAfter(deadline: .now() + flyDuration + 1.5) {
            trailParticles.removeAll()
        }

        // Phase 4: Fade label and complete
        DispatchQueue.main.asyncAfter(deadline: .now() + flyDuration + 2.5) {
            withAnimation(.easeOut(duration: 0.4)) {
                labelOpacity = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + flyDuration + 3.0) {
            onComplete?()
        }
    }

    // MARK: - Path Interpolation

    private func interpolatedPosition(from start: CGPoint, to end: CGPoint, progress: CGFloat) -> CGPoint {
        let t = progress
        let controlPoint = CGPoint(
            x: (start.x + end.x) / 2,
            y: min(start.y, end.y) - 80
        )

        let x = (1 - t) * (1 - t) * start.x + 2 * (1 - t) * t * controlPoint.x + t * t * end.x
        let y = (1 - t) * (1 - t) * start.y + 2 * (1 - t) * t * controlPoint.y + t * t * end.y

        return CGPoint(x: x, y: y)
    }

    // MARK: - Helpers

    private var trailColor: Color {
        switch sticker.type {
        case .golden: return L2RTheme.Logo.yellow
        case .special: return L2RTheme.Logo.purple
        case .normal: return L2RTheme.Logo.blue
        }
    }

    private var trailColors: [Color] {
        switch sticker.type {
        case .golden: return [L2RTheme.Logo.yellow, L2RTheme.Logo.orange, .white]
        case .special: return [L2RTheme.Logo.purple, L2RTheme.Logo.blue, .white]
        case .normal: return [L2RTheme.Logo.blue, L2RTheme.Logo.green, .white]
        }
    }

    private func miniStarPath(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = rect.width / 2
        let inner = outer * 0.4
        var path = Path()
        for i in 0..<10 {
            let angle = (Double(i) * .pi / 5) - (.pi / 2)
            let r = i.isMultiple(of: 2) ? outer : inner
            let pt = CGPoint(x: center.x + CGFloat(cos(angle)) * r,
                             y: center.y + CGFloat(sin(angle)) * r)
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Trail Particle

private struct TrailParticle: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let color: Color
    let shape: TrailShape
    let driftX: Double
    let driftY: Double
    let lifetime: Double
    let spawnTime: TimeInterval

    enum TrailShape {
        case circle
        case star
    }
}

// MARK: - View Modifier

struct StickerFlyInModifier: ViewModifier {
    let sticker: Sticker?
    let onComplete: (() -> Void)?

    func body(content: Content) -> some View {
        content
            .overlay {
                if let sticker {
                    StickerFlyInView(sticker: sticker, onComplete: onComplete)
                }
            }
    }
}

extension View {
    /// Shows a sticker fly-in animation overlay when a sticker is earned.
    func stickerFlyIn(sticker: Sticker?, onComplete: (() -> Void)? = nil) -> some View {
        modifier(StickerFlyInModifier(sticker: sticker, onComplete: onComplete))
    }
}
