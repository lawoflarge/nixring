import XCTest
@testable import NixringCore

final class SmsFilterEngineTests: XCTestCase {
    private let rules = SmsRules()

    func testDisabledAllowsEverything() {
        var r = SmsRules(); r.enabled = false
        XCTAssertEqual(SmsFilterEngine.classify(sender: "x", body: "you have won a prize", rules: r), .allow)
    }

    func testJunkKeyword() {
        XCTAssertEqual(SmsFilterEngine.classify(sender: "x", body: "URGENT: your account is suspended", rules: rules), .junk)
    }

    func testSmishingSuspiciousTLDWithScheme() {
        XCTAssertEqual(SmsFilterEngine.classify(sender: "x", body: "Login at http://secure-bank.xyz/verify", rules: rules), .junk)
    }

    func testSmishingSchemelessSuspiciousTLD() {
        XCTAssertEqual(SmsFilterEngine.classify(sender: "x", body: "go to paypa1.top now", rules: rules), .junk)
    }

    func testShortenerHostIsJunk() {
        XCTAssertEqual(SmsFilterEngine.classify(sender: "x", body: "click bit.ly/abcd", rules: rules), .junk)
    }

    func testNormalMessageAllowed() {
        XCTAssertEqual(SmsFilterEngine.classify(sender: "x", body: "Hey, are we still on for lunch tomorrow?", rules: rules), .allow)
    }

    func testGoodTLDLinkAllowedWhenNotAggressive() {
        XCTAssertEqual(SmsFilterEngine.classify(sender: "x", body: "meeting notes at https://notion.so/xyz", rules: rules), .allow)
    }

    func testBlockAllLinksMode() {
        var r = SmsRules(); r.blockAllLinks = true
        XCTAssertEqual(SmsFilterEngine.classify(sender: "x", body: "see https://example.com", rules: r), .junk)
    }

    func testPromotion() {
        XCTAssertEqual(SmsFilterEngine.classify(sender: "x", body: "Weekend sale, use promo code SAVE20", rules: rules), .promotion)
    }
}
