//
//  StartMessageCommand.swift
//  ChelseabandSDK
//
//  Created by Vladyslav Shepitko on 10.03.2021.
//

import RxSwift

class StartMessageCommand: Command {
    static let prefix = "00A1"
    static let suffix = "01"
    private let command: HexCommand

    init() {
        command = HexCommand(hex: StartMessageCommand.prefix + "01" + "01" + StartMessageCommand.suffix.xor)
    }

    func perform(on executor: CommandExecutor, notifyWith notifier: CommandNotifier) -> Observable<Void> {
        command
            .perform(on: executor, notifyWith: notifier)
            .debug("\(self)-write")
    }

    deinit {
        print("\(self)-deinit")
    }
}
