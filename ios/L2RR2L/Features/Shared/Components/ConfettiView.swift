import SwiftUI

/// A confetti particle effect view for celebrations.
/// Displays colorful falling particles with gravity physics.
public struct ConfettiView: View {
    /// Configuration for the confetti effect
    public struct Configuration {
        /// Number of particles to emit
        public var particleCount: Int
        /// Duration before particles fade out (seconds)
        public var duration: Double
        /// Colors to use for particles
        public var colors: [Color]
        /// Whether particles should fall with gravity
        public var enableGravity: Bool
        /// Initial burst spread (horizontal velocity range)
        public var spreadRadius: CGFloat

        public init(
            particleCount: Int = 100,
            duration: Double = 3.0,
            colors: [Color] = L2RTheme.Logo.all,
            enableGravity: Bool = true,
            spreadRadius: CGFloat = 400
        ) {
            self.particleCount = particleCount
            self.duration = duration
            self.colors = colors
            self.enableGravity = enableGravity
            self.spreadRadius = spreadRadius
        }

        /// Default celebration configuration
        public static let celebration = Configuration()

        /// Smaller burst for correct answers
        public static let correctAnswer = Configuration(
            particleCount: 50,
            duration: 2.0,
            spreadRadius: 300
        )

        /// Large burst for game completion
        public static let gameComplete = Configuration(
            particleCount: 150,
            duration: 4.0,
            spreadRadius: 500
        )

        /// Streak milestone configuration
        public static let streakMilestone = Configuration(
            particleCount: 80,
            duration: 2.5,
            spreadRadius: 350
        )
    }

    private let configuration: Configuration
    @Binding var isActive: Bool

    @State private var particles: [ConfettiParticle] = []
    @State private var animationProgress: CGFloat = 0

    public init(isActive: Binding<Bool>, configuration: Configuration = .celebration) {
        self._isActive = isActive
        self.configuration = configuration
    }

    public var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let now = timeline.date.timeIntervalSinceReferenceDate

                    for particle in particles {
                        let elapsed = now - particle.startTime
                        guard elapsed < configuration.duration else { continue }

                        let progress = elapsed / configuration.duration
                        let opacity = 1.0 - pow(progress, 2)

                        // Apply physics
                        let gravity: CGFloat = configuration.enableGravity ? 800 : 0
                        let x = particle.startX + particle.velocityX * elapsed
                        let y = particle.startY + particle.velocityY * elapsed + 0.5 * gravity * elapsed * elapsed

                        // Skip if off screen
                        guard y < size.height + 50 else { continue }

                        let rotation = Angle(degrees: particle.rotation + particle.rotationSpeed * elapsed * 360)

                        context.opacity = opacity
                        context.translateBy(x: x, y: y)
                        context.rotate(by: rotation)

                        let rect = CGRect(
                            x: -particle.width / 2,
                            y: -particle.height / 2,
                            width: particle.width,
                            height: particle.height
                        )

                        switch particle.shape {
                        case .rectangle:
                            context.fill(Path(rect), with: .color(particle.color))
                        case .circle:
                            context.fill(Path(ellipseIn: rect), with: .color(particle.color))
                        case .triangle:
                            var path = Path()
                            path.move(to: CGPoint(x: 0, y: -particle.height / 2))
                            path.addLine(to: CGPoint(x: particle.width / 2, y: particle.height / 2))
                            path.addLine(to: CGPoint(x: -particle.width / 2, y: particle.height / 2))
                            path.closeSubpath()
                            context.fill(path, with: .color(particle.color))
                        }

                        context.rotate(by: -rotation)
                        context.translateBy(x: -x, y: -y)
                    }
                }
            }
            .onChange(of: isActive) { _, active in
                if active {
                    spawnParticles(in: geometry.size)
                    scheduleCleanup()
                }
            }
            .onAppear {
                if isActive {
                    spawnParticles(in: geometry.size)
                    scheduleCleanup()
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func spawnParticles(in size: CGSize) {
        let now = Date().timeIntervalSinceReferenceDate
        let centerX = size.width / 2
        let topY = size.height * 0.3

        particles = (0..<configuration.particleCount).map { _ in
            let angle = Double.random(in: -Double.pi...0)
            let speed = Double.random(in: 200...configuration.spreadRadius)

            return ConfettiParticle(
                startX: centerX + CGFloat.random(in: -50...50),
                startY: topY + CGFloat.random(in: -30...30),
                velocityX: cos(angle) * speed * (Bool.random() ? 1 : -1),
                velocityY: sin(angle) * speed - Double.random(in: 100...300),
                rotation: Double.random(in: 0...360),
                rotationSpeed: Double.random(in: 0.5...2.0) * (Bool.random() ? 1 : -1),
                width: CGFloat.random(in: 8...14),
                height: CGFloat.random(in: 6...12),
                color: configuration.colors.randomElement() ?? L2RTheme.Logo.yellow,
                shape: ConfettiShape.allCases.randomElement() ?? .rectangle,
                startTime: now
            )
        }
    }

    private func scheduleCleanup() {
        DispatchQueue.main.asyncAfter(deadline: .now() + configuration.duration + 0.5) {
            particles.removeAll()
            isActive = false
        }
    }
}

// MARK: - Particle Model

private struct ConfettiParticle {
    let startX: CGFloat
    let startY: CGFloat
    let velocityX: Double
    let velocityY: Double
    let rotation: Double
    let rotationSpeed: Double
    let width: CGFloat
    let height: CGFloat
    let color: Color
    let shape: ConfettiShape
    let startTime: TimeInterval
}

private enum ConfettiShape: CaseIterable {
    case rectangle
    case circle
    case triangle
}

// MARK: - View Modifier

/// A view modifier that adds confetti overlay to any view.
public struct ConfettiModifier: ViewModifier {
    @Binding var isActive: Bool
    let configuration: ConfettiView.Configuration

    public func body(content: Content) -> some View {
        content.overlay {
            if isActive {
                ConfettiView(isActive: $isActive, configuration: configuration)
                    .ignoresSafeArea()
            }
        }
    }
}

extension View {
    /// Adds a confetti celebration overlay to the view.
    /// - Parameters:
    ///   - isActive: Binding to control when confetti is shown
    ///   - configuration: Configuration for the confetti effect
    public func confetti(
        isActive: Binding<Bool>,
        configuration: ConfettiView.Configuration = .celebration
    ) -> some View {
        modifier(ConfettiModifier(isActive: isActive, configuration: configuration))
    }
}

// MARK: - Preview

#Preview("Confetti Demo") {
    ConfettiDemoView()
}

private struct ConfettiDemoView: View {
    @State private var showConfetti = false

    var body: some View {
        ZStack {
            LinearGradient.spellingGame
                .ignoresSafeArea()

            VStack(spacing: 30) {
                Text("Tap to Celebrate!")
                    .font(L2RTheme.Typography.playful(size: 28, weight: .bold))
                    .foregroundStyle(.white)

                Button {
                    showConfetti = true
                } label: {
                    Text("Trigger Confetti")
                        .font(L2RTheme.Typography.playful(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(
                            Capsule()
                                .fill(LinearGradient.ctaButton)
                        )
                }
            }
        }
        .confetti(isActive: $showConfetti)
    }
}
