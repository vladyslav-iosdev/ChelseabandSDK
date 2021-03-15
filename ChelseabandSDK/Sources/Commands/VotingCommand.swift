//
//  VotingCommand.swift
//  ChelseabandSDK
//
//  Created by Vladyslav Shepitko on 06.03.2021.
//

import Foundation
import RxSwift

public enum VotingResult {
    case approve
    case refuse
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
    private static let prefix = "00A4"
    private static let suffix = "01"

    private let voteCommand: HexCommand
    public var votingObservable: Observable<VotingResult> {
        return votingPublishSubject.asObservable()
    }

    private var votingPublishSubject: PublishSubject<VotingResult>

    public init() {
        voteCommand = HexCommand(hex: VotingCommand.prefix + "01" + "01" + VotingCommand.suffix.xor)
        votingPublishSubject = PublishSubject<VotingResult>()
    }

    public func perform(on executor: CommandExecutor, notifyWith notifier: CommandNotifier) -> Observable<Void> {
//        return Observable.create { seal -> Disposable in
//
//            let perfomanceDisposable = notifier
//                .notifyObservable
//                .completeWhenByteEqualsToOne(hexStartWith: StartMessageCommand.prefix)
////                .filter { $0.hex.starts(with: StartMessageCommand.prefix) && $0.bytes.count >= 4 }
////                .debug("\(self)-trigget")
////                .compactMap { guard $0.bytes[3] == 1 else { throw CommandError.invalid } }
//                .debug("\(self).read")
//                .flatMap { _ in return self.voteCommand.perform(on: executor, notifyWith: notifier) }
//                .subscribe(onError: { error in
//                    seal.onError(error)
//
//                    seal.onCompleted()
//                })
//
//            let votingDisposable = notifier
//                .notifyObservable
//                .filter { $0.hex.starts(with: VotingCommand.prefix) && $0.bytes.count >= 4 }
//                .debug("\(self)-trigget")
//                .flatMap { data -> Observable<Void> in
//                    self.votingResult = VotingResult(byte: data.bytes[3])
//                    return EndMessageCommand().perform(on: executor, notifyWith: notifier)
//                }.subscribe(seal)
//
//            let initialWrite = StartMessageCommand().perform(on: executor, notifyWith: notifier)
//                .debug("\(self)-initial write")
//                .subscribe(onError: { e in
//                    seal.onError(e)
//                })
//
//            return Disposables.create {
//                initialWrite.dispose()
//                perfomanceDisposable.dispose()
//                votingDisposable.dispose()
//            }
//        }

        return Observable.create { seal -> Disposable in
            let votingDisposable = notifier
                .notifyObservable
                .filter { $0.hex.starts(with: VotingCommand.prefix) && $0.bytes.count >= 4 }
                .debug("\(self)-trigget")
                .flatMap { data -> Observable<Void> in
                    let result = VotingResult(byte: data.bytes[3])

                    self.votingPublishSubject.onNext(result)
                    self.votingPublishSubject.onCompleted()

                    return EndMessageCommand().perform(on: executor, notifyWith: notifier)
                }.subscribe(seal)

            let initialWrite = StartMessageCommand()
                .perform(on: executor, notifyWith: notifier)
                .debug("\(self)-initial write")
                .flatMap { _ -> Observable<Void> in
                    return self.voteCommand.perform(on: executor, notifyWith: notifier)
                }
                .subscribe(onError: { e in
                    seal.onError(e)
                })

            return Disposables.create {
                initialWrite.dispose()
                votingDisposable.dispose()
            }
        }
    }

    deinit {
        print("\(self)-deinit")
    }
}
