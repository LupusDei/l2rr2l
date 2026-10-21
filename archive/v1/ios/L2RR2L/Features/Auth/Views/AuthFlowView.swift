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
                                    .font(L2RTheme.Typography.Scaled.system(.callout, weight: .semibold))
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
                                .font(L2RTheme.Typography.Scaled.system(.callout, weight: .semibold))
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
