import SwiftUI

/// A view modifier that constrains content width on iPad and adjusts grid columns.
struct AdaptiveContainer: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var maxWidth: CGFloat = L2RTheme.Layout.maxContentWidth

    func body(content: Content) -> some View {
        if horizontalSizeClass == .regular {
            content
                .frame(maxWidth: maxWidth)
                .frame(maxWidth: .infinity)
        } else {
            content
        }
    }
}

extension View {
    /// Constrains content to maxContentWidth on iPad, centered.
    func adaptiveContainer(maxWidth: CGFloat = L2RTheme.Layout.maxContentWidth) -> some View {
        modifier(AdaptiveContainer(maxWidth: maxWidth))
    }
}

/// Returns an appropriate column count based on horizontal size class.
struct AdaptiveGridColumns {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    /// Returns 2 columns for iPhone, 3 for iPad.
    static func gameColumns(sizeClass: UserInterfaceSizeClass?) -> [GridItem] {
        let count = sizeClass == .regular ? 3 : 2
        return Array(repeating: GridItem(.flexible(), spacing: L2RTheme.Spacing.md), count: count)
    }

    /// Returns 1 column for iPhone, 2 for iPad.
    static func lessonColumns(sizeClass: UserInterfaceSizeClass?) -> [GridItem] {
        let count = sizeClass == .regular ? 2 : 1
        return Array(repeating: GridItem(.flexible(), spacing: L2RTheme.Spacing.md), count: count)
    }
}
