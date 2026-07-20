import Foundation
import NixringCore

/// Fetches the optional static remote blocklist (Pro auto-update). ETag-cached, times out
/// fast, and fails silently offline — there is no backend and nothing is ever uploaded.
enum RemoteBlocklist {
    static let url = URL(string: "https://nixring.vercel.app/blocklist.json")!
    private static let etagKey = "nixring.remoteBlocklist.etag"

    /// Returns fresh entries, or `nil` when unchanged (304) / offline / failed.
    static func fetch() async -> [BlocklistEntry]? {
        var request = URLRequest(url: url)
        request.timeoutInterval = 12
        if let etag = UserDefaults.standard.string(forKey: etagKey) {
            request.setValue(etag, forHTTPHeaderField: "If-None-Match")
        }
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { return nil }
            if http.statusCode == 304 { return nil }
            guard http.statusCode == 200 else { return nil }
            if let etag = http.value(forHTTPHeaderField: "ETag") {
                UserDefaults.standard.set(etag, forKey: etagKey)
            }
            let entries = BundledBlocklist.decode(data, source: .remote)
            return entries.isEmpty ? nil : entries
        } catch {
            return nil
        }
    }
}
