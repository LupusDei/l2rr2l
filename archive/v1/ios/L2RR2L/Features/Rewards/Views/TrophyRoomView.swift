import SwiftUI
import SwiftData

/// Trophy room displaying the child's sticker collection across all games.
struct TrophyRoomView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var stickerBook: StickerBook?
    @State private var selectedSticker: Sticker?

    private let columns = [
        GridItem(.flexible(), spacing: L2RTheme.Spacing.sm),
        GridItem(.flexible(), spacing: L2RTheme.Spacing.sm),
        GridItem(.flexible(), spacing: L2RTheme.Spacing.sm)
    ]

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    L2RTheme.Logo.purple.opacity(0.8),
                    L2RTheme.Logo.blue.opacity(0.6),
                    L2RTheme.Logo.purple.opacity(0.9)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                stickerContent
            }
        }
        .onAppear {
            stickerBook = StickerBook(modelContext: modelContext)
        }
        .sheet(item: $selectedSticker) { sticker in
            StickerDetailView(sticker: sticker)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(minWidth: L2RTheme.TouchTarget.minimum, minHeight: L2RTheme.TouchTarget.minimum)
            }
            .accessibilityLabel("Close trophy room")

            Spacer()

            VStack(spacing: L2RTheme.Spacing.xxs) {
                Text("Trophy Room")
                    .font(L2RTheme.Typography.Scaled.playful(relativeTo: .title2, weight: .bold))
                    .foregroundStyle(.white)

                if let book = stickerBook {
                    Text("\(book.totalCount()) stickers earned")
                        .font(L2RTheme.Typography.Scaled.system(.footnote, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }

            Spacer()

            // Balance the close button
            Color.clear
                .frame(width: L2RTheme.TouchTarget.minimum, height: L2RTheme.TouchTarget.minimum)
        }
        .padding(.horizontal, L2RTheme.Spacing.md)
        .padding(.vertical, L2RTheme.Spacing.md)
    }

    // MARK: - Sticker Content

    private var stickerContent: some View {
        ScrollView {
            LazyVStack(spacing: L2RTheme.Spacing.xl) {
                ForEach(GameType.allCases) { gameType in
                    gameSection(for: gameType)
                }
            }
            .padding(.horizontal, L2RTheme.Spacing.md)
            .padding(.bottom, L2RTheme.Spacing.xxl)
        }
    }

    // MARK: - Game Section

    private func gameSection(for gameType: GameType) -> some View {
        let catalogEntries = StickerCatalog.entries(for: gameType)
        let earnedStickers = stickerBook?.stickers(for: gameType) ?? []
        let earnedNames = Set(earnedStickers.map(\.displayName))
        let earnedCount = min(earnedNames.count, catalogEntries.count)

        return VStack(spacing: L2RTheme.Spacing.sm) {
            // Section header
            HStack {
                Image(systemName: gameType.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(.white)

                Text(gameType.title)
                    .font(L2RTheme.Typography.Scaled.playful(relativeTo: .headline, weight: .bold))
                    .foregroundStyle(.white)

                Spacer()

                Text("\(earnedCount)/\(catalogEntries.count)")
                    .font(L2RTheme.Typography.Scaled.system(.callout, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.horizontal, L2RTheme.Spacing.sm)
                    .padding(.vertical, L2RTheme.Spacing.xxs)
                    .background(
                        Capsule()
                            .fill(.white.opacity(0.2))
                    )
            }
            .padding(.horizontal, L2RTheme.Spacing.xs)

            // Sticker grid
            LazyVGrid(columns: columns, spacing: L2RTheme.Spacing.sm) {
                ForEach(Array(catalogEntries.enumerated()), id: \.offset) { _, entry in
                    let earned = earnedStickers.first { $0.displayName == entry.displayName }
                    if let earned {
                        earnedStickerCard(sticker: earned, entry: entry)
                    } else {
                        unearnedStickerCard(entry: entry)
                    }
                }
            }
        }
        .padding(L2RTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.large)
                .fill(.white.opacity(0.1))
        )
    }

    // MARK: - Earned Sticker Card

    private func earnedStickerCard(sticker: Sticker, entry: StickerCatalogEntry) -> some View {
        Button {
            selectedSticker = sticker
        } label: {
            VStack(spacing: L2RTheme.Spacing.xs) {
                Text(entry.emoji)
                    .font(.system(size: 40))

                Text(entry.displayName)
                    .font(L2RTheme.Typography.Scaled.playful(relativeTo: .caption2, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                stickerTypeBadge(entry.type)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, L2RTheme.Spacing.sm)
            .padding(.horizontal, L2RTheme.Spacing.xxs)
            .background(
                RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.medium)
                    .fill(cardColor(for: entry.type))
            )
            .shadow(
                color: cardColor(for: entry.type).opacity(0.4),
                radius: 4,
                y: 3
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(entry.displayName) sticker, earned")
    }

    // MARK: - Unearned Sticker Card

    private func unearnedStickerCard(entry: StickerCatalogEntry) -> some View {
        VStack(spacing: L2RTheme.Spacing.xs) {
            Text(entry.emoji)
                .font(.system(size: 40))
                .grayscale(1.0)
                .opacity(0.3)

            Text("???")
                .font(L2RTheme.Typography.Scaled.playful(relativeTo: .caption2, weight: .bold))
                .foregroundStyle(.white.opacity(0.3))

            stickerTypeBadge(entry.type)
                .opacity(0.3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, L2RTheme.Spacing.sm)
        .padding(.horizontal, L2RTheme.Spacing.xxs)
        .background(
            RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.medium)
                .fill(.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.medium)
                        .stroke(.white.opacity(0.1), style: StrokeStyle(lineWidth: 1, dash: [4]))
                )
        )
        .accessibilityLabel("Locked sticker")
    }

    // MARK: - Helpers

    private func stickerTypeBadge(_ type: StickerType) -> some View {
        Text(typeBadgeText(type))
            .font(L2RTheme.Typography.Scaled.system(.caption2, weight: .semibold))
            .foregroundStyle(.white.opacity(0.7))
    }

    private func typeBadgeText(_ type: StickerType) -> String {
        switch type {
        case .normal: return ""
        case .golden: return "GOLDEN"
        case .special: return "SPECIAL"
        }
    }

    private func cardColor(for type: StickerType) -> Color {
        switch type {
        case .normal: return L2RTheme.Logo.blue
        case .golden: return L2RTheme.Logo.yellow
        case .special: return L2RTheme.Logo.purple
        }
    }
}

// MARK: - Sticker Detail View

private struct StickerDetailView: View {
    let sticker: Sticker
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: L2RTheme.Spacing.lg) {
            // Emoji large
            Text(sticker.emoji)
                .font(.system(size: 80))
                .padding(.top, L2RTheme.Spacing.lg)

            // Name
            Text(sticker.displayName)
                .font(L2RTheme.Typography.Scaled.playful(relativeTo: .title2, weight: .bold))

            // Type badge
            HStack(spacing: L2RTheme.Spacing.xs) {
                Image(systemName: badgeIcon(for: sticker.type))
                    .foregroundStyle(badgeColor(for: sticker.type))
                Text(sticker.type.rawValue.capitalized)
                    .font(L2RTheme.Typography.Scaled.system(.callout, weight: .semibold))
                    .foregroundStyle(badgeColor(for: sticker.type))
            }
            .padding(.horizontal, L2RTheme.Spacing.md)
            .padding(.vertical, L2RTheme.Spacing.xs)
            .background(
                Capsule()
                    .fill(badgeColor(for: sticker.type).opacity(0.15))
            )

            // Game source
            if let gameSource = sticker.gameSource {
                HStack(spacing: L2RTheme.Spacing.xs) {
                    Image(systemName: gameSource.icon)
                    Text("From \(gameSource.title)")
                }
                .font(L2RTheme.Typography.Scaled.system(.subheadline, weight: .medium))
                .foregroundStyle(.secondary)
            }

            // Date earned
            Text("Earned \(sticker.dateEarned.formatted(date: .abbreviated, time: .omitted))")
                .font(L2RTheme.Typography.Scaled.system(.footnote, weight: .regular))
                .foregroundStyle(.secondary)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func badgeIcon(for type: StickerType) -> String {
        switch type {
        case .normal: return "star"
        case .golden: return "star.fill"
        case .special: return "sparkles"
        }
    }

    private func badgeColor(for type: StickerType) -> Color {
        switch type {
        case .normal: return L2RTheme.Logo.blue
        case .golden: return L2RTheme.Logo.yellow
        case .special: return L2RTheme.Logo.purple
        }
    }
}

// MARK: - Preview

#Preview("Trophy Room") {
    TrophyRoomView()
        .modelContainer(for: Sticker.self, inMemory: true)
}
