import SwiftUI
import CallKit

struct DiagnosticsView: View {
    @Environment(AppModel.self) private var model
    @State private var reloading = false

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                DiagCard(title: "Spam call blocking",
                         detail: callDetail,
                         ok: model.callDirStatus == .enabled,
                         actionTitle: model.callDirStatus == .enabled ? nil : "Open Settings",
                         action: { model.openCallSettings() })

                DiagCard(title: "Junk text filter",
                         detail: smsDetail,
                         ok: model.isPro && model.data.settings.smsFilterEnabled,
                         actionTitle: nil, action: nil)

                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How SMS filtering is verified")
                            .font(.subheadline.weight(.semibold)).foregroundStyle(Palette.textPrimary)
                        Text("iOS doesn't report SMS-filter status to apps. Enable it under Settings ▸ Messages ▸ Unknown & Spam ▸ SMS Filtering ▸ Nixring. Real blocking is only visible on a physical iPhone.")
                            .font(.footnote).foregroundStyle(Palette.textSecondary)
                    }
                }

                PrimaryButton(title: reloading ? "Reloading…" : "Reload protection", systemImage: "arrow.clockwise") {
                    Task {
                        reloading = true
                        try? await ProtectionController.reload()
                        await model.refreshStatus()
                        reloading = false
                    }
                }
            }
            .padding(20)
        }
        .nixringBackground()
        .navigationTitle("Protection status")
        .navigationBarTitleDisplayMode(.inline)
        .task { await model.refreshStatus() }
    }

    private var callDetail: String {
        switch model.callDirStatus {
        case .enabled:
            return model.data.settings.protectionEnabled
                ? "Active — shielding \(model.shieldedNumberCount) known spam numbers."
                : "Enabled in Settings, but paused in the app."
        case .disabled:
            return "Turned off in Settings. Tap below to enable Nixring."
        case .unknown:
            return "Status unknown. Open Settings to enable Nixring."
        @unknown default:
            return "Unknown status."
        }
    }

    private var smsDetail: String {
        if !model.isPro { return "Junk text filtering is a Pro feature." }
        return model.data.settings.smsFilterEnabled
            ? "On. Make sure Nixring is enabled under Settings ▸ Messages ▸ Unknown & Spam."
            : "Turned off in the app."
    }
}

private struct DiagCard: View {
    let title: String
    let detail: String
    let ok: Bool
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: ok ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .foregroundStyle(ok ? Palette.success : Palette.amber)
                    Text(title).font(.headline).foregroundStyle(Palette.textPrimary)
                    Spacer()
                }
                Text(detail).font(.subheadline).foregroundStyle(Palette.textSecondary)
                if let actionTitle, let action {
                    Button(actionTitle, action: action)
                        .font(.subheadline.weight(.semibold)).foregroundStyle(Palette.accent).padding(.top, 2)
                }
            }
        }
    }
}
