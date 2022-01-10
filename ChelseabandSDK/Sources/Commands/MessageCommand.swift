//
//  MessageCommand.swift
//  ChelseabandSDK
//
//  Created by Vladyslav Shepitko on 17.12.2020.
//

import RxSwift

public enum MessageCommandError: LocalizedError {
    case messageIsEmpty
    case cantDecodeMessageToData
    case messageIsLong
    
    public var errorDescription: String? {
        switch self {
        case .messageIsEmpty:
            return "Message is empty"
        case .cantDecodeMessageToData:
            return "Cant decode message to data"
        case .messageIsLong:
            return "Message is long. Maximum length of message is 98 symbols"
        }
    }
}

public protocol MessageType {
    var messageTypeIdentifier: UInt8 { get }
}

public struct MessageCommand: PerformableWriteCommand {
    public let commandUUID = ChelseabandConfiguration.default.alertCharacteristic

    public var dataForSend: Data
    
    init(_ message: String, type: MessageType) throws {
        guard !message.isEmpty else {
            throw MessageCommandError.messageIsEmpty
        }
        
        let nullTerminatedMessage = message + "\0"
        //NOTE: band ignore lowercase symbols
        guard let messageData = nullTerminatedMessage.uppercased().data(using: .utf8) else {
            throw MessageCommandError.cantDecodeMessageToData
        }
        //NOTE: 99 it's maximum of message length
        guard messageData.count <= 99 else { throw MessageCommandError.messageIsLong }
        
        dataForSend = type.messageTypeIdentifier.data + messageData
    }
    
    public func perform(on executor: CommandExecutor) -> Observable<Void> {
        executor.write(command: self)
    }
}
