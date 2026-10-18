# L2RR2L TestFlight Distribution Guide

Distribute L2RR2L iOS app to beta testers via TestFlight.

## Prerequisites

- Apple Developer Program membership ($99/year)
- Xcode 16+
- Ruby 3.0+ (for fastlane)
- App Store Connect access

## Initial Setup

### 1. Install Fastlane

```bash
# Using Bundler (recommended)
cd ios
bundle install

# Or directly via gem
gem install fastlane
```

### 2. Configure App Store Connect

1. Log in to [App Store Connect](https://appstoreconnect.apple.com)
2. Go to **My Apps** > **+** > **New App**
3. Fill in app details:
   - **Platform:** iOS
   - **Name:** L2RR2L - Learn to Read
   - **Primary Language:** English (U.S.)
   - **Bundle ID:** com.l2rr2l.app
   - **SKU:** com.l2rr2l.app

### 3. Create App Store Connect API Key (Recommended for CI)

1. Go to [Users and Access](https://appstoreconnect.apple.com/access/api) > **Keys**
2. Click **+** to generate a new key
3. Give it a name (e.g., "CI Automation")
4. Select **App Manager** role
5. Download the `.p8` file (you can only download once!)
6. Note the **Key ID** and **Issuer ID**

### 4. Set Up Code Signing with Match

Match syncs code signing identities across your team and CI.

```bash
# Initialize match (creates a private git repo for certificates)
fastlane match init

# Generate App Store certificates and profiles
fastlane match appstore

# Generate development certificates and profiles
fastlane match development
```

**Required secrets for CI:**
- `MATCH_GIT_URL`: URL to your certificates repo
- `MATCH_PASSWORD`: Password to decrypt certificates
- `APPLE_TEAM_ID`: Your Apple Developer Team ID

## Environment Variables

Set these in your CI environment or `.env` file (never commit!):

| Variable | Description | Example |
|----------|-------------|---------|
| `APPLE_TEAM_ID` | Apple Developer Team ID | `ABC123DEF4` |
| `FASTLANE_USER` | Apple ID email | `dev@example.com` |
| `ITC_TEAM_ID` | App Store Connect Team ID | `12345678` |
| `MATCH_GIT_URL` | Certificates repo URL | `git@github.com:org/certs.git` |
| `MATCH_PASSWORD` | Encryption password | (secret) |
| `APP_STORE_CONNECT_API_KEY_ID` | API Key ID | `ABC123DEF4` |
| `APP_STORE_CONNECT_API_KEY_ISSUER_ID` | Issuer ID | `abc-123-def-456` |
| `APP_STORE_CONNECT_API_KEY_KEY` | Base64 encoded .p8 | (secret) |
| `BETA_FEEDBACK_EMAIL` | Email for beta feedback | `beta@example.com` |

## Local Development

### Build and Upload Manually

```bash
cd ios

# Build and upload to TestFlight (internal testers only)
fastlane upload_testflight

# Build and distribute to external testers
fastlane beta groups:"Beta Testers" changelog:"New features and bug fixes"

# Run tests before uploading
fastlane ci_testflight
```

### Increment Version

```bash
# Bump patch version (1.0.0 -> 1.0.1)
fastlane bump_version type:patch

# Bump minor version (1.0.0 -> 1.1.0)
fastlane bump_version type:minor

# Bump major version (1.0.0 -> 2.0.0)
fastlane bump_version type:major
```

## CI/CD with GitHub Actions

The `.github/workflows/ios-testflight.yml` workflow automatically:

1. Runs on push to `main` branch
2. Executes all tests
3. Builds the app
4. Uploads to TestFlight

### Required GitHub Secrets

Add these secrets in **Settings** > **Secrets and variables** > **Actions**:

| Secret | Description |
|--------|-------------|
| `APPLE_TEAM_ID` | Your Apple Developer Team ID |
| `APP_STORE_CONNECT_API_KEY_ID` | App Store Connect API Key ID |
| `APP_STORE_CONNECT_API_KEY_ISSUER_ID` | API Key Issuer ID |
| `APP_STORE_CONNECT_API_KEY_P8` | Base64 encoded .p8 key |
| `MATCH_GIT_URL` | URL to certificates repo |
| `MATCH_PASSWORD` | Certificate encryption password |
| `MATCH_GIT_BASIC_AUTHORIZATION` | Base64 encoded `user:token` |

### Encode the API Key

```bash
# Encode the .p8 file for storage as a secret
base64 -i AuthKey_XXXXXXXXXX.p8 | tr -d '\n'
```

## Testing Groups

### Internal Testers

Internal testers are members of your App Store Connect team. They can:
- Test builds immediately after processing
- No app review required
- Limited to 100 testers

**Add internal testers:**
1. Go to App Store Connect > Users and Access
2. Add team members with appropriate roles
3. They'll appear automatically in TestFlight

### External Testers

External testers are anyone with an email address. They can:
- Test builds after Beta App Review (24-48 hours first time)
- Up to 10,000 testers
- Organized in groups

**Create a testing group:**
1. Go to App Store Connect > TestFlight > External Testing
2. Click **+** to create a group
3. Name the group (e.g., "Beta Testers", "Parent Testers")
4. Add testers by email

**Recommended groups:**
- **Beta Testers** - Early adopters and power users
- **Parent Testers** - Parents testing with their kids
- **QA Team** - Internal QA testing
- **Family** - Friends and family testing

## Beta App Information

Configure in App Store Connect > TestFlight > Test Information:

### Beta App Description
```
L2RR2L - Learn to Read, Read to Learn

A fun, engaging reading app designed for children ages 4-8. Features:
- Interactive spelling games
- Memory matching with words and images
- Progress tracking for parents
- Beautiful, kid-friendly design
```

### What to Test
```
Thank you for testing L2RR2L! Please focus on:

1. Spelling Game - Does word pronunciation work correctly?
2. Memory Game - Are the animations smooth?
3. Progress Tracking - Does it accurately record your child's progress?
4. Accessibility - Can you use VoiceOver effectively?

Report issues using the in-app feedback or reply to this email.
```

### Feedback Email
Set `BETA_FEEDBACK_EMAIL` environment variable or update in App Store Connect.

## Version Numbering Strategy

We follow semantic versioning: `MAJOR.MINOR.PATCH`

- **MAJOR** (1.x.x): Breaking changes, major new features
- **MINOR** (x.1.x): New features, non-breaking changes
- **PATCH** (x.x.1): Bug fixes, minor improvements

**Build numbers** are auto-incremented by CI using the format `YYYYMMDDHHMM`.

## Build Expiration

TestFlight builds expire after **90 days**. To handle this:

1. CI automatically uploads new builds on push to main
2. Monitor build expiration in App Store Connect
3. Encourage testers to update regularly
4. Consider monthly release cadence for stability

## Troubleshooting

### "No provisioning profile" Error

```bash
# Refresh provisioning profiles
fastlane match appstore --force
```

### Build Processing Takes Too Long

- Normal processing: 5-15 minutes
- If > 30 minutes, check App Store Connect status
- Upload may have failed silently

### "Missing Compliance" Warning

Add export compliance to `Info.plist`:
```xml
<key>ITSAppUsesNonExemptEncryption</key>
<false/>
```

### Beta App Review Rejection

Common reasons:
- App crashes on launch
- Login required with no demo account
- Placeholder content

## Quick Reference

```bash
# Run tests
fastlane test

# Upload to TestFlight (internal)
fastlane upload_testflight

# Upload to TestFlight (external)
fastlane beta

# Full CI pipeline
fastlane ci_testflight

# Sync certificates
fastlane sync_appstore_certs
```
