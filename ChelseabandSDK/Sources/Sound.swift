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

    public var title: String {
        switch self {
        case .one:
            return "Gool"
        case .two:
            return "Ole Ole Ole"
        case .three:
            return "Vuvuzella horn"
        case .off:
            return "Off"
        }
    }

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
