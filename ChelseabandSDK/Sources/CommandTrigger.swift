//
//  CommandTrigger.swift
//  ChelseabandSDK
//
//  Created by Vladyslav Shepitko on 07.12.2020.
//

import Foundation

public enum CommandTrigger: String, CaseIterable {
    case promo
    case news
    case vote

    var hex: String {
        switch self {
        case .promo:
            return "01"
        case .news:
            return "02"
        case .vote:
            return "03"
        }
    }
}
