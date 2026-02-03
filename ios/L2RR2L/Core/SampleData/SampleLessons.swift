import Foundation

/// Sample lessons for development and preview purposes.
/// In production, these would be fetched from the API.
enum SampleLessons {
    /// All available sample lessons
    static let all: [Lesson] = [
        phonicsBasics,
        letterSoundsAE,
        sightWordsOne,
        spellingPractice,
        readingComprehension
    ]

    /// Get a lesson by ID, returns nil if not found
    static func lesson(for id: String) -> Lesson? {
        all.first { $0.id == id }
    }

    /// Get a lesson by index (1-based to match UI)
    static func lesson(at index: Int) -> Lesson? {
        let adjustedIndex = index - 1
        guard adjustedIndex >= 0 && adjustedIndex < all.count else {
            return nil
        }
        return all[adjustedIndex]
    }

    // MARK: - Sample Lessons

    static let phonicsBasics = Lesson(
        id: "lesson-1",
        title: "Phonics Basics",
        description: "Learn the sounds that letters make and how to blend them together to form words. This foundational lesson covers the alphabet sounds and introduces simple word building.",
        subject: .phonics,
        difficulty: .beginner,
        objectives: [
            "Learn letter sounds A-Z",
            "Practice beginning sounds",
            "Blend simple CVC words",
            "Identify sounds in words"
        ],
        activities: [
            LessonActivity(
                id: "pb-a1",
                type: .phonics,
                instructions: "Listen to the sound and repeat",
                spokenInstructions: "Listen to the sound and say it back",
                order: 1,
                points: 10,
                content: nil, imageUrl: nil, readAloud: nil, word: nil, hint: nil, audioUrl: nil,
                sound: "a",
                exampleWords: ["apple", "ant", "alligator"],
                soundPosition: "beginning",
                words: nil, showInContext: nil, question: nil, options: nil, correctIndex: nil, explanation: nil, pairs: nil, matchType: nil, sentence: nil, answer: nil, wordBank: nil, phrase: nil, checkPronunciation: nil, pattern: nil, onsets: nil
            ),
            LessonActivity(
                id: "pb-a2",
                type: .quiz,
                instructions: "Choose the correct answer",
                spokenInstructions: "Which word starts with the 'a' sound?",
                order: 2,
                points: 10,
                content: nil, imageUrl: nil, readAloud: nil, word: nil, hint: nil, audioUrl: nil, sound: nil, exampleWords: nil, soundPosition: nil, words: nil, showInContext: nil,
                question: "Which word starts with the 'a' sound?",
                options: ["Apple", "Ball", "Cat"],
                correctIndex: 0,
                explanation: "Apple starts with the 'a' sound!",
                pairs: nil, matchType: nil, sentence: nil, answer: nil, wordBank: nil, phrase: nil, checkPronunciation: nil, pattern: nil, onsets: nil
            ),
            LessonActivity(
                id: "pb-a3",
                type: .matching,
                instructions: "Match the letters to their sounds",
                spokenInstructions: nil,
                order: 3,
                points: 15,
                content: nil, imageUrl: nil, readAloud: nil, word: nil, hint: nil, audioUrl: nil, sound: nil, exampleWords: nil, soundPosition: nil, words: nil, showInContext: nil, question: nil, options: nil, correctIndex: nil, explanation: nil,
                pairs: [["A", "ah"], ["B", "buh"], ["C", "kuh"]],
                matchType: "letter-sound",
                sentence: nil, answer: nil, wordBank: nil, phrase: nil, checkPronunciation: nil, pattern: nil, onsets: nil
            ),
            LessonActivity(
                id: "pb-a4",
                type: .listenRepeat,
                instructions: "Listen and repeat the word",
                spokenInstructions: "Say the word: cat",
                order: 4,
                points: 10,
                content: nil, imageUrl: nil, readAloud: nil, word: nil, hint: nil, audioUrl: nil, sound: nil, exampleWords: nil, soundPosition: nil, words: nil, showInContext: nil, question: nil, options: nil, correctIndex: nil, explanation: nil, pairs: nil, matchType: nil, sentence: nil, answer: nil, wordBank: nil,
                phrase: "cat",
                checkPronunciation: true,
                pattern: nil, onsets: nil
            ),
            LessonActivity(
                id: "pb-a5",
                type: .wordBuilding,
                instructions: "Build words using the -at pattern",
                spokenInstructions: nil,
                order: 5,
                points: 20,
                content: nil, imageUrl: nil, readAloud: nil, word: nil, hint: nil, audioUrl: nil, sound: nil, exampleWords: nil, soundPosition: nil, words: nil, showInContext: nil, question: nil, options: nil, correctIndex: nil, explanation: nil, pairs: nil, matchType: nil, sentence: nil, answer: nil, wordBank: nil, phrase: nil, checkPronunciation: nil,
                pattern: "-at",
                onsets: ["c", "b", "h", "m", "s"]
            )
        ],
        durationMinutes: 15,
        prerequisites: nil,
        tags: ["phonics", "beginner", "alphabet"],
        thumbnailUrl: nil,
        ageRange: Lesson.AgeRange(min: 4, max: 6),
        createdAt: "2026-01-01",
        updatedAt: "2026-01-15"
    )

