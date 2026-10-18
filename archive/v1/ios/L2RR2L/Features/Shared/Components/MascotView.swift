import SwiftUI

/// A friendly animated owl mascot that reacts to children's actions.
/// Designed for ages 3-6: warm, safe, and expressive.
struct MascotView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var state: MascotState
    var size: CGFloat = 80

    // MARK: - Animation State

    @State private var idleOffset: CGFloat = 0
    @State private var idleTilt: Double = 0
    @State private var celebrateOffset: CGFloat = 0
    @State private var celebrateScale: CGFloat = 1
    @State private var celebrateRotation: Double = 0
    @State private var encourageTilt: Double = 0
    @State private var hintWave: Double = 0
    @State private var danceOffset: CGFloat = 0
    @State private var danceTilt: Double = 0
    @State private var danceScale: CGFloat = 1
    @State private var proudScale: CGFloat = 1
    @State private var showStars: Bool = false
    @State private var showBubble: Bool = false

    var body: some View {
        VStack(spacing: 4) {
            speechBubble
            mascotBody
        }
        .onChange(of: state.currentAnimation) { _, newValue in
            animateTransition(to: newValue)
        }
        .onChange(of: state.speechBubbleText) { _, text in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showBubble = text != nil
            }
            if let text {
                AccessibilityNotification.Announcement(text).post()
            }
        }
        .onAppear { startIdleAnimation() }
    }

    // MARK: - Speech Bubble

    @ViewBuilder
    private var speechBubble: some View {
        if showBubble, let text = state.speechBubbleText {
            Text(text)
                .font(L2RTheme.Typography.playful(size: 14, weight: .bold))
                .foregroundStyle(L2RTheme.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background {
                    BubbleShape()
                        .fill(L2RTheme.surface)
                        .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
                }
                .transition(.scale(scale: 0.5).combined(with: .opacity))
                .accessibilityLabel(text)
        }
    }

    // MARK: - Mascot Body (Owl)

    private var mascotBody: some View {
        ZStack {
            if showStars {
                starParticles
            }

            owlCharacter
                .frame(width: size, height: size)
                .offset(y: currentVerticalOffset)
                .scaleEffect(currentScale)
                .rotationEffect(.degrees(currentRotation))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Reading buddy owl")
        .accessibilityValue(accessibilityDescription)
    }

    // MARK: - Owl Character

    private var owlCharacter: some View {
        Canvas { context, canvasSize in
            let cx = canvasSize.width / 2
            let cy = canvasSize.height / 2
            let r = min(canvasSize.width, canvasSize.height) / 2

            // Body circle
            let bodyRect = CGRect(x: cx - r, y: cy - r * 0.85, width: r * 2, height: r * 1.85)
            context.fill(Path(ellipseIn: bodyRect), with: .color(faceColor))

            // Belly circle (lighter)
            let bellyR = r * 0.55
            let bellyRect = CGRect(x: cx - bellyR, y: cy + r * 0.05, width: bellyR * 2, height: bellyR * 1.3)
            context.fill(Path(ellipseIn: bellyRect), with: .color(bellyColor))

            // Ear tufts
            drawEarTuft(context: &context, cx: cx, cy: cy, r: r, side: -1)
            drawEarTuft(context: &context, cx: cx, cy: cy, r: r, side: 1)

            // Eye whites
            let eyeSpacing = r * 0.38
            let eyeR = r * 0.3
            let eyeY = cy - r * 0.2
            for side: CGFloat in [-1, 1] {
                let eyeX = cx + side * eyeSpacing
                let whiteRect = CGRect(x: eyeX - eyeR, y: eyeY - eyeR, width: eyeR * 2, height: eyeR * 2)
                context.fill(Path(ellipseIn: whiteRect), with: .color(.white))

                // Pupil
                let pupilR = eyeR * pupilScale
                let pupilRect = CGRect(x: eyeX - pupilR, y: eyeY - pupilR, width: pupilR * 2, height: pupilR * 2)
                context.fill(Path(ellipseIn: pupilRect), with: .color(Color(hex: "#333333")))

                // Eye shine
                let shineR = pupilR * 0.35
                let shineRect = CGRect(x: eyeX - pupilR * 0.3 - shineR, y: eyeY - pupilR * 0.3 - shineR, width: shineR * 2, height: shineR * 2)
                context.fill(Path(ellipseIn: shineRect), with: .color(.white))
            }

            // Beak
            var beakPath = Path()
            let beakY = cy + r * 0.1
            beakPath.move(to: CGPoint(x: cx - r * 0.12, y: beakY))
            beakPath.addLine(to: CGPoint(x: cx, y: beakY + r * 0.18))
            beakPath.addLine(to: CGPoint(x: cx + r * 0.12, y: beakY))
            beakPath.closeSubpath()
            context.fill(beakPath, with: .color(beakColor))

            // Mouth expression
            drawMouth(context: &context, cx: cx, cy: cy, r: r)

            // Feet
            let footY = cy + r * 0.85
            for side: CGFloat in [-1, 1] {
                let footX = cx + side * r * 0.25
                var footPath = Path()
                footPath.move(to: CGPoint(x: footX - r * 0.12, y: footY))
                footPath.addLine(to: CGPoint(x: footX, y: footY + r * 0.15))
                footPath.addLine(to: CGPoint(x: footX + r * 0.12, y: footY))
                context.fill(footPath, with: .color(beakColor))
            }
        }
        .overlay(alignment: .bottomTrailing) {
            accessorySymbol
        }
    }

    // MARK: - Canvas Helpers

    private func drawEarTuft(context: inout GraphicsContext, cx: CGFloat, cy: CGFloat, r: CGFloat, side: CGFloat) {
        var path = Path()
        let baseX = cx + side * r * 0.55
        let baseY = cy - r * 0.65
        path.move(to: CGPoint(x: baseX - side * r * 0.15, y: baseY))
        path.addLine(to: CGPoint(x: baseX + side * r * 0.12, y: baseY - r * 0.4))
        path.addLine(to: CGPoint(x: baseX + side * r * 0.3, y: baseY + r * 0.05))
        path.closeSubpath()
        context.fill(path, with: .color(earColor))
    }

    private func drawMouth(context: inout GraphicsContext, cx: CGFloat, cy: CGFloat, r: CGFloat) {
        let mouthY = cy + r * 0.32
        switch state.currentAnimation {
        case .celebrating, .dancing, .proud:
            // Big happy smile
            var path = Path()
            path.addArc(
                center: CGPoint(x: cx, y: mouthY - r * 0.05),
                radius: r * 0.18,
                startAngle: .degrees(10),
                endAngle: .degrees(170),
                clockwise: true
            )
            context.stroke(path, with: .color(Color(hex: "#333333")), lineWidth: 2)
        case .encouraging:
            // Small sympathetic 'o'
            let oRect = CGRect(x: cx - r * 0.06, y: mouthY - r * 0.06, width: r * 0.12, height: r * 0.1)
            context.fill(Path(ellipseIn: oRect), with: .color(Color(hex: "#333333")))
        case .hinting:
            // Slightly open thinking mouth
            var path = Path()
            path.move(to: CGPoint(x: cx - r * 0.1, y: mouthY))
            path.addLine(to: CGPoint(x: cx + r * 0.1, y: mouthY))
            context.stroke(path, with: .color(Color(hex: "#333333")), lineWidth: 2)
        case .idle:
            // Gentle content smile
            var path = Path()
            path.addArc(
                center: CGPoint(x: cx, y: mouthY - r * 0.03),
                radius: r * 0.12,
                startAngle: .degrees(20),
                endAngle: .degrees(160),
                clockwise: true
            )
            context.stroke(path, with: .color(Color(hex: "#333333")), lineWidth: 1.5)
        }
    }

    // MARK: - Dynamic Properties Per State

    private var faceColor: Color {
        L2RTheme.adaptive(light: "#c89b6e", dark: "#a37b52")
    }

    private var bellyColor: Color {
        L2RTheme.adaptive(light: "#f5e6cc", dark: "#d4c4a8")
    }

    private var earColor: Color {
        L2RTheme.adaptive(light: "#a37b52", dark: "#8b6340")
    }

    private var beakColor: Color {
        L2RTheme.Accent.orange
    }

    private var pupilScale: CGFloat {
        switch state.currentAnimation {
        case .celebrating, .proud: return 0.55
        case .encouraging:         return 0.7
        case .hinting:             return 0.6
        case .dancing:             return 0.5
        case .idle:                return 0.6
        }
    }

    // MARK: - Accessory Symbols

    @ViewBuilder
    private var accessorySymbol: some View {
        switch state.currentAnimation {
        case .encouraging:
            Image(systemName: "hand.thumbsup.fill")
                .font(.system(size: size * 0.22))
                .foregroundStyle(L2RTheme.Status.success)
                .transition(.scale.combined(with: .opacity))
                .offset(x: size * 0.1, y: -size * 0.15)
        case .hinting:
            Image(systemName: "hand.point.right.fill")
                .font(.system(size: size * 0.22))
                .foregroundStyle(L2RTheme.Accent.orange)
                .transition(.scale.combined(with: .opacity))
                .offset(x: size * 0.1, y: -size * 0.1)
        default:
            EmptyView()
        }
    }

    // MARK: - Star Particles (Proud State)

    private var starParticles: some View {
        ForEach(0..<6, id: \.self) { i in
            Image(systemName: "star.fill")
                .font(.system(size: size * 0.14))
                .foregroundStyle(L2RTheme.Logo.all[i % L2RTheme.Logo.all.count])
                .offset(starOffset(index: i))
                .opacity(showStars ? 1 : 0)
                .scaleEffect(showStars ? 1 : 0.3)
        }
    }

    private func starOffset(index: Int) -> CGSize {
        let angle = Double(index) * (360.0 / 6.0) * .pi / 180
        let radius = size * 0.7
        return CGSize(
            width: cos(angle) * radius,
            height: sin(angle) * radius - size * 0.1
        )
    }

    // MARK: - Computed Transform Values

    private var currentVerticalOffset: CGFloat {
        switch state.currentAnimation {
        case .idle:         return idleOffset
        case .celebrating:  return celebrateOffset
        case .dancing:      return danceOffset
        default:            return 0
        }
    }

    private var currentScale: CGFloat {
        switch state.currentAnimation {
        case .celebrating:  return celebrateScale
        case .dancing:      return danceScale
        case .proud:        return proudScale
        default:            return 1
        }
    }

    private var currentRotation: Double {
        switch state.currentAnimation {
        case .idle:         return idleTilt
        case .celebrating:  return celebrateRotation
        case .encouraging:  return encourageTilt
        case .hinting:      return hintWave
        case .dancing:      return danceTilt
        default:            return 0
        }
    }

    // MARK: - Accessibility

    private var accessibilityDescription: String {
        switch state.currentAnimation {
        case .idle:         return "Relaxed"
        case .celebrating:  return "Celebrating"
        case .encouraging:  return "Encouraging you"
        case .hinting:      return "Giving a hint"
        case .dancing:      return "Dancing"
        case .proud:        return "Proud of you"
        }
    }

    // MARK: - Animation Logic

    private func startIdleAnimation() {
        guard !reduceMotion else { return }
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            idleOffset = -3
        }
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
            idleTilt = 2
        }
    }

    private func animateTransition(to animation: MascotAnimation) {
        // Reset all animation values
        resetAnimationValues()

        guard !reduceMotion else { return }

        switch animation {
        case .idle:
            startIdleAnimation()

        case .celebrating:
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                celebrateOffset = -20
                celebrateScale = 1.2
                celebrateRotation = 8
            }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5).delay(0.4)) {
                celebrateOffset = 0
                celebrateScale = 1.0
                celebrateRotation = 0
            }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5).delay(0.8)) {
                celebrateOffset = -15
                celebrateScale = 1.15
                celebrateRotation = -5
            }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(1.2)) {
                celebrateOffset = 0
                celebrateScale = 1.0
                celebrateRotation = 0
            }

        case .encouraging:
            withAnimation(.easeInOut(duration: 0.6).repeatCount(3, autoreverses: true)) {
                encourageTilt = 8
            }

        case .hinting:
            withAnimation(.easeInOut(duration: 0.4).repeatCount(5, autoreverses: true)) {
                hintWave = 10
            }

        case .dancing:
            withAnimation(.easeInOut(duration: 0.25).repeatCount(8, autoreverses: true)) {
                danceOffset = -10
                danceTilt = 12
                danceScale = 1.1
            }

        case .proud:
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                proudScale = 1.3
                showStars = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(2.5)) {
                proudScale = 1.0
                showStars = false
            }
        }
    }

    private func resetAnimationValues() {
        idleOffset = 0
        idleTilt = 0
        celebrateOffset = 0
        celebrateScale = 1
        celebrateRotation = 0
        encourageTilt = 0
        hintWave = 0
        danceOffset = 0
        danceTilt = 0
        danceScale = 1
        proudScale = 1
        showStars = false
    }
}

