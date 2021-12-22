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
        guard let characteristicID = characteristicUUIDs else {
            return Observable.just(characteristics).asSingle()
        }
        
        let filteredCharacteristics = characteristics.filter{ characteristicID.contains($0.uuid) }
        return Observable.just(filteredCharacteristics).asSingle()
    }
}

extension MockService {
    static var batteryService: MockService {
        .init(uuid: ChelseabandConfiguration.default.batteryService,
              characteristics: [MockCharacteristic.battery])
    }
    
    static var deviceInfoService: MockService {
        .init(uuid: ChelseabandConfiguration.default.deviceInfoService,
              characteristics: [MockCharacteristic.firmwareVersion,
                                .software,
                                .hardware,
                                .model,
                                .manufacturer,
                                .serial])
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
                                .vibration,
                                .seatingPosition,
                                .nfcTicket,
                                .alert,
                                .score,
                                .poll,
                                .imageChunk,
                                .imageControl,
                                .deviceSettings])
    }
}
