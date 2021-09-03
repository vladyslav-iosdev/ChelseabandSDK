//
//  VibrationCommandNew.swift
//  ChelseabandSDK
//
//  Created by Sergey Pohrebnuak on 03.09.2021.
//

import RxSwift

public struct VibrationCommandNew: CommandNew {
    public let uuidForWrite = ChelseabandConfiguration.default.vibrationCharacteristic

    public var dataForSend: Data {
        VibrationPattern(loopCount: 2, frames: [
            .init(time: 20, intensity: 255),
            .init(time: 10, intensity: 0)
        ]).encodeToData()
    }
    
    public func perform(on executor: CommandExecutor) -> Observable<Void> {
        executor.write(command: self)
    }
}

extension VibrationCommandNew {
    private struct VibrationPattern {
        let loopCount: UInt8
        let frames: [VibrationFrame] //max count of array == 20!
        private let maxFramesCount = 20
        
        func encodeToData() -> Data {
            var bytesArray = [loopCount]
            var mutatingFrames = frames
            mutatingFrames.removeLast(max(0, frames.count - maxFramesCount))
            mutatingFrames.forEach {
                bytesArray.append($0.time)
                bytesArray.append($0.intensity)
            }
            
            return Data(bytesArray)
        }
    }
    
    private struct VibrationFrame {
        let time: UInt8 //how long to show colors for units: 10ms
        let intensity: UInt8 //How intense to run the motor, 0 - it's off
    }
}
