import XCTest
@testable import NixringCore

final class PhoneNumberTests: XCTestCase {
    func testNormalizePlus() {
        XCTAssertEqual(PhoneNumber.normalize("+49 170 1234567"), "+491701234567")
    }
    func testNormalizeDoubleZero() {
        XCTAssertEqual(PhoneNumber.normalize("0049 170 1234567"), "+491701234567")
    }
    func testNormalizeNationalTrunk() {
        XCTAssertEqual(PhoneNumber.normalize("0170 1234567"), "+491701234567")
    }
    func testNormalizeNationalTrunkCustomCountryCode() {
        XCTAssertEqual(PhoneNumber.normalize("0170 1234567", defaultCountryCode: "44"), "+441701234567")
    }
    func testNormalizeShortNationalPrependsCountryCode() {
        XCTAssertEqual(PhoneNumber.normalize("1234567"), "+491234567")
    }
    func testNormalizeLongBareKeptAsIs() {
        XCTAssertEqual(PhoneNumber.normalize("12345678901"), "+12345678901")
    }
    func testNormalizeStripsFormatting() {
        XCTAssertEqual(PhoneNumber.normalize("+49 (170) 123-45-67"), "+491701234567")
    }
    func testNormalizeNoDigits() {
        XCTAssertNil(PhoneNumber.normalize("call me!"))
    }
    func testInt64FromE164() {
        XCTAssertEqual(PhoneNumber.int64("+491701234567"), 491701234567)
    }
    func testInt64Normalizing() {
        XCTAssertEqual(PhoneNumber.int64(normalizing: "0170 1234567"), 491701234567)
    }
    func testInt64TooLongReturnsNil() {
        XCTAssertNil(PhoneNumber.int64("1234567890123456789012"))
    }
    func testInt64EmptyReturnsNil() {
        XCTAssertNil(PhoneNumber.int64("++"))
    }
}
