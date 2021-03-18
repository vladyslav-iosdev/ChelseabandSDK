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

    private static let prefix: String = "00f8"
//    private static let sizeHex: String = "c6"

    public var axisObservable: Observable<AXIS> {
        return axisPublishSubject.asObservable()
    }

    private var axisPublishSubject: PublishSubject<AXIS>

    public init() {
        axisPublishSubject = PublishSubject<AXIS>()
    }

//    private static let prefix = "00f70101"
//    private static let suffix = "01"

    private static func value(from data: Data) -> (x: [UInt64], y: [UInt64], z: [UInt64])? {
//        let prefixSize = (AccelerometerCommand.prefix + sizeHex).count
//        if data.hex.starts(with: AccelerometerCommand.prefix) && data.hex.count >= prefixSize + 2 {
//            //NOTE: (prefixSize + 1) : header + one byte for command length
//            // (data.hex.count - 2) : `-2` drop last check byte
//            return data.hex[prefixSize + 1 ..< data.hex.count - 2].valueFromHex
//        } else {
//            return nil
//        }
        print("\(self) data: \(data.hex)")
//
//        let kk = data[3 ..< data.count - 2].bytes
//        data[3 ..< data.count - 2].bytes.chunked(by: 33)

//        data[3 ..< data.count - 2].hex[0 ..< 1].valueFromHex

        let value = data[3 ..< data.count - 2].hex

        

        return nil
    }

    public func perform(on executor: CommandExecutor, notifyWith notifier: CommandNotifier) -> Observable<Void> {
        notifier
            .notifyObservable
            .filter { $0.hex.starts(with: AccelerometerCommand.prefix) }
            .compactMap { AccelerometerCommand.value(from: $0) }
            .debug("\(self)-trigget")
            .do(onNext: { data in
                print("\(self) data: \(data)")
            })
            .mapToVoid()
    }

    deinit {
        print("\(self)-deinit")
    }
}
