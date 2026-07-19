import XCTest
@testable import NixringCore

final class CallDirectoryBuilderTests: XCTestCase {

    private func data(pro: Bool = false, protection: Bool = true) -> NixringData {
        var d = NixringData()
        d.settings.isPro = pro
        d.settings.protectionEnabled = protection
        return d
    }

    func testProtectionDisabledReturnsEmpty() {
        var d = data(protection: false)
        d.customBlocklist = [BlocklistEntry(e164: "+491234")]
        let out = CallDirectoryBuilder.build(data: d, bundled: [BlocklistEntry(e164: "+495678")])
        XCTAssertEqual(out, .empty)
    }

    func testBundledAlwaysBlockedEvenOnFree() {
        let out = CallDirectoryBuilder.build(data: data(), bundled: [
            BlocklistEntry(e164: "+4930222", source: .bundled),
            BlocklistEntry(e164: "+4930111", source: .bundled),
        ])
        XCTAssertEqual(out.blocked, [4930111, 4930222])
    }

    func testWhitelistBeatsBlocklist() {
        var d = data()
        d.whitelist = [WhitelistEntry(e164: "+4930111")]
        let out = CallDirectoryBuilder.build(data: d, bundled: [
            BlocklistEntry(e164: "+4930111"), BlocklistEntry(e164: "+4930222"),
        ])
        XCTAssertEqual(out.blocked, [4930222])
    }

    func testFreeCustomLimitOfTen() {
        var d = data()
        d.customBlocklist = (0..<15).map { BlocklistEntry(e164: "+4930\(1000 + $0)") }
        let out = CallDirectoryBuilder.build(data: d, bundled: [])
        XCTAssertEqual(out.blocked.count, 10)
    }

    func testProCustomIsUnlimited() {
        var d = data(pro: true)
        d.customBlocklist = (0..<15).map { BlocklistEntry(e164: "+4930\(1000 + $0)") }
        let out = CallDirectoryBuilder.build(data: d, bundled: [])
        XCTAssertEqual(out.blocked.count, 15)
    }

    func testDedupAndSortAscending() {
        var d = data(pro: true)
        d.customBlocklist = [
            BlocklistEntry(e164: "+4930222"),
            BlocklistEntry(e164: "+4930111"),
            BlocklistEntry(e164: "+4930222"),
        ]
        let out = CallDirectoryBuilder.build(data: d, bundled: [BlocklistEntry(e164: "+4930111")])
        XCTAssertEqual(out.blocked, [4930111, 4930222])
    }

    func testPrefixRuleExpandsForPro() {
        var d = data(pro: true)
        d.callRules = [CallRule(prefix: "49900", suffixDigits: 2)]
        let out = CallDirectoryBuilder.build(data: d, bundled: [])
        XCTAssertEqual(out.blocked.count, 100)
        XCTAssertEqual(out.blocked.first, 4990000)
        XCTAssertEqual(out.blocked.last, 4990099)
    }

    func testPrefixRuleIgnoredForFree() {
        var d = data()
        d.callRules = [CallRule(prefix: "49900", suffixDigits: 2)]
        let out = CallDirectoryBuilder.build(data: d, bundled: [])
        XCTAssertTrue(out.blocked.isEmpty)
    }

    func testDisabledRuleSkipped() {
        var d = data(pro: true)
        d.callRules = [CallRule(prefix: "49900", suffixDigits: 2, enabled: false)]
        let out = CallDirectoryBuilder.build(data: d, bundled: [])
        XCTAssertTrue(out.blocked.isEmpty)
    }

    func testRuleRespectsWhitelist() {
        var d = data(pro: true)
        d.callRules = [CallRule(prefix: "49900", suffixDigits: 1)] // 499000...499009
        d.whitelist = [WhitelistEntry(e164: "+499005")]
        let out = CallDirectoryBuilder.build(data: d, bundled: [])
        XCTAssertEqual(out.blocked.count, 9)
        XCTAssertFalse(out.blocked.contains(499005))
    }

    func testIdentifyOnlyGoesToIdentificationNotBlocked() {
        var d = data(pro: true)
        d.customBlocklist = [BlocklistEntry(e164: "+4930111", label: "Telemarketer", source: .custom, identifyOnly: true)]
        let out = CallDirectoryBuilder.build(data: d, bundled: [])
        XCTAssertTrue(out.blocked.isEmpty)
        XCTAssertEqual(out.identification, [IdentificationEntry(number: 4930111, label: "Telemarketer")])
    }

    func testRemoteListOnlyForPro() {
        var d = data() // free
        d.cachedRemote = [BlocklistEntry(e164: "+4930999", source: .remote)]
        XCTAssertTrue(CallDirectoryBuilder.build(data: d, bundled: []).blocked.isEmpty)
        d.settings.isPro = true
        XCTAssertEqual(CallDirectoryBuilder.build(data: d, bundled: []).blocked, [4930999])
    }

    func testGlobalCapHonoured() {
        var d = data(pro: true)
        d.callRules = [CallRule(prefix: "1", suffixDigits: 5)] // would be 100k
        let out = CallDirectoryBuilder.build(data: d, bundled: [], maxGenerated: 50)
        XCTAssertLessThanOrEqual(out.blocked.count, 50)
    }
}
