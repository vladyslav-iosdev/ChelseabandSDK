//
//  VibrationCommand.swift
//  ChelseabandSDK
//
//  Created by Vladyslav Shepitko on 06.03.2021.
//

import RxSwift
import Foundation

public class VibrationCommand: Command {

    private static let prefix: String = "00f3"
    private let command: HexCommand

    public init(trigger: CommandTrigger, enabled: Bool) {
        let body = trigger.hex + enabled.hex

        command = HexCommand(hex: VibrationCommand.prefix + body + body.xor)
    }

    public func perform(on executor: CommandExecutor, notifyWith notifier: CommandNotifier) -> Observable<Void> {
        command
            .perform(on: executor, notifyWith: notifier)
            .debug("\(self)-write")
    }

    deinit {
        print("\(self)-deinit")
    }
}

extension Bool {
    var hex: String {
        switch self {
        case true:
            return "01"
        case false:
            return "00"
        }
    }
}
