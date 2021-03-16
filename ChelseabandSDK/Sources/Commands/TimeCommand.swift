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
        return String(format: "%02x", self)
    }
}

public class TimeCommand: Command {

    private static let trigger = "00fb0101"
    //NOTE: 8 for old device and 12 for a new device version
    private static let delaySystemTime: Int64 = 946656000000 + Date.hoursToMiliseconds(hours: 12)
    private static let trigger2 = "0088"

    private var hex: String {
        let timeZoneOffset: Int64 = Int64(TimeZone.current.secondsFromGMT() * 1000)

        let timeValue = ((Date().millisecondsSince1970 + timeZoneOffset) - TimeCommand.delaySystemTime) / 1000
        let timeHex = timeValue.data.hex

        return TimeCommand.trigger2 + "08" + timeHex + timeHex.xor
    }

    init() {
        //no op
    }

    public func perform(on executor: CommandExecutor, notifyWith notifier: CommandNotifier) -> Observable<Void> {
        let completionObservable = notifier
            .notifyObservable
            .completeWhenByteEqualsToOne(hexStartWith: TimeCommand.trigger2)

        let initialCommandObservable = notifier
            .notifyObservable
            .completeWhenByteEqualsToOne(hexStartWith: TimeCommand.trigger)
            .flatMap { data -> Observable<Void> in
                HexCommand(hex: self.hex)
                    .perform(on: executor, notifyWith: notifier)
            }

        return Observable.zip(
            completionObservable,
            initialCommandObservable
        )
        .mapToVoid()
    }

    deinit {
        print("\(self)-deinit")
    }
}
