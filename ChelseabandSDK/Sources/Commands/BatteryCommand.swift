//
//  BatteryCommand.swift
//  ChelseabandSDK
//
//  Created by Vladyslav Shepitko on 17.12.2020.
//

import RxSwift
import UIKit
public enum BatteryLevel: UInt64, CustomStringConvertible {
    case full
    case middleUp //Rename
    case middle
    case low
    case empty

    public init(value: UInt64) {
        if value <= 10 {
            self = .empty
        } else if value <= 25 {
            self = .low
        } else if value <= 50 {
            self = .middle
        } else if value <= 75 {
            self = .middleUp
        } else {
            self = .full
        }
    }

    public var description: String {
        switch self {
        case .full:
            return "Full"
        case .middleUp:
            return "SS"
        case .middle:
            return "Middle"
        case .low:
            return "Low"
        case .empty:
            return "Empty"
        }
    }
}

class BatteryCommand: Command {
    
    private enum Keys {
        static let lastBatteryValue: String = "lastBatteryValueKey"
    }

    public let batteryLevel: BehaviorSubject<UInt64>

    private static let prefix = "00f70101"
    private static let suffix = "01"

    private let command = HexCommand(hex: BatteryCommand.prefix + BatteryCommand.suffix)
    private let defaults: UserDefaults = .standard

    public init() {
        if let value = defaults.value(forKey: Keys.lastBatteryValue) as? UInt64 {
            batteryLevel = .init(value: value)
        } else {
            batteryLevel = .init(value: 0)
        }
    }

    func perform(on executor: CommandExecutor, notifyWith notifier: CommandNotifier) -> Observable<Void> {
        return Observable.create { seal -> Disposable in

            let timerObservable = Observable<Int>.interval(.seconds(5), scheduler: MainScheduler.instance)
                .withLatestFrom(executor.isConnected)
                .filter { $0 }
                .debug("\(self)-trigget")
                .flatMap { _ -> Observable<Void> in
                    return self.command.perform(on: executor, notifyWith: notifier)
                        .debug("\(self)-write")
                }.subscribe()

            let batteryLevelDisposable = notifier
                .notifyObservable
                .compactMap { data -> UInt64? in
                    let commandSize = BatteryCommand.prefix.count
                    if data.hex.starts(with: BatteryCommand.prefix) && data.hex.count >= commandSize + 2 {
                        return data.hex[commandSize ..< commandSize + 2].valueFromHex
                    } else {
                        return nil
                    }
                }
                .debug("\(self)-read")
                .subscribe(onNext: { value in
                    self.batteryLevel.onNext(value)
                    self.defaults.set(value, forKey: Keys.lastBatteryValue)
                })

            let initialWrite = self.command.perform(on: executor, notifyWith: notifier)
                .debug("\(self)-write.initial")
                .subscribe()

            return Disposables.create {
                initialWrite.dispose()
                timerObservable.dispose()
                batteryLevelDisposable.dispose()
            }
        }
    }

    deinit {
        print("\(self)-deinit")
    }
}
