//
//  MockPeripheral.swift
//  ChelseabandSDKTests
//
//  Created by Sergey Pohrebnuak on 13.09.2021.
//

import Foundation
import ChelseabandSDK
import RxSwift

final class MockPeripheral: PeripheralType {
    
    enum MockType {
        case fanband
        case extraneous
    }
    
    var cbperipheral: CBPeripheralType = MockCBPeripheral()
    
    var isConnected: Bool = false
    
    private var services: [ServiceType]
    
    init(type: MockType) {
        switch type {
        case .fanband:
            services = [
                MockService.batteryService,
                MockService.suotaService,
                MockService.deviceInfoService,
                MockService.fanbandService
            ]
        case .extraneous:
            services = [MockService.deviceInfoService]
        }
    }
    
    func establishConnection(options: [String: Any]?) -> Observable<PeripheralType> {
        Observable.just(self)
    }
    
    func discoverServices(_ serviceUUIDs: [ID]?) -> Single<[ServiceType]> {
        guard let servicesID = serviceUUIDs else {
            return .just(services)
        }
        
        let filteredServices = services.filter{ servicesID.contains($0.uuid) }
        return .just(filteredServices)
    }
}
