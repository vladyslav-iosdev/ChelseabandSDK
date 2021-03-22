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

    public var axisObservable: Observable<[Double]> {
        return axisPublishSubject.asObservable()
    }

    private var axisPublishSubject: PublishSubject<[Double]>

    public init() {
        axisPublishSubject = PublishSubject<[Double]>()
    }

    private static func value(from data: Data) -> [Double] {
        return data[3 ..< data.count - 2].hex.chunked(by: 2).map{ String($0).valueFromHex }.compactMap{ Double($0) * 9.8 / Double(512) }
    }

    public func perform(on executor: CommandExecutor, notifyWith notifier: CommandNotifier) -> Observable<Void> {
        notifier
            .notifyObservable
            .filter { $0.hex.starts(with: AccelerometerCommand.prefix) }
            .compactMap { AccelerometerCommand.value(from: $0) }
            .debug("\(self)-trigget")
            .do(onNext: { data in
                self.axisPublishSubject.onNext(data)
            })
            .mapToVoid()
    }

    deinit {
        print("\(self)-deinit")
    }
}
