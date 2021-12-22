//
//  VibrationCommand.swift
//  ChelseabandSDK
//
//  Created by Sergey Pohrebnuak on 14.12.2021.
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

public struct VibrationCommand: PerformableWriteCommand {
    public let commandUUID = ChelseabandConfiguration.default.vibrationCharacteristic

    public var dataForSend: Data { vibrationPattern.encodeToData() }
    
    private let vibrationPattern: VibrationPatternType
    
    init(fromData data: Data, withDecoder decoder: JSONDecoder) throws {
        if let vibrationModel = try? decoder.decode(VibrationPattern.self, from: data) {
            vibrationPattern = vibrationModel
        } else {
            throw VibrationError.cantDecodeDataToVibrationModel
        }
    }
    
    public init(vibrationPattern: VibrationPatternType) {
        self.vibrationPattern = vibrationPattern
    }
    
    public func perform(on executor: CommandExecutor) -> Observable<Void> {
        executor.write(command: self)
    }
}

extension VibrationCommand {
    private struct VibrationPattern: VibrationPatternType, Decodable {
        let loopCount: UInt8
        let frames: [VibrationFrameType]
        private let maxFramesCount = 20
        
        func encodeToData() -> Data {
            var resultData = Data([loopCount])
            var mutatingFrames = frames
            mutatingFrames.removeLast(max(0, frames.count - maxFramesCount))
            mutatingFrames.forEach { resultData.append($0.encodeToData()) }
            
            return resultData
        }
        
        // MARK: Decoding
        enum CodingKeys: String, CodingKey {
            case loopCount
            case frames
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            loopCount = try container.decode(UInt8.self, forKey: .loopCount)
            frames = try container.decode([VibrationFrame].self, forKey: .frames)
        }
    }
    
    private struct VibrationFrame: VibrationFrameType, Decodable {
        let time: UInt8
        let intensity: UInt8
        
        func encodeToData() -> Data {
            Data([time, intensity])
        }
    }
}
