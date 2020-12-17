//
//  LightCommand.swift
//  ChelseabandSDK
//
//  Created by Vladyslav Shepitko on 08.12.2020.
//

import RxSwift

public class LightCommand: Command {
    private static let prefix: String = "00FB04"
//    private static let suffix: String = "01"

    private let command: HexCommand

    public init(lights: [LightTrigger], vibration: Vibration) {
        let body = vibration.rawValue + lights.toLightCommand + "01"
//        let value = body + LightCommand.suffix

        command = HexCommand(hex: LightCommand.prefix + body + body.xor)
    }
    /*
    val firstCmd = "${if (vibrate) "0100" else "0000"}${
        if (goal && news) "03"
        else if (news) "02"
        else if (goal) "01"
        else "00"
    }"

    commands.add("00FB04".plus(firstCmd).plus("01").plus(CmdUtils.checkXor("${firstCmd}01")))
    */
    public func perform(on executor: CommandExecutor, notifyWith notifier: CommandNotifier) -> Observable<Void> {
        command.perform(on: executor, notifyWith: notifier).debug("\(self)-write")
    }

    deinit {
        print("\(self)-deinit")
    }
}
