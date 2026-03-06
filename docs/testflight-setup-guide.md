# TestFlight Pipeline Setup Guide

This guide walks you through activating the automated TestFlight CI/CD pipeline for L2RR2L. Once complete, every push to `main` that touches `ios/**` will automatically build, sign, and upload to TestFlight.

**Bundle ID:** `com.jmm.l2rr2l`
**Workflow:** `.github/workflows/ios-testflight.yml`
**Pipeline:** Test -> Build & Sign -> Upload to TestFlight -> Notify + Tag

---

## Prerequisites

Before starting, make sure you have:

- [ ] An [Apple Developer Program](https://developer.apple.com/programs/) membership ($99/year)
- [ ] Access to [App Store Connect](https://appstoreconnect.apple.com)
- [ ] Admin access to the [LupusDei/l2rr2l](https://github.com/LupusDei/l2rr2l) GitHub repo
- [ ] Ruby installed locally (`ruby -v` -- the workflow uses 3.2)
- [ ] Fastlane installed locally (`cd ios && bundle install`)

---

## Step 1: Register the App ID

If you haven't already registered the bundle ID with Apple:

1. Go to [Apple Developer > Identifiers](https://developer.apple.com/account/resources/identifiers/list)
2. Click **+** to register a new identifier
3. Select **App IDs** -> **App**
4. Fill in:
   - **Description:** `L2RR2L`
   - **Bundle ID:** Explicit -> `com.jmm.l2rr2l`
5. Enable any capabilities your app needs (Push Notifications, etc.)
6. Click **Register**

---

## Step 2: Create the App in App Store Connect

If the app doesn't exist yet in App Store Connect:

1. Go to [App Store Connect > My Apps](https://appstoreconnect.apple.com/apps)
2. Click **+** -> **New App**
3. Fill in:
   - **Platform:** iOS
   - **Name:** L2RR2L (or your preferred display name)
   - **Primary Language:** English (U.S.)
   - **Bundle ID:** Select `com.jmm.l2rr2l` from the dropdown
   - **SKU:** `com.jmm.l2rr2l` (or any unique string)
   - **Access:** Full Access
4. Click **Create**

---

## Step 3: Find Your Apple Team ID

1. Go to [Apple Developer > Membership](https://developer.apple.com/account#MembershipDetailsCard)
2. Find your **Team ID** -- a 10-character alphanumeric string (e.g., `ABCD1234EF`)
3. Save this value -- you'll need it as `APPLE_TEAM_ID`

---

## Step 4: Create an App Store Connect API Key

This key allows the CI pipeline to upload builds without your Apple ID password.

1. Go to [App Store Connect > Users and Access > Integrations > App Store Connect API](https://appstoreconnect.apple.com/access/integrations/api)
2. If this is your first key, click **Request Access** first
3. Click **+** to generate a new key
4. Fill in:
   - **Name:** `L2RR2L CI`
   - **Access:** `App Manager` (minimum required for TestFlight uploads)
5. Click **Generate**
6. **IMPORTANT:** Download the `.p8` file immediately -- you can only download it **once**
7. Note these values from the keys list:
   - **Key ID** -- shown in the table (e.g., `ABC123DEFG`)
   - **Issuer ID** -- shown at the top of the page (a UUID like `12345678-abcd-...`)

### Base64-encode the .p8 key

The GitHub workflow expects the key as a base64-encoded string:

```bash
# macOS
base64 -i ~/Downloads/AuthKey_ABC123DEFG.p8 | tr -d '\n' | pbcopy
# The encoded string is now on your clipboard

# Linux
base64 -w 0 ~/Downloads/AuthKey_ABC123DEFG.p8
# Copy the output
```

Save this encoded string -- you'll need it as `APP_STORE_CONNECT_API_KEY_P8`.

---

## Step 5: Set Up Match (Code Signing)

Match syncs your code signing certificates and provisioning profiles via a private git repo. This is how CI gets access to sign your app.

### 5a. Create a Private Certificate Repository

1. Go to [GitHub > New Repository](https://github.com/new)
2. Fill in:
   - **Name:** `l2rr2l-certificates`
   - **Visibility:** **Private** (this will contain encrypted certificates)
   - **Initialize:** Leave empty (no README, no .gitignore)
3. Click **Create repository**

### 5b. Generate a GitHub Personal Access Token

CI needs this token to clone the private certificate repo.

1. Go to [GitHub > Settings > Developer Settings > Personal Access Tokens > Tokens (classic)](https://github.com/settings/tokens)
2. Click **Generate new token (classic)**
3. Fill in:
   - **Note:** `L2RR2L Match CI`
   - **Expiration:** Choose based on your preference (or no expiration)
   - **Scopes:** Check `repo` (full control of private repositories)
4. Click **Generate token**
5. **Copy the token immediately** -- it won't be shown again

### 5c. Create the Base64 Authorization String

```bash
# Replace with your actual GitHub username and token
echo -n 'your-github-username:ghp_xxxxxxxxxxxxxxxxxxxx' | base64 | tr -d '\n' | pbcopy
# The encoded string is now on your clipboard
```

Save this -- you'll need it as `MATCH_GIT_BASIC_AUTHORIZATION`.

### 5d. Initialize Match Locally

Run Match once locally to generate certificates and push them to the repo:

```bash
cd ios

# Set required environment variables
export MATCH_GIT_URL="git@github.com:LupusDei/l2rr2l-certificates.git"
export APPLE_TEAM_ID="YOUR_TEAM_ID"

# Run Match -- this will:
# 1. Create a new distribution certificate (if needed)
# 2. Create an App Store provisioning profile
# 3. Encrypt and push both to the certificate repo
bundle exec fastlane match appstore
```

During this process Match will:
- Ask you to log in to the Apple Developer Portal
- Ask you to create an **encryption password** -- **save this password**, you'll need it as `MATCH_PASSWORD`
- Generate a distribution certificate and provisioning profile
- Push the encrypted files to your certificate repo

**Verify it worked:**
```bash
# Check the certificate repo has content
git clone git@github.com:LupusDei/l2rr2l-certificates.git /tmp/cert-check
ls /tmp/cert-check/
# You should see: certs/ and profiles/ directories
rm -rf /tmp/cert-check
```

---

## Step 6: Add GitHub Repository Secrets

Now add all the values you've collected as GitHub repository secrets.

1. Go to [LupusDei/l2rr2l > Settings > Secrets and variables > Actions](https://github.com/LupusDei/l2rr2l/settings/secrets/actions)
2. Click **New repository secret** for each:

| Secret Name | Value | Source |
|-------------|-------|--------|
| `APPLE_TEAM_ID` | Your 10-char Team ID (e.g., `ABCD1234EF`) | Step 3 |
| `APP_STORE_CONNECT_API_KEY_ID` | API Key ID (e.g., `ABC123DEFG`) | Step 4 |
| `APP_STORE_CONNECT_API_KEY_ISSUER_ID` | Issuer ID UUID | Step 4 |
| `APP_STORE_CONNECT_API_KEY_P8` | Base64-encoded .p8 file contents | Step 4 |
| `MATCH_GIT_URL` | `https://github.com/LupusDei/l2rr2l-certificates.git` | Step 5a |
| `MATCH_PASSWORD` | The encryption password you created | Step 5d |
| `MATCH_GIT_BASIC_AUTHORIZATION` | Base64-encoded `username:token` | Step 5c |

**Double-check:** You should have exactly 7 secrets configured.

---

## Step 7: Trigger Your First Build

### Option A: Manual Trigger (Recommended for First Build)

1. Go to [Actions > iOS TestFlight](https://github.com/LupusDei/l2rr2l/actions/workflows/ios-testflight.yml)
2. Click **Run workflow**
3. Fill in:
   - **Changelog:** `First TestFlight build`
   - **Distribute to external testers:** Leave unchecked
4. Click **Run workflow**

### Option B: Automatic Trigger

Push any change to a file under `ios/` on the `main` branch:

```bash
# A trivial change to trigger the pipeline
echo "" >> ios/L2RR2L/Info.plist
git add ios/L2RR2L/Info.plist
git commit -m "Trigger first TestFlight build"
git push
```

### Monitor the Build

The workflow runs 3 jobs in sequence:

1. **Run Tests** (~5-10 min) -- Builds and runs unit tests on iOS Simulator
2. **Build and Upload to TestFlight** (~10-20 min) -- Signs with Match, archives with gym, uploads with pilot
3. **Notify on Completion** -- Writes build report to GitHub Actions summary, creates `testflight/build-N` git tag

Watch progress at: [Actions tab](https://github.com/LupusDei/l2rr2l/actions)

---

## Step 8: Verify in TestFlight

After a successful build:

1. Go to [App Store Connect > My Apps > L2RR2L > TestFlight](https://appstoreconnect.apple.com)
2. The build should appear under **iOS Builds**
3. Processing takes **5-30 minutes** after upload
4. Once processed, the build is available to internal testers automatically

### Verify the Git Tag

```bash
git fetch --tags
git tag -l 'testflight/*'
# Should show: testflight/build-1 (or whatever the run number was)
```

---

## Step 9: Set Up External Testers (Optional)

To distribute builds to external testers (the `beta` lane):

1. In App Store Connect > TestFlight > **External Testing**
2. Click **+** next to "External Groups"
3. Create a group named exactly: **`External Testers`** (this name is referenced in the Fastfile)
4. Add testers by email
5. External builds require **Beta App Review** by Apple (first build only, usually < 24 hours)

To trigger an external build:
- Manual: Run workflow with **Distribute to external testers** checked
- The workflow will use the `beta` lane instead of `upload_testflight`

---

## Troubleshooting

### Build fails at "Run Tests"
- Check that the Xcode scheme `L2RR2L` exists and is shared
- Verify tests pass locally: `cd ios && xcodebuild test -scheme L2RR2L -destination 'platform=iOS Simulator,name=iPhone 16'`

### Build fails at code signing (Match)
- **"Could not find a matching profile"** -- Run `bundle exec fastlane match appstore` locally to regenerate
- **"Authentication failed"** -- Check `MATCH_GIT_BASIC_AUTHORIZATION` is correctly base64-encoded `username:token`
- **"Could not decrypt"** -- Verify `MATCH_PASSWORD` matches the password used during `match appstore` init

### Build fails at upload (Pilot)
- **"Invalid API key"** -- Verify all three API key secrets (ID, Issuer ID, P8)
- **"No suitable application records"** -- Make sure the app exists in App Store Connect with bundle ID `com.jmm.l2rr2l`
- **"The bundle identifier is not available"** -- The App ID may not be registered; complete Step 1

### Build succeeds but no TestFlight build appears
- Processing can take up to 30 minutes
- Check App Store Connect > TestFlight > iOS Builds for processing status
- Check your email for any compliance/export issues from Apple

### Match password lost
If you lose the Match encryption password:
```bash
# Nuke existing certs and start fresh
bundle exec fastlane match nuke distribution
bundle exec fastlane match appstore
# Use the new password as MATCH_PASSWORD in GitHub secrets
```

---

## Quick Reference

### Secrets Checklist

```
[ ] APPLE_TEAM_ID
[ ] APP_STORE_CONNECT_API_KEY_ID
[ ] APP_STORE_CONNECT_API_KEY_ISSUER_ID
[ ] APP_STORE_CONNECT_API_KEY_P8
[ ] MATCH_GIT_URL
[ ] MATCH_PASSWORD
[ ] MATCH_GIT_BASIC_AUTHORIZATION
```

### Pipeline Flow

```
Push to main (ios/**)
        |
   Run Tests (xcodebuild test, iPhone 16 Simulator)
        |
   Build & Sign (Match + gym)
        |
   Upload to TestFlight (pilot)
        |
   Notify (GitHub Summary + testflight/build-N tag)
```

### Useful Local Commands

```bash
cd ios

# Run tests locally
xcodebuild test -scheme L2RR2L -destination 'platform=iOS Simulator,name=iPhone 16'

# Re-sync certificates
bundle exec fastlane sync_appstore_certs

# Build and upload manually
bundle exec fastlane upload_testflight changelog:"Manual build"

# Build for external testers
bundle exec fastlane beta changelog:"Beta release"
```
