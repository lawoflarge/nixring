import XCTest
@testable import NixringCore

final class BundledBlocklistTests: XCTestCase {

    func testTolerantDecodeWithMissingFields() {
        let json = Data("""
        { "version": 1, "entries": [ {"e164":"+4930111"}, {"e164":"0170 999", "label":"Scam"} ] }
        """.utf8)
        let entries = BundledBlocklist.decode(json, source: .bundled)
        XCTAssertEqual(entries.count, 2)
        XCTAssertEqual(entries[0].source, .bundled)
        XCTAssertEqual(entries[0].e164, "+4930111")
        XCTAssertFalse(entries[0].identifyOnly)
        // normalized on the way in
        XCTAssertEqual(entries[1].e164, "+49170999")
        XCTAssertEqual(entries[1].label, "Scam")
    }

    func testDecodeInvalidReturnsEmpty() {
        XCTAssertTrue(BundledBlocklist.decode(Data("not json".utf8)).isEmpty)
    }

    func testRoundTripThroughBuilder() {
        let json = Data("""
        { "version": 1, "entries": [ {"e164":"+4930111","label":"Spam"}, {"e164":"+4930222"} ] }
        """.utf8)
        let bundled = BundledBlocklist.decode(json)
        let out = CallDirectoryBuilder.build(data: NixringData(), bundled: bundled)
        XCTAssertEqual(out.blocked, [4930111, 4930222])
    }
}
