import SwiftUI
import NixringCore

struct SettingsView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        NavigationStack {
            List {
                if model.isPro { proActiveSection } else { upgradeSection }

                Section("Blocklist updates") {
                    Toggle("Auto-update blocklist",
                           isOn: Binding(get: { model.data.settings.autoUpdateEnabled },
                                         set: { on in Task { await model.setAutoUpdate(on) } }))
                    Button { Task { await model.updateRemoteList() } } label: {
                        HStack {
                            Text("Update now")
                            Spacer()
                            if model.isUpdatingList { ProgressView() }
                        }
                    }
                    if let updated = model.data.stats.lastUpdated {
                        Text("Last updated \(updated.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption).foregroundStyle(Palette.textMuted)
                    }
                }
                .listRowBackground(Palette.surface)

                Section {
                    Toggle("Aggressive mode: block all links",
                           isOn: Binding(get: { model.data.smsRules.blockAllLinks },
                                         set: { model.setBlockAllLinks($0) }))
                } header: {
                    Text("Text filtering")
                } footer: {
                    Text("When on, any text from an unknown sender that contains a link is filtered as junk.")
                }
                .listRowBackground(Palette.surface)

                Section("Privacy & legal") {
                    Link(destination: AppLinks.privacy) { linkRow("Privacy Policy", "hand.raised.fill") }
                    Link(destination: AppLinks.terms) { linkRow("Terms of Use (EULA)", "doc.text.fill") }
                    Link(destination: AppLinks.support) { linkRow("Support", "questionmark.circle.fill") }
                }
                .listRowBackground(Palette.surface)

                Section {
                    Button("Restore purchases") { Task { await model.restore() } }
                        .foregroundStyle(Palette.accent)
                }
                .listRowBackground(Palette.surface)

                Section {
                    HStack {
                        Text("Version").foregroundStyle(Palette.textPrimary)
                        Spacer()
                        Text(appVersion).foregroundStyle(Palette.textMuted)
                    }
                }
                .listRowBackground(Palette.surface)
            }
            .scrollContentBackground(.hidden)
            .background(Palette.bg.ignoresSafeArea())
            .tint(Palette.accent)
            .navigationTitle("Settings")
        }
    }

    private var proActiveSection: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.seal.fill").foregroundStyle(Palette.accent).font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Nixring Pro active").foregroundStyle(Palette.textPrimary).fontWeight(.semibold)
                    Text("Full protection unlocked. Thank you.").font(.footnote).foregroundStyle(Palette.textSecondary)
                }
            }
        }
        .listRowBackground(Palette.surface)
    }

    private var upgradeSection: some View {
        Section {
            Button { model.showPaywall = true } label: {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles").foregroundStyle(Palette.accent).font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) { Text("Unlock Nixring Pro").foregroundStyle(Palette.textPrimary).fontWeight(.semibold); ProBadge() }
                        Text("3-day free trial. Calls + texts, on-device.").font(.footnote).foregroundStyle(Palette.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").font(.footnote).foregroundStyle(Palette.textMuted)
                }
            }
        }
        .listRowBackground(Palette.surface)
    }

    private func linkRow(_ title: String, _ icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundStyle(Palette.accent).frame(width: 24)
            Text(title).foregroundStyle(Palette.textPrimary)
            Spacer()
            Image(systemName: "arrow.up.right").font(.caption).foregroundStyle(Palette.textMuted)
        }
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }
}
