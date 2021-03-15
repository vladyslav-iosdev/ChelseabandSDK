//
//  HardwareSettings.swift
//  ChelseabandSDK
//
//  Created by Vladyslav Shepitko on 06.03.2021.
//

import Foundation
import RxSwift

public class HardwareEnablement: Command {
    private static let prefix: String = "00FB"
    private static let commandLength: String = "04"

    private let command: HexCommand

    public init(led: [CommandTrigger], vibrationEnabled: Bool, screenEnabled: Bool, speakerEnabled: Bool) {
        let body = vibrationEnabled.hex + speakerEnabled.hex + led.enabledLEDsHex + screenEnabled.hex

        command = HexCommand(hex: HardwareEnablement.prefix + HardwareEnablement.commandLength + body + body.xor)
    }

    public func perform(on executor: CommandExecutor, notifyWith notifier: CommandNotifier) -> Observable<Void> {
        let completionObservable = notifier
            .notifyObservable
            .completeWhenByteEqualsToOne(hexStartWith: HardwareEnablement.prefix)
            .debug("\(self)-trigget")

        let performanceObservable = command
            .perform(on: executor, notifyWith: notifier)
            .debug("\(self)-write")

        return Observable.zip(
            performanceObservable,
            completionObservable
        ).mapToVoid()
    }

    deinit {
        print("\(self)-deinit")
    }
}

fileprivate extension Array where Element == CommandTrigger {
    var enabledLEDsHex: String {
        if contains(.goal) && contains(.news) {
            return "03"
        } else if contains(.news) {
            return "02"
        } else if contains(.goal) {
            return "01"
        } else {
            return "00"
        }
    }
}
