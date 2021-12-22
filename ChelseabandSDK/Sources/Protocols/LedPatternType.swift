//
//  LedPatternType.swift
//  ChelseabandSDK
//
//  Created by Sergey Pohrebnuak on 13.12.2021.
//

import Foundation

public protocol LedPatternType {
    var loopCount: UInt8 { get }
    var frames: [LedFrameType] { get } //Max count of array == 13!
    func encodeToData() -> Data
}

public protocol LedFrameType {
    var time: UInt8 { get } //How long to show colors for units: 12ms
    var colors: [LedColorType] { get } //Max count of color == 6!
    func encodeToData() -> Data
}

public protocol LedColorType {
    var red: UInt8 { get }
    var green: UInt8 { get }
    var blue: UInt8{ get }
    func encodeToData() -> Data
}
