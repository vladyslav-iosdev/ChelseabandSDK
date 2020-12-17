//
//  TimeCommand.swift
//  ChelseabandSDK
//
//  Created by Vladyslav Shepitko on 17.12.2020.
//

import RxSwift

public class TimeCommand: Command {

    private static let trigger = "00fb0101"

    private var hex: String {
        let time = Date().timeIntervalSince1970.data.hex
        return "008808\(time)00000000" + time.xor
    }

    init() {
        //no op
    }

    public func perform(on executor: CommandExecutor, notifyWith notifier: CommandNotifier) -> Observable<Void> {
        return Observable.create { [weak self] seal -> Disposable in
            guard let strongSelf = self else {
                seal.onError(RxError.unknown)

                return Disposables.create()
            }

            let triggerObservable = notifier
                .notifyObservable
                .filter { $0.hex.starts(with: TimeCommand.trigger) }
                .debug("\(strongSelf)-trigget")
                .flatMap { data -> Observable<Void> in
                    let command = HexCommand(hex: strongSelf.hex)
                    print("\(strongSelf)-write: \(command.hex)")
                    return command.perform(on: executor, notifyWith: notifier)
                }
                .debug("\(strongSelf)-action")
                .subscribe(seal)

            return Disposables.create {
                triggerObservable.dispose()
            }
        }
    }

    /*
    public func perform(on executor: CommandExecutor, notifyWith notifier: CommandNotifier) -> Observable<Void> {
        return Observable.create { seal -> Disposable in

            let timerObservable = Observable<Int>.interval(.seconds(2), scheduler: MainScheduler.instance)
                .withLatestFrom(executor.isConnected)
                .filter { $0 }
                .debug("\(self)-trigger")
                .flatMap { _ -> Observable<Void> in
                    let time = "0""\(Date().timeIntervalSince1970)"
                    let command = HexCommand(hex: TimeCommand.prefix + time.hex + TimeCommand.suffix + time.xor)
                    print("\(self)-write: \(command.hex)")
                    return command.perform(on: executor, notifyWith: notifier)
                        .debug("\(self)-write")
                }.debug("t-t")
                .subscribe()

            let time = "0"//"\(Date().timeIntervalSince1970)"
            let command = HexCommand(hex: TimeCommand.prefix + time.hex + TimeCommand.suffix + time.xor)
            print("\(self)-initial write: \(command.hex)")

            let initialWrite = command.perform(on: executor, notifyWith: notifier)
                .debug("\(self)-initial write")
                .subscribe()

            return Disposables.create {
                initialWrite.dispose()
                timerObservable.dispose()
            }
        }
    }*/
}
