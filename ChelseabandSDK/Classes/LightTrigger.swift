//
//  LightTrigger.swift
//  ChelseabandSDK
//
//  Created by Vladyslav Shepitko on 07.12.2020.
//

import Foundation

public enum LightTrigger: String, CaseIterable {
    case goal
    case news

    public var title: String {
        switch self {
        case .goal:
            return "Goal Alerts"
        case .news:
            return "News Alerts"
        }
    }
}

public extension Array where Element == LightTrigger {
    var toLightCommand: String {
        if contains(.goal) && contains(.news) {
            return "03"
        } else if contains(.news) {
            return "02"
        } else if contains(.goal) {
            return "01"
        } else {
            return "00"
        }
    }
}
