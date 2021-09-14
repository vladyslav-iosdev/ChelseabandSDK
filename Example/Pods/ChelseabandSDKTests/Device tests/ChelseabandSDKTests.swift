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
    
    func testBattery() {
        let device = defaultDevice
        let fanband = MockFanbandScannedPeripheral()
        let connectStatus: Void? = connect(device: device, withFanband: fanband)
        XCTAssert(connectStatus != nil)
        
        let batteryCharacteristicId = ChelseabandConfiguration.default.batteryCharacteristic
        let batteryCharacteristic = findCharacteristic(in: fanband,
                                                       withId: batteryCharacteristicId)
        
        let batteryChargingLevel = try? batteryCharacteristic.observeValueUpdateAndSetNotification()
            .take(5)
            .compactMap { $0.value }
            .map { $0.uint8 }
            .toBlocking()
            .toArray()

        XCTAssertEqual(batteryChargingLevel?.count, 5)
        XCTAssertEqual(batteryChargingLevel, [0, 1, 2, 3, 4])
    }
}

private extension ChelseabandSDKTests {
    func connect(device: DeviceType, withFanband fanband: ScannedPeripheralType) -> Void? {
        try? device.connect(peripheral: fanband).toBlocking().first()
    }
    
    func findCharacteristic(in device: ScannedPeripheralType, withId id: ID) -> CharacteristicType {
        let services = try? device.peripheralType.discoverServices(nil).toBlocking().first()
        XCTAssert(services != nil)
        
        let characteristics = services?.reduce([CharacteristicType]()) { resultArray, service in
            if let serviceCharacteristics = try? service.discoverCharacteristics([id]).toBlocking().first() {
                var mutableArray = resultArray
                mutableArray.append(contentsOf: serviceCharacteristics)
                return mutableArray
            }
            return resultArray
        }
        
        XCTAssertEqual(characteristics?.count, 1)
        
        if let characteristic = characteristics?.first {
            return characteristic
        } else {
            fatalError("characteristic not found")
        }
    }
}

fileprivate extension Data {
    var uint8: UInt8 {
        var number: UInt8 = 0
        self.copyBytes(to:&number, count: MemoryLayout<UInt8>.size)
        return number
    }
}
