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

public class NewsCommand: Command {
    private static let prefix = "00a10101"
    private static let suffix = "01"
    private var body: [HexCommand]

    private let initialCommand = HexCommand(hex: NewsCommand.prefix.uppercased() + NewsCommand.suffix.xor)
    private let completionCommand = HexCommand(hex: "00A301" + "01" + NewsCommand.suffix.xor)
    private lazy var isEmptyTrigger = Observable.of(body).filter{ $0.isEmpty }

    public init(value: String) {
        //NOTE: converted string into its hex, deviced by 16 cheracters in chunk
        let values = value.hex.components(length: 16)
        body = values.map { part -> HexCommand in
            let lengthHex = (part.count / 2).hex
            let hex = (GoalCommand.prefix + lengthHex + NewsCommand.suffix + part + part.xor).uppercased()
            print("\(Self.self)-command: \(hex)")

            return HexCommand(hex: hex)
        }
        print("\(self)-body: \(body)")
    }

    public func perform(on executor: CommandExecutor, notifyWith notifier: CommandNotifier) -> Observable<Void> {
        return Observable.create { seal -> Disposable in

            let triggerDisposable = notifier.notifyObservable
                .takeUntil(self.isEmptyTrigger)
                .map { _ -> HexCommand? in
                    if self.body.isEmpty {
                        return nil
                    } else {
                        return self.body.removeFirst()
                    }
                }.flatMap { command -> Observable<Void> in
                    if let command = command {
                        print("\(self)-write: \(command.hex)")
                        return command.perform(on: executor, notifyWith: notifier)
                    } else {
                        print("\(self)-done")
                        throw NewsCommandError.done
                    }
                }.flatMap { _ -> Observable<Void> in
                    if self.body.isEmpty {
                        return self.completionCommand.perform(on: executor, notifyWith: notifier)
                    } else {
                        return .just(())
                    }
                }.catchError { e -> Observable<Void> in
                    if case NewsCommandError.done = e {
                        return self.completionCommand.perform(on: executor, notifyWith: notifier)
                    } else {
                        throw e
                    }
                }.debug("\(self)-write body").subscribe { e in
                    if let error = e.error {
                        seal.onError(error)
                    } else if e.isCompleted {
                        seal.onCompleted()
                    }
                }

            let initialWrite = self.initialCommand.perform(on: executor, notifyWith: notifier)
                .debug("\(self)-initial write")
                .subscribe { e in
                    //NOTE: we need to keep track response, if its errro, return it to upper observable
                    //and if `body` is empty complete observable
                    //other wait for response
                    if let error = e.error {
                        seal.onError(error)
                    } else if self.body.isEmpty {
                        //send completion
                        seal.onCompleted()
                    }
                }

            return Disposables.create {
                initialWrite.dispose()
                triggerDisposable.dispose()
            }
        } 
    }

    deinit {
        print("\(self)-deinit")
    }
}
