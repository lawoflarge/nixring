import SwiftUI

/// Big animated status ring on the home screen.
struct ShieldRing: View {
    let active: Bool
    var body: some View {
        ZStack {
            if active {
                Circle().fill(Palette.shieldGlow).frame(width: 320, height: 320)
            }
            Circle().stroke(Palette.stroke, lineWidth: 14).frame(width: 196, height: 196)
            Circle()
                .trim(from: 0, to: active ? 1 : 0.0001)
                .stroke(active ? AnyShapeStyle(Palette.accentGradient) : AnyShapeStyle(Palette.textMuted),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 196, height: 196)
                .animation(.easeInOut(duration: 0.7), value: active)
            VStack(spacing: 8) {
                Image(systemName: active ? "checkmark.shield.fill" : "shield.slash.fill")
                    .font(.system(size: 46, weight: .bold))
                    .foregroundStyle(active ? Palette.accent : Palette.textMuted)
                Text(active ? "Protected" : "Paused")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Palette.textPrimary)
            }
        }
    }
}

struct StatTile: View {
    let title: String
    let value: String
    let systemImage: String
    var tint: Color = Palette.accent

    var body: some View {
        Card(padding: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(tint)
                Text(value)
                    .font(.system(size: 27, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.textPrimary)
                    .contentTransition(.numericText())
                Text(title)
                    .font(.footnote)
                    .foregroundStyle(Palette.textSecondary)
            }
        }
    }
}

struct ProBadge: View {
    var body: some View {
        Text("PRO")
            .font(.system(size: 11, weight: .heavy))
            .padding(.horizontal, 7).padding(.vertical, 3)
            .background(Palette.accentGradient, in: Capsule())
            .foregroundStyle(Palette.bg)
    }
}

struct SectionLabel: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text.uppercased())
            .font(.caption.weight(.semibold))
            .foregroundStyle(Palette.textMuted)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct PrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title).fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                enabled ? AnyShapeStyle(Palette.accentGradient) : AnyShapeStyle(Palette.surfaceHi),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .foregroundStyle(enabled ? Palette.bg : Palette.textMuted)
        }
        .disabled(!enabled)
    }
}

/// A row that opens the paywall, used to gate Pro features.
struct ProUpsellRow: View {
    let title: String
    let subtitle: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: "lock.fill").foregroundStyle(Palette.accent)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) { Text(title).foregroundStyle(Palette.textPrimary); ProBadge() }
                    Text(subtitle).font(.footnote).foregroundStyle(Palette.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.footnote).foregroundStyle(Palette.textMuted)
            }
        }
    }
}
