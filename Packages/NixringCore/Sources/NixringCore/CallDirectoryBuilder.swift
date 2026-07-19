import Foundation

/// One entry in the CallKit *identification* list (labels a caller without blocking it).
public struct IdentificationEntry: Equatable, Sendable {
    public let number: Int64
    public let label: String
    public init(number: Int64, label: String) { self.number = number; self.label = label }
}

/// The two sorted-ascending lists a `CXCallDirectoryProvider` must feed to CallKit.
public struct CallDirectoryLists: Equatable, Sendable {
    /// Blocked numbers, ascending, unique.
    public let blocked: [Int64]
    /// Identified (labelled, not blocked) numbers, ascending by number, unique.
    public let identification: [IdentificationEntry]

    public init(blocked: [Int64], identification: [IdentificationEntry]) {
        self.blocked = blocked
        self.identification = identification
    }
    public static let empty = CallDirectoryLists(blocked: [], identification: [])
}

/// Turns the user's `NixringData` + the bundled database into the exact, de-duplicated,
/// sorted-ascending lists CallKit requires. This is the whole business brain of call
/// blocking — pure and fully unit-tested — so the extension itself can stay trivial.
public enum CallDirectoryBuilder {

    public static func build(data: NixringData,
                             bundled: [BlocklistEntry],
                             freeLimit: Int = Entitlement.freeCustomNumberLimit,
                             maxGenerated: Int = Entitlement.maxGeneratedEntries) -> CallDirectoryLists {
        guard data.settings.protectionEnabled else { return .empty }
        let isPro = data.settings.isPro

        // Whitelist beats every blocklist and rule.
        let white = Set(data.whitelist.compactMap { PhoneNumber.int64($0.e164) })

        var blockedSet = Set<Int64>()
        var identify = [Int64: String]()

        func consider(_ e: BlocklistEntry) {
            guard let n = PhoneNumber.int64(e.e164), !white.contains(n) else { return }
            if e.identifyOnly {
                if let l = e.label, !l.isEmpty { identify[n] = l }
            } else {
                blockedSet.insert(n)
            }
        }

        // Bundled database is the always-on free base protection.
        bundled.forEach(consider)

        // Custom numbers: free tier honours only the first `freeLimit`.
        let custom = isPro ? data.customBlocklist : Array(data.customBlocklist.prefix(freeLimit))
        custom.forEach(consider)

        // Remote auto-update list and prefix rules are Pro-only.
        if isPro {
            data.cachedRemote.forEach(consider)
            for rule in data.callRules where rule.enabled {
                if blockedSet.count >= maxGenerated { break }
                expand(rule: rule, into: &blockedSet, whitelist: white, cap: maxGenerated)
            }
        }

        let blockedArr = blockedSet.sorted()
        let idArr = identify
            .filter { !blockedSet.contains($0.key) }         // don't identify what we already block
            .map { IdentificationEntry(number: $0.key, label: $0.value) }
            .sorted { $0.number < $1.number }

        return CallDirectoryLists(blocked: blockedArr, identification: idArr)
    }

    /// Expand a prefix rule into a contiguous `Int64` range (`prefix` + `suffixDigits` trailing
    /// digits), skipping whitelisted numbers and honouring the global cap.
    static func expand(rule: CallRule, into set: inout Set<Int64>, whitelist: Set<Int64>, cap: Int) {
        let digits = rule.prefix.filter(\.isNumber)
        let sfx = min(max(rule.suffixDigits, 1), 5)
        guard !digits.isEmpty, digits.count + sfx <= 18, let base = Int64(digits) else { return }

        var multiplier: Int64 = 1
        for _ in 0..<sfx { multiplier *= 10 }
        let start = base * multiplier
        let end = start + multiplier            // exclusive
        var n = start
        while n < end {
            if set.count >= cap { return }
            if !whitelist.contains(n) { set.insert(n) }
            n += 1
        }
    }
}
