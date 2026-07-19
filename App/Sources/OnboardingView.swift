import SwiftUI

struct OnboardingView: View {
    @Environment(AppModel.self) private var model
    @State private var page = 0
    private let lastPage = 3

    var body: some View {
        ZStack {
            Palette.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    OnboardPanel(icon: "lock.shield.fill", title: "Your privacy, by design",
                                 lines: [
                                    "Nixring blocks spam calls and scam texts 100% on your iPhone.",
                                    "Your contacts and blocklist never leave your phone. No upload. No tracking. No data sold — ever.",
                                 ]).tag(0)

                    OnboardPanel(icon: "phone.down.fill", title: "Turn on call blocking",
                                 lines: ["Enable Nixring in Settings so it can silence known spam callers before your phone even rings."],
                                 buttonTitle: "Open Call Settings",
                                 buttonAction: { model.openCallSettings() }).tag(1)

                    OnboardPanel(icon: "message.badge.filled.fill", title: "Filter junk texts",
                                 lines: [
                                    "Open Settings ▸ Messages ▸ Unknown & Spam and switch on “Nixring” under SMS Filtering.",
                                    "Scam texts from unknown senders then move to a Junk folder automatically.",
                                 ],
                                 buttonTitle: "Open Settings",
                                 buttonAction: openAppSettings).tag(2)

                    OnboardPanel(icon: "checkmark.seal.fill", title: "You're protected",
                                 lines: [
                                    "That's it — Nixring runs quietly in the background.",
                                    "Add your own numbers, keep real callers whitelisted, and see everything you blocked any time.",
                                 ]).tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                VStack(spacing: 10) {
                    PrimaryButton(title: page == lastPage ? "Start protecting me" : "Continue",
                                  systemImage: page == lastPage ? "checkmark" : nil) {
                        if page == lastPage { model.completeOnboarding() }
                        else { withAnimation { page += 1 } }
                    }
                    Button("Skip setup") { model.completeOnboarding() }
                        .font(.footnote).foregroundStyle(Palette.textMuted)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
        }
    }

    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
    }
}

private struct OnboardPanel: View {
    let icon: String
    let title: String
    let lines: [String]
    var buttonTitle: String? = nil
    var buttonAction: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle().fill(Palette.shieldGlow).frame(width: 220, height: 220)
                Image(systemName: icon)
                    .font(.system(size: 74, weight: .semibold))
                    .foregroundStyle(Palette.accentGradient)
            }
            VStack(spacing: 14) {
                Text(title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.textPrimary)
                    .multilineTextAlignment(.center)
                ForEach(lines, id: \.self) { line in
                    Text(line)
                        .font(.body)
                        .foregroundStyle(Palette.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 28)

            if let buttonTitle, let buttonAction {
                Button(action: buttonAction) {
                    Text(buttonTitle).fontWeight(.semibold)
                        .padding(.horizontal, 22).padding(.vertical, 12)
                        .background(Palette.surfaceHi, in: Capsule())
                        .foregroundStyle(Palette.accent)
                }
            }
            Spacer(); Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
