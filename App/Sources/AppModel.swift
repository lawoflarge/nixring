import Foundation
import SwiftUI
import Observation
import StoreKit
import CallKit
import NixringCore

/// Single source of truth for the UI. Owns the App-Group-persisted `NixringData`, the
/// StoreKit subscription state, and the Call Directory status, and keeps the extension
/// in sync (save + reload) on every change.
@Observable
@MainActor
final class AppModel {
    static let appGroupID = "group.com.levinschwab.nixring"
    private static let onboardedKey = "nixring.hasOnboarded"

    var data: NixringData
    var counters: NixringCounters = .zero
    var callDirStatus: CXCallDirectoryManager.EnabledStatus = .unknown
    var hasOnboarded: Bool
    var showPaywall = false
    private(set) var bundledCount = 0
    private(set) var isUpdatingList = false

    let subs = SubscriptionManager()
    private let store = AppGroupStore(groupID: AppModel.appGroupID)

    init() {
        data = AppGroupStore(groupID: AppModel.appGroupID).load()
        hasOnboarded = UserDefaults.standard.bool(forKey: AppModel.onboardedKey)
    }

    var isPro: Bool {
        #if DEBUG
        if ProcessInfo.processInfo.environment["NIXRING_PRO"] == "1" { return true }
        #endif
        return subs.isPro
    }

    /// Initial tab (screenshot automation only; 0 in release).
    var initialTab: Int {
        #if DEBUG
        return Int(ProcessInfo.processInfo.environment["NIXRING_TAB"] ?? "0") ?? 0
        #else
        return 0
        #endif
    }

    /// Explicit numbers actively shielding the user (rule expansions excluded — they can be huge).
    var shieldedNumberCount: Int {
        let custom = isPro ? data.customBlocklist.count : min(data.customBlocklist.count, Entitlement.freeCustomNumberLimit)
        let remote = isPro ? data.cachedRemote.count : 0
        return bundledCount + custom + remote
    }

    var callProtectionActive: Bool { data.settings.protectionEnabled && callDirStatus == .enabled }

    // MARK: lifecycle

    func bootstrap() async {
        bundledCount = BundledBlocklist.loadBundled(from: .main).count
        counters = store.loadCounters()
        await subs.loadProducts()
        await subs.refreshEntitlements()
        syncProFlag()
        await refreshStatus()
        if data.settings.autoUpdateEnabled && isPro { await updateRemoteList() }
        #if DEBUG
        applyScreenshotStateIfNeeded()
        #endif
    }

    #if DEBUG
    private func applyScreenshotStateIfNeeded() {
        let env = ProcessInfo.processInfo.environment
        guard env["NIXRING_SCREENSHOT"] == "1" else { return }
        hasOnboarded = true
        data.settings.protectionEnabled = true
        data.settings.smsFilterEnabled = true
        if data.customBlocklist.isEmpty {
            data.customBlocklist = [
                BlocklistEntry(e164: "+18005550142", label: "Robocaller", source: .custom),
                BlocklistEntry(e164: "+491771234567", source: .custom),
                BlocklistEntry(e164: "+442071234567", source: .custom),
            ]
        }
        counters = NixringCounters(textsFiltered: 47, textsPromotion: 12, lastFiltered: nil)
        callDirStatus = .enabled
        if env["NIXRING_PAYWALL"] == "1" { showPaywall = true }
    }
    #endif

    func refresh() async {
        #if DEBUG
        if ProcessInfo.processInfo.environment["NIXRING_SCREENSHOT"] == "1" {
            applyScreenshotStateIfNeeded()
            return
        }
        #endif
        counters = store.loadCounters()
        await subs.refreshEntitlements()
        syncProFlag()
        await refreshStatus()
    }

    func refreshStatus() async {
        #if DEBUG
        if ProcessInfo.processInfo.environment["NIXRING_SCREENSHOT"] == "1" {
            callDirStatus = .enabled
            return
        }
        #endif
        callDirStatus = await ProtectionController.status()
    }

    private func syncProFlag() {
        guard data.settings.isPro != subs.isPro else { return }
        data.settings.isPro = subs.isPro
        persistAndReload()
    }

    private func persistAndReload() {
        store.save(data)
        Task { try? await ProtectionController.reload(); await refreshStatus() }
    }

    func completeOnboarding() {
        hasOnboarded = true
        UserDefaults.standard.set(true, forKey: Self.onboardedKey)
        data.settings.protectionEnabled = true
        persistAndReload()
    }

    // MARK: mutations

    enum AddResult { case ok, invalid, duplicate, needsPro }

    func addCustomNumber(_ raw: String) -> AddResult {
        guard let e164 = PhoneNumber.normalize(raw) else { return .invalid }
        if data.customBlocklist.contains(where: { $0.e164 == e164 }) { return .duplicate }
        if !isPro && data.customBlocklist.count >= Entitlement.freeCustomNumberLimit { return .needsPro }
        data.customBlocklist.append(BlocklistEntry(e164: e164, source: .custom))
        persistAndReload()
        return .ok
    }
    func removeCustom(_ offsets: IndexSet) { data.customBlocklist.remove(atOffsets: offsets); persistAndReload() }

    func addWhitelist(_ raw: String) -> AddResult {
        guard isPro else { return .needsPro }
        guard let e164 = PhoneNumber.normalize(raw) else { return .invalid }
        if data.whitelist.contains(where: { $0.e164 == e164 }) { return .duplicate }
        data.whitelist.append(WhitelistEntry(e164: e164))
        persistAndReload()
        return .ok
    }
    func removeWhitelist(_ offsets: IndexSet) { data.whitelist.remove(atOffsets: offsets); persistAndReload() }

    func addRule(prefix raw: String, suffixDigits: Int) -> AddResult {
        guard isPro else { return .needsPro }
        let digits = raw.filter(\.isNumber)
        guard !digits.isEmpty else { return .invalid }
        if data.callRules.contains(where: { $0.prefix == digits }) { return .duplicate }
        data.callRules.append(CallRule(prefix: digits, suffixDigits: suffixDigits, label: raw))
        persistAndReload()
        return .ok
    }
    func removeRule(_ offsets: IndexSet) { data.callRules.remove(atOffsets: offsets); persistAndReload() }

    func setProtection(_ on: Bool) { data.settings.protectionEnabled = on; persistAndReload() }

    func setSMSFilter(_ on: Bool) {
        if on && !isPro { showPaywall = true; return }
        data.settings.smsFilterEnabled = on
        store.save(data)
    }

    func setBlockAllLinks(_ on: Bool) { data.smsRules.blockAllLinks = on; store.save(data) }

    func setAutoUpdate(_ on: Bool) async {
        if on && !isPro { showPaywall = true; return }
        data.settings.autoUpdateEnabled = on
        store.save(data)
        if on { await updateRemoteList() }
    }

    func updateRemoteList() async {
        guard isPro else { showPaywall = true; return }
        isUpdatingList = true
        defer { isUpdatingList = false }
        if let entries = await RemoteBlocklist.fetch() {
            data.cachedRemote = entries
            data.stats.lastUpdated = Date()
            persistAndReload()
        }
    }

    // MARK: purchases

    func purchase(_ product: Product) async {
        await subs.purchase(product)
        syncProFlag()
        if isPro { showPaywall = false }
    }
    func restore() async {
        await subs.restore()
        syncProFlag()
        if isPro { showPaywall = false }
    }

    func openCallSettings() { ProtectionController.openSettings() }
}
