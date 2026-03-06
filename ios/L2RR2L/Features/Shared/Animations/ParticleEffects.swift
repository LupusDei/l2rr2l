import SwiftUI

// MARK: - Particle Model

/// A single particle with physics properties for animation.
struct JuiceParticle: Identifiable {
    let id = UUID()
    let startX: CGFloat
    let startY: CGFloat
    let velocityX: Double
    let velocityY: Double
    let rotation: Double
    let rotationSpeed: Double
    let size: CGFloat
    let color: Color
    let shape: JuiceParticleShape
    let startTime: TimeInterval
}

enum JuiceParticleShape: CaseIterable {
    case circle
    case star
}

// MARK: - ParticleEmitter

/// Reusable particle system that emits colored shapes with physics.
/// Used by juicyCorrect and juicyDrag modifiers.
struct ParticleEmitter: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let isActive: Bool
    let origin: CGPoint
    let particleCount: Int
    let colors: [Color]
    let shapes: [JuiceParticleShape]
    let gravity: CGFloat
    let speed: Double
    let duration: Double

    @State private var particles: [JuiceParticle] = []

    init(
        isActive: Bool,
        origin: CGPoint = .zero,
        particleCount: Int = 20,
        colors: [Color] = L2RTheme.Logo.all,
        shapes: [JuiceParticleShape] = JuiceParticleShape.allCases,
        gravity: CGFloat = 200,
        speed: Double = 150,
        duration: Double = 1.5
    ) {
        self.isActive = isActive
        self.origin = origin
        self.particleCount = particleCount
        self.colors = colors
        self.shapes = shapes
        self.gravity = gravity
        self.speed = speed
        self.duration = duration
    }

    var body: some View {
        if reduceMotion {
            Color.clear
        } else {
            TimelineView(.animation) { timeline in
                Canvas { context, _ in
                    let now = timeline.date.timeIntervalSinceReferenceDate
                    for particle in particles {
                        let elapsed = now - particle.startTime
                        guard elapsed >= 0, elapsed < duration else { continue }

                        let progress = elapsed / duration
                        let opacity = 1.0 - progress * progress

                        let x = particle.startX + particle.velocityX * elapsed
                        let y = particle.startY + particle.velocityY * elapsed
                            + 0.5 * Double(gravity) * elapsed * elapsed
                        let angle = Angle(degrees: particle.rotation + particle.rotationSpeed * elapsed * 360)

                        context.opacity = opacity
                        context.translateBy(x: x, y: y)
                        context.rotate(by: angle)

                        let rect = CGRect(
                            x: -particle.size / 2,
                            y: -particle.size / 2,
                            width: particle.size,
                            height: particle.size
                        )

                        switch particle.shape {
                        case .circle:
                            context.fill(Path(ellipseIn: rect), with: .color(particle.color))
                        case .star:
                            context.fill(starPath(in: rect), with: .color(particle.color))
                        }

                        context.rotate(by: -angle)
                        context.translateBy(x: -x, y: -y)
                    }
                }
            }
            .allowsHitTesting(false)
            .onChange(of: isActive) { _, active in
                if active { spawnParticles() }
            }
        }
    }

    private func spawnParticles() {
        let now = Date().timeIntervalSinceReferenceDate
        particles = (0..<particleCount).map { _ in
            let angle = Double.random(in: 0...(2 * .pi))
            let spd = Double.random(in: speed * 0.5...speed)
            return JuiceParticle(
                startX: origin.x + CGFloat.random(in: -5...5),
                startY: origin.y + CGFloat.random(in: -5...5),
                velocityX: cos(angle) * spd,
                velocityY: sin(angle) * spd - Double.random(in: 50...100),
                rotation: Double.random(in: 0...360),
                rotationSpeed: Double.random(in: 0.3...1.5) * (Bool.random() ? 1 : -1),
                size: CGFloat.random(in: 4...10),
                color: colors.randomElement() ?? L2RTheme.Logo.yellow,
                shape: shapes.randomElement() ?? .circle,
                startTime: now + Double.random(in: 0...0.05)
            )
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.2) {
            particles.removeAll()
        }
    }

    private func starPath(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = rect.width / 2
        let innerRadius = outerRadius * 0.4
        let points = 5
        var path = Path()

        for i in 0..<(points * 2) {
            let angle = (Double(i) * .pi / Double(points)) - (.pi / 2)
            let radius = i.isMultiple(of: 2) ? outerRadius : innerRadius
            let point = CGPoint(
                x: center.x + CGFloat(cos(angle)) * radius,
                y: center.y + CGFloat(sin(angle)) * radius
            )
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - StarBurst

/// Star-shaped particles that burst outward and fade.
/// Used by juicyCorrect for celebration feedback.
struct StarBurst: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let isActive: Bool
    let starCount: Int
    let colors: [Color]
    let burstRadius: CGFloat
    let duration: Double

    @State private var stars: [BurstStar] = []
    @State private var animationProgress: CGFloat = 0

    init(
        isActive: Bool,
        starCount: Int = 12,
        colors: [Color] = [L2RTheme.Logo.yellow, L2RTheme.Logo.orange, L2RTheme.Logo.green],
        burstRadius: CGFloat = 60,
        duration: Double = 0.8
    ) {
        self.isActive = isActive
        self.starCount = starCount
        self.colors = colors
        self.burstRadius = burstRadius
        self.duration = duration
    }

    var body: some View {
        if reduceMotion {
            Color.clear
        } else {
            ZStack {
                ForEach(stars) { star in
                    Image(systemName: "star.fill")
                        .font(.system(size: star.size))
                        .foregroundStyle(star.color)
                        .offset(
                            x: animationProgress * cos(star.angle) * burstRadius,
                            y: animationProgress * sin(star.angle) * burstRadius
                        )
                        .scaleEffect(1.0 - animationProgress * 0.5)
                        .opacity(Double(1.0 - animationProgress))
                }
            }
            .allowsHitTesting(false)
            .onChange(of: isActive) { _, active in
                if active { burst() }
            }
        }
    }

    private func burst() {
        animationProgress = 0
        stars = (0..<starCount).map { i in
            let angle = (CGFloat(i) / CGFloat(starCount)) * 2 * .pi
            return BurstStar(
                angle: angle,
                size: CGFloat.random(in: 6...12),
                color: colors.randomElement() ?? L2RTheme.Logo.yellow
            )
        }

        withAnimation(.easeOut(duration: duration)) {
            animationProgress = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.1) {
            stars.removeAll()
            animationProgress = 0
        }
    }
}

private struct BurstStar: Identifiable {
    let id = UUID()
    let angle: CGFloat
    let size: CGFloat
    let color: Color
}

// MARK: - PulseRing

/// Expanding circle that fades as it grows.
/// Used by juicySnap for satisfying snap-into-place feedback.
struct PulseRing: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let isActive: Bool
    let color: Color
    let maxScale: CGFloat
    let duration: Double

    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0.8
    @State private var showing = false

    init(
        isActive: Bool,
        color: Color = L2RTheme.Logo.blue,
        maxScale: CGFloat = 2.5,
        duration: Double = 0.5
    ) {
        self.isActive = isActive
        self.color = color
        self.maxScale = maxScale
        self.duration = duration
    }

    var body: some View {
        if reduceMotion {
            Color.clear
        } else {
            Group {
                if showing {
                    Circle()
                        .stroke(color, lineWidth: 3)
                        .scaleEffect(scale)
                        .opacity(opacity)
                }
            }
            .allowsHitTesting(false)
            .onChange(of: isActive) { _, active in
                if active { pulse() }
            }
        }
    }

    private func pulse() {
        scale = 0.5
        opacity = 0.8
        showing = true

        withAnimation(.easeOut(duration: duration)) {
            scale = maxScale
            opacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.05) {
            showing = false
        }
    }
}
