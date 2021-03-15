//
//  ScreenCommand.swift
//  ChelseabandSDK
//
//  Created by Vladyslav Shepitko on 06.03.2021.
//

import RxSwift
import Foundation

public class ScreenCommand: Command {

    private static let prefix: String = "00F6"
    private static let commandLength: String = "01"

    private let command: HexCommand

    public init(screen: Screen) {
        command = HexCommand(hex: ScreenCommand.prefix + ScreenCommand.commandLength + screen.hex + screen.hex.xor)
    }

    public func perform(on executor: CommandExecutor, notifyWith notifier: CommandNotifier) -> Observable<Void> {
        let completionObservable = notifier
            .notifyObservable
            .completeWhenByteEqualsToOne(hexStartWith: ScreenCommand.prefix)
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
