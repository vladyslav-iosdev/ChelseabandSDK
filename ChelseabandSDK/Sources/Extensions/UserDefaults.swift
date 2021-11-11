//
//  UserDefaults.swift
//  ChelseabandSDK
//
//  Created by Sergey Pohrebnuak on 17.03.2021.
//

import Foundation
import RxSwift

extension UserDefaults {
    // MARK: - Keys
    private enum Keys {
        static let apiBaseEndpoint: String = "apiBaseEndpoint"
        static let apiKey: String = "apiKey"
        static let lastConnectedPeripheralUUID: String = "lastConnectedPeripheralUUIDKey"
        static let firmwareVersion: String = "firmwareVersion"
        static let fanbandId: String = "fanbandId"
    }
    
    var apiBaseEndpoint: String {
        get { value(forKey: Keys.apiBaseEndpoint) as? String ?? "" }
        set { setValue(newValue, forKey: Keys.apiBaseEndpoint) }
    }
    
    var apiKey: String {
        get { value(forKey: Keys.apiKey) as? String ?? "" }
        set { setValue(newValue, forKey: Keys.apiKey) }
    }
    
    var isAuthorizeObservable: Observable<Bool> {
        UserDefaults.standard.rx.observe(String.self, Keys.fanbandId)
            .map { $0 == nil ? false : true}
    }
    
    var fanbandId: String? {
        get {
            return value(forKey: Keys.fanbandId) as? String
        }

        set {
            if let value = newValue {
                setValue(value, forKey: Keys.fanbandId)
            } else {
                removeObject(forKey: Keys.fanbandId)
            }
        }
    }

    var lastConnectedPeripheralUUID: String? {
        get {
            return value(forKey: Keys.lastConnectedPeripheralUUID) as? String
        }
        set {
            if let value = newValue {
                setValue(value, forKey: Keys.lastConnectedPeripheralUUID)
            } else {
                removeObject(forKey: Keys.lastConnectedPeripheralUUID)
                removeObject(forKey: Keys.firmwareVersion)
            }
        }
    }
    
    var firmwareVersion: String? {
        get { value(forKey: Keys.firmwareVersion) as? String }
        set { setValue(newValue, forKey: Keys.firmwareVersion) }
    }
}
