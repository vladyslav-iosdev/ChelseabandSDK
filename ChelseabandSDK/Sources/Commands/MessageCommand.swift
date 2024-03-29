//
//  NewsCommand.swift
//  ChelseabandSDK
//
//  Created by Vladyslav Shepitko on 17.12.2020.
//

import RxSwift

public enum MessageType: String {
    case goal = "01"
    case news = "02"
}

enum NewsCommandError: Error {
    case done
}

public class MessageCommand: Command {
    private var body: [MessagePartCommand]

    public init(value: String, messagePartPrefix: String = GoalCommand.prefix) {
        //NOTE: converted string into its hex, deviced by 16 cheracters in chunk
        let values = value.hex.components(length: 16)
        body = values.map { part -> MessagePartCommand in
            return MessagePartCommand(value: part, commandPrefix: messagePartPrefix)
        }
    }

    public func perform(on executor: CommandExecutor, notifyWith notifier: CommandNotifier) -> Observable<Void> {
        let triggerDisposable = notifier.notifyObservable
            .flatMap { data -> Observable<Void> in
                if self.body.isEmpty {
                    throw NewsCommandError.done
                } else {
                    let command = self.body.removeFirst()
                    return command.perform(on: executor, notifyWith: notifier)
                }
            }.catchError { e -> Observable<Void> in
                if case NewsCommandError.done = e {
                    return EndMessageCommand().perform(on: executor, notifyWith: notifier)
                } else {
                    throw e
                }
            }
            .ignoreElements()
            .asObservable()

        let performanceObservable = StartMessageCommand().perform(on: executor, notifyWith: notifier)
            .ignoreElements()
            .asObservable()

        return Observable.zip(
            performanceObservable,
            triggerDisposable
        )
        .mapToVoid()
    }

    deinit {
        print("\(self)-deinit")
    }
}
