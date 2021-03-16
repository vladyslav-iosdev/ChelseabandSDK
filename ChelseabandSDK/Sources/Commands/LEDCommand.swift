//
//  LightCommand.swift
//  ChelseabandSDK
//
//  Created by Vladyslav Shepitko on 08.12.2020.
//

import RxSwift
import Foundation

public class LEDCommand: Command {
    private static let prefix: String = "00f4"
    private let command: HexCommand

    public init(trigger: CommandTrigger, enabled: Bool) {
        let body = trigger.hex + enabled.hex

        command = HexCommand(hex: LEDCommand.prefix + body + body.xor)
    }

    public func perform(on executor: CommandExecutor, notifyWith notifier: CommandNotifier) -> Observable<Void> {
        let completionObservable = notifier
            .notifyObservable
            .completeWhenByteEqualsToOne(hexStartWith: LEDCommand.prefix)
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


