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

public class NewsCommand: Command {
    private static let prefix = "00a10101"
    private static let suffix = "01"
    private let commandStack: [HexCommand]

    private let initialCommand = HexCommand(hex: NewsCommand.prefix.uppercased() + NewsCommand.suffix.xor)

    init(value: String, type: MessageType) {
        let values = value.components(length: 16)

//        let initialCommand = HexCommand(hex: NewsCommand.prefix + NewsCommand.suffix.xor)

        commandStack = values.map { part -> HexCommand in
            let length = (part.count / 2).hex
            let hex = GoalCommand.prefix.uppercased() + "\(length)" + NewsCommand.suffix + part + part.xor

            return HexCommand(hex: hex)
        }

//        val make = PREFIX_NEWS.toUpperCase(Locale.US).plus(CmdUtils.checkXor("01"))
//        writeHex(make)
//
//        commandStack = [initialCommand] + bodyPartCommands
//    val length = Integer.toHexString((msgList[writeCurrent].length / 2))
//    val makes = PREFIX_GOAL.toUpperCase(Locale.US)
//            .plus(if (length.length == 1) "0$length" else length)
//            .plus(msgType)//01消息标题  02进球
//            .plus(msgList[writeCurrent])
//            .plus(CmdUtils.checkXor(msgList[writeCurrent]))
//
//    writeHex(makes)

//         "00A301".plus("01").plus(CmdUtils.checkXor("01"))

//    to trigger “news” the app use more complex algorithm:
//    Convert message text to hex string.
//    Split converted message to parts 16 symbols length

//    Send to device “00a10101" + result of function checkXor(“01”)
//    Waiting for some callback from sdk ( onCharacteristicChanged(data: ByteArray) )
//    In the loop send to device previously split parts of hex text message next way:  “00a10101" + part’s length + “01” + part of message + result of function checkXor(part of message)

    }

    public func perform(on executor: CommandExecutor, notifyWith notifier: CommandNotifier) -> Observable<Void> {
        return Observable.create { seal -> Disposable in

//            let timerObservable = Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.instance)
//                .debug("\(self)-trigger")
//                .flatMap { _ -> Observable<Void> in
//                    return self.command.perform(on: executor, notifyWith: notifier)
//                        .debug("\(self)-write")
//                        .mapToVoid()
//                }.debug("t-t")
//                .subscribe()

            let triggerObservable = notifier
                .notifyObservable
                .debug("\(self)-trigget")
                .skipWhile { !$0.hex.starts(with: NewsCommand.prefix) }
    //            .take(1)
    //            .flatMap { data -> Observable<Void> in
    //                print("\(self)-trigger on: \(data.hex)")
    //                print("\(self)-write: \(self.completeHex.hex)")
    //                return executor.write(data: self.completeHex)
    //            }
                .timeout(.milliseconds(250), other: Observable.error(RxError.timeout), scheduler: MainScheduler.instance)
                .subscribe(onNext: { _ in
                    seal.onCompleted()
                }, onError: { e in
                    seal.onError(e)
                })

            let initialWrite = self.initialCommand.perform(on: executor, notifyWith: notifier)
                .debug("\(self)-initial write")
                .subscribe()

            return Disposables.create {
                initialWrite.dispose()
//                timerObservable.dispose()
            }
        } 
    }
}

//        return Observable.create { seal -> Disposable in
//            print("\(self)-stard")
//
////            let notifyObservable = notifier.notifyObservable.debug("\(self)-read").subscribe(onNext: { data in
////                print("\(self)-read: \(data.hex)")
////            }, onError: { e in
////                seal.onError(e)
////            })
//
//            let triggerObservable = notifier
//                .notifyObservable
//                .debug("\(self)-trigget")
//                .skipWhile { !$0.hex.starts(with: GoalCommand.prefix) }
//                .take(1)
//                .flatMap { data -> Observable<Void> in
//                    print("\(self)-trigger on: \(data.hex)")
//                    print("\(self)-write: \(self.completeHex.hex)")
//                    return executor.write(data: self.completeHex)
//                }
//                .timeout(.milliseconds(250), other: Observable.error(RxError.timeout), scheduler: MainScheduler.instance)
//                .subscribe(onNext: { _ in
//                    seal.onCompleted()
//                }, onError: { e in
//                    seal.onError(e)
//                })
//
////            print(executor)
//            print("\(self)-write: \(self.initHex.hex)")
//            let writeDisposable = executor
//                .write(data: self.initHex)
//                .debug("\(self)-write")
//                .subscribe(onNext: { data in
//
//                }, onError: { e in
//                    seal.onError(e)
//                })
//
//            return Disposables.create {
//                writeDisposable.dispose()
//                triggerObservable.dispose()
//                print("\(self)-dispose")
//            }
//        }

