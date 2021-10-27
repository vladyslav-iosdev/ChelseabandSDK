//
//  VibrationCommandNew.swift
//  ChelseabandSDK
//
//  Created by Sergey Pohrebnuak on 03.09.2021.
//

import RxSwift

public enum VibrationError: LocalizedError {
    case cantDecodeDataToVibrationModel
    
    public var errorDescription: String? {
        switch self {
        case .cantDecodeDataToVibrationModel:
            return "Cant decode data to vibration model"
        }
    }
}

public struct VibrationCommandNew: CommandNew {
    public let uuidForWrite = ChelseabandConfiguration.default.vibrationCharacteristic

    public var dataForSend: Data {
        vibrationPattern.encodeToData()
    }
    
    private let vibrationPattern: VibrationPattern
    
    init(fromData data: Data, withDecoder decoder: JSONDecoder) throws {
        if let ledModel = try? decoder.decode(VibrationPattern.self, from: data) {
            vibrationPattern = ledModel
        } else {
            throw VibrationError.cantDecodeDataToVibrationModel
        }
    }
    
    public func perform(on executor: CommandExecutor) -> Observable<Void> {
        executor.write(command: self)
    }
}

extension VibrationCommandNew {
    private struct VibrationPattern: Decodable {
        let loopCount: UInt8
        let frames: [VibrationFrame] //Max count of array == 20!
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
    
    private struct VibrationFrame: Decodable {
        let time: UInt8 //How long to show colors for units: 12ms
        let intensity: UInt8 //How intense to run the motor, 0 - it's off
    }
}
