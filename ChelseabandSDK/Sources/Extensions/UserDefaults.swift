//
//  UserDefaults.swift
//  ChelseabandSDK
//
//  Created by Sergey Pohrebnuak on 17.03.2021.
//

import Foundation

extension UserDefaults {
    // MARK: - Keys
    private enum Key: String {
        case pushToken
    }
    
    // MARK: Syntax sugar
    func removeToken() {
        removeObject(forKey: Key.pushToken.rawValue)
        synchronize()
    }
    
    func save(token: String) {
        set(token, forKey: Key.pushToken.rawValue)
        synchronize()
    }
    
    func getToken() -> String? {
        object(forKey: Key.pushToken.rawValue) as? String
    }
}
