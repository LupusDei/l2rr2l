import SwiftUI

/// Centralized animation constants for the entire app.
/// All juice animations reference these values for consistency.
/// Tune values here to adjust the feel globally.
///
/// Note: Basic duration & animation presets live in `L2RTheme.Animation`.
/// This file extends those with detailed per-interaction parameters.
enum AnimationConfig {

    // MARK: - Tap Animations

    /// Quick squash-and-stretch on any tappable element.
    enum Tap {
        static let squashScale: CGSize = CGSize(width: 1.1, height: 0.9)
        static let spring = Spring(response: 0.3, dampingRatio: 0.5)
        static let duration: TimeInterval = 0.15
    }

    // MARK: - Button Press

    /// Subtle press-down feel for buttons.
    enum ButtonPress {
        static let pressScale: CGFloat = 0.95
        static let spring = Spring(response: 0.2, dampingRatio: 0.6)
    }

    // MARK: - Drag

    /// Visual feedback while a tile or piece is being dragged.
    enum Drag {
        static let activeScale: CGFloat = 1.2
        static let shadowRadius: CGFloat = 8
        static let shadowOpacity: Double = 0.3
        static let particleTrailInterval: TimeInterval = 0.05
        static let particleCount: Int = 3
    }

    // MARK: - Correct Answer

    /// Celebration when the child answers correctly.
    enum Correct {
        static let bounceScale: CGFloat = 1.3
        static let spring = Spring(response: 0.4, dampingRatio: 0.4)
        static let starBurstCount: Int = 12
        static let starBurstDuration: TimeInterval = 0.8
        static let glowColor = L2RTheme.Logo.green.opacity(0.3)
        static let glowPulseDuration: TimeInterval = 0.6
    }

    // MARK: - Incorrect Answer

    /// Gentle nudge when the answer is wrong — warm tones only, never harsh red.
    enum Incorrect {
        static let wobbleAngle: Angle = .degrees(5)
        static let wobbleCount: Int = 3
        static let wobbleDuration: TimeInterval = 0.5
        static let tintColor = L2RTheme.Logo.orange.opacity(0.2)
    }

    // MARK: - Snap Into Place

    /// Satisfying lock-in when a piece reaches its target.
    enum Snap {
        static let bounceScale: CGFloat = 1.1
        static let spring = Spring(response: 0.25, dampingRatio: 0.5)
        static let pulseRingMaxScale: CGFloat = 2.0
        static let pulseRingDuration: TimeInterval = 0.4
        static let pulseRingColor = L2RTheme.Logo.blue.opacity(0.3)
    }

    // MARK: - Card Flip

    /// 3D flip with slight overshoot for memory/matching cards.
    enum Flip {
        static let duration: TimeInterval = 0.5
        static let overshootAngle: Angle = .degrees(195)
        static let settleAngle: Angle = .degrees(180)
        static let sparkleCount: Int = 8
        static let sparkleDuration: TimeInterval = 0.6
    }

    // MARK: - Mascot

    /// Mascot character states — idle, celebrate, encourage, hint, dance, proud.
    enum Mascot {
        static let idleFloatAmplitude: CGFloat = 3
        static let idleFloatDuration: TimeInterval = 2.0
        static let celebrateJumpHeight: CGFloat = 20
        static let celebrateScale: CGFloat = 1.2
        static let celebrateDuration: TimeInterval = 2.0
        static let encourageDuration: TimeInterval = 1.5
        static let hintWaveDuration: TimeInterval = 1.0
        static let danceDuration: TimeInterval = 3.0
        static let proudScale: CGFloat = 1.3
        static let proudDuration: TimeInterval = 2.5
    }

    // MARK: - Speech Bubble

    /// Pop-in speech bubble shown alongside the mascot.
    enum SpeechBubble {
        static let spring = Spring(response: 0.3, dampingRatio: 0.6)
        static let displayDuration: TimeInterval = 2.5
        static let maxWidth: CGFloat = 150
    }

    // MARK: - Particles

    /// Burst and trail particle effects (confetti, sparkles, etc.).
    enum Particles {
        static let maxCount: Int = 25
        static let defaultLifetime: TimeInterval = 0.8
        static let gravity: CGFloat = 200
        static let minVelocity: CGFloat = 100
        static let maxVelocity: CGFloat = 300
    }

    // MARK: - Round Transitions

    /// Between-round transition timing (exit → counter bump → enter).
    enum RoundTransition {
        static let exitDuration: TimeInterval = 0.3
        static let counterBumpScale: CGFloat = 1.5
        static let counterBumpDuration: TimeInterval = 0.6
        static let enterDuration: TimeInterval = 0.3
        static let totalDuration: TimeInterval = 1.2
    }

    // MARK: - Rewards

    /// End-of-lesson reward animations (stickers, stars).
    enum Reward {
        static let stickerFlyDuration: TimeInterval = 1.0
        static let stickerBounceScale: CGFloat = 1.4
        static let newStickerTextDuration: TimeInterval = 2.0
        /// Delay between each star filling in.
        static let starFillDelay: TimeInterval = 0.3
    }

    // MARK: - Inactivity

    /// Timers for mascot reactions when the child stops interacting.
    enum Inactivity {
        static let waveTrigger: TimeInterval = 8.0
        static let hintTrigger: TimeInterval = 15.0
        static let resetOnInteraction: Bool = true
    }
}

// MARK: - Theme Color Integration

extension AnimationConfig.Particles {
    /// Rainbow palette pulled from the app's logo colors.
    static var themeColors: [Color] {
        L2RTheme.Logo.all
    }
}
