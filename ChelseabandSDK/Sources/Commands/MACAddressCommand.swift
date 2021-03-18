//
//  MACAddressCommand.swift
//  ChelseabandSDK
//
//  Created by Vladyslav Shepitko on 17.03.2021.
//

import RxSwift
import Foundation

public class MACAddressCommand: Command {
    private enum Keys {
        static let lastMACAddressValue: String = "lastMACAddressValueKey"
    }

    private static let prefix = "00f2"
    private static let perfomanceTrigger = "00fb0101"

    private var hex: String {
        return MACAddressCommand.prefix + "01" + "01" + "01".xor
    }
    private let defaults: UserDefaults = .standard

    public var MACAddressObservable: Observable<String> {
        MACAddressBehaviourSubject
            .compactMap { $0 }
            .asObservable()
    }
    private let MACAddressBehaviourSubject: BehaviorSubject<String?>

    init() {
        if let value = defaults.value(forKey: Keys.lastMACAddressValue) as? String {
            MACAddressBehaviourSubject = .init(value: value)
        } else {
            MACAddressBehaviourSubject = .init(value: .none)
        }
    }

    private func MACAddressValue(from data: Data) -> String? {
        let data = Data(data[4 ..< data.count - 1])
        if let string = String(data: data, encoding: .utf8) {
            return string.components(length: 2).joined(separator: ":")
        } else {
            return .none
        }
    }

    public func perform(on executor: CommandExecutor, notifyWith notifier: CommandNotifier) -> Observable<Void> {
        let completionObservable = notifier
            .notifyObservable
            .completeWhenByteEqualsToOne(hexStartWith: MACAddressCommand.prefix)
            .debug("\(self).trigger-2")
            .compactMap { self.MACAddressValue(from: $0) }
            .do(onNext: { data in
                self.defaults.set(data, forKey: Keys.lastMACAddressValue)

                self.MACAddressBehaviourSubject.onNext(data)
                self.MACAddressBehaviourSubject.onCompleted()
            })

        let performanceObservable = notifier
            .notifyObservable
            .completeWhenByteEqualsToOne(hexStartWith: MACAddressCommand.perfomanceTrigger)
            .debug("\(self).trigger")
            .flatMap { _ in
                HexCommand(hex: self.hex)
                    .perform(on: executor, notifyWith: notifier)
                    .debug("\(self).write")
            }

        return Observable.zip(
            completionObservable,
            performanceObservable
        ).mapToVoid()
    }

    deinit {
        print("\(self)-deinit")
    }
}
