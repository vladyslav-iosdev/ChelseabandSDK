//
//  Vibration.swift
//  ChelseabandSDK
//
//  Created by Vladyslav Shepitko on 07.12.2020.
//

import Foundation

public enum Vibration: String {
    case on = "0100"
    case off = "0000"

    public init(_ value: Bool) {
        switch value {
        case true:
            self = .on
        case false:
            self = .off
        }
    }
}
