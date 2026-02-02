import SwiftUI

// MARK: - Drop Zone State

enum DropZoneState {
    case empty
    case active
    case filled
    case locked
}

// MARK: - Drop Zone

/// A drop zone target for letter tile placement in spelling games.
struct DropZone: View {
    let index: Int
    let placedLetter: Character?
    let isActive: Bool
    let isLocked: Bool
    let onDrop: (Character) -> Bool

    @State private var animateAccept = false
    @State private var animateReject = false

    private var state: DropZoneState {
        if isLocked { return .locked }
        if placedLetter != nil { return .filled }
        if isActive { return .active }
        return .empty
    }

    var body: some View {
        ZStack {
            // Background
            backgroundView

            // Letter content
            if let letter = placedLetter {
                letterContent(letter)
            } else {
                indexIndicator
            }
        }
        .frame(width: 52, height: 60)
        .scaleEffect(animateAccept ? 1.1 : 1.0)
        .scaleEffect(animateReject ? 0.9 : 1.0)
        .offset(x: animateReject ? -4 : 0)
        .animation(L2RTheme.Animation.bounce, value: animateAccept)
        .animation(.default, value: animateReject)
        .onDrop(of: [.text], isTargeted: nil) { providers in
            handleDrop(providers: providers)
        }
    }

    // MARK: - Background

    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.medium)
            .fill(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.medium)
                    .stroke(borderStyle, lineWidth: borderWidth)
            )
            .shadow(
                color: shadowColor,
                radius: state == .active ? 6 : 2,
                y: state == .active ? 4 : 2
            )
    }

    private var backgroundColor: Color {
        switch state {
        case .empty:
            return L2RTheme.background
        case .active:
            return L2RTheme.primary.opacity(0.1)
        case .filled:
            return .white
        case .locked:
            return L2RTheme.Status.success.opacity(0.15)
        }
    }

    private var borderStyle: some ShapeStyle {
        switch state {
        case .empty:
            return AnyShapeStyle(L2RTheme.border.opacity(0.6))
        case .active:
            return AnyShapeStyle(L2RTheme.primary)
        case .filled:
            return AnyShapeStyle(L2RTheme.primary.opacity(0.3))
        case .locked:
            return AnyShapeStyle(L2RTheme.Status.success)
        }
    }

    private var borderWidth: CGFloat {
        switch state {
        case .empty: return 2
        case .active: return 3
        case .filled: return 2
        case .locked: return 2
        }
    }

    private var shadowColor: Color {
        switch state {
        case .empty:
            return .clear
        case .active:
            return L2RTheme.primary.opacity(0.3)
        case .filled:
            return Color.black.opacity(0.1)
        case .locked:
            return L2RTheme.Status.success.opacity(0.3)
        }
    }

    // MARK: - Letter Content

    private func letterContent(_ letter: Character) -> some View {
        Text(String(letter).uppercased())
            .font(L2RTheme.Typography.playful(size: L2RTheme.Typography.Size.title2, weight: .bold))
            .foregroundStyle(letterColor)
    }

    private var letterColor: Color {
        switch state {
        case .locked:
            return L2RTheme.Status.success
        default:
            return L2RTheme.textPrimary
        }
    }

    // MARK: - Index Indicator

    private var indexIndicator: some View {
        Text("\(index + 1)")
            .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.small, weight: .medium))
            .foregroundStyle(L2RTheme.textSecondary.opacity(0.5))
    }

    // MARK: - Drop Handling

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard !isLocked else { return false }

        for provider in providers {
            if provider.canLoadObject(ofClass: NSString.self) {
                provider.loadObject(ofClass: NSString.self) { object, _ in
                    if let string = object as? String, let char = string.first {
                        DispatchQueue.main.async {
                            let accepted = onDrop(char)
                            if accepted {
                                triggerAcceptAnimation()
                            } else {
                                triggerRejectAnimation()
                            }
                        }
                    }
                }
                return true
            }
        }
        return false
    }

    private func triggerAcceptAnimation() {
        animateAccept = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            animateAccept = false
        }
    }

    private func triggerRejectAnimation() {
        withAnimation(.default.speed(4).repeatCount(3, autoreverses: true)) {
            animateReject = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            animateReject = false
        }
    }
}

// MARK: - Drop Zone Row

/// A horizontal row of drop zones for a word.
struct DropZoneRow: View {
    let wordLength: Int
    let placedLetters: [Character?]
    let lockedIndices: Set<Int>
    let activeIndex: Int?
    let onDrop: (Int, Character) -> Bool

    var body: some View {
        HStack(spacing: L2RTheme.Spacing.xs) {
            ForEach(0..<wordLength, id: \.self) { index in
                DropZone(
                    index: index,
                    placedLetter: index < placedLetters.count ? placedLetters[index] : nil,
                    isActive: activeIndex == index,
                    isLocked: lockedIndices.contains(index),
                    onDrop: { char in
                        onDrop(index, char)
                    }
                )
            }
        }
    }
}

// MARK: - Preview

#Preview("Drop Zone States") {
    VStack(spacing: L2RTheme.Spacing.xl) {
        Text("Drop Zone States")
            .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.title3, weight: .bold))

        HStack(spacing: L2RTheme.Spacing.md) {
            VStack {
                DropZone(index: 0, placedLetter: nil, isActive: false, isLocked: false, onDrop: { _ in true })
                Text("Empty").font(.caption)
            }

            VStack {
                DropZone(index: 1, placedLetter: nil, isActive: true, isLocked: false, onDrop: { _ in true })
                Text("Active").font(.caption)
            }

            VStack {
                DropZone(index: 2, placedLetter: "C", isActive: false, isLocked: false, onDrop: { _ in true })
                Text("Filled").font(.caption)
            }

            VStack {
                DropZone(index: 3, placedLetter: "A", isActive: false, isLocked: true, onDrop: { _ in true })
                Text("Locked").font(.caption)
            }
        }

        Divider()

        Text("Word: CAT")
            .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.title3, weight: .bold))

        DropZoneRow(
            wordLength: 3,
            placedLetters: ["C", "A", nil],
            lockedIndices: [0],
            activeIndex: 2,
            onDrop: { _, _ in true }
        )
    }
    .padding()
    .background(L2RTheme.background)
}
