//
//  Command.swift
//  ChelseabandSDK
//
//  Created by Vladyslav Shepitko on 24.11.2020.
//

import Foundation
import RxSwift
import CoreBluetooth

public protocol CommandExecutor {
    var isConnected: Observable<Bool> { get }

    func write(command: WritableCommand) -> Observable<Void>
    func writeAndObservNotify(command: WritableCommand) -> Observable<Data>
    func read(command: ReadableCommand) -> Observable<Data?>
}

public protocol Command {
    var commandUUID: ID { get }
}

public protocol WritableCommand: Command {
    var dataForSend: Data { get }
    var writeType: CBCharacteristicWriteType { get }
}

public protocol ReadableCommand: Command {
    
}

public extension WritableCommand {
    var writeType: CBCharacteristicWriteType {
        .withResponse
    }
}
public typealias PerformableWriteCommand = CommandPerformer & WritableCommand

public protocol CommandPerformer {
    func perform(on executor: CommandExecutor) -> Observable<Void>
    func performAndObserveNotify(on executor: CommandExecutor) -> Observable<Data>
}

public enum CommandError: LocalizedError {
    case performCommandNotImplemented
    case performAndObserveCommandNotImplemented
    
    public var errorDescription: String? {
        switch self {
        case .performCommandNotImplemented:
            return "Perform command not implemented"
        case .performAndObserveCommandNotImplemented:
            return "Perform and observe command not implemented"
        }
    }
}

public extension CommandPerformer {
    func perform(on executor: CommandExecutor) -> Observable<Void> {
        .error(CommandError.performCommandNotImplemented)
    }
    func performAndObserveNotify(on executor: CommandExecutor) -> Observable<Data> {
        .error(CommandError.performAndObserveCommandNotImplemented)
    }
}

public protocol PerformReadCommandProtocol: ReadableCommand {
    func performRead(on executor: CommandExecutor) -> Observable<Void>
}
