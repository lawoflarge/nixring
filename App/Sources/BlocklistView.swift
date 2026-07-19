import SwiftUI
import NixringCore

struct BlocklistView: View {
    @State private var tab = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $tab) {
                    Text("Numbers").tag(0)
                    Text("Whitelist").tag(1)
                    Text("Rules").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(16)

                switch tab {
                case 0: NumbersList()
                case 1: WhitelistList()
                default: RulesList()
                }
            }
            .background(Palette.bg.ignoresSafeArea())
            .navigationTitle("Blocklist")
        }
    }
}

// MARK: - Numbers

private struct NumbersList: View {
    @Environment(AppModel.self) private var model
    @State private var input = ""
    @State private var alertText: String?

    var body: some View {
        List {
            Section {
                HStack {
                    TextField("Add a number to block", text: $input)
                        .keyboardType(.phonePad)
                        .foregroundStyle(Palette.textPrimary)
                    Button("Add") { add() }
                        .disabled(input.isEmpty)
                        .foregroundStyle(input.isEmpty ? Palette.textMuted : Palette.accent)
                }
                .listRowBackground(Palette.surface)
            } footer: {
                if !model.isPro {
                    Text("Free: \(model.data.customBlocklist.count)/\(Entitlement.freeCustomNumberLimit) numbers. Upgrade for unlimited blocking.")
                }
            }

            Section {
                if model.data.customBlocklist.isEmpty {
                    Text("No numbers yet — Nixring already blocks its built-in spam list.")
                        .foregroundStyle(Palette.textSecondary)
                        .listRowBackground(Palette.surface)
                } else {
                    ForEach(model.data.customBlocklist) { entry in
                        Text(entry.e164).foregroundStyle(Palette.textPrimary)
                            .listRowBackground(Palette.surface)
                    }
                    .onDelete { model.removeCustom($0) }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .alert(alertText ?? "", isPresented: Binding(get: { alertText != nil }, set: { if !$0 { alertText = nil } })) {
            Button("OK", role: .cancel) {}
        }
    }

    private func add() {
        switch model.addCustomNumber(input) {
        case .ok: input = ""
        case .invalid: alertText = "That doesn't look like a valid phone number."
        case .duplicate: alertText = "That number is already on your list."; input = ""
        case .needsPro: model.showPaywall = true
        }
    }
}

// MARK: - Whitelist

private struct WhitelistList: View {
    @Environment(AppModel.self) private var model
    @State private var input = ""
    @State private var alertText: String?

    var body: some View {
        if !model.isPro {
            ProGate(title: "Whitelist real callers",
                    message: "Keep the people you trust from ever being blocked. Available with Nixring Pro.")
        } else {
            List {
                Section {
                    HStack {
                        TextField("Add a trusted number", text: $input)
                            .keyboardType(.phonePad).foregroundStyle(Palette.textPrimary)
                        Button("Add") { add() }
                            .disabled(input.isEmpty)
                            .foregroundStyle(input.isEmpty ? Palette.textMuted : Palette.accent)
                    }
                    .listRowBackground(Palette.surface)
                } footer: {
                    Text("Whitelisted numbers are never blocked — they beat every blocklist and rule.")
                }
                Section {
                    if model.data.whitelist.isEmpty {
                        Text("No trusted numbers yet.").foregroundStyle(Palette.textSecondary)
                            .listRowBackground(Palette.surface)
                    } else {
                        ForEach(model.data.whitelist) { entry in
                            Text(entry.e164).foregroundStyle(Palette.textPrimary)
                                .listRowBackground(Palette.surface)
                        }
                        .onDelete { model.removeWhitelist($0) }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .alert(alertText ?? "", isPresented: Binding(get: { alertText != nil }, set: { if !$0 { alertText = nil } })) {
                Button("OK", role: .cancel) {}
            }
        }
    }

    private func add() {
        switch model.addWhitelist(input) {
        case .ok: input = ""
        case .invalid: alertText = "That doesn't look like a valid phone number."
        case .duplicate: alertText = "That number is already trusted."; input = ""
        case .needsPro: model.showPaywall = true
        }
    }
}

// MARK: - Rules

private struct RulesList: View {
    @Environment(AppModel.self) private var model
    @State private var prefix = ""
    @State private var suffix = 4
    @State private var alertText: String?

    var body: some View {
        if !model.isPro {
            ProGate(title: "Prefix rules",
                    message: "Block whole number ranges by prefix — e.g. premium-rate or a spammer's block. Available with Nixring Pro.")
        } else {
            List {
                Section("Add a prefix rule") {
                    TextField("Prefix, e.g. +49 900", text: $prefix)
                        .keyboardType(.phonePad).foregroundStyle(Palette.textPrimary)
                        .listRowBackground(Palette.surface)
                    Stepper("Trailing digits: \(suffix)  (\(rangeSize) numbers)", value: $suffix, in: 1...5)
                        .foregroundStyle(Palette.textPrimary)
                        .listRowBackground(Palette.surface)
                    Button("Add rule") { add() }
                        .disabled(prefix.isEmpty)
                        .foregroundStyle(prefix.isEmpty ? Palette.textMuted : Palette.accent)
                        .listRowBackground(Palette.surface)
                }
                Section {
                    if model.data.callRules.isEmpty {
                        Text("No rules yet.").foregroundStyle(Palette.textSecondary)
                            .listRowBackground(Palette.surface)
                    } else {
                        ForEach(model.data.callRules) { rule in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(rule.label ?? "+\(rule.prefix)").foregroundStyle(Palette.textPrimary)
                                Text("Blocks +\(rule.prefix) + \(rule.suffixDigits) digits")
                                    .font(.caption).foregroundStyle(Palette.textSecondary)
                            }
                            .listRowBackground(Palette.surface)
                        }
                        .onDelete { model.removeRule($0) }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .alert(alertText ?? "", isPresented: Binding(get: { alertText != nil }, set: { if !$0 { alertText = nil } })) {
                Button("OK", role: .cancel) {}
            }
        }
    }

    private var rangeSize: Int { Int(pow(10.0, Double(suffix))) }

    private func add() {
        switch model.addRule(prefix: prefix, suffixDigits: suffix) {
        case .ok: prefix = ""
        case .invalid: alertText = "Enter a numeric prefix."
        case .duplicate: alertText = "That prefix rule already exists."; prefix = ""
        case .needsPro: model.showPaywall = true
        }
    }
}

// MARK: - Pro gate

private struct ProGate: View {
    @Environment(AppModel.self) private var model
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 56)).foregroundStyle(Palette.accentGradient)
            Text(title).font(.title3.weight(.bold)).foregroundStyle(Palette.textPrimary)
            Text(message)
                .font(.subheadline).foregroundStyle(Palette.textSecondary)
                .multilineTextAlignment(.center).padding(.horizontal, 40)
            PrimaryButton(title: "Unlock Nixring Pro", systemImage: "sparkles") { model.showPaywall = true }
                .padding(.horizontal, 40)
            Spacer(); Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.bg.ignoresSafeArea())
    }
}