// MARK: - Speech Bubble Shape

private struct BubbleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let cornerRadius: CGFloat = 12
        let arrowWidth: CGFloat = 10
        let arrowHeight: CGFloat = 6
        let bubbleRect = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height - arrowHeight)

        var path = Path()
        path.addRoundedRect(in: bubbleRect, cornerSize: CGSize(width: cornerRadius, height: cornerRadius))

        // Bottom arrow pointing down (center)
        let arrowCenter = bubbleRect.midX
        path.move(to: CGPoint(x: arrowCenter - arrowWidth / 2, y: bubbleRect.maxY))
        path.addLine(to: CGPoint(x: arrowCenter, y: rect.maxY))
        path.addLine(to: CGPoint(x: arrowCenter + arrowWidth / 2, y: bubbleRect.maxY))
        path.closeSubpath()

        return path
    }
}

// MARK: - Preview

#Preview("Mascot Demo") {
    MascotDemoView()
}

private struct MascotDemoView: View {
    @State private var mascotState = MascotState()

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            MascotView(state: mascotState, size: 100)

            Spacer()

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    demoButton("Celebrate", color: L2RTheme.Status.success) { mascotState.celebrate() }
                    demoButton("Encourage", color: L2RTheme.Status.info) { mascotState.encourage() }
                }
                HStack(spacing: 12) {
                    demoButton("Hint", color: L2RTheme.Accent.orange) { mascotState.hint(message: "Try the letter B!") }
                    demoButton("Dance", color: L2RTheme.Accent.purple) { mascotState.dance() }
                }
                demoButton("Proud", color: L2RTheme.Accent.coral) { mascotState.proud() }
            }
            .padding()
        }
        .background(LinearGradient.homeBackground.ignoresSafeArea())
    }

    private func demoButton(_ title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(L2RTheme.Typography.playful(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Capsule().fill(color))
        }
    }
}