    static let letterSoundsAE = Lesson(
        id: "lesson-2",
        title: "Letter Sounds A-E",
        description: "Master the sounds of the first five letters of the alphabet. Learn how to identify and produce each sound correctly.",
        subject: .phonics,
        difficulty: .beginner,
        objectives: [
            "Identify letter sounds A through E",
            "Match sounds to letters",
            "Practice pronunciation"
        ],
        activities: [
            LessonActivity(
                id: "ls-a1",
                type: .phonics,
                instructions: "Listen to the letter A sound",
                spokenInstructions: "The letter A makes the 'ah' sound",
                order: 1,
                points: 10,
                content: nil, imageUrl: nil, readAloud: nil, word: nil, hint: nil, audioUrl: nil,
                sound: "a",
                exampleWords: ["apple", "astronaut"],
                soundPosition: "beginning",
                words: nil, showInContext: nil, question: nil, options: nil, correctIndex: nil, explanation: nil, pairs: nil, matchType: nil, sentence: nil, answer: nil, wordBank: nil, phrase: nil, checkPronunciation: nil, pattern: nil, onsets: nil
            ),
            LessonActivity(
                id: "ls-a2",
                type: .phonics,
                instructions: "Listen to the letter B sound",
                spokenInstructions: "The letter B makes the 'buh' sound",
                order: 2,
                points: 10,
                content: nil, imageUrl: nil, readAloud: nil, word: nil, hint: nil, audioUrl: nil,
                sound: "b",
                exampleWords: ["ball", "banana"],
                soundPosition: "beginning",
                words: nil, showInContext: nil, question: nil, options: nil, correctIndex: nil, explanation: nil, pairs: nil, matchType: nil, sentence: nil, answer: nil, wordBank: nil, phrase: nil, checkPronunciation: nil, pattern: nil, onsets: nil
            ),
            LessonActivity(
                id: "ls-a3",
                type: .quiz,
                instructions: "Test your knowledge",
                spokenInstructions: nil,
                order: 3,
                points: 15,
                content: nil, imageUrl: nil, readAloud: nil, word: nil, hint: nil, audioUrl: nil, sound: nil, exampleWords: nil, soundPosition: nil, words: nil, showInContext: nil,
                question: "What sound does the letter E make?",
                options: ["eh", "ah", "oh"],
                correctIndex: 0,
                explanation: "E makes the 'eh' sound like in 'egg'",
                pairs: nil, matchType: nil, sentence: nil, answer: nil, wordBank: nil, phrase: nil, checkPronunciation: nil, pattern: nil, onsets: nil
            )
        ],
        durationMinutes: 12,
        prerequisites: nil,
        tags: ["phonics", "alphabet"],
        thumbnailUrl: nil,
        ageRange: Lesson.AgeRange(min: 4, max: 5),
        createdAt: "2026-01-02",
        updatedAt: "2026-01-15"
    )

