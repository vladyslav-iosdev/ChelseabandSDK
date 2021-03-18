//
//  BatteryCommand.swift
//  ChelseabandSDK
//
//  Created by Vladyslav Shepitko on 17.12.2020.
//

import RxSwift
import Foundation

public enum BatteryLevel: UInt64 {
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
}

class BatteryCommand: Command {
    
    private enum Keys {
        static let lastBatteryValue: String = "lastBatteryValueKey"
    }

    public let batteryLevel: BehaviorSubject<UInt64>

    private static let prefix = "00f7"
    private static let hex = prefix + "01" + "01"
    private static let suffix = "01"

    private let defaults: UserDefaults = .standard
    private let interval: DispatchTimeInterval

    public init(interval: DispatchTimeInterval = .seconds(15)) {
        self.interval = interval
        
        if let value = defaults.value(forKey: Keys.lastBatteryValue) as? UInt64 {
            batteryLevel = .init(value: value)
        } else {
            batteryLevel = .init(value: 0)
        }
        print("\(self).init")
    }

    private func batteryLevelValue(from data: Data) -> UInt64? {
        let commandSize = BatteryCommand.hex.count
        if data.hex.starts(with: BatteryCommand.hex) && data.hex.count >= commandSize + 2 {
            return data.hex[commandSize ..< commandSize + 2].valueFromHex
        } else {
            return nil
        }
    }

    func perform(on executor: CommandExecutor, notifyWith notifier: CommandNotifier) -> Observable<Void> {
        return Observable.create { seal -> Disposable in

            let timerObservable = Observable<Int>
                .interval(self.interval, scheduler: MainScheduler.instance)
                .flatMap { _ in
                    BatteryHexCommand(hex: BatteryCommand.hex)
                        .perform(on: executor, notifyWith: notifier)
                        .debug("\(self).write")
                }
                .subscribe()

            let batteryLevelDisposable = notifier
                .notifyObservable
                .compactMap { self.batteryLevelValue(from: $0) }
                .debug("\(self).read")
                .subscribe(onNext: { value in
                    print("\(self).read.value: \(value)")
                    self.batteryLevel.onNext(value)
                    self.defaults.set(value, forKey: Keys.lastBatteryValue)
                })

            let initialWrite = BatteryHexCommand(hex: BatteryCommand.hex)
                .perform(on: executor, notifyWith: notifier)
                .debug("\(self).write.initial")
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

private extension BatteryCommand {
    class BatteryHexCommand: Command {
        private let command: HexCommand

        init(hex: String) {
            command = HexCommand(hex: hex)
        }

        func perform(on executor: CommandExecutor, notifyWith notifier: CommandNotifier) -> Observable<Void> {
            let completionObservable = notifier
                .notifyObservable
                .completeWhenByteEqualsToOne(hexStartWith: BatteryCommand.prefix)
                .debug("\(self)-trigget")

            let performanceObservable = command
                .perform(on: executor, notifyWith: notifier)
                .debug("\(self)-write")

            return Observable.zip(
                performanceObservable,
                completionObservable
            ).mapToVoid()
        }
    }
}
