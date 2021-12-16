//
//  PollCommand.swift
//  ChelseabandSDK
//
//  Created by Sergey Pohrebnuak on 03.12.2021.
//

import RxSwift

public enum PollCommandError: LocalizedError {
    case pollQuestionCantBeEmpty
    case pollAnswersNotInRange
    case cantDecodePollCommandToData
    case commandIsBig
    case writeCommandTimeOut
    case wrongDataInResponse
    case timeoutOfReceiveAnswer
    case cantDecodeEndOfPoll
    
    public var errorDescription: String? {
        switch self {
        case .pollQuestionCantBeEmpty:
            return "Poll question can't be empty"
        case .pollAnswersNotInRange:
            return "Poll answers should be in range from 2 to 10 (2 minimum and 10 is maximum)"
        case .cantDecodePollCommandToData:
            return "Can't decode poll command to data"
        case .commandIsBig:
            return "Command is big. It should be equal or less then 100 bytes"
        case .writeCommandTimeOut:
            return "Poll command didn't sent to the band. Time out."
        case .wrongDataInResponse:
            return "Wrong data in poll command response"
        case .timeoutOfReceiveAnswer:
            return "Time out of receive poll command answer"
        case .cantDecodeEndOfPoll:
            return "Cant decode end of poll command"
        }
    }
}

public struct PollCommand: PerformableWriteCommand {
    
    public var commandUUID = ChelseabandConfiguration.default.pollCharacteristic
    
    public var dataForSend: Data
    
    public func performAndObserveNotify(on executor: CommandExecutor) -> Observable<Data> {
        executor.writeAndObservNotify(command: self)
            .mapTimeoutError(to: PollCommandError.writeCommandTimeOut)
            .map { data -> Data in
                guard let stringAnswer = String(data: data, encoding: .utf8) else {
                    throw PollCommandError.wrongDataInResponse
                }
                
                let clearStringAnswer = stringAnswer.removeNullTerminated()
                return clearStringAnswer.data(using: .utf8) ?? Data()
            }
            .take(1)
            .timeout(.seconds(60), scheduler: MainScheduler.instance)
            .mapTimeoutError(to: PollCommandError.timeoutOfReceiveAnswer)
    }
    
    public func perform(on executor: CommandExecutor) -> Observable<Void> {
        executor.write(command: self)
    }
    
    init(pollText: String, pollAnswers: [String]) throws {
        let separator = "\n"
        let endOfCommand = "\0"
        let availableCountOfAnswers = Range(2...10)
        guard !pollText.isEmpty else { throw PollCommandError.pollQuestionCantBeEmpty }
        guard availableCountOfAnswers.contains(pollAnswers.count)   else { throw PollCommandError.pollAnswersNotInRange }
        
        var textArray = [pollText]
        textArray.append(contentsOf: pollAnswers)
        textArray = textArray.map { $0.uppercased() }
        
        let resultString = textArray.joined(separator: separator) + endOfCommand
        
        guard let resultData = resultString.data(using: .utf8) else {
            throw PollCommandError.cantDecodePollCommandToData
        }
        
        if resultData.count > 100  {
            throw PollCommandError.commandIsBig
        }
    
        dataForSend = resultData
    }
    
    //NOTE: End poll
    init() throws {
        if let data = "\0".data(using: .utf8) {
            dataForSend = data
        } else {
            throw PollCommandError.cantDecodeEndOfPoll
        }
    }
}