    static let sightWordsOne = Lesson(
        id: "lesson-3",
        title: "Sight Words: Set 1",
        description: "Learn essential sight words that appear frequently in children's books. These words are the building blocks of reading fluency.",
        subject: .sightWords,
        difficulty: .beginner,
        objectives: [
            "Recognize 10 common sight words",
            "Read sight words in context",
            "Build reading confidence"
        ],
        activities: [
            LessonActivity(
                id: "sw-a1",
                type: .sightWords,
                instructions: "Learn these sight words",
                spokenInstructions: "Let's learn some important words you'll see a lot",
                order: 1,
                points: 10,
                content: nil, imageUrl: nil, readAloud: nil, word: nil, hint: nil, audioUrl: nil, sound: nil, exampleWords: nil, soundPosition: nil,
                words: ["the", "and", "is", "it", "you"],
                showInContext: true,
                question: nil, options: nil, correctIndex: nil, explanation: nil, pairs: nil, matchType: nil, sentence: nil, answer: nil, wordBank: nil, phrase: nil, checkPronunciation: nil, pattern: nil, onsets: nil
            ),
            LessonActivity(
                id: "sw-a2",
                type: .matching,
                instructions: "Match the words",
                spokenInstructions: nil,
                order: 2,
                points: 15,
                content: nil, imageUrl: nil, readAloud: nil, word: nil, hint: nil, audioUrl: nil, sound: nil, exampleWords: nil, soundPosition: nil, words: nil, showInContext: nil, question: nil, options: nil, correctIndex: nil, explanation: nil,
                pairs: [["the", "the"], ["and", "and"], ["is", "is"]],
                matchType: "word-word",
                sentence: nil, answer: nil, wordBank: nil, phrase: nil, checkPronunciation: nil, pattern: nil, onsets: nil
            ),
            LessonActivity(
                id: "sw-a3",
                type: .fillInBlank,
                instructions: "Fill in the missing word",
                spokenInstructions: nil,
                order: 3,
                points: 15,
                content: nil, imageUrl: nil, readAloud: nil, word: nil, hint: nil, audioUrl: nil, sound: nil, exampleWords: nil, soundPosition: nil, words: nil, showInContext: nil, question: nil, options: nil, correctIndex: nil, explanation: nil, pairs: nil, matchType: nil,
                sentence: "I like ___ play.",
                answer: "to",
                wordBank: ["to", "the", "is"],
                phrase: nil, checkPronunciation: nil, pattern: nil, onsets: nil
            ),
            LessonActivity(
                id: "sw-a4",
                type: .reading,
                instructions: "Read the sentence",
                spokenInstructions: "Try reading this sentence out loud",
                order: 4,
                points: 10,
                content: "The cat is on the mat.",
                imageUrl: nil,
                readAloud: true,
                word: nil, hint: nil, audioUrl: nil, sound: nil, exampleWords: nil, soundPosition: nil, words: nil, showInContext: nil, question: nil, options: nil, correctIndex: nil, explanation: nil, pairs: nil, matchType: nil, sentence: nil, answer: nil, wordBank: nil, phrase: nil, checkPronunciation: nil, pattern: nil, onsets: nil
            )
        ],
        durationMinutes: 18,
        prerequisites: nil,
        tags: ["sight-words", "reading", "beginner"],
        thumbnailUrl: nil,
        ageRange: Lesson.AgeRange(min: 4, max: 6),
        createdAt: "2026-01-03",
        updatedAt: "2026-01-15"
    )

