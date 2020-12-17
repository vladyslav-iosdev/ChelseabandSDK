//
//  DefaultConfiguration.swift
//  ChelseabandSDK_Example
//
//  Created by Vladyslav Shepitko on 24.11.2020.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import Foundation
import ChelseabandSDK

enum ChelseabandConfiguration: Configuration {
    case initial

    public var service: ID {
        switch self {
        case .initial:
            return ID(string: "00000001-0000-1000-8000-00805f9b34fb")
        }
    }

    public var writeCharacteristic: ID {
        switch self {
        case .initial:
            return ID(string: "00000002-0000-1000-8000-00805f9b34fb")
        }
    }

    public var readCharacteristic: ID {
        switch self {
        case .initial:
            return ID(string: "00000003-0000-1000-8000-00805f9b34fb")
        }
    }
}
