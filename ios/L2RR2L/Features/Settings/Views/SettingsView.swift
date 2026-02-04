import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @ObservedObject var authService = AuthService.shared
    @ObservedObject var childProfileService = ChildProfileService.shared
    @Environment(\.dismiss) private var dismiss

    @State private var showVoiceSelector = false
    @State private var showLogoutConfirmation = false
    @State private var showDeleteAccountConfirmation = false
    @State private var showProfileSwitcher = false

    var body: some View {
        List {
            // Voice Section
            Section("Voice") {
                voiceRow
                voiceSettingsLink
            }

            // App Section
            Section("App") {
                soundEffectsToggle
                hapticsToggle
                notificationsLink
            }

            // Profile Section
            Section("Profile") {
                activeProfileRow
                switchProfileLink
                editProfileLink
            }

            // Account Section
            Section("Account") {
                editAccountLink
                changePasswordLink
                logoutButton
                deleteAccountButton
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadData()
        }
        .sheet(isPresented: $showVoiceSelector) {
            VoiceSelectorView(
                selectedVoiceId: Binding(
                    get: { viewModel.selectedVoice?.id ?? "" },
                    set: { newId in
                        if let voice = viewModel.voices.first(where: { $0.id == newId }) {
                            viewModel.selectVoice(voice)
                        }
                    }
                ),
                voices: viewModel.voices,
                isLoading: viewModel.isLoadingVoices
            )
        }
        .sheet(isPresented: $showProfileSwitcher) {
            ProfileSwitcherSheet(
                children: childProfileService.children,
                activeChild: childProfileService.activeChild,
                onSelect: { child in
                    childProfileService.setActiveChild(child)
                    showProfileSwitcher = false
                }
            )
        }
        .confirmationDialog(
            "Are you sure you want to log out?",
            isPresented: $showLogoutConfirmation,
            titleVisibility: .visible
        ) {
            Button("Log Out", role: .destructive) {
                Task {
                    await authService.logout()
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog(
            "Are you sure you want to delete your account? This action cannot be undone.",
            isPresented: $showDeleteAccountConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Account", role: .destructive) {
                // TODO: Implement account deletion
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Voice Section

    private var voiceRow: some View {
        Button {
            showVoiceSelector = true
        } label: {
            HStack {
                Label("Voice", systemImage: "waveform")
                Spacer()
                if viewModel.isLoadingVoices {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Text(viewModel.selectedVoice?.name ?? "Select")
                        .foregroundStyle(L2RTheme.textSecondary)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(L2RTheme.textSecondary)
            }
        }
        .foregroundStyle(L2RTheme.textPrimary)
    }

    private var voiceSettingsLink: some View {
        NavigationLink {
            VoiceSettingsView()
        } label: {
            Label("Voice Settings", systemImage: "slider.horizontal.3")
        }
    }

    // MARK: - App Section

    private var soundEffectsToggle: some View {
        Toggle(isOn: $viewModel.soundEffectsEnabled) {
            Label("Sound Effects", systemImage: "speaker.wave.2.fill")
        }
        .tint(L2RTheme.primary)
    }

    private var hapticsToggle: some View {
        Toggle(isOn: $viewModel.hapticsEnabled) {
            Label("Haptics", systemImage: "hand.tap.fill")
        }
        .tint(L2RTheme.primary)
    }

    private var notificationsLink: some View {
        NavigationLink {
            Text("Notifications")
                .navigationTitle("Notifications")
        } label: {
            Label("Notifications", systemImage: "bell.fill")
        }
    }

    // MARK: - Profile Section

    private var activeProfileRow: some View {
        HStack(spacing: L2RTheme.Spacing.md) {
            // Avatar
            childAvatar(for: childProfileService.activeChild)

            // Name
            VStack(alignment: .leading, spacing: L2RTheme.Spacing.xxxs) {
                Text(childProfileService.activeChild?.name ?? "No Profile")
                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body, weight: .medium))
                    .foregroundStyle(L2RTheme.textPrimary)

                if let age = childProfileService.activeChild?.age {
                    Text("\(age) years old")
                        .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.small))
                        .foregroundStyle(L2RTheme.textSecondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, L2RTheme.Spacing.xxs)
    }

    private var switchProfileLink: some View {
        Button {
            showProfileSwitcher = true
        } label: {
            HStack {
                Label("Switch Profile", systemImage: "person.2.fill")
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(L2RTheme.textSecondary)
            }
        }
        .foregroundStyle(L2RTheme.textPrimary)
    }

    private var editProfileLink: some View {
        NavigationLink {
            Text("Edit Profile")
                .navigationTitle("Edit Profile")
        } label: {
            Label("Edit Profile", systemImage: "pencil")
        }
    }

    // MARK: - Account Section

    private var editAccountLink: some View {
        NavigationLink {
            Text("Edit Account")
                .navigationTitle("Edit Account")
        } label: {
            Label("Edit Account", systemImage: "person.crop.circle")
        }
    }

    private var changePasswordLink: some View {
        NavigationLink {
            Text("Change Password")
                .navigationTitle("Change Password")
        } label: {
            Label("Change Password", systemImage: "lock.fill")
        }
    }

    private var logoutButton: some View {
        Button {
            showLogoutConfirmation = true
        } label: {
            Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                .foregroundStyle(L2RTheme.Status.warning)
        }
    }

    private var deleteAccountButton: some View {
        Button {
            showDeleteAccountConfirmation = true
        } label: {
            Label("Delete Account", systemImage: "trash.fill")
                .foregroundStyle(L2RTheme.Status.error)
        }
    }

    // MARK: - Helper Views

    private func childAvatar(for child: Child?) -> some View {
        ZStack {
            Circle()
                .fill(L2RTheme.primary.opacity(0.2))
                .frame(width: 44, height: 44)

            if let avatar = child?.avatar {
                Text(avatar)
                    .font(.system(size: 24))
            } else {
                Text(child?.name.prefix(1).uppercased() ?? "?")
                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.large, weight: .bold))
                    .foregroundStyle(L2RTheme.primary)
            }
        }
    }
}

// MARK: - Profile Switcher Sheet

private struct ProfileSwitcherSheet: View {
    let children: [Child]
    let activeChild: Child?
    let onSelect: (Child) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(children) { child in
                Button {
                    onSelect(child)
                } label: {
                    HStack(spacing: L2RTheme.Spacing.md) {
                        // Avatar
                        ZStack {
                            Circle()
                                .fill(L2RTheme.primary.opacity(0.2))
                                .frame(width: 44, height: 44)

                            if let avatar = child.avatar {
                                Text(avatar)
                                    .font(.system(size: 24))
                            } else {
                                Text(child.name.prefix(1).uppercased())
                                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.large, weight: .bold))
                                    .foregroundStyle(L2RTheme.primary)
                            }
                        }

                        // Info
                        VStack(alignment: .leading, spacing: L2RTheme.Spacing.xxxs) {
                            Text(child.name)
                                .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body, weight: .medium))
                                .foregroundStyle(L2RTheme.textPrimary)

                            if let age = child.age {
                                Text("\(age) years old")
                                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.small))
                                    .foregroundStyle(L2RTheme.textSecondary)
                            }
                        }

                        Spacer()

                        // Checkmark for active
                        if child.id == activeChild?.id {
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(L2RTheme.primary)
                        }
                    }
                }
            }
            .navigationTitle("Switch Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body, weight: .semibold))
                    .foregroundStyle(L2RTheme.primary)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
