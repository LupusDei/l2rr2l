import SwiftUI

// MARK: - Juicy Tap

/// Squash/stretch on tap with spring animation and pop sound.
struct JuicyTapModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPressed = false

    let onTap: (() -> Void)?

    init(onTap: (() -> Void)? = nil) {
        self.onTap = onTap
    }

    func body(content: Content) -> some View {
        content
            .scaleEffect(
                x: isPressed ? 1.1 : 1.0,
                y: isPressed ? 0.9 : 1.0
            )
            .animation(
                reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.5),
                value: isPressed
            )
            .onTapGesture {
                guard !reduceMotion else {
                    onTap?()
                    return
                }
                SoundEffectService.shared.play(.buttonTap)
                HapticService.shared.buttonTap()
                isPressed = true
                onTap?()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    isPressed = false
                }
            }
    }
}

// MARK: - Juicy Drag

/// During drag: scale 1.2x with shadow. On drop: snap back.
struct JuicyDragModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false

    let onDragEnded: ((CGSize) -> Void)?

    init(onDragEnded: ((CGSize) -> Void)? = nil) {
        self.onDragEnded = onDragEnded
    }

    func body(content: Content) -> some View {
        content
            .scaleEffect(isDragging && !reduceMotion ? 1.2 : 1.0)
            .shadow(
                color: isDragging && !reduceMotion ? .black.opacity(0.25) : .clear,
                radius: isDragging ? 8 : 0,
                y: isDragging ? 8 : 0
            )
            .offset(dragOffset)
            .animation(
                reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.7),
                value: isDragging
            )
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation
                        if !isDragging {
                            isDragging = true
                            if !reduceMotion {
                                HapticService.shared.dragStart()
                            }
                        }
                    }
                    .onEnded { value in
                        isDragging = false
                        onDragEnded?(value.translation)
                        withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.6)) {
                            dragOffset = .zero
                        }
                    }
            )
    }
}

// MARK: - Juicy Correct

/// Celebratory bounce with star burst and green glow.
struct JuicyCorrectModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var trigger: Bool

    @State private var scale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0
    @State private var showStars = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .overlay {
                RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.medium)
                    .fill(L2RTheme.Logo.green.opacity(glowOpacity))
                    .allowsHitTesting(false)
            }
            .overlay {
                StarBurst(isActive: showStars)
                    .allowsHitTesting(false)
            }
            .onChange(of: trigger) { _, active in
                guard active else { return }
                // Sound/haptic intentionally omitted — ViewModels already handle
                // game-specific sounds (e.g. Memory uses .match, not .correct)

                guard !reduceMotion else {
                    resetTrigger()
                    return
                }

                showStars = true

                // Green glow pulse
                withAnimation(.easeIn(duration: 0.2)) {
                    glowOpacity = 0.3
                }
                withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                    glowOpacity = 0
                }

                // Celebratory bounce
                withAnimation(.spring(response: 0.4, dampingFraction: 0.4)) {
                    scale = 1.3
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.4)) {
                        scale = 1.0
                    }
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    showStars = false
                    resetTrigger()
                }
            }
    }

    private func resetTrigger() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            trigger = false
        }
    }
}

// MARK: - Juicy Incorrect

/// Gentle wobble with warm tint - encouraging, not punitive.
struct JuicyIncorrectModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var trigger: Bool

    @State private var wobbleAngle: Double = 0
    @State private var tintOpacity: Double = 0

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(wobbleAngle))
            .overlay {
                RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.medium)
                    .fill(L2RTheme.Logo.orange.opacity(tintOpacity))
                    .allowsHitTesting(false)
            }
            .onChange(of: trigger) { _, active in
                guard active else { return }
                // Sound/haptic intentionally omitted — ViewModels already handle
                // game-specific feedback to avoid doubled audio

                guard !reduceMotion else {
                    resetTrigger()
                    return
                }

                // Soft warm tint
                withAnimation(.easeIn(duration: 0.15)) {
                    tintOpacity = 0.2
                }
                withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
                    tintOpacity = 0
                }

                // Gentle wobble: ±5° three times
                wobble(count: 3, index: 0)
            }
    }

    private func wobble(count: Int, index: Int) {
        guard index < count else {
            withAnimation(.easeOut(duration: 0.1)) {
                wobbleAngle = 0
            }
            resetTrigger()
            return
        }

        let direction: Double = index.isMultiple(of: 2) ? 1 : -1
        withAnimation(.easeInOut(duration: 0.1)) {
            wobbleAngle = 5 * direction
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.1)) {
                wobbleAngle = -5 * direction
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                wobble(count: count, index: index + 1)
            }
        }
    }

    private func resetTrigger() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            trigger = false
        }
    }
}

