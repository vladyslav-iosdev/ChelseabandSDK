//
//  HexCommand.swift
//  ChelseabandSDK
//
//  Created by Vladyslav Shepitko on 08.12.2020.
//

import RxSwift

public enum CommandError: Error {
    case invalid
    case timeout
}

public class HexCommand: Command {

    public let hex: String

    public init(hex: String) {
        self.hex = hex
    }

    public func perform(on executor: CommandExecutor, notifyWith notifier: CommandNotifier) -> Observable<Void> {
        guard let data = hex.uppercased().hexadecimal else {
            return .error(CommandError.invalid)
        }

        return executor.write(data: data).debug("\(self).write")
    }

    deinit {
        print("\(self)-deinit")
    }
} 
