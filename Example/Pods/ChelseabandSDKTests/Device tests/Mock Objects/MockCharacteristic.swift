//
//  MockCharacteristic.swift
//  ChelseabandSDKTests
//
//  Created by Sergey Pohrebnuak on 13.09.2021.
//

import Foundation
import RxSwift
import ChelseabandSDK
import CoreBluetooth

final class MockCharacteristic: CharacteristicType {
    var cbCharacteristic: CBCharacteristicType
    var value: Data?
    var uuid: ID
    
    init(cbCharacteristic: CBCharacteristicType, uuid: ID, value: Data? = nil) {
        self.cbCharacteristic = cbCharacteristic
        self.uuid = uuid
        self.value = value
    }
    
    func readValue() -> Single<CharacteristicType> {
        Observable<CharacteristicType>.just(self).asSingle()
    }
    
    func writeValue(_ data: Data, type: CBCharacteristicWriteType) -> Single<CharacteristicType> {
        value = data
        return Observable<CharacteristicType>.just(self).asSingle()
    }
    
    func observeValueUpdateAndSetNotification() -> Observable<CharacteristicType> {
        Observable<CharacteristicType>.just(self)
    }
}

extension MockCharacteristic {
    static var battery: MockCharacteristic {
        .init(cbCharacteristic: MockCBCharacteristic.battery,
              uuid: ChelseabandConfiguration.default.batteryCharacteristic,
              value: MockCBCharacteristic.battery.value)
    }
    
    static var firmwareVersion: MockCharacteristic {
        .init(cbCharacteristic: MockCBCharacteristic.empty,
              uuid: ChelseabandConfiguration.default.firmwareVersionCharacteristic)
    }
    
    static var suotaPatch: MockCharacteristic {
        .init(cbCharacteristic: MockCBCharacteristic.empty,
              uuid: ChelseabandConfiguration.default.suotaPatchDataCharSizeCharacteristic)
    }
    
    static var suotaMtu: MockCharacteristic {
        .init(cbCharacteristic: MockCBCharacteristic.empty,
              uuid: ChelseabandConfiguration.default.suotaMtuCharSizeCharacteristic)
    }
    
    static var suotaMemDev: MockCharacteristic {
        .init(cbCharacteristic: MockCBCharacteristic.empty,
              uuid: ChelseabandConfiguration.default.suotaMemDevCharacteristic)
    }

    static var suotaGpio: MockCharacteristic {
        .init(cbCharacteristic: MockCBCharacteristic.empty,
              uuid: ChelseabandConfiguration.default.suotaGpioMapCharacteristic)
    }
    
    static var suotaPatchLen: MockCharacteristic {
        .init(cbCharacteristic: MockCBCharacteristic.empty,
              uuid: ChelseabandConfiguration.default.suotaPatchLenCharacteristic)
    }
    
    static var suotaPatchData: MockCharacteristic {
        .init(cbCharacteristic: MockCBCharacteristic.empty,
              uuid: ChelseabandConfiguration.default.suotaPatchDataCharacteristic)
    }
    
    static var suotaServStatus: MockCharacteristic {
        .init(cbCharacteristic: MockCBCharacteristic.empty,
              uuid: ChelseabandConfiguration.default.suotaServStatusCharacteristic)
    }
    
    static var led: MockCharacteristic {
        .init(cbCharacteristic: MockCBCharacteristic.empty,
              uuid: ChelseabandConfiguration.default.ledCharacteristic)
    }
    
    static var vibration: MockCharacteristic {
        .init(cbCharacteristic: MockCBCharacteristic.empty,
              uuid: ChelseabandConfiguration.default.vibrationCharacteristic)
    }
}
