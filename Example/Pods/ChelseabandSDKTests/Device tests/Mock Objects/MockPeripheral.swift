//
//  MockPeripheral.swift
//  ChelseabandSDKTests
//
//  Created by Sergey Pohrebnuak on 13.09.2021.
//

import Foundation
import ChelseabandSDK
import RxSwift
import UIKit

final class MockPeripheral: PeripheralType {
    
    enum MockType {
        case fanband
        case extraneous
        case maxRetryConnectionError
    }
    
    var cbperipheral: CBPeripheralType = MockCBPeripheral()
    
    var isConnected: Bool = false
    
    private var mockType: MockType
    private var services: [ServiceType]
    private var establishConnectionObservable: Observable<PeripheralType> {
        switch mockType {
        case .fanband, .extraneous:
            return Observable.of(self).never()
        case .maxRetryConnectionError:
            return Observable.create({ observer -> Disposable in
                let error = NSError(domain:"test error", code: 1, userInfo:nil)
                observer.onError(error)
                return Disposables.create()
            })
        }
    }
    
    init(type: MockType) {
        self.mockType = type
        switch type {
        case .fanband, .maxRetryConnectionError:
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
        establishConnectionObservable
    }
    
    func discoverServices(_ serviceUUIDs: [ID]?) -> Single<[ServiceType]> {
        guard let servicesID = serviceUUIDs else {
            return .just(services)
        }
        
        let filteredServices = services.filter{ servicesID.contains($0.uuid) }
        return .just(filteredServices)
    }
}

extension Observable {
    public func never() -> Observable<Element> {
        return .merge(self, .never())
    }
}
