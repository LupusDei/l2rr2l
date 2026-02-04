import SwiftUI
import AVFoundation

/// Voice selection picker with preview functionality
struct VoiceSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedVoiceId: String
    let voices: [Voice]
    let isLoading: Bool

    @State private var searchText = ""
    @State private var previewingVoiceId: String?
    @State private var audioPlayer: AVAudioPlayer?

    private var filteredVoices: [Voice] {
        if searchText.isEmpty {
            return voices
        }
        return voices.filter { voice in
            voice.name.localizedCaseInsensitiveContains(searchText) ||
            (voice.category?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            (voice.description?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        NavigationStack {
            content
                .background(L2RTheme.background)
                .navigationTitle("Select Voice")
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
                .searchable(text: $searchText, prompt: "Search voices")
        }
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            loadingView
        } else if voices.isEmpty {
            emptyView
        } else {
            voiceList
        }
    }

    private var loadingView: some View {
        VStack(spacing: L2RTheme.Spacing.lg) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading voices...")
                .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body))
                .foregroundStyle(L2RTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: L2RTheme.Spacing.lg) {
            Image(systemName: "waveform.slash")
                .font(.system(size: 48))
                .foregroundStyle(L2RTheme.textSecondary)
            Text("No voices available")
                .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.large, weight: .medium))
                .foregroundStyle(L2RTheme.textPrimary)
            Text("Please try again later")
                .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body))
                .foregroundStyle(L2RTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var voiceList: some View {
        ScrollView {
            LazyVStack(spacing: L2RTheme.Spacing.sm) {
                if filteredVoices.isEmpty {
                    noResultsView
                } else {
                    ForEach(filteredVoices) { voice in
                        VoiceRow(
                            voice: voice,
                            isSelected: voice.id == selectedVoiceId,
                            isPreviewing: voice.id == previewingVoiceId,
                            onSelect: {
                                selectedVoiceId = voice.id
                            },
                            onPreview: {
                                previewVoice(voice)
                            }
                        )
                    }
                }
            }
            .padding(L2RTheme.Spacing.md)
        }
    }

    private var noResultsView: some View {
        VStack(spacing: L2RTheme.Spacing.md) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36))
                .foregroundStyle(L2RTheme.textSecondary)
            Text("No voices match \"\(searchText)\"")
                .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body))
                .foregroundStyle(L2RTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, L2RTheme.Spacing.xxxl)
    }

    private func previewVoice(_ voice: Voice) {
        // Stop any current preview
        audioPlayer?.stop()

        // If tapping the same voice, just stop
        if previewingVoiceId == voice.id {
            previewingVoiceId = nil
            return
        }

        previewingVoiceId = voice.id

        // If voice has a preview URL, try to play it
        if let urlString = voice.previewUrl, let url = URL(string: urlString) {
            Task {
                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    await MainActor.run {
                        do {
                            audioPlayer = try AVAudioPlayer(data: data)
                            audioPlayer?.play()

                            // Clear preview state when done
                            DispatchQueue.main.asyncAfter(deadline: .now() + (audioPlayer?.duration ?? 2.0)) {
                                if previewingVoiceId == voice.id {
                                    previewingVoiceId = nil
                                }
                            }
                        } catch {
                            previewingVoiceId = nil
                        }
                    }
                } catch {
                    await MainActor.run {
                        previewingVoiceId = nil
                    }
                }
            }
        } else {
            // No preview URL - simulate preview
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                if previewingVoiceId == voice.id {
                    previewingVoiceId = nil
                }
            }
        }
    }
}

// MARK: - Voice Row

private struct VoiceRow: View {
    let voice: Voice
    let isSelected: Bool
    let isPreviewing: Bool
    let onSelect: () -> Void
    let onPreview: () -> Void

    var body: some View {
        HStack(spacing: L2RTheme.Spacing.md) {
            // Selection indicator
            Button(action: onSelect) {
                HStack(spacing: L2RTheme.Spacing.md) {
                    // Checkmark
                    ZStack {
                        Circle()
                            .stroke(isSelected ? L2RTheme.primary : L2RTheme.inputBorder, lineWidth: 2)
                            .frame(width: 24, height: 24)

                        if isSelected {
                            Circle()
                                .fill(L2RTheme.primary)
                                .frame(width: 16, height: 16)
                        }
                    }

                    // Voice info
                    VStack(alignment: .leading, spacing: L2RTheme.Spacing.xxs) {
                        Text(voice.name)
                            .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body, weight: .semibold))
                            .foregroundStyle(L2RTheme.textPrimary)

                        if let description = voice.description {
                            Text(description)
                                .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.small))
                                .foregroundStyle(L2RTheme.textSecondary)
                                .lineLimit(2)
                        }

                        if let category = voice.category {
                            Text(category.capitalized)
                                .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.small, weight: .medium))
                                .foregroundStyle(L2RTheme.primary)
                                .padding(.horizontal, L2RTheme.Spacing.xs)
                                .padding(.vertical, L2RTheme.Spacing.xxxs)
                                .background(L2RTheme.primary.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.small))
                        }
                    }

                    Spacer()
                }
            }
            .buttonStyle(.plain)

            // Preview button
            Button(action: onPreview) {
                ZStack {
                    Circle()
                        .fill(isPreviewing ? L2RTheme.primary : L2RTheme.primary.opacity(0.1))
                        .frame(width: L2RTheme.TouchTarget.minimum, height: L2RTheme.TouchTarget.minimum)

                    if isPreviewing {
                        ProgressView()
                            .scaleEffect(0.7)
                            .tint(.white)
                    } else {
                        Image(systemName: "play.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(L2RTheme.primary)
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .padding(L2RTheme.Spacing.md)
        .background(isSelected ? L2RTheme.primary.opacity(0.05) : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.medium)
                .stroke(isSelected ? L2RTheme.primary : L2RTheme.border, lineWidth: isSelected ? 2 : 1)
        )
    }
}

// Previews removed due to type incompatibility
