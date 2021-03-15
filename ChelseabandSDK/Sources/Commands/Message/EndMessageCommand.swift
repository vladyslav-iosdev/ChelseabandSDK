//
//  EndMessageCommand.swift
//  ChelseabandSDK
//
//  Created by Vladyslav Shepitko on 10.03.2021.
//

import RxSwift

class EndMessageCommand: Command {

    static let prefix = "00A3"
    static let suffix = "01"
    private let command: HexCommand

    init() {
        command = HexCommand(hex: "00A3" + "01" + "01" + EndMessageCommand.suffix.xor)
    }

    func perform(on executor: CommandExecutor, notifyWith notifier: CommandNotifier) -> Observable<Void> {
        return command
            .perform(on: executor, notifyWith: notifier)
            .debug("\(self)-write")
    }

    deinit {
        print("\(self)-deinit")
    }
}
