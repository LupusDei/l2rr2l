import Foundation

/// Game states for the Read Aloud game.
enum ReadAloudGameState: Equatable {
    case notStarted
    case listening
    case recording
    case correct
    case incorrect
    case gameComplete
}

/// ViewModel for the Read Aloud game.
/// Players read sight words aloud and get feedback on pronunciation.
@MainActor
final class ReadAloudGameViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published private(set) var gameState: ReadAloudGameState = .notStarted
    @Published private(set) var currentWord: String?
    @Published private(set) var score = 0
    @Published private(set) var streak = 0
    @Published private(set) var bestStreak = 0
    @Published private(set) var round = 0
    @Published private(set) var isCorrect: Bool?
    @Published private(set) var transcription = ""
    @Published private(set) var pronunciationScore: Double = 0
    @Published var selectedLevel: ReadAloudLevel = .prePrimer
    @Published var showCelebration = false
    @Published var permissionDenied = false

    // MARK: - Configuration

    let totalRounds = 10

    // MARK: - Private Properties

    private var words: [String] = []
    private var usedWords: Set<String> = []
    private let speechService = SpeechRecognitionService.shared
    private let voiceService = VoiceService.shared

    // MARK: - Computed Properties

    var progress: Double {
        guard totalRounds > 0 else { return 0 }
        return Double(round) / Double(totalRounds)
    }

    var isRecording: Bool {
        speechService.isRecording
    }

    var audioLevel: Float {
        speechService.audioLevel
    }

    // MARK: - Game Flow

    /// Starts a new game with the selected level.
    func startGame() {
        score = 0
        streak = 0
        bestStreak = 0
        round = 0
        usedWords.removeAll()
        isCorrect = nil
        transcription = ""
        showCelebration = false

        words = SightWordsData.randomWords(level: selectedLevel, count: totalRounds)
        nextWord()
    }

    /// Advances to the next word.
    func nextWord() {
        guard round < totalRounds else {
            gameState = .gameComplete
            HapticService.shared.levelComplete()
            SoundEffectService.shared.play(.levelComplete)
            return
        }

        round += 1
        isCorrect = nil
        transcription = ""
        pronunciationScore = 0

        if round - 1 < words.count {
            currentWord = words[round - 1]
        } else {
            // Fallback: pick a random unused word
            let available = selectedLevel.words.filter { !usedWords.contains($0) }
            currentWord = available.randomElement() ?? selectedLevel.words.randomElement()
        }

        if let word = currentWord {
            usedWords.insert(word)
        }

        gameState = .listening

        // Speak the prompt
        if let word = currentWord {
            Task {
                await voiceService.speak("Can you read the word: \(word)?")
            }
        }
    }

    /// Speaks the current word aloud for the child to hear again.
    func hearWord() {
        guard let word = currentWord else { return }
        Task {
            await voiceService.speak(word)
        }
    }

    /// Starts recording the user's pronunciation.
    func startRecording() async {
        guard gameState == .listening else { return }

        gameState = .recording
        transcription = ""

        do {
            try await speechService.startRecording()
        } catch {
            permissionDenied = true
            gameState = .listening
        }
    }

    /// Stops recording and evaluates the pronunciation.
    func stopRecording() {
        guard gameState == .recording else { return }

        let result = speechService.stopRecording()
        transcription = result

        guard let word = currentWord else { return }

        // Check pronunciation
        pronunciationScore = speechService.checkPronunciation(expected: word, actual: result)
        let correct = speechService.isPronunciationCorrect(expected: word, actual: result)

        isCorrect = correct

        if correct {
            score += 10 * (streak + 1)
            streak += 1
            bestStreak = max(bestStreak, streak)
            gameState = .correct
            HapticService.shared.correctAnswer()
            SoundEffectService.shared.play(.correct)

            // Celebration at streak milestones
            if streak >= 3 && streak % 3 == 0 {
                showCelebration = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                    self?.showCelebration = false
                }
            }

            // Speak encouragement
            Task {
                let messages = ["Great job!", "You got it!", "Well done!", "Awesome!"]
                await voiceService.speak(messages.randomElement()!)
            }
        } else {
            streak = 0
            gameState = .incorrect
            HapticService.shared.incorrectAnswer()
            SoundEffectService.shared.play(.incorrect)

            // Speak the correct word
            Task {
                await voiceService.speak("The word is: \(word)")
            }
        }
    }

    /// Resets the game to initial state.
    func resetGame() {
        score = 0
        streak = 0
        bestStreak = 0
        round = 0
        usedWords.removeAll()
        isCorrect = nil
        transcription = ""
        currentWord = nil
        showCelebration = false
        gameState = .notStarted

        if speechService.isRecording {
            _ = speechService.stopRecording()
        }
    }
}
