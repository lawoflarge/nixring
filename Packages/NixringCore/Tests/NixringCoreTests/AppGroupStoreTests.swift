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

    func testCountersBumpAndPersist() throws {
        let dir = try tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = AppGroupStore(containerURL: dir)

        XCTAssertEqual(store.loadCounters(), .zero)
        store.bumpTextsFiltered(promotion: false, now: Date(timeIntervalSince1970: 1_000_000))
        store.bumpTextsFiltered(promotion: false, now: Date(timeIntervalSince1970: 1_000_001))
        store.bumpTextsFiltered(promotion: true, now: Date(timeIntervalSince1970: 1_000_002))
        let c = store.loadCounters()
        XCTAssertEqual(c.textsFiltered, 2)
        XCTAssertEqual(c.textsPromotion, 1)
        XCTAssertEqual(c.lastFiltered, Date(timeIntervalSince1970: 1_000_002))
    }

    func testCountersSeparateFromConfig() throws {
        let dir = try tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = AppGroupStore(containerURL: dir)
        // saving config must not wipe counters and vice versa
        store.bumpTextsFiltered(promotion: false)
        store.save(NixringData(settings: NixringSettings(isPro: true)))
        XCTAssertEqual(store.loadCounters().textsFiltered, 1)
        XCTAssertTrue(store.load().settings.isPro)
    }
}
