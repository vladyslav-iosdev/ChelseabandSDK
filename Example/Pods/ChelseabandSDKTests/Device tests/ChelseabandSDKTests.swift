//
//  ChelseabandSDKTests.swift
//  ChelseabandSDKTests
//
//  Created by Sergey Pohrebnuak on 09.09.2021.
//

import XCTest
import ChelseabandSDK
import RxBlocking

final class ChelseabandSDKTests: XCTestCase {

    func testSuccessfullConnected() throws {
        let device = Device(configuration: ChelseabandConfiguration.default)
        let value: Void? = try? device.connect(peripheral: MockFanbandScannedPeripheral()).toBlocking().first()
        XCTAssert(value != nil)
    }
    
    func testConnectedWithError() throws {
        let device = Device(configuration: ChelseabandConfiguration.default)
        let value: Void? = try? device.connect(peripheral: MockExtraneousScannedPeripheral()).toBlocking().first()
        XCTAssert(value == nil)
    }

}
