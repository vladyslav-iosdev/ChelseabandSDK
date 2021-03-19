//
//  CommandTrigger.swift
//  ChelseabandSDK
//
//  Created by Vladyslav Shepitko on 07.12.2020.
//

import Foundation

public enum CommandTrigger: String, CaseIterable {
    case goal
    case news
    case gesture

    var hex: String {
        switch self {
        case .goal:
            return "01"
        case .news:
            return "02"
        case .gesture:
            return "03"
        }
    }
}
