import Foundation

/// The action a Message Filter extension returns for a text from an unknown sender.
public enum SmsAction: String, Sendable, Equatable {
    case allow       // -> .none / .allow
    case junk        // -> .junk
    case promotion   // -> .promotion
}

/// Offline SMS classifier. Runs entirely in memory inside the Message Filter extension —
/// message content is never stored or transmitted. Pure and fully unit-tested.
public enum SmsFilterEngine {

    public static func classify(sender: String, body: String, rules: SmsRules) -> SmsAction {
        guard rules.enabled else { return .allow }
        let lower = body.lowercased()

        // 1) Junk keywords (scam/smishing phrasing).
        for kw in rules.keywords where !kw.isEmpty {
            if lower.contains(kw.lowercased()) { return .junk }
        }

        // 2) Links — smishing usually rides on a URL.
        let hosts = extractHosts(from: body)
        if !hosts.isEmpty {
            if rules.blockAllLinks { return .junk }
            let shorteners = Set(rules.shortenerHosts.map { $0.lowercased() })
            let badTLDs = Set(rules.suspiciousTLDs.map { $0.lowercased() })
            for host in hosts {
                if shorteners.contains(host) { return .junk }
                if let tld = host.split(separator: ".").last.map(String.init)?.lowercased(),
                   badTLDs.contains(tld) {
                    return .junk
                }
            }
        }

        // 3) Promotions (soft filter, not scam).
        for kw in rules.promoKeywords where !kw.isEmpty {
            if lower.contains(kw.lowercased()) { return .promotion }
        }
        return .allow
    }

    /// Extract lowercased hostnames from URLs in the text — both proper `http(s)://` links
    /// (via `NSDataDetector`) and scheme-less domains (via regex), which smishing loves.
    static func extractHosts(from text: String) -> [String] {
        var hosts = Set<String>()

        if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) {
            let range = NSRange(text.startIndex..<text.endIndex, in: text)
            detector.enumerateMatches(in: text, options: [], range: range) { match, _, _ in
                if let host = match?.url?.host { hosts.insert(host.lowercased()) }
            }
        }

        // Scheme-less domain fallback, e.g. "verify at secure-bank.xyz/login".
        let pattern = "([a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\\.)+[a-zA-Z]{2,}"
        if let re = try? NSRegularExpression(pattern: pattern) {
            let ns = text as NSString
            re.enumerateMatches(in: text, range: NSRange(location: 0, length: ns.length)) { match, _, _ in
                if let m = match {
                    // strip any trailing path the detector might not have
                    let host = ns.substring(with: m.range).lowercased()
                    hosts.insert(host)
                }
            }
        }
        return Array(hosts)
    }
}
