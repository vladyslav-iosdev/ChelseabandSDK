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
    private enum Keys: String {
        case apiBaseEndpoint
        case apiKey
        case lastConnectedPeripheralUUID
        case firmwareVersion
        case userId
    }
    
    var apiBaseEndpoint: String {
        get { value(forKey: Keys.apiBaseEndpoint.rawValue) as? String ?? "" }
        set { setValue(newValue, forKey: Keys.apiBaseEndpoint.rawValue) }
    }
    
    var apiKey: String {
        get { value(forKey: Keys.apiKey.rawValue) as? String ?? "" }
        set { setValue(newValue, forKey: Keys.apiKey.rawValue) }
    }
    
    var isAuthorizeObservable: Observable<Bool> {
        UserDefaults.standard.rx.observe(String.self, Keys.userId.rawValue)
            .map { $0 != nil }
    }
    
    var userId: String? {
        get {
            return value(forKey: Keys.userId.rawValue) as? String
        }

        set {
            if let value = newValue {
                setValue(value, forKey: Keys.userId.rawValue)
            } else {
                removeObject(forKey: Keys.userId.rawValue)
            }
        }
    }

    var lastConnectedPeripheralUUID: String? {
        get {
            return value(forKey: Keys.lastConnectedPeripheralUUID.rawValue) as? String
        }
        set {
            if let value = newValue {
                setValue(value, forKey: Keys.lastConnectedPeripheralUUID.rawValue)
            } else {
                removeObject(forKey: Keys.lastConnectedPeripheralUUID.rawValue)
                removeObject(forKey: Keys.firmwareVersion.rawValue)
            }
        }
    }
    
    var firmwareVersion: String? {
        get { value(forKey: Keys.firmwareVersion.rawValue) as? String }
        set { setValue(newValue, forKey: Keys.firmwareVersion.rawValue) }
    }
}
