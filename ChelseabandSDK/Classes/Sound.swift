//
//  Sound.swift
//  ChelseabandSDK
//
//  Created by Vladyslav Shepitko on 07.12.2020.
//

import Foundation

public enum Sound: String, CaseIterable {
    case one = "01"
    case two = "02"
    case three = "03"
    case off = "00"

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
}
