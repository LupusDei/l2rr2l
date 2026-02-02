import SwiftUI

/// Generic activity content view that renders the appropriate UI based on activity type.
struct ActivityContentView: View {
    let activity: LessonActivity
    let onComplete: (Int?) -> Void

    var body: some View {
        VStack(spacing: L2RTheme.Spacing.xl) {
            // Instructions
            Text(activity.instructions)
                .font(L2RTheme.Typography.playful(size: L2RTheme.Typography.Size.title3, weight: .semibold))
                .foregroundStyle(L2RTheme.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, L2RTheme.Spacing.md)

            // Activity-specific content
            activityContent
        }
        .padding(L2RTheme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.xlarge)
                .fill(.white)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }

    @ViewBuilder
    private var activityContent: some View {
        switch activity.type {
        case .reading:
            ReadingActivityView(activity: activity, onComplete: onComplete)
        case .spelling:
            SpellingActivityView(activity: activity, onComplete: onComplete)
        case .phonics:
            PhonicsActivityView(activity: activity, onComplete: onComplete)
        case .sightWords:
            SightWordsActivityView(activity: activity, onComplete: onComplete)
        case .quiz:
            QuizActivityView(activity: activity, onComplete: onComplete)
        case .matching:
            MatchingActivityView(activity: activity, onComplete: onComplete)
        case .fillInBlank:
            FillInBlankActivityView(activity: activity, onComplete: onComplete)
        case .listenRepeat:
            ListenRepeatActivityView(activity: activity, onComplete: onComplete)
        case .wordBuilding:
            WordBuildingActivityView(activity: activity, onComplete: onComplete)
        }
    }
}

// MARK: - Reading Activity

struct ReadingActivityView: View {
    let activity: LessonActivity
    let onComplete: (Int?) -> Void
    @State private var hasRead = false

    var body: some View {
        VStack(spacing: L2RTheme.Spacing.lg) {
            if let content = activity.content {
                Text(content)
                    .font(L2RTheme.Typography.playful(size: L2RTheme.Typography.Size.title2, weight: .medium))
                    .foregroundStyle(L2RTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(L2RTheme.Spacing.lg)
            }

            Button {
                hasRead = true
                onComplete(activity.points)
            } label: {
                HStack(spacing: L2RTheme.Spacing.sm) {
                    Image(systemName: hasRead ? "checkmark.circle.fill" : "book.fill")
                    Text(hasRead ? "Read!" : "I Read It!")
                }
                .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.large, weight: .bold))
                .foregroundStyle(.white)
                .frame(height: L2RTheme.TouchTarget.large)
                .frame(maxWidth: 200)
                .background(hasRead ? L2RTheme.Status.success : L2RTheme.primary)
                .clipShape(RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.medium))
            }
            .disabled(hasRead)
        }
    }
}

// MARK: - Spelling Activity

struct SpellingActivityView: View {
    let activity: LessonActivity
    let onComplete: (Int?) -> Void
    @State private var userInput = ""
    @State private var showResult = false
    @State private var isCorrect = false

    var body: some View {
        VStack(spacing: L2RTheme.Spacing.lg) {
            if let hint = activity.hint {
                Text("Hint: \(hint)")
                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body, weight: .medium))
                    .foregroundStyle(L2RTheme.textSecondary)
            }

            TextField("Type the word...", text: $userInput)
                .font(L2RTheme.Typography.playful(size: L2RTheme.Typography.Size.title2, weight: .medium))
                .multilineTextAlignment(.center)
                .padding(L2RTheme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.medium)
                        .stroke(L2RTheme.inputBorder, lineWidth: 2)
                )
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .disabled(showResult)

            if showResult {
                HStack(spacing: L2RTheme.Spacing.sm) {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    Text(isCorrect ? "Correct!" : "The word was: \(activity.word ?? "")")
                }
                .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.large, weight: .semibold))
                .foregroundStyle(isCorrect ? L2RTheme.Status.success : L2RTheme.Status.error)
            } else {
                Button {
                    checkAnswer()
                } label: {
                    Text("Check")
                        .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.large, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(height: L2RTheme.TouchTarget.large)
                        .frame(maxWidth: 200)
                        .background(L2RTheme.primary)
                        .clipShape(RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.medium))
                }
                .disabled(userInput.isEmpty)
            }
        }
    }

    private func checkAnswer() {
        guard let word = activity.word else { return }
        isCorrect = userInput.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == word.lowercased()
        showResult = true
        onComplete(isCorrect ? activity.points : 0)
    }
}

