//
//  AccelerometerCommand.swift
//  ChelseabandSDK
//
//  Created by Vladyslav Shepitko on 06.03.2021.
//

import RxSwift
import Foundation

public class AccelerometerCommand: Command {

    private static let prefix: String = "00f8"

    public var axisObservable: Observable<(values: [[Double]], isActive: Bool)> {
        return axisPublishSubject.asObservable()
    }

    private var axisPublishSubject: PublishSubject<(values: [[Double]], isActive: Bool)>

    public init() {
        axisPublishSubject = PublishSubject<(values: [[Double]], isActive: Bool)>()
    }

    private static func value(from data: Data) -> (values: [[Double]], isActive: Bool) {
        let valuesHex = data[3 ..< data.count - 2].hex
        let hexValues = valuesHex.chunked(by: 2).map { String($0).valueFromHex }
        let values = hexValues.chunked(by: 6).compactMap {
            $0.compactMap { v in
                Double(v) * 9.8 / Double(512)
            }
        }
        let isActive = data[data.count - 2 ..< data.count].hex.valueFromHex == 1

        return (values, isActive)
    }

    public func perform(on executor: CommandExecutor, notifyWith notifier: CommandNotifier) -> Observable<Void> {
        notifier
            .notifyObservable
            .filter { $0.hex.starts(with: AccelerometerCommand.prefix) }
            .compactMap { AccelerometerCommand.value(from: $0) }
            .do(onNext: { data in
                self.axisPublishSubject.onNext(data)
            })
            .mapToVoid()
    }

    deinit {
        print("\(self)-deinit")
    }
}
