// https://github.com/Quick/Quick

import XCTest
@testable import ChelseabandSDK

class DataConvertationsTests: XCTestCase {

    func testDataChunked() {
        let string: String = "Hello world! hello bluetooth device!".hex
        let chunks = string.hexaBytes.chunked(by: 16)

        XCTAssertEqual(chunks.count, 3)
    }
}

