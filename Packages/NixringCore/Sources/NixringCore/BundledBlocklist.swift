import Foundation

/// On-disk format of the bundled + remote blocklist files.
public struct BlocklistFile: Codable, Sendable {
    public var version: Int
    public var updated: String?
    public var entries: [BlocklistEntry]
    public init(version: Int = 1, updated: String? = nil, entries: [BlocklistEntry]) {
        self.version = version
        self.updated = updated
        self.entries = entries
    }
}

/// Loads and normalizes blocklist JSON (from the app bundle or a remote fetch).
public enum BundledBlocklist {

    /// Decode raw JSON `Data` into entries, stamping every entry with `source`.
    public static func decode(_ data: Data, source: EntrySource = .bundled) -> [BlocklistEntry] {
        guard let file = try? JSONDecoder().decode(BlocklistFile.self, from: data) else { return [] }
        return file.entries.map { entry in
            var e = entry
            e.source = source
            // normalize on the way in so equality/Int64 conversion is consistent
            if let n = PhoneNumber.normalize(e.e164) { e.e164 = n }
            return e
        }
    }

    /// Load the blocklist that ships in a bundle (looks up `blocklist.json`).
    public static func loadBundled(from bundle: Bundle, resource: String = "blocklist", ext: String = "json") -> [BlocklistEntry] {
        guard let url = bundle.url(forResource: resource, withExtension: ext),
              let data = try? Data(contentsOf: url) else { return [] }
        return decode(data, source: .bundled)
    }
}
