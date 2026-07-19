import XCTest
@testable import NixringCore

final class AppGroupStoreTests: XCTestCase {

    private func tempDir() throws -> URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    func testSaveLoadRoundTrip() throws {
        let dir = try tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = AppGroupStore(containerURL: dir)

        var d = NixringData()
        d.settings.isPro = true
        d.customBlocklist = [BlocklistEntry(e164: "+4930111", label: "Spam", source: .custom)]
        d.whitelist = [WhitelistEntry(e164: "+4930999", label: "Mom")]
        d.stats = BlockStats(callsBlocked: 5, textsFiltered: 2, lastUpdated: Date(timeIntervalSince1970: 1_000_000))

        XCTAssertTrue(store.save(d))
        XCTAssertEqual(store.load(), d)
    }

    func testLoadMissingReturnsEmpty() throws {
        let dir = try tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        XCTAssertEqual(AppGroupStore(containerURL: dir).load(), .empty)
    }

    func testUpdateMutatesAndPersists() throws {
        let dir = try tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = AppGroupStore(containerURL: dir)

        let out = store.update { $0.stats.callsBlocked += 3 }
        XCTAssertEqual(out.stats.callsBlocked, 3)
        XCTAssertEqual(store.load().stats.callsBlocked, 3)
    }
}
