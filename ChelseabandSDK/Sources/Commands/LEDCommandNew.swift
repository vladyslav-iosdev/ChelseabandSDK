//
//  LEDCommandNew.swift
//  ChelseabandSDK
//
//  Created by Sergey Pohrebnuak on 13.12.2021.
//

import RxSwift

public enum LedError: LocalizedError {
    case cantDecodeDataToLedModel
    
    public var errorDescription: String? {
        switch self {
        case .cantDecodeDataToLedModel:
            return "Cant decode data to led model"
        }
    }
}

public struct LEDCommandNew: CommandNew {
    public let commandUUID = ChelseabandConfiguration.default.ledCharacteristic

    public var dataForSend: Data { ledPattern.encodeToData() }
    
    private let ledPattern: LedPatternType
    
    init(fromData data: Data, withDecoder decoder: JSONDecoder) throws {
        if let ledModel = try? decoder.decode(LedPattern.self, from: data) {
            ledPattern = ledModel
        } else {
            throw LedError.cantDecodeDataToLedModel
        }
    }
    
    public init(ledPattern: LedPatternType) {
        self.ledPattern = ledPattern
    }
    
    public func perform(on executor: CommandExecutor) -> Observable<Void> {
        executor.write(command: self)
    }
}

extension LEDCommandNew {
    private struct LedPattern: LedPatternType, Decodable {
        let loopCount: UInt8
        let frames: [LedFrameType]
        private let maxFramesCount = 13
        
        func encodeToData() -> Data {
            var bytesArray = [loopCount]
            var mutatingFrames = frames
            mutatingFrames.removeLast(max(0, frames.count - maxFramesCount))
            mutatingFrames.forEach { bytesArray.append(contentsOf: $0.encodeToData()) }
            
            return Data(bytesArray)
        }
        
        // MARK: Decoding
        enum CodingKeys: String, CodingKey {
            case loopCount
            case frames
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            loopCount = try container.decode(UInt8.self, forKey: .loopCount)
            frames = try container.decode([LedFrame].self, forKey: .frames)
        }
    }
    
    private struct LedFrame: LedFrameType, Decodable {
        let time: UInt8
        let colors: [LedColorType]
        private let maxColorsCount = 6
        
        init(time: UInt8, colorForAllLed: LedColor) {
            self.time = time
            self.colors = Array(repeating: colorForAllLed, count: maxColorsCount)
        }
        
        func encodeToData() -> Data {
            var resultData = Data([time])
            var mutatingColors = colors
            mutatingColors.removeLast(max(0, mutatingColors.count - maxColorsCount))
            mutatingColors.forEach { resultData.append(contentsOf: $0.encodeToData()) }
            
            return resultData
        }
        
        // MARK: Decoding
        enum CodingKeys: String, CodingKey {
            case time
            case colors
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            time = try container.decode(UInt8.self, forKey: .time)
            colors = try container.decode([LedColor].self, forKey: .colors)
        }
    }
    
    private struct LedColor: LedColorType, Decodable {
        let red: UInt8
        let green: UInt8
        let blue: UInt8
        
        func encodeToData() -> Data {
            Data([red, green, blue])
        }
    }
}
