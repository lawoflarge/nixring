import Foundation

/// Where a blocklist entry came from.
public enum EntrySource: String, Codable, Sendable {
    case bundled   // shipped in the app bundle
    case remote    // fetched from the static remote blocklist
    case custom    // added by the user
}

/// A single phone number the user (or our database) wants blocked or identified.
/// `e164` is a normalized number in `+<countrycode><national>` form, e.g. `+491701234567`.
public struct BlocklistEntry: Codable, Equatable, Sendable, Identifiable {
    public var id: String { e164 }
    public var e164: String
    public var label: String?
    public var source: EntrySource
    /// If true the number is only *identified* (labelled when it rings), not blocked.
    public var identifyOnly: Bool

    public init(e164: String, label: String? = nil, source: EntrySource = .custom, identifyOnly: Bool = false) {
        self.e164 = e164
        self.label = label
        self.source = source
        self.identifyOnly = identifyOnly
    }

    private enum CodingKeys: String, CodingKey { case e164, label, source, identifyOnly }

    // Tolerant decoding: hand-authored blocklists may omit `source`/`identifyOnly`.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        e164 = try c.decode(String.self, forKey: .e164)
        label = try c.decodeIfPresent(String.self, forKey: .label)
        source = try c.decodeIfPresent(EntrySource.self, forKey: .source) ?? .custom
        identifyOnly = try c.decodeIfPresent(Bool.self, forKey: .identifyOnly) ?? false
    }
}

/// A number that must never be blocked (trusted). Whitelist beats every blocklist and rule.
public struct WhitelistEntry: Codable, Equatable, Sendable, Identifiable {
    public var id: String { e164 }
    public var e164: String
    public var label: String?

    public init(e164: String, label: String? = nil) {
        self.e164 = e164
        self.label = label
    }
}

/// A Pro rule that blocks a contiguous number range by prefix.
///
/// CallKit's Call Directory is list-based (explicit `Int64` numbers only — no wildcards),
/// so a "prefix" rule is realised by enumerating `prefix` followed by `suffixDigits`
/// trailing digits, i.e. a bounded, contiguous block of `10^suffixDigits` numbers.
public struct CallRule: Codable, Equatable, Sendable, Identifiable {
    public var id: String
    /// Digits only, country-coded, no `+` — e.g. `49900` for German premium-rate 0900.
    public var prefix: String
    /// Number of trailing digits to enumerate (clamped 1...5). Default 4 → 10 000 numbers.
    public var suffixDigits: Int
    public var label: String?
    public var enabled: Bool

    public init(id: String = UUID().uuidString, prefix: String, suffixDigits: Int = 4, label: String? = nil, enabled: Bool = true) {
        self.id = id
        self.prefix = prefix
        self.suffixDigits = suffixDigits
        self.label = label
        self.enabled = enabled
    }
}

/// Offline SMS classification rules. Content is never persisted or transmitted — only these
/// rules leave the user's device (they don't, they're local), and messages are matched in memory.
public struct SmsRules: Codable, Equatable, Sendable {
    public var enabled: Bool
    /// Body contains any of these (case-insensitive) → junk.
    public var keywords: [String]
    /// Any URL in the body → junk (aggressive smishing mode).
    public var blockAllLinks: Bool
    /// URLs whose host ends in one of these TLDs → junk.
    public var suspiciousTLDs: [String]
    /// Known URL-shortener hosts → treated as suspicious links.
    public var shortenerHosts: [String]
    /// Body contains any of these → promotion (soft filter).
    public var promoKeywords: [String]

    public init(enabled: Bool = true,
                keywords: [String] = SmsRules.defaultKeywords,
                blockAllLinks: Bool = false,
                suspiciousTLDs: [String] = SmsRules.defaultSuspiciousTLDs,
                shortenerHosts: [String] = SmsRules.defaultShortenerHosts,
                promoKeywords: [String] = SmsRules.defaultPromoKeywords) {
        self.enabled = enabled
        self.keywords = keywords
        self.blockAllLinks = blockAllLinks
        self.suspiciousTLDs = suspiciousTLDs
        self.shortenerHosts = shortenerHosts
        self.promoKeywords = promoKeywords
    }

    public static let defaultKeywords: [String] = [
        "verify your account", "suspended", "click the link", "urgent", "act now",
        "gift card", "you have won", "you've won", "claim your prize", "congratulations you",
        "bank account", "unusual activity", "confirm your identity", "package could not",
        "delivery fee", "customs fee", "your parcel", "reactivate", "crypto", "bitcoin",
        "investment opportunity", "final notice", "outstanding payment", "tax refund",
        "social security", "one time password for", "otp is", "login attempt",
    ]
    public static let defaultSuspiciousTLDs: [String] = [
        "xyz", "top", "click", "link", "live", "buzz", "cn", "ru", "tk", "ml", "ga", "cf", "gq", "rest", "cam", "sbs",
    ]
    public static let defaultShortenerHosts: [String] = [
        "bit.ly", "tinyurl.com", "t.co", "goo.gl", "ow.ly", "is.gd", "cutt.ly", "rb.gy", "rebrand.ly", "shorturl.at",
    ]
    public static let defaultPromoKeywords: [String] = [
        "sale", "discount", "% off", "coupon", "promo code", "limited offer", "unsubscribe", "deal",
    ]
}

/// Running counters shown on the home screen.
public struct BlockStats: Codable, Equatable, Sendable {
    public var callsBlocked: Int
    public var textsFiltered: Int
    public var lastUpdated: Date?

    public init(callsBlocked: Int = 0, textsFiltered: Int = 0, lastUpdated: Date? = nil) {
        self.callsBlocked = callsBlocked
        self.textsFiltered = textsFiltered
        self.lastUpdated = lastUpdated
    }
}

/// User-facing toggles + entitlement flag (mirrored into the App Group so extensions can read it).
public struct NixringSettings: Codable, Equatable, Sendable {
    public var protectionEnabled: Bool
    public var smsFilterEnabled: Bool
    public var autoUpdateEnabled: Bool
    public var isPro: Bool

    public init(protectionEnabled: Bool = true, smsFilterEnabled: Bool = true, autoUpdateEnabled: Bool = false, isPro: Bool = false) {
        self.protectionEnabled = protectionEnabled
        self.smsFilterEnabled = smsFilterEnabled
        self.autoUpdateEnabled = autoUpdateEnabled
        self.isPro = isPro
    }
}

/// The complete persisted state, stored as one JSON file in the App Group container and
/// read by the main app and both extensions.
public struct NixringData: Codable, Equatable, Sendable {
    public var customBlocklist: [BlocklistEntry]
    public var whitelist: [WhitelistEntry]
    public var callRules: [CallRule]
    public var smsRules: SmsRules
    public var settings: NixringSettings
    public var stats: BlockStats
    /// Numbers pulled from the static remote list (Pro auto-update).
    public var cachedRemote: [BlocklistEntry]

    public init(customBlocklist: [BlocklistEntry] = [],
                whitelist: [WhitelistEntry] = [],
                callRules: [CallRule] = [],
                smsRules: SmsRules = SmsRules(),
                settings: NixringSettings = NixringSettings(),
                stats: BlockStats = BlockStats(),
                cachedRemote: [BlocklistEntry] = []) {
        self.customBlocklist = customBlocklist
        self.whitelist = whitelist
        self.callRules = callRules
        self.smsRules = smsRules
        self.settings = settings
        self.stats = stats
        self.cachedRemote = cachedRemote
    }

    public static let empty = NixringData()
}
