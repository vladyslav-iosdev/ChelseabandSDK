//
//  LEDCommandNew.swift
//  ChelseabandSDK
//
//  Created by Sergey Pohrebnuak on 03.09.2021.
//

import RxSwift

public struct LEDCommandNew: CommandNew {
    public let uuidForWrite = ChelseabandConfiguration.default.ledCharacteristic

    public var dataForSend: Data {
        LedPattern(loopCount: 1, frames: [LedFrame(time: 16, colorForAllLed: LedColor(red: 255, green: 0, blue: 0))]).encodeToData()
    }
    
    public func perform(on executor: CommandExecutor) -> Observable<Void> {
        executor.write(command: self)
    }
}

extension LEDCommandNew {
    private struct LedPattern {
        let loopCount: UInt8
        let frames: [LedFrame] //max count of array == 13!
        private let maxFramesCount = 13
        
        func encodeToData() -> Data {
            var bytesArray = [loopCount]
            var mutatingFrames = frames
            mutatingFrames.removeLast(max(0, frames.count - maxFramesCount))
            mutatingFrames.forEach { bytesArray.append(contentsOf: $0.encodeToData()) }
            
            return Data(bytesArray)
        }
    }
    
    private struct LedFrame {
        let time: UInt8 //how long to show colors for units: 12ms
        let colors: [LedColor] //max count of color == 6!
        private let maxColorsCount = 6
        
        init(time: UInt8, colorForAllLed: LedColor) {
            self.time = time
            self.colors = Array(repeating: colorForAllLed, count: maxColorsCount)
        }
        
        func encodeToData() -> [UInt8] {
            var bytesArray = [time]
            var mutatingColors = colors
            mutatingColors.removeLast(max(0, mutatingColors.count - maxColorsCount))
            mutatingColors.forEach { bytesArray.append(contentsOf: $0.likeArray) }
            
            return bytesArray
        }
    }
    
    private struct LedColor {
        let red: UInt8
        let green: UInt8
        let blue: UInt8
        
        var likeArray: [UInt8] {
            [red, green, blue]
        }
    }
}
