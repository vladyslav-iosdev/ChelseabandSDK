//
//  SoundCommand.swift
//  ChelseabandSDK
//
//  Created by Vladyslav Shepitko on 08.12.2020.
//

import RxSwift

//NOTE: Add safe secommand send, check whether sound is playing now, sending command while another one is performing may cause device loop play
public class SoundCommand: Command {
    private static let prefix: String = "00f5"

    private let command: HexCommand

    public init(sound: Sound, trigger: CommandTrigger) {
        let value = trigger.hex + sound.hex

        command = HexCommand(hex: SoundCommand.prefix + value + value.xor)
    } 

    public func perform(on executor: CommandExecutor, notifyWith notifier: CommandNotifier) -> Observable<Void> {
        let completionObservable = notifier
            .notifyObservable
            .completeWhenByteEqualsToOne(hexStartWith: SoundCommand.prefix)
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
