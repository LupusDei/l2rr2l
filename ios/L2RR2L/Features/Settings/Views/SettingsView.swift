import SwiftUI

struct SettingsView: View {
    @ObservedObject var authService = AuthService.shared
    @ObservedObject var onboardingService = OnboardingService.shared
    @State private var showVoiceSettings = false
    @State private var showLogoutConfirmation = false
    @State private var hapticsEnabled = HapticService.shared.isEnabled

    var body: some View {
        List {
            // Profile Section
            Section {
                profileRow
            }

            // Voice & Sound Section
            Section("Voice & Sound") {
                NavigationLink {
                    VoiceSettingsView()
                } label: {
                    Label("Voice Settings", systemImage: "speaker.wave.2.fill")
                }

                Toggle(isOn: .constant(true)) {
                    Label("Sound Effects", systemImage: "speaker.fill")
                }

                Toggle(isOn: .constant(true)) {
                    Label("Background Music", systemImage: "music.note")
                }

                Toggle(isOn: $hapticsEnabled) {
                    Label("Haptic Feedback", systemImage: "hand.tap.fill")
                }
                .onChange(of: hapticsEnabled) { _, newValue in
                    HapticService.shared.isEnabled = newValue
                    if newValue {
                        HapticService.shared.selection()
                    }
                }
            }

            // Learning Section
            Section("Learning") {
                NavigationLink {
                    Text("Progress")
                        .navigationTitle("My Progress")
                } label: {
                    Label("My Progress", systemImage: "chart.line.uptrend.xyaxis")
                }

                NavigationLink {
                    Text("Achievements")
                        .navigationTitle("Achievements")
                } label: {
                    Label("Achievements", systemImage: "star.fill")
                }
            }

            // Account Section
            Section("Account") {
                NavigationLink {
                    Text("Manage Children")
                        .navigationTitle("Children")
                } label: {
                    Label("Manage Children", systemImage: "person.2.fill")
                }

                NavigationLink {
                    Text("Subscription")
                        .navigationTitle("Subscription")
                } label: {
                    Label("Subscription", systemImage: "creditcard.fill")
                }
            }

            // Support Section
            Section("Support") {
                NavigationLink {
                    Text("Help Center")
                        .navigationTitle("Help")
                } label: {
                    Label("Help Center", systemImage: "questionmark.circle.fill")
                }

                NavigationLink {
                    Text("Contact Us")
                        .navigationTitle("Contact")
                } label: {
                    Label("Contact Us", systemImage: "envelope.fill")
                }
            }

            // Debug Section (for development)
            Section("Developer") {
                Button {
                    onboardingService.resetOnboarding()
                } label: {
                    Label("Reset Onboarding", systemImage: "arrow.counterclockwise")
                        .foregroundStyle(L2RTheme.Status.warning)
                }

                Button {
                    showLogoutConfirmation = true
                } label: {
                    Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                        .foregroundStyle(L2RTheme.Status.error)
                }
            }

            // App Info
            Section {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(L2RTheme.textSecondary)
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .confirmationDialog(
            "Are you sure you want to log out?",
            isPresented: $showLogoutConfirmation,
            titleVisibility: .visible
        ) {
            Button("Log Out", role: .destructive) {
                authService.logout()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var profileRow: some View {
        HStack(spacing: L2RTheme.Spacing.md) {
            // Avatar
            ZStack {
                Circle()
                    .fill(L2RTheme.primary.opacity(0.2))
                    .frame(width: 60, height: 60)

                Text(authService.currentUser?.name.prefix(1).uppercased() ?? "?")
                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.title2, weight: .bold))
                    .foregroundStyle(L2RTheme.primary)
            }

            VStack(alignment: .leading, spacing: L2RTheme.Spacing.xxs) {
                Text(authService.currentUser?.name ?? "Guest")
                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.large, weight: .semibold))
                    .foregroundStyle(L2RTheme.textPrimary)

                Text(authService.currentUser?.email ?? "Not signed in")
                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.small))
                    .foregroundStyle(L2RTheme.textSecondary)
            }

            Spacer()
        }
        .padding(.vertical, L2RTheme.Spacing.xs)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
