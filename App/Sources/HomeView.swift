import SwiftUI
import NixringCore

struct HomeView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    ShieldRing(active: model.callProtectionActive).padding(.top, 6)
                    statusBanner
                    HStack(spacing: 12) {
                        StatTile(title: "Numbers Shielded", value: "\(model.shieldedNumberCount)", systemImage: "nosign")
                        StatTile(title: "Texts Filtered", value: "\(model.counters.textsFiltered)",
                                 systemImage: "message.badge.filled.fill", tint: Palette.accent2)
                    }
                    protectionCard
                    privacyCard
                    if !model.isPro { upgradeCard }
                }
                .padding(20)
            }
            .nixringBackground()
            .navigationTitle("Nixring")
            .toolbar {
                if model.isPro { ToolbarItem(placement: .topBarTrailing) { ProBadge() } }
            }
        }
    }

    @ViewBuilder private var statusBanner: some View {
        if model.callDirStatus != .enabled {
            Button { model.openCallSettings() } label: {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(Palette.amber)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Call blocking is off")
                            .font(.subheadline.weight(.semibold)).foregroundStyle(Palette.textPrimary)
                        Text("Enable Nixring in Settings to start blocking.")
                            .font(.footnote).foregroundStyle(Palette.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").font(.footnote).foregroundStyle(Palette.textMuted)
                }
                .padding(14)
                .background(Palette.amber.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Palette.amber.opacity(0.3)))
            }
        }
    }

    private var protectionCard: some View {
        Card {
            VStack(spacing: 16) {
                Toggle(isOn: Binding(get: { model.data.settings.protectionEnabled },
                                     set: { model.setProtection($0) })) {
                    Label("Spam call blocking", systemImage: "phone.down.fill")
                }
                Divider().overlay(Palette.stroke)
                Toggle(isOn: Binding(get: { model.data.settings.smsFilterEnabled && model.isPro },
                                     set: { model.setSMSFilter($0) })) {
                    HStack(spacing: 6) {
                        Label("Junk text filter", systemImage: "message.badge.filled.fill")
                        if !model.isPro { ProBadge() }
                    }
                }
                Divider().overlay(Palette.stroke)
                NavigationLink { DiagnosticsView() } label: {
                    HStack {
                        Label("Protection status", systemImage: "waveform.path.ecg")
                        Spacer()
                        Image(systemName: "chevron.right").font(.footnote).foregroundStyle(Palette.textMuted)
                    }
                }
            }
            .tint(Palette.accent)
            .foregroundStyle(Palette.textPrimary)
        }
    }

    private var privacyCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                Label("100% on-device", systemImage: "lock.shield.fill")
                    .font(.headline).foregroundStyle(Palette.accent)
                Text("Your contacts and blocklist never leave your iPhone. Nixring has no account, no server, and collects no data.")
                    .font(.subheadline).foregroundStyle(Palette.textSecondary)
            }
        }
    }

    private var upgradeCard: some View {
        Button { model.showPaywall = true } label: {
            Card {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Unlock Nixring Pro").font(.headline).foregroundStyle(Palette.textPrimary)
                        Spacer(); ProBadge()
                    }
                    Text("Unlimited numbers, junk-text filtering, auto-updating blocklist, prefix rules, whitelist, and full stats.")
                        .font(.subheadline).foregroundStyle(Palette.textSecondary)
                    Text("Try 3 days free →")
                        .font(.subheadline.weight(.semibold)).foregroundStyle(Palette.accent).padding(.top, 2)
                }
            }
        }
    }
}
