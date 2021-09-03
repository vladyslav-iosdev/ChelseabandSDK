//
//  Command.swift
//  ChelseabandSDK
//
//  Created by Vladyslav Shepitko on 24.11.2020.
//

import Foundation
import RxSwift

public protocol CommandExecutor {
    var isConnected: Observable<Bool> { get }

    func write(data: Data) -> Observable<Void>
    func write(command: WritableCommand) -> Observable<Void>
}

public protocol CommandNotifier {
    var notifyObservable: Observable<Data> { get }
}

public protocol WritableCommand {
    var uuidForWrite: ID { get }
    var dataForSend: Data { get }
}

public protocol CommandNew: WritableCommand {
    func perform(on executor: CommandExecutor) -> Observable<Void>
}

public protocol Command {
    func perform(on executor: CommandExecutor, notifyWith notifier: CommandNotifier) -> Observable<Void>
}