// MARK: - Phonics Activity

struct PhonicsActivityView: View {
    let activity: LessonActivity
    let onComplete: (Int?) -> Void
    @State private var hasListened = false

    var body: some View {
        VStack(spacing: L2RTheme.Spacing.lg) {
            if let sound = activity.sound {
                Text(sound)
                    .font(.system(size: 72, weight: .bold))
                    .foregroundStyle(L2RTheme.primary)
            }

            if let examples = activity.exampleWords, !examples.isEmpty {
                VStack(spacing: L2RTheme.Spacing.sm) {
                    Text("Examples:")
                        .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body, weight: .medium))
                        .foregroundStyle(L2RTheme.textSecondary)

                    HStack(spacing: L2RTheme.Spacing.md) {
                        ForEach(examples, id: \.self) { word in
                            Text(word)
                                .font(L2RTheme.Typography.playful(size: L2RTheme.Typography.Size.large, weight: .medium))
                                .foregroundStyle(L2RTheme.textPrimary)
                                .padding(.horizontal, L2RTheme.Spacing.md)
                                .padding(.vertical, L2RTheme.Spacing.sm)
                                .background(
                                    RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.small)
                                        .fill(L2RTheme.Accent.teal.opacity(0.2))
                                )
                        }
                    }
                }
            }

            Button {
                hasListened = true
                onComplete(activity.points)
            } label: {
                HStack(spacing: L2RTheme.Spacing.sm) {
                    Image(systemName: hasListened ? "checkmark.circle.fill" : "speaker.wave.2.fill")
                    Text(hasListened ? "Got It!" : "I Learned It!")
                }
                .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.large, weight: .bold))
                .foregroundStyle(.white)
                .frame(height: L2RTheme.TouchTarget.large)
                .frame(maxWidth: 200)
                .background(hasListened ? L2RTheme.Status.success : L2RTheme.primary)
                .clipShape(RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.medium))
            }
            .disabled(hasListened)
        }
    }
}

// MARK: - Sight Words Activity

struct SightWordsActivityView: View {
    let activity: LessonActivity
    let onComplete: (Int?) -> Void
    @State private var currentWordIndex = 0
    @State private var completedWords: Set<Int> = []

    private var words: [String] {
        activity.words ?? []
    }

    var body: some View {
        VStack(spacing: L2RTheme.Spacing.lg) {
            if !words.isEmpty {
                Text(words[currentWordIndex])
                    .font(L2RTheme.Typography.playful(size: 48, weight: .bold))
                    .foregroundStyle(L2RTheme.primary)
                    .id(currentWordIndex)
                    .transition(.scale.combined(with: .opacity))

                // Word progress dots
                HStack(spacing: L2RTheme.Spacing.xs) {
                    ForEach(0..<words.count, id: \.self) { index in
                        Circle()
                            .fill(completedWords.contains(index) ? L2RTheme.Status.success : (index == currentWordIndex ? L2RTheme.primary : Color.gray.opacity(0.3)))
                            .frame(width: 10, height: 10)
                    }
                }

                Button {
                    markWordComplete()
                } label: {
                    HStack(spacing: L2RTheme.Spacing.sm) {
                        Image(systemName: currentWordIndex == words.count - 1 ? "checkmark.circle.fill" : "arrow.right")
                        Text(currentWordIndex == words.count - 1 ? "Done!" : "Next Word")
                    }
                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.large, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(height: L2RTheme.TouchTarget.large)
                    .frame(maxWidth: 200)
                    .background(L2RTheme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.medium))
                }
            }
        }
    }

    private func markWordComplete() {
        completedWords.insert(currentWordIndex)

        if currentWordIndex < words.count - 1 {
            withAnimation(L2RTheme.Animation.bounce) {
                currentWordIndex += 1
            }
        } else {
            onComplete(activity.points)
        }
    }
}

// MARK: - Quiz Activity

