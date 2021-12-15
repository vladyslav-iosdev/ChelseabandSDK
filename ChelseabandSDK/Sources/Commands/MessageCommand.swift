//
//  NewsCommand.swift
//  ChelseabandSDK
//
//  Created by Vladyslav Shepitko on 17.12.2020.
//

import RxSwift

public enum MessageCommandError: LocalizedError {
    case messageIsEmpty
    case cantDecodeMessageToData
    
    public var errorDescription: String? {
        switch self {
        case .messageIsEmpty:
            return "Message is empty"
        case .cantDecodeMessageToData:
            return "Cant decode message to data"
        }
    }
}

public protocol MessageType {
    var messageTypeIdentifier: UInt8 { get }
}

public struct MessageCommandNew: CommandNew {
    public let uuidForWrite = ChelseabandConfiguration.default.alertCharacteristic

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
        
        dataForSend = type.messageTypeIdentifier.data + messageData
    }
    
    public func perform(on executor: CommandExecutor) -> Observable<Void> {
        executor.write(command: self)
    }
}
