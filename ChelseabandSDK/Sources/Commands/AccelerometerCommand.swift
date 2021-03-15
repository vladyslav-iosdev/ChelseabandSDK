//
//  AccelerometerCommand.swift
//  ChelseabandSDK
//
//  Created by Vladyslav Shepitko on 06.03.2021.
//

import RxSwift
import Foundation

public struct AXIS {
    let x, y, z: Double
}

public class AccelerometerCommand: Command {

    private static let prefix: String = "00F8"

    public var axisObservable: Observable<AXIS> {
        return axisPublishSubject.asObservable()
    }

    private var axisPublishSubject: PublishSubject<AXIS>

    public init() {
        axisPublishSubject = PublishSubject<AXIS>()
    }

//    private static let prefix = "00f70101"
//    private static let suffix = "01"

    private static func value(from data: Data) -> UInt64? {
//        let prefixSize = AccelerometerCommand.prefix.count
//        if data.hex.starts(with: AccelerometerCommand.prefix) && data.hex.count >= prefixSize + 2 {
//            //NOTE: (prefixSize + 1) : header + one byte for command length
//            // (data.hex.count - 2) : `-2` drop last check byte
//            return data.hex[prefixSize + 1 ..< data.hex.count - 2].valueFromHex
//        } else {
            return nil
//        }
    }

    public func perform(on executor: CommandExecutor, notifyWith notifier: CommandNotifier) -> Observable<Void> {
        return Observable.create { seal -> Disposable in
            let perfomanceDisposable = notifier
                .notifyObservable
                .filter { $0.hex.starts(with: AccelerometerCommand.prefix) && $0.bytes.count >= 4 }
                .debug("\(self)-trigget")
                //??
//                .compactMap { guard $0.bytes[3] == 1 else { throw CommandError.invalid } }
//                .debug("\(self).read")
                .subscribe(onNext: { _ in
//                    seal.onNext(())
//
//                    seal.onCompleted()
                }, onError: { error in
//                    seal.onError(error)
//
//                    seal.onCompleted()
                })

//            let command = self.command.perform(on: executor, notifyWith: notifier)
//                .debug("\(self).write.initial")
//                .subscribe()

            return Disposables.create {
//                command.dispose()
                perfomanceDisposable.dispose()
            }
        }
    }

    deinit {
        print("\(self)-deinit")
    }
}
