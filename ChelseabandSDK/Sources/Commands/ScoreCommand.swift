//
//  ScoreCommand.swift
//  ChelseabandSDK
//
//  Created by Sergey Pohrebnuak on 01.12.2021.
//

import RxSwift

public enum ScoreError: LocalizedError {
    case cantDecodeDataToScoreModel
    case scoreDataIsEmpty
    case scoreDataIsNull
    
    public var errorDescription: String? {
        switch self {
        case .cantDecodeDataToScoreModel:
            return "Cant decode data to Score model"
        case .scoreDataIsEmpty:
            return "Score data is empty"
        case .scoreDataIsNull:
            return "Score data is null"
        }
    }
}

public struct ScoreCommand: PerformableWriteCommand {
    
    public let commandUUID = ChelseabandConfiguration.default.scoreCharacteristic
    
    public var dataForSend: Data { scoreModel.encodeToData() }
    
    private let scoreModel: ScoreModelType
    
    init(fromData data: Data, withDecoder decoder: JSONDecoder) throws {
        guard !data.isEmpty else { throw ScoreError.scoreDataIsEmpty }
        
        if let scoreModel = try? decoder.decode(ScoreModel.self, from: data) {
            self.scoreModel = scoreModel
        } else {
            throw ScoreError.cantDecodeDataToScoreModel
        }
    }
    
    init(scoreModel: ScoreModelType) {
        self.scoreModel = scoreModel
    }
    
    public func perform(on executor: CommandExecutor) -> Observable<Void> {
        executor.write(command: self)
    }
}

extension ScoreCommand {
    private struct ScoreModel: ScoreModelType, Decodable {
        let wakeUpScreen: UInt8
        let titleType: UInt8
        let opposingTeamID: UInt8 = 0 //TODO: change in future on real opposing team id
        let time: UInt16
        let title: String
        private var nullTerminatedTitle: String {
            title + "\0"
        }
        let body: String?
        private var nullTerminatedBody: String? {
            if let body = body {
                return body + "\0"
            }
            return nil
        }
        
        func encodeToData() -> Data {
            var resultData = Data([wakeUpScreen, titleType])
            resultData.append(time.data)
            resultData.append(Data([opposingTeamID]))
            resultData.append(nullTerminatedTitle.uppercased().data(using: .utf8) ?? Data()) //NOTE: band ignore lowercase symbols
            resultData.append(nullTerminatedBody?.uppercased().data(using: .utf8) ?? Data()) //NOTE: band ignore lowercase symbols
            
            return resultData
        }
    }
}
