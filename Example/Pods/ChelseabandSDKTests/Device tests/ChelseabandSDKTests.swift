//
//  ChelseabandSDKTests.swift
//  ChelseabandSDKTests
//
//  Created by Sergey Pohrebnuak on 09.09.2021.
//

import XCTest
import ChelseabandSDK
import RxBlocking
import RxTest
import RxSwift

final class ChelseabandSDKTests: XCTestCase {
    
    private var defaultDevice: Device {
        .init(configuration: ChelseabandConfiguration.default)
    }

    func testSuccessfullConnected() throws {
        let connectStatus: Void? = connect(device: defaultDevice,
                                           withFanband: MockFanbandScannedPeripheral())
        XCTAssert(connectStatus != nil)
    }
    
    func testConnectedWithError() throws {
        let connectStatus: Void? = connect(device: defaultDevice,
                                           withFanband: MockExtraneousScannedPeripheral())
        XCTAssert(connectStatus == nil)
    }
    
    func testMaxRetryConnectError() throws {
        let disposeBag = DisposeBag()
        let scheduler = TestScheduler(initialClock: 0, resolution: 1)
        
        let connectionObserver = scheduler.record(defaultDevice.connect(peripheral: MaxRetryConnectErrorScannedPeripheral(), scheduler: scheduler),
                                        disposeBag: disposeBag)
        scheduler.start()
        
        let correctValues: [Recorded<Event<Void>>] = Recorded.events(
            .error(15, DeviceError.maxRetryAttempts)
        )
        
        XCTAssertEqual(connectionObserver.events.count, correctValues.count)
        
        for (actual, expected) in zip(connectionObserver.events, correctValues) {
            XCTAssertEqual(actual.time, expected.time, "different times")

            let equal: Bool
            switch (actual.value, expected.value) {
            case (.next, .next),
                 (.completed, .completed):
                equal = true
            case (.error(let errorObserved), .error(let errorExpected)):
                equal = errorObserved.localizedDescription == errorExpected.localizedDescription
            default:
                equal = false
            }
            XCTAssertTrue(equal, "different event")
        }
    }

    func testWriteCommandInExistedCharacteristic() {
        let device = defaultDevice
        let fanband = MockFanbandScannedPeripheral()
        let mockCommand = MockCommand(typeOfUUID: .existed)
        let connectStatus: Void? = connect(device: device, withFanband: fanband)
        XCTAssert(connectStatus != nil)
        
        let writeStatus: Void? = try? device.write(command: mockCommand, timeout: .seconds(5))
            .toBlocking()
            .first()
        XCTAssert(writeStatus != nil)
        
        let characteristic = findCharacteristic(in: fanband, withId: mockCommand.uuidForWrite)
        XCTAssertEqual(characteristic.value, mockCommand.dataForSend)
    }
    
    func testWriteCommandInMissingCharacteristic() {
        let device = defaultDevice
        let fanband = MockFanbandScannedPeripheral()
        let mockCommand = MockCommand(typeOfUUID: .notExisted)
        let connectStatus: Void? = connect(device: device, withFanband: fanband)
        XCTAssert(connectStatus != nil)
        
        let writeStatus: Void? = try? device.write(command: mockCommand, timeout: .seconds(5))
            .toBlocking()
            .first()
        XCTAssert(writeStatus == nil)
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
    
    func test1TimeSynchronizationCommand() {
        let timeForCheck: Double = 1630924946068 / 1000
        let dateForCheck = Date(timeIntervalSince1970: timeForCheck)
        let expectedValue: [UInt8] = [229, 7, 9, 6, 13, 42, 26, 1, 17, 128]
        let timeSynchronizationCommand = TimeSynchronizationCommand(date: dateForCheck)
        XCTAssertEqual([UInt8](timeSynchronizationCommand.dataForSend), expectedValue)
    }
    
    func test2TimeSynchronizationCommand() {
        let timeForCheck: Double = 1630838546068 / 1000
        let dateForCheck = Date(timeIntervalSince1970: timeForCheck)
        let expectedValue: [UInt8] = [229, 7, 9, 5, 13, 42, 26, 7, 17, 128]
        let timeSynchronizationCommand = TimeSynchronizationCommand(date: dateForCheck)
        XCTAssertEqual([UInt8](timeSynchronizationCommand.dataForSend), expectedValue)
    }
}

private extension ChelseabandSDKTests {
    func connect(device: DeviceType, withFanband fanband: ScannedPeripheralType) -> Void? {
        try? device.connect(peripheral: fanband,
                            scheduler: MainScheduler.instance).mapToVoid().toBlocking().first()
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

extension TestScheduler {
/**
    Creates a `TestableObserver` instance which immediately subscribes to the `source`
    */
   func record<O: ObservableConvertibleType>(
       _ source: O,
       disposeBag: DisposeBag
   ) -> TestableObserver<O.Element> {
       let observer = self.createObserver(O.Element.self)
       source
           .asObservable()
           .bind(to: observer)
           .disposed(by: disposeBag)
       return observer
   }
}
