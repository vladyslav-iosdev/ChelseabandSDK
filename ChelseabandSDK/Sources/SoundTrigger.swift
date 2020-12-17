//
//  SoundTrigger.swift
//  ChelseabandSDK
//
//  Created by Vladyslav Shepitko on 07.12.2020.
//

import Foundation

public enum SoundTrigger: Int, CustomStringConvertible, CaseIterable {
    case goal = 1
    case news
    case gesture

    public var description: String {
        String(rawValue)
    }

    public var title: String {
        switch self {
        case .goal:
            return "Goal Alert Sound"
        case .news:
            return "News Alert Sound"
        case .gesture:
            return "Gesture Sound"
        }
    }
}
