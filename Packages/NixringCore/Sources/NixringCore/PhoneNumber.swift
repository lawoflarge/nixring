import Foundation

/// Phone-number normalization used everywhere numbers cross a boundary (UI input,
/// blocklist storage, CallKit `Int64` conversion). Kept deliberately simple and
/// dependency-free so it runs identically in the app and both extensions.
public enum PhoneNumber {

    /// Normalize a raw user/string number to `+<countrycode><national>` form.
    ///
    /// - `+49 170 123` → `+49170123`
    /// - `0049170123`  → `+49170123`   (00 international prefix)
    /// - `0170123`     → `+49170123`   (national trunk 0 → default country code)
    /// - `170123`      → `+49170123`   (assumed national, default country code prepended)
    ///
    /// Returns `nil` when there are no digits at all.
    public static func normalize(_ raw: String, defaultCountryCode: String = "49") -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasPlus = trimmed.hasPrefix("+")
        let digits = trimmed.filter(\.isNumber)
        guard !digits.isEmpty else { return nil }

        if hasPlus { return "+" + digits }
        if digits.hasPrefix("00") { return "+" + String(digits.dropFirst(2)) }
        if digits.hasPrefix("0") { return "+" + defaultCountryCode + String(digits.dropFirst()) }
        // Bare number long enough to already contain a country code (heuristic): keep as-is.
        // Otherwise assume it's national and prepend the default country code.
        if digits.count >= 11 { return "+" + digits }
        return "+" + defaultCountryCode + digits
    }

    /// The `Int64` CallKit expects (digits only, no `+`). Phone numbers are ≤ 15 digits
    /// (E.164) so they always fit in `Int64`. Returns `nil` for empty or over-long input.
    public static func int64(_ e164OrDigits: String) -> Int64? {
        let digits = e164OrDigits.filter(\.isNumber)
        guard !digits.isEmpty, digits.count <= 18 else { return nil }
        return Int64(digits)
    }

    /// Convenience: normalize then convert to `Int64` in one step.
    public static func int64(normalizing raw: String, defaultCountryCode: String = "49") -> Int64? {
        guard let e164 = normalize(raw, defaultCountryCode: defaultCountryCode) else { return nil }
        return int64(e164)
    }
}
