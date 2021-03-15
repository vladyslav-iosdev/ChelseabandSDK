//
//  TimeCommand.swift
//  ChelseabandSDK
//
//  Created by Vladyslav Shepitko on 17.12.2020.
//

import RxSwift
import Foundation

extension Date {
    var millisecondsSince1970: Int64 {
        return Int64((self.timeIntervalSince1970 * 1000.0).rounded())
    }

    static func hoursToMiliseconds(hours: Int64) -> Int64 {
        return hours * 3600 * 1000
    }
}

extension Int64 {
    var hex: String {
        return String(format: "%02X", self)
    }
}

public class TimeCommand: Command {

    private static let trigger = "00fb0101"
    //NOTE: 8 for old device and 12 for a new device version
    private static let delaySystemTime: Int64 = 946656000000 + Date.hoursToMiliseconds(hours: 8)

    private static var hex: String {
        let timeZoneOffset: Int64 = Int64(TimeZone.current.secondsFromGMT() * 1000)

        let timeValue = ((Date().millisecondsSince1970 + timeZoneOffset) - TimeCommand.delaySystemTime) / 1000
        let time: String = timeValue.hex

        return "008808\(time)00000000" + time.xor
    }

    init() {
        //no op
    }

    public func perform(on executor: CommandExecutor, notifyWith notifier: CommandNotifier) -> Observable<Void> {
        notifier
            .notifyObservable
            .completeWhenByteEqualsToOne(hexStartWith: TimeCommand.trigger)
            .debug("\(self)-trigget")
            .flatMap { data -> Observable<Void> in
                let command = HexCommand(hex: TimeCommand.hex)
                print("\(self)-write: \(command.hex)")
                return command.perform(on: executor, notifyWith: notifier)
            }
    }

    deinit {
        print("\(self)-deinit")
    }
}
