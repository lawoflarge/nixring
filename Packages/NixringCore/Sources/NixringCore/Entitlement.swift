import Foundation

/// Free vs Pro limits, in one place so the UI and the list builder agree.
public enum Entitlement {
    /// Free tier: up to this many user-added numbers are honoured by the Call Directory.
    public static let freeCustomNumberLimit = 10

    /// Global safety cap on generated Call Directory entries (rule expansion + lists),
    /// keeping reload time and memory sane within CallKit limits.
    public static let maxGeneratedEntries = 300_000

    /// Whether a given custom-number count is within the free allowance.
    public static func customNumbersAllowed(count: Int, isPro: Bool) -> Bool {
        isPro || count <= freeCustomNumberLimit
    }
}
