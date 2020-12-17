import XCTest
@testable import ChelseabandSDK

final class ChelseabandSDKTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(ChelseabandSDK().text, "Hello, World!")
    }

    func testDevice() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
//        Device
        XCTAssertEqual(ChelseabandSDK().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
