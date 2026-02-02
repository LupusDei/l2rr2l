import SwiftUI

// MARK: - Loading Size

enum LoadingSize {
    case small
    case medium
    case large

    var dimension: CGFloat {
        switch self {
        case .small: return 20
        case .medium: return 36
        case .large: return 56
        }
    }

    var lineWidth: CGFloat {
        switch self {
        case .small: return 2
        case .medium: return 3
        case .large: return 4
        }
    }
}

// MARK: - Loading Spinner

struct LoadingSpinner: View {
    let size: LoadingSize
    var color: Color = L2RTheme.primary

    @State private var isAnimating = false

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(
                color,
                style: StrokeStyle(
                    lineWidth: size.lineWidth,
                    lineCap: .round
                )
            )
            .frame(width: size.dimension, height: size.dimension)
            .rotationEffect(.degrees(isAnimating ? 360 : 0))
            .onAppear {
                withAnimation(
                    .linear(duration: 1.0)
                    .repeatForever(autoreverses: false)
                ) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Progress Bar

struct ProgressBar: View {
    let progress: Double
    var showLabel: Bool = false
    var color: Color = L2RTheme.primary
    var backgroundColor: Color = L2RTheme.border
    var height: CGFloat = 8

    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: L2RTheme.Spacing.xxs) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(backgroundColor)
                        .frame(height: height)

                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(color)
                        .frame(
                            width: geometry.size.width * clampedProgress,
                            height: height
                        )
                        .animation(.easeInOut(duration: L2RTheme.Animation.normal), value: clampedProgress)
                }
            }
            .frame(height: height)

            if showLabel {
                Text("\(Int(clampedProgress * 100))%")
                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.small, weight: .medium))
                    .foregroundStyle(L2RTheme.textSecondary)
            }
        }
    }
}

// MARK: - Shimmer Modifier

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0),
                            Color.white.opacity(0.5),
                            Color.white.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 0.6)
                    .offset(x: -geometry.size.width * 0.3 + (geometry.size.width * 1.6) * phase)
                }
                .mask(content)
            )
            .onAppear {
                withAnimation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Skeleton View

struct SkeletonView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.small)
            .fill(L2RTheme.border)
            .shimmer()
    }
}

// MARK: - Skeleton Card

struct SkeletonCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: L2RTheme.Spacing.sm) {
            SkeletonView()
                .frame(height: 120)

            VStack(alignment: .leading, spacing: L2RTheme.Spacing.xs) {
                SkeletonView()
                    .frame(height: 20)

                SkeletonView()
                    .frame(width: 150, height: 14)
            }
            .padding(.horizontal, L2RTheme.Spacing.sm)
            .padding(.bottom, L2RTheme.Spacing.sm)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.medium))
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Skeleton List Item

struct SkeletonListItem: View {
    var body: some View {
        HStack(spacing: L2RTheme.Spacing.md) {
            SkeletonView()
                .frame(width: 48, height: 48)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: L2RTheme.Spacing.xs) {
                SkeletonView()
                    .frame(height: 16)

                SkeletonView()
                    .frame(width: 100, height: 12)
            }

            Spacer()
        }
        .padding(L2RTheme.Spacing.md)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.medium))
    }
}

// MARK: - Full Screen Loader

struct FullScreenLoader: View {
    var message: String?
    var spinnerColor: Color = L2RTheme.primary
    var backgroundColor: Color = Color.black.opacity(0.4)

    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()

            VStack(spacing: L2RTheme.Spacing.lg) {
                LoadingSpinner(size: .large, color: spinnerColor)

                if let message = message {
                    Text(message)
                        .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body, weight: .medium))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(L2RTheme.Spacing.xxl)
            .background(
                RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.large)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
            )
        }
    }
}

// MARK: - Loading Overlay Modifier

struct LoadingOverlayModifier: ViewModifier {
    let isLoading: Bool
    let message: String?

    func body(content: Content) -> some View {
        ZStack {
            content
                .disabled(isLoading)

            if isLoading {
                FullScreenLoader(message: message)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: L2RTheme.Animation.normal), value: isLoading)
    }
}

extension View {
    func loadingOverlay(isLoading: Bool, message: String? = nil) -> some View {
        modifier(LoadingOverlayModifier(isLoading: isLoading, message: message))
    }
}

// MARK: - Previews

#Preview("Loading Spinner Sizes") {
    HStack(spacing: L2RTheme.Spacing.xl) {
        VStack {
            LoadingSpinner(size: .small)
            Text("Small").font(.caption)
        }
        VStack {
            LoadingSpinner(size: .medium)
            Text("Medium").font(.caption)
        }
        VStack {
            LoadingSpinner(size: .large)
            Text("Large").font(.caption)
        }
    }
    .padding()
}

#Preview("Loading Spinner Colors") {
    HStack(spacing: L2RTheme.Spacing.xl) {
        LoadingSpinner(size: .medium, color: L2RTheme.Status.success)
        LoadingSpinner(size: .medium, color: L2RTheme.Status.warning)
        LoadingSpinner(size: .medium, color: L2RTheme.Status.error)
        LoadingSpinner(size: .medium, color: L2RTheme.Status.info)
    }
    .padding()
}

#Preview("Progress Bar") {
    VStack(spacing: L2RTheme.Spacing.lg) {
        ProgressBar(progress: 0.3)
        ProgressBar(progress: 0.6, showLabel: true)
        ProgressBar(progress: 0.9, showLabel: true, color: L2RTheme.Status.success)
    }
    .padding()
}

#Preview("Skeleton Card") {
    SkeletonCard()
        .frame(width: 200)
        .padding()
        .background(L2RTheme.background)
}

#Preview("Skeleton List Items") {
    VStack(spacing: L2RTheme.Spacing.sm) {
        SkeletonListItem()
        SkeletonListItem()
        SkeletonListItem()
    }
    .padding()
    .background(L2RTheme.background)
}

#Preview("Full Screen Loader") {
    ZStack {
        Color.blue
            .ignoresSafeArea()

        Text("Background Content")
            .foregroundStyle(.white)

        FullScreenLoader(message: "Loading...")
    }
}

#Preview("Full Screen Loader - No Message") {
    ZStack {
        LinearGradient.homeBackground
            .ignoresSafeArea()

        FullScreenLoader()
    }
}
