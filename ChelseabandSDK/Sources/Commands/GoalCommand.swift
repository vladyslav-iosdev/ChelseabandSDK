//
//  GoalCommand.swift
//  ChelseabandSDK
//
//  Created by Vladyslav Shepitko on 08.12.2020.
//

import RxSwift

public class GoalCommand: Command {

    public static let prefix: String = "00a2"
    public static let suffix: String = "000200"

    public init() {
        //no op
    }

    public func perform(on executor: CommandExecutor, notifyWith notifier: CommandNotifier) -> Observable<Void> {
        let command = HexCommand(hex: GoalCommand.prefix + GoalCommand.suffix)
        return command.perform(on: executor, notifyWith: notifier)
    }

    deinit {
        print("\(self)-deinit")
    }
}
