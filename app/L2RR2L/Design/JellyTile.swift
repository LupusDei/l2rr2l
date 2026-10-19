import SwiftUI

/// A letter as a soft jelly toy (design v2, 3.2): it breathes when idle,
/// squashes under a finger, stretches in the direction it's dragged, wobbles
/// when let go, and plays a note from the world's pentatonic scale on every
/// touch. Tap and drag are both reported; the caller decides what they mean.
struct JellyTile: View {
    let letter: String
    let size: CGFloat
    var color: Color = Color(red: 1, green: 0.97, blue: 0.92)
    var glow: Bool = false
    var dimmed: Bool = false
    /// Coordinate space drag locations are reported in.
    var space: CoordinateSpace = .global
    var onTap: () -> Void = {}
    var onDrag: ((CGPoint) -> Void)? = nil
    var onDrop: ((CGPoint) -> Void)? = nil

    @Environment(AppServices.self) private var services: AppServices?
    @State private var pressed = false
    @State private var drag: CGSize = .zero
    @State private var wobble = 0
    @State private var phase = Double.random(in: 0...6)

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let breathe = 1 + 0.025 * sin(t * 2.2 + phase)
            let stretchX = 1 + min(0.18, abs(drag.width) / 500) - min(0.1, abs(drag.height) / 900)
            let stretchY = 1 + min(0.18, abs(drag.height) / 500) - min(0.1, abs(drag.width) / 900)
            face
                .scaleEffect(x: (pressed ? 1.14 : breathe) * stretchX, y: (pressed ? 0.86 : breathe) * stretchY, anchor: .bottom)
                .rotationEffect(.degrees(Double(drag.width) / 25))
                .offset(drag)
        }
        .keyframeAnimator(initialValue: CGFloat(1), trigger: wobble) { view, s in
            view.scaleEffect(x: s, y: 2 - s)
        } keyframes: { _ in
            SpringKeyframe(0.86, duration: 0.08)
            SpringKeyframe(1.12, duration: 0.12)
            SpringKeyframe(0.95, duration: 0.12)
            SpringKeyframe(1.0, duration: 0.25, spring: .bouncy)
        }
        .opacity(dimmed ? 0.4 : 1)
        .zIndex(drag == .zero ? 0 : 10)
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: space)
                .onChanged { v in
                    if !pressed {
                        pressed = true
                        services?.sounds.playTwinkle()
                    }
                    let moved = hypot(v.translation.width, v.translation.height)
                    if moved > 8, let onDrag {
                        drag = v.translation
                        onDrag(v.location)
                    }
                }
                .onEnded { v in
                    pressed = false
                    let moved = hypot(v.translation.width, v.translation.height)
                    if moved > 8, onDrag != nil {
                        onDrop?(v.location)
                    } else {
                        onTap()
                    }
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) { drag = .zero }
                    wobble += 1
                }
        )
        .animation(.spring(response: 0.2, dampingFraction: 0.5), value: pressed)
        .accessibilityElement()
        .accessibilityLabel(letter)
        .accessibilityIdentifier("tile-\(letter)")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { onTap() }
    }

    private var face: some View {
        let shape = RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
        return Text(letter)
            .font(.reading(size * 0.6))
            .foregroundStyle(Theme.skyTop)
            .frame(width: size, height: size)
            .background {
                ZStack {
                    shape.fill(color.mix(with: .black, by: 0.22)).offset(y: size * 0.07)
                    shape.fill(LinearGradient(colors: [.white, color], startPoint: .top, endPoint: .bottom))
                    // jelly highlight
                    Ellipse().fill(.white.opacity(0.7))
                        .frame(width: size * 0.42, height: size * 0.16)
                        .offset(x: -size * 0.16, y: -size * 0.3)
                    shape.stroke(glow ? Theme.gold : .white.opacity(0.9), lineWidth: glow ? 5 : 2)
                }
            }
            .glow(glow ? Theme.gold : .clear, radius: 16)
    }
}
