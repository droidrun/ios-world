import SwiftUI

private enum SplitPayTab: Hashable {
    case home
    case cards
    case crypto
    case me
}

struct RootTabView: View {
    @EnvironmentObject private var store: SplitPayStore
    @State private var selectedTab: SplitPayTab = .home
    @State private var showPayRequest = false

    var body: some View {
        ZStack(alignment: .bottom) {
            SplitPayTheme.background.ignoresSafeArea()

            Group {
                switch selectedTab {
                case .home:
                    FeedView()
                case .cards:
                    WalletView()
                case .crypto:
                    SettingsView()
                case .me:
                    RequestsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            MockSplitPayTabBar(
                selectedTab: $selectedTab,
                payRequestAction: { showPayRequest = true }
            )
        }
        .preferredColorScheme(.light)
        .fullScreenCover(isPresented: $showPayRequest) {
            PayRequestHomeView()
                .environmentObject(store)
        }
    }
}

private struct MockSplitPayTabBar: View {
    @EnvironmentObject private var store: SplitPayStore
    @Binding var selectedTab: SplitPayTab
    let payRequestAction: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: -6)
                .frame(height: 92)

            HStack(alignment: .bottom, spacing: 0) {
                tabButton(title: "Home", systemImage: "house.fill", tab: .home)
                tabButton(title: "Cards", systemImage: "creditcard.fill", tab: .cards)

                VStack(spacing: 8) {
                    Button(action: payRequestAction) {
                        ZStack {
                            Circle()
                                .fill(SplitPayTheme.accent)
                                .frame(width: 72, height: 72)
                                .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 6)

                            Circle()
                                .stroke(Color.white.opacity(0.95), lineWidth: 8)
                                .frame(width: 80, height: 80)

                            Text("V")
                                .font(.system(size: 34, weight: .black, design: .rounded))
                                .italic()
                                .foregroundStyle(Color.white)
                        }
                    }
                    .buttonStyle(.plain)
                    .offset(y: -20)
                    .accessibilityIdentifier("pay_or_request_button")

                    Text("Pay/Request")
                        .font(SplitPayTheme.bodyFont(size: 12, weight: .semibold))
                        .foregroundStyle(SplitPayTheme.accent)
                        .offset(y: -20)
                }
                .frame(maxWidth: .infinity)

                tabButton(title: "Crypto", systemImage: "bitcoinsign.circle.fill", tab: .crypto)
                profileTab
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 6)
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 4)
    }

    private func tabButton(title: String, systemImage: String, tab: SplitPayTab) -> some View {
        Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 26, weight: .semibold))
                Text(title)
                    .font(SplitPayTheme.bodyFont(size: 12, weight: .semibold))
            }
            .foregroundStyle(selectedTab == tab ? SplitPayTheme.accentDark : SplitPayTheme.accent)
            .frame(maxWidth: .infinity)
            .padding(.top, 14)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("splitpay_tab_\(title.lowercased())")
    }

    private var profileTab: some View {
        Button {
            selectedTab = .me
        } label: {
            VStack(spacing: 5) {
                SplitPayAvatarView(user: store.you, size: 30)
                Text("Me")
                    .font(SplitPayTheme.bodyFont(size: 12, weight: .semibold))
            }
            .foregroundStyle(selectedTab == .me ? SplitPayTheme.accentDark : SplitPayTheme.accent)
            .frame(maxWidth: .infinity)
            .padding(.top, 12)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("splitpay_tab_me")
    }
}

#Preview {
    RootTabView()
        .environmentObject(SplitPayStore())
}
