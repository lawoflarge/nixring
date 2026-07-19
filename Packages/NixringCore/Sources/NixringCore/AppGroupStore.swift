import Foundation

/// Reads/writes the single JSON state file shared between the app and both extensions.
/// Uses the App Group container by default; a custom container URL can be injected for tests.
public final class AppGroupStore {
    public static let defaultFileName = "nixring-data.json"

    private let fileURL: URL?
    public let groupID: String?

    /// Real app / extension use.
    public init(groupID: String, fileName: String = AppGroupStore.defaultFileName) {
        self.groupID = groupID
        self.fileURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: groupID)?
            .appendingPathComponent(fileName)
    }

    /// Testing / custom location.
    public init(containerURL: URL, fileName: String = AppGroupStore.defaultFileName) {
        self.groupID = nil
        self.fileURL = containerURL.appendingPathComponent(fileName)
    }

    /// False when the App Group container is unavailable (mis-provisioned entitlement).
    public var isAvailable: Bool { fileURL != nil }

    private static func makeDecoder() -> JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }
    private static func makeEncoder() -> JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }

    public func load() -> NixringData {
        guard let url = fileURL, let data = try? Data(contentsOf: url) else { return .empty }
        return (try? Self.makeDecoder().decode(NixringData.self, from: data)) ?? .empty
    }

    @discardableResult
    public func save(_ value: NixringData) -> Bool {
        guard let url = fileURL, let data = try? Self.makeEncoder().encode(value) else { return false }
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: url, options: .atomic)
            return true
        } catch {
            return false
        }
    }

    /// Load, mutate, save, and return the new value.
    @discardableResult
    public func update(_ transform: (inout NixringData) -> Void) -> NixringData {
        var d = load()
        transform(&d)
        save(d)
        return d
    }
}