struct QuizActivityView: View {
    let activity: LessonActivity
    let onComplete: (Int?) -> Void
    @State private var selectedIndex: Int?
    @State private var showResult = false

    private var options: [String] {
        activity.options ?? []
    }

    private var isCorrect: Bool {
        selectedIndex == activity.correctIndex
    }

    var body: some View {
        VStack(spacing: L2RTheme.Spacing.lg) {
            if let question = activity.question {
                Text(question)
                    .font(L2RTheme.Typography.playful(size: L2RTheme.Typography.Size.title3, weight: .medium))
                    .foregroundStyle(L2RTheme.textPrimary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: L2RTheme.Spacing.md) {
                ForEach(0..<options.count, id: \.self) { index in
                    optionButton(index: index, text: options[index])
                }
            }

            if showResult {
                HStack(spacing: L2RTheme.Spacing.sm) {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    Text(isCorrect ? "Correct!" : (activity.explanation ?? "Try again!"))
                }
                .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body, weight: .semibold))
                .foregroundStyle(isCorrect ? L2RTheme.Status.success : L2RTheme.Status.error)
                .multilineTextAlignment(.center)
            }
        }
    }

    private func optionButton(index: Int, text: String) -> some View {
        Button {
            guard !showResult else { return }
            selectedIndex = index
            showResult = true
            onComplete(isCorrect ? activity.points : 0)
        } label: {
            HStack {
                Text(text)
                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.large, weight: .medium))
                Spacer()
                if showResult && index == activity.correctIndex {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(L2RTheme.Status.success)
                } else if showResult && index == selectedIndex {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(L2RTheme.Status.error)
                }
            }
            .foregroundStyle(L2RTheme.textPrimary)
            .padding(L2RTheme.Spacing.md)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.medium)
                    .fill(optionBackground(index: index))
            )
            .overlay(
                RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.medium)
                    .stroke(optionBorder(index: index), lineWidth: 2)
            )
        }
        .disabled(showResult)
    }

    private func optionBackground(index: Int) -> Color {
        if showResult {
            if index == activity.correctIndex {
                return L2RTheme.Status.success.opacity(0.2)
            } else if index == selectedIndex {
                return L2RTheme.Status.error.opacity(0.2)
            }
        }
        return .white
    }

    private func optionBorder(index: Int) -> Color {
        if showResult {
            if index == activity.correctIndex {
                return L2RTheme.Status.success
            } else if index == selectedIndex {
                return L2RTheme.Status.error
            }
        }
        return L2RTheme.inputBorder
    }
}

// MARK: - Matching Activity

struct MatchingActivityView: View {
    let activity: LessonActivity
    let onComplete: (Int?) -> Void
    @State private var matchedPairs: Set<Int> = []
    @State private var selectedLeft: Int?
    @State private var selectedRight: Int?

    private var pairs: [[String]] {
        activity.pairs ?? []
    }

    var body: some View {
        VStack(spacing: L2RTheme.Spacing.lg) {
            HStack(spacing: L2RTheme.Spacing.xl) {
                // Left column
                VStack(spacing: L2RTheme.Spacing.sm) {
                    ForEach(0..<pairs.count, id: \.self) { index in
                        matchButton(text: pairs[index].first ?? "", index: index, isLeft: true)
                    }
                }

                // Right column (shuffled)
                VStack(spacing: L2RTheme.Spacing.sm) {
                    ForEach(0..<pairs.count, id: \.self) { index in
                        matchButton(text: pairs[index].last ?? "", index: index, isLeft: false)
                    }
                }
            }

            if matchedPairs.count == pairs.count {
                HStack(spacing: L2RTheme.Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("All matched!")
                }
                .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.large, weight: .semibold))
                .foregroundStyle(L2RTheme.Status.success)
            }
        }
    }

    private func matchButton(text: String, index: Int, isLeft: Bool) -> some View {
        let isMatched = matchedPairs.contains(index)
        let isSelected = isLeft ? selectedLeft == index : selectedRight == index

        return Button {
            handleSelection(index: index, isLeft: isLeft)
        } label: {
            Text(text)
                .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body, weight: .medium))
                .foregroundStyle(isMatched ? .white : L2RTheme.textPrimary)
                .frame(width: 100, height: L2RTheme.TouchTarget.comfortable)
                .background(
                    RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.small)
                        .fill(isMatched ? L2RTheme.Status.success : (isSelected ? L2RTheme.primary.opacity(0.2) : .white))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.small)
                        .stroke(isSelected ? L2RTheme.primary : L2RTheme.inputBorder, lineWidth: isSelected ? 3 : 1)
                )
        }
        .disabled(isMatched)
    }

    private func handleSelection(index: Int, isLeft: Bool) {
        if isLeft {
            selectedLeft = index
        } else {
            selectedRight = index
        }

        // Check for match
        if let left = selectedLeft, let right = selectedRight {
            if left == right {
                matchedPairs.insert(left)
                if matchedPairs.count == pairs.count {
                    onComplete(activity.points)
                }
            }
            selectedLeft = nil
            selectedRight = nil
        }
    }
}

