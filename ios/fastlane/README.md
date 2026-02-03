# Fastlane Screenshot Automation

This directory contains configuration for automated App Store screenshot capture.

## Prerequisites

1. Install Ruby (comes with macOS)
2. Install fastlane:
   ```bash
   bundle install
   # or
   gem install fastlane
   ```

## Available Device Sizes

App Store requires screenshots for these device sizes:

| Device Type | Size | Example Device |
|-------------|------|----------------|
| iPhone 6.7" | 1290 x 2796 | iPhone 16 Pro Max |
| iPhone 6.5" | 1242 x 2688 | iPhone 11 Pro Max |
| iPhone 5.5" | 1242 x 2208 | iPhone 8 Plus |
| iPad 12.9" | 2048 x 2732 | iPad Pro 12.9" |
| iPad 11" | 1668 x 2388 | iPad Pro 11" |

## Screenshot Locations

Screenshots capture the following screens:

1. **Home Screen** - Main app view with animated background and logo
2. **Games Grid** - Game selection screen with all game cards
3. **Spelling Game Start** - Spelling game introduction screen
4. **Spelling Game Playing** - Active spelling gameplay
5. **Memory Game** - Memory match game screen
6. **Lesson Browser** - Lesson list with progress
7. **Settings** - App settings and profile

## Running Screenshots

### Using Fastlane

```bash
# Capture all screenshots
bundle exec fastlane screenshots

# Full workflow: capture and frame
bundle exec fastlane full_screenshots

# Upload to App Store Connect
bundle exec fastlane upload_screenshots
```

### Manual Capture

```bash
# Run UI tests on specific device
xcodebuild test \
  -scheme L2RR2L \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' \
  -only-testing:L2RR2LUITests/ScreenshotTests

# Screenshots saved to: ./fastlane/screenshots/
```

## Adding Device Frames

Use [fastlane frameit](https://docs.fastlane.tools/actions/frameit/) to add device frames:

```bash
bundle exec fastlane frame_screenshots
```

Configure frames in `./screenshots/Framefile.json`.

## Customizing Screenshots

### Adding Captions

Create `./screenshots/title.strings` for each locale:

```
"01_HomeScreen" = "Learn to Read with Fun!";
"02_GamesGrid" = "Choose Your Game";
"03_SpellingGameStart" = "Spelling Bee Challenge";
```

### Background Colors

Configure in `./screenshots/Framefile.json`:

```json
{
  "default": {
    "background": "#FFFFFF",
    "title": {
      "color": "#333333"
    }
  }
}
```

## Troubleshooting

### Tests not finding elements

Check accessibility labels in views:
```swift
.accessibilityLabel("Start Game")
```

### Animations causing issues

Screenshots wait for animations to settle. Adjust timing in `ScreenshotTests.swift`:
```swift
sleep(2) // Increase wait time
```

### Simulator issues

Reset simulators:
```bash
xcrun simctl erase all
```