// MARK: - Juicy Snap

/// Snap-into-place with pulse ring and satisfying click feel.
struct JuicySnapModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var trigger: Bool

    @State private var scale: CGFloat = 1.0
    @State private var showPulse = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .overlay {
                PulseRing(isActive: showPulse)
                    .allowsHitTesting(false)
            }
            .onChange(of: trigger) { _, active in
                guard active else { return }
                HapticService.shared.dropItem()

                guard !reduceMotion else {
                    resetTrigger()
                    return
                }

                showPulse = true

                withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                    scale = 1.1
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                        scale = 1.0
                    }
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    showPulse = false
                    resetTrigger()
                }
            }
    }

    private func resetTrigger() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            trigger = false
        }
    }
}

// MARK: - Juicy Flip

/// 3D flip with overshoot and sparkle particles on reveal.
struct JuicyFlipModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var isFlipped: Bool

    @State private var rotation: Double = 0
    @State private var showSparkles = false

    func body(content: Content) -> some View {
        content
            .rotation3DEffect(
                .degrees(rotation),
                axis: (x: 0, y: 1, z: 0),
                perspective: 0.4
            )
            .overlay {
                if showSparkles && !reduceMotion {
                    SparkleOverlay()
                        .allowsHitTesting(false)
                }
            }
            .onChange(of: isFlipped) { _, flipped in
                SoundEffectService.shared.play(.flip)
                HapticService.shared.cardFlip()

                guard !reduceMotion else {
                    rotation = flipped ? 180 : 0
                    return
                }

                // Overshoot past 180° then settle
                let target = flipped ? 180.0 : 0.0
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    rotation = target
                }

                // Sparkle on reveal
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    showSparkles = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    showSparkles = false
                }
            }
    }
}

/// Sparkle dots that twinkle briefly on flip reveal.
private struct SparkleOverlay: View {
    @State private var sparkles: [SparklePoint] = []
    @State private var opacity: Double = 1.0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(sparkles) { sparkle in
                    Image(systemName: "sparkle")
                        .font(.system(size: sparkle.size))
                        .foregroundStyle(sparkle.color)
                        .position(sparkle.position)
                        .opacity(opacity)
                }
            }
            .onAppear {
                let size = geo.size
                sparkles = (0..<8).map { _ in
                    SparklePoint(
                        position: CGPoint(
                            x: CGFloat.random(in: size.width * 0.1...size.width * 0.9),
                            y: CGFloat.random(in: size.height * 0.1...size.height * 0.9)
                        ),
                        size: CGFloat.random(in: 8...16),
                        color: L2RTheme.Logo.all.randomElement() ?? L2RTheme.Logo.yellow
                    )
                }
                withAnimation(.easeOut(duration: 0.5)) {
                    opacity = 0
                }
            }
        }
    }
}

private struct SparklePoint: Identifiable {
    let id = UUID()
    let position: CGPoint
    let size: CGFloat
    let color: Color
}

// MARK: - Juicy Button Press

/// Universal micro-press for tappable buttons.
/// Scale 0.95x on press, spring back on release.
struct JuicyButtonPressModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed && !reduceMotion ? 0.95 : 1.0)
            .animation(
                reduceMotion ? nil : .spring(response: 0.2, dampingFraction: 0.6),
                value: isPressed
            )
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard !isPressed else { return }
                        isPressed = true
                    }
                    .onEnded { _ in
                        isPressed = false
                    }
            )
    }
}

// MARK: - View Extensions

extension View {
    /// Squash/stretch on tap with pop sound and haptic.
    /// - Parameter onTap: Optional callback when tapped.
    public func juicyTap(onTap: (() -> Void)? = nil) -> some View {
        modifier(JuicyTapModifier(onTap: onTap))
    }

