import SwiftUI

/// Voice settings configuration screen with parameter sliders
struct VoiceSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = VoiceSettingsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: L2RTheme.Spacing.lg) {
                    // Voice selector
                    voiceSelector

                    Divider()

                    // Stability slider
                    ParameterSlider(
                        title: "Stability",
                        value: $viewModel.stability,
                        range: 0...1,
                        description: "Higher values make the voice more consistent"
                    )

                    Divider()

                    // Similarity boost slider
                    ParameterSlider(
                        title: "Similarity",
                        value: $viewModel.similarityBoost,
                        range: 0...1,
                        description: "How closely to match the original voice"
                    )

                    Divider()

                    // Style slider
                    ParameterSlider(
                        title: "Style",
                        value: $viewModel.style,
                        range: 0...1,
                        description: "Adds expressiveness to the voice"
                    )

                    Divider()

                    // Speed slider
                    ParameterSlider(
                        title: "Speed",
                        value: $viewModel.speed,
                        range: 0.5...2.0,
                        description: "Adjust the speaking rate"
                    )

                    Divider()

                    // Speaker boost toggle
                    speakerBoostToggle

                    Divider()

                    // Action buttons
                    actionButtons
                }
                .padding(L2RTheme.Spacing.lg)
            }
            .background(L2RTheme.background)
            .navigationTitle("Voice Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body, weight: .semibold))
                    .foregroundStyle(L2RTheme.primary)
                }
            }
            .task {
                await viewModel.loadVoices()
            }
            .alert("Error", isPresented: .init(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
        }
    }

    // MARK: - Voice Selector

    private var voiceSelector: some View {
        VStack(alignment: .leading, spacing: L2RTheme.Spacing.sm) {
            Text("Voice")
                .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body, weight: .semibold))
                .foregroundStyle(L2RTheme.textPrimary)

            if viewModel.isLoadingVoices {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading voices...")
                        .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.small))
                        .foregroundStyle(L2RTheme.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(L2RTheme.Spacing.md)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.medium))
                .overlay(
                    RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.medium)
                        .stroke(L2RTheme.inputBorder, lineWidth: 1)
                )
            } else {
                Menu {
                    ForEach(viewModel.voices) { voice in
                        Button {
                            viewModel.selectedVoiceId = voice.id
                        } label: {
                            HStack {
                                Text(voice.name)
                                if voice.id == viewModel.selectedVoiceId {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(viewModel.selectedVoice?.name ?? "Select Voice")
                            .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body))
                            .foregroundStyle(L2RTheme.textPrimary)

                        Spacer()

                        Image(systemName: "chevron.down")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(L2RTheme.textSecondary)
                    }
                    .padding(L2RTheme.Spacing.md)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.medium))
                    .overlay(
                        RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.medium)
                            .stroke(L2RTheme.inputBorder, lineWidth: 1)
                    )
                }
            }

            if let description = viewModel.selectedVoice?.description {
                Text(description)
                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.small))
                    .foregroundStyle(L2RTheme.textSecondary)
            }
        }
    }

    // MARK: - Speaker Boost Toggle

    private var speakerBoostToggle: some View {
        HStack {
            VStack(alignment: .leading, spacing: L2RTheme.Spacing.xxs) {
                Text("Speaker Boost")
                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body, weight: .semibold))
                    .foregroundStyle(L2RTheme.textPrimary)

                Text("Enhances voice clarity")
                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.small))
                    .foregroundStyle(L2RTheme.textSecondary)
            }

            Spacer()

            Toggle("", isOn: $viewModel.useSpeakerBoost)
                .labelsHidden()
                .tint(L2RTheme.primary)
        }
        .padding(.vertical, L2RTheme.Spacing.xs)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: L2RTheme.Spacing.md) {
            // Preview button
            Button {
                Task {
                    await viewModel.previewVoice()
                }
            } label: {
                HStack(spacing: L2RTheme.Spacing.sm) {
                    if viewModel.isPreviewPlaying {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Image(systemName: "play.fill")
                    }
                    Text(viewModel.isPreviewPlaying ? "Playing..." : "Preview Voice")
                        .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: L2RTheme.TouchTarget.large)
                .background(L2RTheme.primary)
                .clipShape(RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.medium))
            }
            .disabled(viewModel.isPreviewPlaying)

            // Reset button
            Button {
                viewModel.resetToDefaults()
            } label: {
                HStack(spacing: L2RTheme.Spacing.sm) {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Reset to Defaults")
                        .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body, weight: .medium))
                }
                .foregroundStyle(L2RTheme.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: L2RTheme.TouchTarget.large)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.medium))
                .overlay(
                    RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.medium)
                        .stroke(L2RTheme.border, lineWidth: 1)
                )
            }
        }
        .padding(.top, L2RTheme.Spacing.md)
    }
}

// MARK: - Parameter Slider Component

/// Reusable slider component for voice parameters
struct ParameterSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: L2RTheme.Spacing.sm) {
            HStack {
                Text(title)
                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body, weight: .semibold))
                    .foregroundStyle(L2RTheme.textPrimary)

                Spacer()

                Text(formattedValue)
                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body, weight: .medium))
                    .foregroundStyle(L2RTheme.primary)
                    .monospacedDigit()
            }

            Slider(value: $value, in: range)
                .tint(L2RTheme.primary)

            Text(description)
                .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.small))
                .foregroundStyle(L2RTheme.textSecondary)
        }
        .padding(.vertical, L2RTheme.Spacing.xs)
    }

    private var formattedValue: String {
        if range.upperBound > 1 {
            return String(format: "%.1f", value)
        }
        return String(format: "%.2f", value)
    }
}

// MARK: - Preview

#Preview {
    VoiceSettingsView()
}
