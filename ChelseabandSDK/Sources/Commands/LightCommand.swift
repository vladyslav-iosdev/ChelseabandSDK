//
//  LightCommand.swift
//  ChelseabandSDK
//
//  Created by Vladyslav Shepitko on 08.12.2020.
//

import RxSwift

public class LightCommand: Command {
    private static let prefix: String = "00FB04"
    private let command: HexCommand

    public init(lights: [LightTrigger], vibration: Vibration) {
        let body = vibration.rawValue + lights.toLightCommand + "01"

        command = HexCommand(hex: LightCommand.prefix + body + body.xor)
    }

    public func perform(on executor: CommandExecutor, notifyWith notifier: CommandNotifier) -> Observable<Void> {
        command.perform(on: executor, notifyWith: notifier).debug("\(self)-write")
    }

    deinit {
        print("\(self)-deinit")
    }
}