// MARK: - Fill In Blank Activity

struct FillInBlankActivityView: View {
    let activity: LessonActivity
    let onComplete: (Int?) -> Void
    @State private var userAnswer = ""
    @State private var showResult = false
    @State private var isCorrect = false

    private var wordBank: [String] {
        activity.wordBank ?? []
    }

    var body: some View {
        VStack(spacing: L2RTheme.Spacing.lg) {
            if let sentence = activity.sentence {
                Text(sentence.replacingOccurrences(of: "_____", with: userAnswer.isEmpty ? "_____" : "[\(userAnswer)]"))
                    .font(L2RTheme.Typography.playful(size: L2RTheme.Typography.Size.title3, weight: .medium))
                    .foregroundStyle(L2RTheme.textPrimary)
                    .multilineTextAlignment(.center)
            }

            if !wordBank.isEmpty && !showResult {
                HStack(spacing: L2RTheme.Spacing.sm) {
                    ForEach(wordBank, id: \.self) { word in
                        Button {
                            userAnswer = word
                        } label: {
                            Text(word)
                                .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body, weight: .medium))
                                .foregroundStyle(userAnswer == word ? .white : L2RTheme.textPrimary)
                                .padding(.horizontal, L2RTheme.Spacing.md)
                                .padding(.vertical, L2RTheme.Spacing.sm)
                                .background(
                                    RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.small)
                                        .fill(userAnswer == word ? L2RTheme.primary : .white)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.small)
                                        .stroke(L2RTheme.inputBorder, lineWidth: 1)
                                )
                        }
                    }
                }
            }

            if showResult {
                HStack(spacing: L2RTheme.Spacing.sm) {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    Text(isCorrect ? "Correct!" : "The answer was: \(activity.answer ?? "")")
                }
                .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body, weight: .semibold))
                .foregroundStyle(isCorrect ? L2RTheme.Status.success : L2RTheme.Status.error)
            } else {
                Button {
                    checkAnswer()
                } label: {
                    Text("Check")
                        .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.large, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(height: L2RTheme.TouchTarget.large)
                        .frame(maxWidth: 200)
                        .background(userAnswer.isEmpty ? Color.gray.opacity(0.4) : L2RTheme.primary)
                        .clipShape(RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.medium))
                }
                .disabled(userAnswer.isEmpty)
            }
        }
    }

    private func checkAnswer() {
        guard let answer = activity.answer else { return }
        isCorrect = userAnswer.lowercased() == answer.lowercased()
        showResult = true
        onComplete(isCorrect ? activity.points : 0)
    }
}

// MARK: - Listen Repeat Activity

struct ListenRepeatActivityView: View {
    let activity: LessonActivity
    let onComplete: (Int?) -> Void
    @State private var hasCompleted = false

