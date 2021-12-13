//
//  NewsCommand.swift
//  ChelseabandSDK
//
//  Created by Vladyslav Shepitko on 17.12.2020.
//

import RxSwift

enum NewsCommandError: Error {
    case done
}

public class MessageCommand: Command {
    private var body: [MessagePartCommand]

    public init(value: String, messagePartPrefix: String = GoalCommand.prefix) {
        //NOTE: converted string into its hex, deviced by 16 cheracters in chunk
        let values = value.hex.components(length: 16)
        body = values.map { part -> MessagePartCommand in
            return MessagePartCommand(value: part, commandPrefix: messagePartPrefix)
        }
    }

    public func perform(on executor: CommandExecutor, notifyWith notifier: CommandNotifier) -> Observable<Void> {
        let triggerDisposable = notifier.notifyObservable
            .flatMap { data -> Observable<Void> in
                if self.body.isEmpty {
                    throw NewsCommandError.done
                } else {
                    let command = self.body.removeFirst()
                    return command.perform(on: executor, notifyWith: notifier)
                }
            }.catchError { e -> Observable<Void> in
                if case NewsCommandError.done = e {
                    return EndMessageCommand().perform(on: executor, notifyWith: notifier)
                } else {
                    throw e
                }
            }
            .ignoreElements()
            .asObservable()

        let performanceObservable = StartMessageCommand().perform(on: executor, notifyWith: notifier)
            .ignoreElements()
            .asObservable()

        return Observable.zip(
            performanceObservable,
            triggerDisposable
        )
        .mapToVoid()
    }

    deinit {
        print("\(self)-deinit")
    }
}

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
