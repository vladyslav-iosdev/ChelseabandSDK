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
        return Data([0])
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
        
        struct LedFrame {
            let time: UInt8 //how long to show colors for units: 12ms
            let colors: [UInt8] //max count of color == 6!
            private let maxColorsCount = 6
            
            init(time: UInt8, colorForAllLed: UInt8) {
                self.time = time
                self.colors = Array(repeating: colorForAllLed, count: maxColorsCount)
            }
        }
    }
}
