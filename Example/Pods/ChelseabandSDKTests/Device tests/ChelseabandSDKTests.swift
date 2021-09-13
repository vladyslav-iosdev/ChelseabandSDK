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
    
    private var defaultDevice: Device {
        .init(configuration: ChelseabandConfiguration.default)
    }

    func testSuccessfullConnected() throws {
        let value: Void? = try? defaultDevice.connect(peripheral: MockFanbandScannedPeripheral()).toBlocking().first()
        XCTAssert(value != nil)
    }
    
    func testConnectedWithError() throws {
        let value: Void? = try? defaultDevice.connect(peripheral: MockExtraneousScannedPeripheral()).toBlocking().first()
        XCTAssert(value == nil)
    }

    func testWriteCommandInExistedCharacteristic() {
        let device = defaultDevice
        let fanband = MockFanbandScannedPeripheral()
        let mockCommand = MockCommand(typeOfUUID: .existed)
        let _ = try? device.connect(peripheral: fanband).toBlocking().first()
        let value: Void? = try? device.write(command: mockCommand, timeout: .seconds(5)).toBlocking().first()
        XCTAssert(value != nil)
        
        let services = try? fanband.peripheralType.discoverServices(nil).toBlocking().first()
        XCTAssert(services != nil)
        
        let characteristics = services?.reduce([CharacteristicType]()) { resultArray, service in
            if let serviceCharacteristics = try? service.discoverCharacteristics([mockCommand.uuidForWrite]).toBlocking().first() {
                var mutableArray = resultArray
                mutableArray.append(contentsOf: serviceCharacteristics)
                return mutableArray
            }
            return resultArray
        }
        
        XCTAssertEqual(characteristics?.count, 1)
        XCTAssertEqual(characteristics?.first?.value, mockCommand.dataForSend)
    }
    
    func testWriteCommandInMissingCharacteristic() {
        let device = defaultDevice
        let fanband = MockFanbandScannedPeripheral()
        let mockCommand = MockCommand(typeOfUUID: .notExisted)
        let _ = try? device.connect(peripheral: fanband).toBlocking().first()
        let value: Void? = try? device.write(command: mockCommand, timeout: .seconds(5)).toBlocking().first()
        XCTAssert(value == nil)
    }
}