    static let spellingPractice = Lesson(
        id: "lesson-4",
        title: "Spelling Practice",
        description: "Practice spelling common three-letter words. Build confidence in spelling through interactive activities.",
        subject: .spelling,
        difficulty: .intermediate,
        objectives: [
            "Spell 10 new words correctly",
            "Sound out words before spelling",
            "Use words in sentences"
        ],
        activities: [
            LessonActivity(
                id: "sp-a1",
                type: .spelling,
                instructions: "Spell the word you hear",
                spokenInstructions: "Listen to the word and spell it",
                order: 1,
                points: 10,
                content: nil, imageUrl: nil, readAloud: nil,
                word: "cat",
                hint: "A furry pet that meows",
                audioUrl: nil, sound: nil, exampleWords: nil, soundPosition: nil, words: nil, showInContext: nil, question: nil, options: nil, correctIndex: nil, explanation: nil, pairs: nil, matchType: nil, sentence: nil, answer: nil, wordBank: nil, phrase: nil, checkPronunciation: nil, pattern: nil, onsets: nil
            ),
            LessonActivity(
                id: "sp-a2",
                type: .spelling,
                instructions: "Spell the word you hear",
                spokenInstructions: "Listen to the word and spell it",
                order: 2,
                points: 10,
                content: nil, imageUrl: nil, readAloud: nil,
                word: "dog",
                hint: "A pet that barks",
                audioUrl: nil, sound: nil, exampleWords: nil, soundPosition: nil, words: nil, showInContext: nil, question: nil, options: nil, correctIndex: nil, explanation: nil, pairs: nil, matchType: nil, sentence: nil, answer: nil, wordBank: nil, phrase: nil, checkPronunciation: nil, pattern: nil, onsets: nil
            ),
            LessonActivity(
                id: "sp-a3",
                type: .quiz,
                instructions: "Which spelling is correct?",
                spokenInstructions: nil,
                order: 3,
                points: 15,
                content: nil, imageUrl: nil, readAloud: nil, word: nil, hint: nil, audioUrl: nil, sound: nil, exampleWords: nil, soundPosition: nil, words: nil, showInContext: nil,
                question: "How do you spell the word for a small red fruit?",
                options: ["aple", "apple", "appel"],
                correctIndex: 1,
                explanation: "Apple is spelled a-p-p-l-e",
                pairs: nil, matchType: nil, sentence: nil, answer: nil, wordBank: nil, phrase: nil, checkPronunciation: nil, pattern: nil, onsets: nil
            )
        ],
        durationMinutes: 20,
        prerequisites: ["lesson-1"],
        tags: ["spelling", "intermediate"],
        thumbnailUrl: nil,
        ageRange: Lesson.AgeRange(min: 5, max: 7),
        createdAt: "2026-01-04",
        updatedAt: "2026-01-15"
    )

    static let readingComprehension = Lesson(
        id: "lesson-5",
        title: "Reading Comprehension",
        description: "Read short stories and answer questions to build understanding. Learn to identify main ideas and details.",
        subject: .comprehension,
        difficulty: .advanced,
        objectives: [
            "Read a complete short story",
            "Answer comprehension questions",
            "Identify main ideas",
            "Recall important details"
        ],
        activities: [
            LessonActivity(
                id: "rc-a1",
                type: .reading,
                instructions: "Read the story carefully",
                spokenInstructions: "Read this story, then we'll talk about it",
                order: 1,
                points: 10,
                content: "Sam had a red ball. He liked to play with it in the park. One day, the ball rolled into the pond. Sam was sad. A nice duck pushed the ball back to Sam. Sam was happy again!",
                imageUrl: nil,
                readAloud: true,
                word: nil, hint: nil, audioUrl: nil, sound: nil, exampleWords: nil, soundPosition: nil, words: nil, showInContext: nil, question: nil, options: nil, correctIndex: nil, explanation: nil, pairs: nil, matchType: nil, sentence: nil, answer: nil, wordBank: nil, phrase: nil, checkPronunciation: nil, pattern: nil, onsets: nil
            ),
            LessonActivity(
                id: "rc-a2",
                type: .quiz,
                instructions: "Answer the question about the story",
                spokenInstructions: nil,
                order: 2,
                points: 15,
                content: nil, imageUrl: nil, readAloud: nil, word: nil, hint: nil, audioUrl: nil, sound: nil, exampleWords: nil, soundPosition: nil, words: nil, showInContext: nil,
                question: "What color was Sam's ball?",
                options: ["Blue", "Red", "Green"],
                correctIndex: 1,
                explanation: "The story said Sam had a RED ball.",
                pairs: nil, matchType: nil, sentence: nil, answer: nil, wordBank: nil, phrase: nil, checkPronunciation: nil, pattern: nil, onsets: nil
            ),
            LessonActivity(
                id: "rc-a3",
                type: .quiz,
                instructions: "Answer the question about the story",
                spokenInstructions: nil,
                order: 3,
                points: 15,
                content: nil, imageUrl: nil, readAloud: nil, word: nil, hint: nil, audioUrl: nil, sound: nil, exampleWords: nil, soundPosition: nil, words: nil, showInContext: nil,
                question: "Who helped Sam get his ball back?",
                options: ["A fish", "A duck", "A frog"],
                correctIndex: 1,
                explanation: "A nice DUCK pushed the ball back to Sam.",
                pairs: nil, matchType: nil, sentence: nil, answer: nil, wordBank: nil, phrase: nil, checkPronunciation: nil, pattern: nil, onsets: nil
            ),
            LessonActivity(
                id: "rc-a4",
                type: .quiz,
                instructions: "What is the main idea?",
                spokenInstructions: nil,
                order: 4,
                points: 20,
                content: nil, imageUrl: nil, readAloud: nil, word: nil, hint: nil, audioUrl: nil, sound: nil, exampleWords: nil, soundPosition: nil, words: nil, showInContext: nil,
                question: "What is the main idea of the story?",
                options: [
                    "Sam lost and found his ball with help",
                    "Ducks live in ponds",
                    "Red balls are the best"
                ],
                correctIndex: 0,
                explanation: "The main idea is that Sam lost his ball and a friendly duck helped him get it back.",
                pairs: nil, matchType: nil, sentence: nil, answer: nil, wordBank: nil, phrase: nil, checkPronunciation: nil, pattern: nil, onsets: nil
            )
        ],
        durationMinutes: 25,
        prerequisites: ["lesson-3"],
        tags: ["comprehension", "reading", "advanced"],
        thumbnailUrl: nil,
        ageRange: Lesson.AgeRange(min: 6, max: 8),
        createdAt: "2026-01-05",
        updatedAt: "2026-01-15"
    )
}

