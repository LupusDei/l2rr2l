import SwiftUI

struct AuthFlowView: View {
    @State private var showLogin = true

    var body: some View {
        NavigationStack {
            if showLogin {
                LoginView()
                    .toolbar {
                        ToolbarItem(placement: .bottomBar) {
                            Button {
                                withAnimation {
                                    showLogin = false
                                }
                            } label: {
                                Text("Create Account")
                                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body, weight: .semibold))
                                    .foregroundStyle(L2RTheme.primary)
                            }
                        }
                    }
            } else {
                RegisterView(onLoginTapped: {
                    withAnimation {
                        showLogin = true
                    }
                })
                .toolbar {
                    ToolbarItem(placement: .bottomBar) {
                        Button {
                            withAnimation {
                                showLogin = true
                            }
                        } label: {
                            Text("Already have an account? Log In")
                                .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body, weight: .semibold))
                                .foregroundStyle(L2RTheme.primary)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    AuthFlowView()
}
