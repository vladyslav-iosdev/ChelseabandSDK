//
//  HexCommand.swift
//  ChelseabandSDK
//
//  Created by Vladyslav Shepitko on 08.12.2020.
//

import RxSwift

enum CommandError: Error {
    case invalid
    case timeout
    case deviceDisconnected
}

public class HexCommand: Command {

    public let hex: String

    public init(hex: String) {
        self.hex = hex
    }

    public func perform(on executor: CommandExecutor, notifyWith notifier: CommandNotifier) -> Observable<Void> {
        guard let data = hex.uppercased().hexadecimal else {
            return .error(CommandError.invalid)
        }

        return Observable.create { seal -> Disposable in

            let writeDisposable = Observable<Void>.just(())
                .withLatestFrom(executor.isConnected)
                .map { isConnected -> Void in
                    if isConnected {
                        //no op
                    } else {
                        throw CommandError.deviceDisconnected
                    }
                }
                .flatMap { executor.write(data: data) }
                .debug("\(self).write")
                .subscribe { e in
                    seal.on(e)
                }

            return Disposables.create {
                writeDisposable.dispose()
            }
        }
    }

    deinit {
        print("\(self)-deinit")
    }
} 
