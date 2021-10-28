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

public protocol MessageType {
    var messageTypeIdentifier: Int { get }
}

public extension MessageType where Self: RawRepresentable, RawValue == Int {
    var messageTypeIdentifier: Int { self.rawValue }
}

public struct MessageCommandNew: CommandNew {
    public let uuidForWrite = ChelseabandConfiguration.default.alertCharacteristic

    public var dataForSend: Data {
        messageType.messageTypeIdentifier.data +
        message.data(using: .utf8)! +
        "\0".data(using: .utf8)!
    }
    
    private let message: String
    private let messageType: MessageType
    
    init(_ message: String, type: MessageType) {
        self.message = message
        messageType = type
    }
    
    public func perform(on executor: CommandExecutor) -> Observable<Void> {
        executor.write(command: self)
    }
}
