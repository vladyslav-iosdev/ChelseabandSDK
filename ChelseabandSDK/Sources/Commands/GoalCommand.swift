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
    private let command = HexCommand(hex: GoalCommand.prefix + GoalCommand.suffix)
    
    public init() {
        //no op
    } 

    public func perform(on executor: CommandExecutor, notifyWith notifier: CommandNotifier) -> Observable<Void> {
        let completionObservable = notifier
            .notifyObservable
            .completeWhenByteEqualsToOne(hexStartWith: GoalCommand.prefix)
            .debug("\(self)-trigget")

        let commandObservable = command
            .perform(on: executor, notifyWith: notifier)
            .debug("\(self).write")

        return Observable.zip(
            commandObservable,
            completionObservable
        ).mapToVoid()
    }

    deinit {
        print("\(self)-deinit")
    }
}
