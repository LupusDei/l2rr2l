import SwiftUI

/// Colorful bouncing bar waveform that reacts to audio input level.
/// Displays a row of bars in rainbow Logo colors that bounce in response
/// to the microphone audio level, creating an engaging visual during recording.
struct AudioWaveform: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let audioLevel: Float
    let isActive: Bool

    private let barCount = 9
    private let barColors = L2RTheme.Logo.all

    var body: some View {
        if reduceMotion {
            // Static indicator for reduced motion
            HStack(spacing: 3) {
                ForEach(0..<barCount, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor(for: index))
                        .frame(width: 12, height: isActive ? 30 : 10)
                }
            }
            .frame(height: 80)
            .accessibilityLabel("Audio level indicator")
        } else {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                HStack(spacing: 3) {
                    ForEach(0..<barCount, id: \.self) { index in
                        AnimatedBar(
                            index: index,
                            audioLevel: audioLevel,
                            isActive: isActive,
                            color: barColor(for: index),
                            time: timeline.date.timeIntervalSinceReferenceDate
                        )
                    }
                }
            }
            .frame(height: 80)
            .accessibilityLabel("Audio waveform, level \(Int(audioLevel * 100)) percent")
        }
    }

    private func barColor(for index: Int) -> Color {
        barColors[index % barColors.count]
    }
}

// MARK: - Animated Bar

private struct AnimatedBar: View {
    let index: Int
    let audioLevel: Float
    let isActive: Bool
    let color: Color
    let time: TimeInterval

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(
                LinearGradient(
                    colors: [color, color.opacity(0.6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 12, height: barHeight)
            .shadow(color: color.opacity(0.4), radius: 3, y: 2)
    }

    private var barHeight: CGFloat {
        guard isActive else { return 8 }

        let level = CGFloat(audioLevel)

        // Each bar has a unique phase offset for wave effect
        let phase = Double(index) * 0.7
        let wave = sin(time * 4.0 + phase) * 0.5 + 0.5

        // Combine audio level with wave pattern
        // Center bars react more, edge bars less (natural waveform shape)
        let centerDistance = abs(CGFloat(index) - CGFloat(4)) / 4.0
        let centerBoost = 1.0 - centerDistance * 0.4

        // Base height + audio-driven height + wave movement
        let base: CGFloat = 10
        let audioHeight = level * 50 * centerBoost
        let waveHeight = CGFloat(wave) * 15 * centerBoost

        return min(max(base + audioHeight + waveHeight, 8), 70)
    }
}

// MARK: - Preview

#Preview("Audio Waveform") {
    ZStack {
        LinearGradient.readAloudGame
            .ignoresSafeArea()

        VStack(spacing: 40) {
            Text("Silent")
                .foregroundStyle(.white)
            AudioWaveform(audioLevel: 0.0, isActive: true)
                .frame(height: 80)
                .padding(.horizontal, 40)

            Text("Quiet")
                .foregroundStyle(.white)
            AudioWaveform(audioLevel: 0.3, isActive: true)
                .frame(height: 80)
                .padding(.horizontal, 40)

            Text("Loud")
                .foregroundStyle(.white)
            AudioWaveform(audioLevel: 0.8, isActive: true)
                .frame(height: 80)
                .padding(.horizontal, 40)
        }
    }
}
