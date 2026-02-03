import SwiftUI

struct LessonsView: View {
    @ObservedObject var router = NavigationRouter.shared

    var body: some View {
        ScrollView {
            VStack(spacing: L2RTheme.Spacing.lg) {
                headerSection

                // Placeholder lesson cards
                ForEach(0..<5) { index in
                    lessonCard(index: index)
                }
            }
            .padding(L2RTheme.Spacing.lg)
        }
        .background(L2RTheme.background)
        .navigationTitle("Lessons")
        .navigationBarTitleDisplayMode(.large)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: L2RTheme.Spacing.sm) {
            Text("Your Learning Journey")
                .font(L2RTheme.Typography.playful(size: L2RTheme.Typography.Size.title2, weight: .bold))
                .foregroundStyle(L2RTheme.textPrimary)

            Text("Keep going! You're doing great!")
                .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body))
                .foregroundStyle(L2RTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func lessonCard(index: Int) -> some View {
        Button {
            router.lessonsPath.append(LessonDestination.detail(id: "lesson-\(index + 1)"))
        } label: {
            HStack(spacing: L2RTheme.Spacing.md) {
                // Lesson icon
                ZStack {
                    Circle()
                        .fill(L2RTheme.Logo.all[index % L2RTheme.Logo.all.count].opacity(0.2))
                        .frame(width: 56, height: 56)

                    Text("\(index + 1)")
                        .font(L2RTheme.Typography.playful(size: L2RTheme.Typography.Size.title2, weight: .bold))
                        .foregroundStyle(L2RTheme.Logo.all[index % L2RTheme.Logo.all.count])
                }

                VStack(alignment: .leading, spacing: L2RTheme.Spacing.xxs) {
                    Text("Lesson \(index + 1)")
                        .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.large, weight: .semibold))
                        .foregroundStyle(L2RTheme.textPrimary)

                    Text("Learn new sounds and words")
                        .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.small))
                        .foregroundStyle(L2RTheme.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(L2RTheme.textSecondary)
            }
            .padding(L2RTheme.Spacing.md)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.medium))
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Lesson \(index + 1), Learn new sounds and words")
        .accessibilityHint("Double tap to view lesson details")
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    NavigationStack {
        LessonsView()
    }
}
