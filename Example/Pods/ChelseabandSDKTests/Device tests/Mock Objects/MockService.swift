//
//  MockService.swift
//  ChelseabandSDKTests
//
//  Created by Sergey Pohrebnuak on 13.09.2021.
//

import Foundation
import ChelseabandSDK
import RxSwift

final class MockService: ServiceType {
    var uuid: ID
    
    private var characteristics: [CharacteristicType]
    
    init(uuid: ID, characteristics: [CharacteristicType] = []) {
        self.uuid = uuid
        self.characteristics = characteristics
    }
    
    func discoverCharacteristics(_ characteristicUUIDs: [ID]?) -> Single<[CharacteristicType]> {
        Observable.just(characteristics).asSingle()
    }
}

extension MockService {
    static var batteryService: MockService {
        .init(uuid: ChelseabandConfiguration.default.batteryService,
              characteristics: [MockCharacteristic.battery])
    }
    
    static var deviceInfoService: MockService {
        .init(uuid: ChelseabandConfiguration.default.deviceInfoService,
              characteristics: [MockCharacteristic.firmwareVersion])
    }
    
    static var suotaService: MockService {
        .init(uuid: ChelseabandConfiguration.default.suotaService,
              characteristics: [MockCharacteristic.suotaPatch,
                                .suotaMtu,
                                .suotaMemDev,
                                .suotaGpio,
                                .suotaPatchLen,
                                .suotaPatchData,
                                .suotaServStatus]
        )
    }
    
    static var fanbandService: MockService {
        .init(uuid: ChelseabandConfiguration.default.fanbandService,
              characteristics: [MockCharacteristic.led,
                                .vibration])
    }
}
