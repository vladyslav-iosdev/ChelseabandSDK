//
//  AlertType.swift
//  ChelseabandSDK_Example
//
//  Created by Vladyslav Shepitko on 03.12.2020.
//  Copyright © 2020 Sonerim. All rights reserved.
//

import UIKit

enum AlertType: CaseIterable {
    case goal
    case news

    var title: String {
        switch self {
        case .goal:
            return "Goal Alerts"
        case .news:
            return "News Alerts"
        }
    }
}
