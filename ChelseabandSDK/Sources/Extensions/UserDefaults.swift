//
//  UserDefaults.swift
//  ChelseabandSDK
//
//  Created by Sergey Pohrebnuak on 17.03.2021.
//

import Foundation

extension UserDefaults {
    // MARK: - Keys
    private enum Keys {
        static let pushToken: String = "pushTokenKey"
        static let lastConnectedPeripheralUUID: String = "lastConnectedPeripheralUUIDKey"
    }

    var pushToken: String? {
        get {
            return value(forKey: Keys.pushToken) as? String
        }

        set {
            if let value = newValue {
                setValue(value, forKey: Keys.pushToken)
            } else {
                removeObject(forKey: Keys.pushToken)
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
            }
        }
    }
}
