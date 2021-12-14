//
//  VibrationPatternType.swift
//  ChelseabandSDK
//
//  Created by Sergey Pohrebnuak on 14.12.2021.
//

import Foundation

public protocol VibrationPatternType {
    var loopCount: UInt8 { get }
    var frames: [VibrationFrameType] { get } //Max count of array == 20!
    func encodeToData() -> Data
}

public protocol VibrationFrameType {
    var time: UInt8 { get } //How long to show colors for units: 12ms
    var intensity: UInt8 { get } //How intense to run the motor, 0 - it's off
    func encodeToData() -> Data
}
