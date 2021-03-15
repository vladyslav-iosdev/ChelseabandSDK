//
//  Screen.swift
//  ChelseabandSDK
//
//  Created by Vladyslav Shepitko on 06.03.2021.
//

import Foundation

public enum Screen {
    case main
    case news
    case goal
    case mac
    case vote
    case voteSent

    var hex: String {
        switch self {
        case .main:
            return "00"
        case .news:
            return "01"
        case .goal:
            return "02"
        case .mac:
            return "03"
        case .vote:
            return "04"
        case .voteSent:
            return "05"
        }
    }
} 
