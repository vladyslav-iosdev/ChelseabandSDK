//
//  SoundCommand.swift
//  ChelseabandSDK
//
//  Created by Vladyslav Shepitko on 08.12.2020.
//

import RxSwift

public class SoundCommand: Command {
    private static let prefix: String = "00f5"

    private let command: HexCommand

    public init(sound: Sound, trigger: SoundTrigger) {
        let value = "0" + trigger.description + sound.rawValue

        command = HexCommand(hex: SoundCommand.prefix + value + value.xor)
    } 

    public func perform(on executor: CommandExecutor, notifyWith notifier: CommandNotifier) -> Observable<Void> {
        command.perform(on: executor, notifyWith: notifier)
    }

    deinit {
        print("\(self)-deinit")
    }
}
