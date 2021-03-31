//
//  VotingCommand.swift
//  ChelseabandSDK
//
//  Created by Vladyslav Shepitko on 06.03.2021.
//

import Foundation
import RxSwift

public enum VotingResult: Int {
    case refuse
    case approve
    case ignore

    init(byte: UInt8) {
        switch byte {
        case 0x00:
            self = .refuse
        case 0x01:
            self = .approve
        case 0x02:
            self = .ignore
        default:
            self = .ignore
        }
    }
}

public class VotingCommand: Command {
    private static let prefix = "00a4"
    private static let suffix = "01"

    public var votingObservable: Observable<VotingResult> {
        return votingPublishSubject.asObservable()
    }

    private var votingPublishSubject: PublishSubject<VotingResult>
    private let messageCommand: MessageCommand

    public init(value: String = "hello world?") {
        messageCommand = MessageCommand(value: value, messagePartPrefix: VotingCommand.prefix)
        votingPublishSubject = PublishSubject<VotingResult>()
    }

    public func perform(on executor: CommandExecutor, notifyWith notifier: CommandNotifier) -> Observable<Void> {
        let completionObservable = notifier
            .notifyObservable
            .filter { $0.hex.starts(with: VotingCommand.prefix) }
            .skip(2) //NOTE: during voting we receive command with header `VotingCommand.prefix` 3 times, and on 3 time it contains reponse from user
            .do(onNext: { data in
                let result = VotingResult(byte: data.bytes[3])

                self.votingPublishSubject.onNext(result)
                self.votingPublishSubject.onCompleted()
            })
            .take(1) //NOTE: complete observable

        let performanceObservable = messageCommand
            .perform(on: executor, notifyWith: notifier)

        return Observable.zip(
            performanceObservable,
            completionObservable
        )
        .mapToVoid()
    }

    deinit {
        print("\(self)-deinit")
    }
}