    /// Scale and shadow during drag, snap back on drop.
    /// - Parameter onDragEnded: Callback with final translation when drag ends.
    public func juicyDrag(onDragEnded: ((CGSize) -> Void)? = nil) -> some View {
        modifier(JuicyDragModifier(onDragEnded: onDragEnded))
    }

    /// Celebratory bounce with star burst and green glow.
    /// - Parameter trigger: Binding that triggers the animation when set to true.
    ///   Automatically resets to false when animation completes.
    public func juicyCorrect(trigger: Binding<Bool>) -> some View {
        modifier(JuicyCorrectModifier(trigger: trigger))
    }

    /// Gentle encouraging wobble with warm tint. Safe for 3-year-olds.
    /// - Parameter trigger: Binding that triggers the animation when set to true.
    ///   Automatically resets to false when animation completes.
    public func juicyIncorrect(trigger: Binding<Bool>) -> some View {
        modifier(JuicyIncorrectModifier(trigger: trigger))
    }

    /// Snap-into-place with expanding pulse ring.
    /// - Parameter trigger: Binding that triggers the animation when set to true.
    ///   Automatically resets to false when animation completes.
    public func juicySnap(trigger: Binding<Bool>) -> some View {
        modifier(JuicySnapModifier(trigger: trigger))
    }

    /// 3D flip with overshoot bounce and sparkle reveal.
    /// - Parameter isFlipped: Binding controlling flip state.
    public func juicyFlip(isFlipped: Binding<Bool>) -> some View {
        modifier(JuicyFlipModifier(isFlipped: isFlipped))
    }

    /// Universal button micro-press: scale 0.95x on press, spring back on release.
    public func juicyButtonPress() -> some View {
        modifier(JuicyButtonPressModifier())
    }
}

// MARK: - Preview

#Preview("Juice Animations Demo") {
    JuiceAnimationsDemoView()
}

private struct JuiceAnimationsDemoView: View {
    @State private var correctTrigger = false
    @State private var incorrectTrigger = false
    @State private var snapTrigger = false
    @State private var isFlipped = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Juice Animations")
                    .font(L2RTheme.Typography.Scaled.playful(relativeTo: .title, weight: .bold))

                // Juicy Tap
                Text("Tap Me!")
                    .font(L2RTheme.Typography.Scaled.playful(relativeTo: .title3, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(Capsule().fill(L2RTheme.Logo.blue))
                    .juicyTap()

                // Juicy Button Press
                Button("Button Press") {}
                    .font(L2RTheme.Typography.Scaled.playful(relativeTo: .title3, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(Capsule().fill(L2RTheme.Logo.purple))
                    .juicyButtonPress()

                // Juicy Correct
                Text("Correct!")
                    .font(L2RTheme.Typography.Scaled.playful(relativeTo: .title3, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(24)
                    .background(RoundedRectangle(cornerRadius: 16).fill(L2RTheme.Logo.green))
                    .juicyCorrect(trigger: $correctTrigger)
                    .onTapGesture { correctTrigger = true }

                // Juicy Incorrect
                Text("Try Again")
                    .font(L2RTheme.Typography.Scaled.playful(relativeTo: .title3, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(24)
                    .background(RoundedRectangle(cornerRadius: 16).fill(L2RTheme.Logo.orange))
                    .juicyIncorrect(trigger: $incorrectTrigger)
                    .onTapGesture { incorrectTrigger = true }

                // Juicy Snap
                Text("Snap!")
                    .font(L2RTheme.Typography.Scaled.playful(relativeTo: .title3, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(24)
                    .background(Circle().fill(L2RTheme.Logo.blue))
                    .juicySnap(trigger: $snapTrigger)
                    .onTapGesture { snapTrigger = true }

                // Juicy Flip
                Text(isFlipped ? "Back" : "Front")
                    .font(L2RTheme.Typography.Scaled.playful(relativeTo: .title3, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 120, height: 80)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(isFlipped ? L2RTheme.Logo.red : L2RTheme.Logo.blue)
                    )
                    .juicyFlip(isFlipped: $isFlipped)
                    .onTapGesture { isFlipped.toggle() }

                // Juicy Drag
                Text("Drag Me")
                    .font(L2RTheme.Typography.Scaled.playful(relativeTo: .title3, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(24)
                    .background(RoundedRectangle(cornerRadius: 16).fill(L2RTheme.Logo.yellow))
                    .juicyDrag()
            }
            .padding(32)
        }
    }
}
