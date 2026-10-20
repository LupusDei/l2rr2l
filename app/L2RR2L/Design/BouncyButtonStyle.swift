import SwiftUI

/// Squishy press for anything a child can tap: shrinks on touch, overshoots
/// back, and plays a pop the instant the finger lands (not on release), so
/// every touch feels answered.
struct BouncyButtonStyle: ButtonStyle {
    var pressedScale: CGFloat = 0.88
    var sound: Feedback.Moment? = .pop

    func makeBody(configuration: Configuration) -> some View {
        PressBody(configuration: configuration, sound: sound) { pressed in
            configuration.label
                .scaleEffect(pressed ? pressedScale : 1)
                .brightness(pressed ? 0.06 : 0)
        }
    }
}

/// Big candy button with real depth: a darker base under a glossy face. The
/// face sinks onto the base when pressed and springs back up.
struct ChunkyButtonStyle: ButtonStyle {
    var color: Color
    var depth: CGFloat = 10
    var cornerRadius: CGFloat = 30
    var sound: Feedback.Moment? = .pop

    func makeBody(configuration: Configuration) -> some View {
        PressBody(configuration: configuration, sound: sound) { pressed in
            let face = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            configuration.label
                .background {
                    ZStack {
                        face.fill(color.gradient)
                        // top gloss
                        face.fill(LinearGradient(colors: [.white.opacity(0.55), .white.opacity(0)],
                                                 startPoint: .top, endPoint: .center))
                            .padding(4)
                            .mask(alignment: .top) { face.frame(maxHeight: .infinity).padding(.bottom, 8) }
                        face.stroke(.white.opacity(0.65), lineWidth: 3)
                    }
                }
                .offset(y: pressed ? depth * 0.8 : 0)
                .background {
                    ZStack {
                        face.fill(color.opacity(0.55)).blur(radius: pressed ? 10 : 20).offset(y: depth * 1.6)
                        face.fill(color.mixed(with: .black, by: 0.35)).offset(y: depth)
                    }
                }
                .scaleEffect(x: pressed ? 1.04 : 1, y: pressed ? 0.96 : 1, anchor: .bottom)
        }
    }
}

/// Shared press behaviour: spring animation + press-down sound.
private struct PressBody<Content: View>: View {
    let configuration: ButtonStyle.Configuration
    let sound: Feedback.Moment?
    @ViewBuilder let content: (Bool) -> Content
    @Environment(AppServices.self) private var services: AppServices?

    var body: some View {
        content(configuration.isPressed)
            .animation(.spring(response: 0.22, dampingFraction: 0.45), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed, let sound { services?.feedback.play(sound) }
            }
    }
}

extension ButtonStyle where Self == BouncyButtonStyle {
    static var bouncy: BouncyButtonStyle { BouncyButtonStyle() }
}

extension ButtonStyle where Self == ChunkyButtonStyle {
    static func chunky(_ color: Color, depth: CGFloat = 10, cornerRadius: CGFloat = 30) -> ChunkyButtonStyle {
        ChunkyButtonStyle(color: color, depth: depth, cornerRadius: cornerRadius)
    }
}

/// Round chunky icon button (home, back) sized for small fingers.
struct BubbleIconButton: View {
    let systemName: String
    var color: Color = Theme.lilac
    let action: () -> Void
    @Environment(\.metrics) private var m

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: m.s(34), weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.25), radius: 0, y: 2)
                .frame(width: m.s(88), height: m.s(84))
        }
        .buttonStyle(.chunky(color, depth: m.s(8), cornerRadius: m.s(42)))
    }
}

/// Toy-like title lettering: candy gradient face, white outline, and a solid
/// extruded underside so the words look like they could be picked up.
struct ChunkyTitle: View {
    let text: String
    var size: CGFloat
    var colors: [Color] = [.white, Theme.pink]
    var extrude: Color = Theme.lilac.mixed(with: .black, by: 0.45)

    var body: some View {
        let label = Text(text).font(.system(size: size, weight: .black, design: .rounded))
        let depth = max(3, Int(size / 10))
        ZStack {
            ForEach(0..<depth, id: \.self) { i in
                label.foregroundStyle(extrude).offset(y: CGFloat(depth - i))
            }
            ForEach(0..<8, id: \.self) { i in
                let a = Double(i) / 8 * 2 * .pi
                label.foregroundStyle(.white).offset(x: cos(a) * size * 0.045, y: sin(a) * size * 0.045)
            }
            label.foregroundStyle(LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom))
        }
        .background {
            // soft colored halo drawn as content (not a layer shadow) so it never clips
            label.foregroundStyle(colors.last!.opacity(0.7)).blur(radius: size * 0.22)
        }
        .multilineTextAlignment(.center)
        .accessibilityElement()
        .accessibilityLabel(text)
    }
}
