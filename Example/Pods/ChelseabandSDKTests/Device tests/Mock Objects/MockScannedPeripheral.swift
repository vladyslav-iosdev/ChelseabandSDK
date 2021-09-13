//
//  MockScannedPeripheral.swift
//  ChelseabandSDKTests
//
//  Created by Sergey Pohrebnuak on 13.09.2021.
//

import Foundation
import ChelseabandSDK

final class MockFanbandScannedPeripheral: ScannedPeripheralType {
    var peripheralType: PeripheralType = MockPeripheral(type: .fanband)
}

final class MockExtraneousScannedPeripheral: ScannedPeripheralType {
    var peripheralType: PeripheralType = MockPeripheral(type: .extraneous)
}
