//
//  Sound.swift
//  ChelseabandSDK
//
//  Created by Vladyslav Shepitko on 07.12.2020.
//

import Foundation

public enum Sound: String, CaseIterable {
    case one
    case two
    case three
    case off

    var hex: String {
        switch self {
        case .one:
            return "01"
        case .two:
            return "02"
        case .three:
            return "03"
        case .off:
            return "00"
        }
    }
}
