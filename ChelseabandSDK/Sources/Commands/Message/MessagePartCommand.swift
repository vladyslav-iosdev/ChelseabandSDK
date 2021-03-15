//
//  MessagePartCommand.swift
//  ChelseabandSDK
//
//  Created by Vladyslav Shepitko on 10.03.2021.
//

import RxSwift

class MessagePartCommand: Command {
    private static let prefix = "00A3"
    private let command: HexCommand
    private static let determinesThatMessageIsNewsHex = "01"

    var hex: String {
        return command.hex
    }

    init(value part: String) {
        let lengthHex = (part.count / 2).hex
        let hex = (GoalCommand.prefix + lengthHex + MessagePartCommand.determinesThatMessageIsNewsHex + part + part.xor).uppercased()
        command = HexCommand(hex: hex)
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