// MARK: - Sample Progress Data

extension SampleLessons {
    /// Sample progress for lesson 1 (in progress)
    static let inProgressSample = LessonProgress(
        lessonId: "lesson-1",
        childId: "child-1",
        status: .inProgress,
        currentActivityIndex: 2,
        activityProgress: [
            ActivityProgress(activityId: "pb-a1", completed: true, score: 10, attempts: 1, timeSpentSeconds: 45, completedAt: "2026-01-15T10:00:00Z"),
            ActivityProgress(activityId: "pb-a2", completed: true, score: 10, attempts: 2, timeSpentSeconds: 60, completedAt: "2026-01-15T10:01:00Z")
        ],
        overallScore: nil,
        totalTimeSeconds: 105,
        startedAt: "2026-01-15T09:58:00Z",
        completedAt: nil
    )

    /// Sample progress for lesson 3 (completed)
    static let completedSample = LessonProgress(
        lessonId: "lesson-3",
        childId: "child-1",
        status: .completed,
        currentActivityIndex: 4,
        activityProgress: [
            ActivityProgress(activityId: "sw-a1", completed: true, score: 10, attempts: 1, timeSpentSeconds: 120, completedAt: "2026-01-14T15:00:00Z"),
            ActivityProgress(activityId: "sw-a2", completed: true, score: 15, attempts: 1, timeSpentSeconds: 90, completedAt: "2026-01-14T15:02:00Z"),
            ActivityProgress(activityId: "sw-a3", completed: true, score: 15, attempts: 2, timeSpentSeconds: 75, completedAt: "2026-01-14T15:04:00Z"),
            ActivityProgress(activityId: "sw-a4", completed: true, score: 10, attempts: 1, timeSpentSeconds: 60, completedAt: "2026-01-14T15:05:00Z")
        ],
        overallScore: 50,
        totalTimeSeconds: 345,
        startedAt: "2026-01-14T14:50:00Z",
        completedAt: "2026-01-14T15:05:00Z"
    )

    /// Get sample progress for a lesson ID
    static func progress(for lessonId: String) -> LessonProgress? {
        switch lessonId {
        case "lesson-1":
            return inProgressSample
        case "lesson-3":
            return completedSample
        default:
            return nil
        }
    }
}
