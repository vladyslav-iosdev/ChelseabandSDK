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

    func write(data: Data) -> Observable<Void>
    func write(command: WritableCommand) -> Observable<Void>
    func read(command: ReadableCommand) -> Observable<Data?>
}

public protocol CommandNotifier { //TODO: remove in future
    var notifyObservable: Observable<Data> { get }
}

public protocol GeneralCommand { //TODO: rename in future on command
    var uuidForWrite: ID { get } //TODO: rename in future on commandUUID
}

public protocol WritableCommand: GeneralCommand {
    var dataForSend: Data { get }
    var writeType: CBCharacteristicWriteType { get }
}

public protocol ReadableCommand: GeneralCommand {
    
}

public extension WritableCommand {
    var writeType: CBCharacteristicWriteType {
        .withResponse
    }
}

public protocol CommandNew: WritableCommand { //TODO: rename in future on PerformWriteCommandProtocol
    func perform(on executor: CommandExecutor) -> Observable<Void>
}

public protocol PerformReadCommandProtocol: ReadableCommand {
    func performRead(on executor: CommandExecutor) -> Observable<Void>
}

public protocol Command { //TODO: remove in future
    func perform(on executor: CommandExecutor, notifyWith notifier: CommandNotifier) -> Observable<Void>
}
