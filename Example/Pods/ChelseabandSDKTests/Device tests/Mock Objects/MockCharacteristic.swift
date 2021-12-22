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

class MockCharacteristic: CharacteristicType {
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

final class BatteryMockCharacteristic: MockCharacteristic {
    override func observeValueUpdateAndSetNotification() -> Observable<CharacteristicType> {
        return .deferred {
            return Observable<CharacteristicType>.create{ [weak self] seal in
                let disposableTimer = Observable<UInt8>.timer(.seconds(0),
                                                            period: .seconds(1),
                                                            scheduler: MainScheduler.instance)
                    .take(5)
                    .subscribe(
                        onNext: { [weak self] tick in
                            guard let strongSelf = self else { return }
                            strongSelf.value = Data([tick])
                            seal.onNext(strongSelf)
                        },
                        onCompleted: { seal.onCompleted() }
                    )
                
                return Disposables.create {
                    disposableTimer.dispose()
                }
            }
        }
    }
}

extension MockCharacteristic {
    static var battery: MockCharacteristic {
        BatteryMockCharacteristic(cbCharacteristic: MockCBCharacteristic.battery,
                                  uuid: ChelseabandConfiguration.default.batteryCharacteristic,
                                  value: MockCBCharacteristic.battery.value)
    }
    
    static var firmwareVersion: MockCharacteristic {
        .init(cbCharacteristic: MockCBCharacteristic.empty,
              uuid: ChelseabandConfiguration.default.firmwareVersionCharacteristic)
    }
    
    static var hardware: MockCharacteristic {
        .init(cbCharacteristic: MockCBCharacteristic.empty,
              uuid: ChelseabandConfiguration.default.hardwareCharacteristic)
    }
    
    static var software: MockCharacteristic {
        .init(cbCharacteristic: MockCBCharacteristic.empty,
              uuid: ChelseabandConfiguration.default.softwareCharacteristic)
    }
    
    static var manufacturer: MockCharacteristic {
        .init(cbCharacteristic: MockCBCharacteristic.empty,
              uuid: ChelseabandConfiguration.default.manufacturerCharacteristic)
    }
    
    static var model: MockCharacteristic {
        .init(cbCharacteristic: MockCBCharacteristic.empty,
              uuid: ChelseabandConfiguration.default.modelCharacteristic)
    }
    
    static var serial: MockCharacteristic {
        .init(cbCharacteristic: MockCBCharacteristic.empty,
              uuid: ChelseabandConfiguration.default.serialCharacteristic)
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
    
    static var seatingPosition: MockCharacteristic {
        .init(cbCharacteristic: MockCBCharacteristic.empty,
              uuid: ChelseabandConfiguration.default.seatingPositionCharacteristic)
    }
    
    static var nfcTicket: MockCharacteristic {
        .init(cbCharacteristic: MockCBCharacteristic.empty,
              uuid: ChelseabandConfiguration.default.nfcTicketCharacteristic)
    }
    
    static var deviceSettings: MockCharacteristic {
        .init(cbCharacteristic: MockCBCharacteristic.empty,
              uuid: ChelseabandConfiguration.default.deviceSettingsCharacteristic)
    }
    
    static var imageChunk: MockCharacteristic {
        .init(cbCharacteristic: MockCBCharacteristic.empty,
              uuid: ChelseabandConfiguration.default.imageChunkCharacteristic)
    }
    
    static var imageControl: MockCharacteristic {
        .init(cbCharacteristic: MockCBCharacteristic.empty,
              uuid: ChelseabandConfiguration.default.imageControlCharacteristic)
    }
    
    static var alert: MockCharacteristic {
        .init(cbCharacteristic: MockCBCharacteristic.empty,
              uuid: ChelseabandConfiguration.default.alertCharacteristic)
    }
    
    static var score: MockCharacteristic {
        .init(cbCharacteristic: MockCBCharacteristic.empty,
              uuid: ChelseabandConfiguration.default.scoreCharacteristic)
    }
    
    static var poll: MockCharacteristic {
        .init(cbCharacteristic: MockCBCharacteristic.empty,
              uuid: ChelseabandConfiguration.default.pollCharacteristic)
    }
}