    var body: some View {
        VStack(spacing: L2RTheme.Spacing.lg) {
            if let phrase = activity.phrase {
                Text(phrase)
                    .font(L2RTheme.Typography.playful(size: L2RTheme.Typography.Size.title2, weight: .bold))
                    .foregroundStyle(L2RTheme.primary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: L2RTheme.Spacing.lg) {
                Button {
                    // TODO: Play audio
                } label: {
                    VStack(spacing: L2RTheme.Spacing.xs) {
                        Image(systemName: "speaker.wave.3.fill")
                            .font(.system(size: 32))
                        Text("Listen")
                            .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body, weight: .medium))
                    }
                    .foregroundStyle(L2RTheme.primary)
                    .frame(width: 100, height: 80)
                    .background(
                        RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.medium)
                            .fill(L2RTheme.primary.opacity(0.1))
                    )
                }

                Button {
                    // TODO: Start recording
                } label: {
                    VStack(spacing: L2RTheme.Spacing.xs) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 32))
                        Text("Repeat")
                            .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body, weight: .medium))
                    }
                    .foregroundStyle(L2RTheme.Accent.coral)
                    .frame(width: 100, height: 80)
                    .background(
                        RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.medium)
                            .fill(L2RTheme.Accent.coral.opacity(0.1))
                    )
                }
            }

            Button {
                hasCompleted = true
                onComplete(activity.points)
            } label: {
                HStack(spacing: L2RTheme.Spacing.sm) {
                    Image(systemName: hasCompleted ? "checkmark.circle.fill" : "hand.thumbsup.fill")
                    Text(hasCompleted ? "Done!" : "I Said It!")
                }
                .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.large, weight: .bold))
                .foregroundStyle(.white)
                .frame(height: L2RTheme.TouchTarget.large)
                .frame(maxWidth: 200)
                .background(hasCompleted ? L2RTheme.Status.success : L2RTheme.primary)
                .clipShape(RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.medium))
            }
            .disabled(hasCompleted)
        }
    }
}

// MARK: - Word Building Activity

struct WordBuildingActivityView: View {
    let activity: LessonActivity
    let onComplete: (Int?) -> Void
    @State private var builtWords: Set<String> = []
    @State private var selectedOnset: String?

    private var onsets: [String] {
        activity.onsets ?? []
    }

    private var words: [String] {
        activity.words ?? []
    }

    var body: some View {
        VStack(spacing: L2RTheme.Spacing.lg) {
            if let pattern = activity.pattern {
                Text("Build words with: -\(pattern)")
                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.large, weight: .medium))
                    .foregroundStyle(L2RTheme.textSecondary)
            }

            // Word building area
            HStack(spacing: L2RTheme.Spacing.sm) {
                Text(selectedOnset ?? "?")
                    .font(L2RTheme.Typography.playful(size: 40, weight: .bold))
                    .foregroundStyle(L2RTheme.primary)
                    .frame(width: 60)

                Text(activity.pattern ?? "")
                    .font(L2RTheme.Typography.playful(size: 40, weight: .bold))
                    .foregroundStyle(L2RTheme.textPrimary)
            }
            .padding(L2RTheme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.large)
                    .fill(Color.gray.opacity(0.1))
            )

            // Onset buttons
            HStack(spacing: L2RTheme.Spacing.sm) {
                ForEach(onsets, id: \.self) { onset in
                    Button {
                        selectOnset(onset)
                    } label: {
                        Text(onset)
                            .font(L2RTheme.Typography.playful(size: L2RTheme.Typography.Size.title2, weight: .bold))
                            .foregroundStyle(builtWords.contains(onset + (activity.pattern ?? "")) ? .white : L2RTheme.textPrimary)
                            .frame(width: 50, height: 50)
                            .background(
                                Circle()
                                    .fill(builtWords.contains(onset + (activity.pattern ?? "")) ? L2RTheme.Status.success : .white)
                            )
                            .overlay(
                                Circle()
                                    .stroke(L2RTheme.inputBorder, lineWidth: 2)
                            )
                    }
                }
            }

            // Progress
            Text("\(builtWords.count) of \(words.count) words built")
                .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body, weight: .medium))
                .foregroundStyle(L2RTheme.textSecondary)

            if builtWords.count == words.count {
                HStack(spacing: L2RTheme.Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("All words built!")
                }
                .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.large, weight: .semibold))
                .foregroundStyle(L2RTheme.Status.success)
            }
        }
    }

    private func selectOnset(_ onset: String) {
        selectedOnset = onset
        let word = onset + (activity.pattern ?? "")

        if words.contains(word) && !builtWords.contains(word) {
            withAnimation(L2RTheme.Animation.bounce) {
                builtWords.insert(word)
            }

            if builtWords.count == words.count {
                onComplete(activity.points)
            }
        }
    }
}
