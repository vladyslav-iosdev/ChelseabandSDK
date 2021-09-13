//
//  MockCBPeripheral.swift
//  ChelseabandSDKTests
//
//  Created by Sergey Pohrebnuak on 13.09.2021.
//

import Foundation
import ChelseabandSDK

final class MockCBPeripheral: CBPeripheralType {
    var name: String?
    
    init() {
        self.name = "FanbandTest"
    }
}
