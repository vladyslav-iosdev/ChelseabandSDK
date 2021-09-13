//
//  MockCBCharacteristic.swift
//  ChelseabandSDKTests
//
//  Created by Sergey Pohrebnuak on 13.09.2021.
//

import Foundation
import ChelseabandSDK

final class MockCBCharacteristic: CBCharacteristicType {
    var value: Data?
    
    init(value: Data? = nil) {
        self.value = value
    }
}

extension MockCBCharacteristic {
    static var empty: MockCBCharacteristic {
        .init()
    }
    
    static var battery: MockCBCharacteristic {
        .init(value: Data([0]))
    }
}
