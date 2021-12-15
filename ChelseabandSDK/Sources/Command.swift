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

public protocol CommandNew: WritableCommand { //TODO: rename in future on PerformWriteCommandProtocol
    func perform(on executor: CommandExecutor) -> Observable<Void>
    func performAndObservNotify(on executor: CommandExecutor) -> Observable<Data>
}

public enum CommandNewError: LocalizedError {
    case performCommandNotImplemented
    case performAndObservCommandNotImplemented
    
    public var errorDescription: String? {
        switch self {
        case .performCommandNotImplemented:
            return "Perform command not implemented"
        case .performAndObservCommandNotImplemented:
            return "Perform and observ command not implemented"
        }
    }
}

public extension CommandNew {
    func perform(on executor: CommandExecutor) -> Observable<Void> {
        .error(CommandNewError.performCommandNotImplemented)
    }
    func performAndObservNotify(on executor: CommandExecutor) -> Observable<Data> {
        .error(CommandNewError.performAndObservCommandNotImplemented)
    }
}

public protocol PerformReadCommandProtocol: ReadableCommand {
    func performRead(on executor: CommandExecutor) -> Observable<Void>
}
