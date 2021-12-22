//
//  CLAuthorizationStatus.swift
//  ChelseabandSDK
//
//  Created by Sergey Pohrebnuak on 20.12.2021.
//

import CoreLocation

extension CLAuthorizationStatus {
    var canObserve: Bool {
        switch self {
        case .notDetermined, .denied, .restricted:
            return false
        case .authorizedAlways, .authorizedWhenInUse:
            return true
        }
    }
}
