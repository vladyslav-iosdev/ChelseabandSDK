//
//  ModelReadCommand.swift
//  ChelseabandSDK
//
//  Created by Sergey Pohrebnuak on 20.12.2021.
//

import RxSwift

struct ModelReadCommand: PerformReadCommandProtocol {
    public let commandUUID = ChelseabandConfiguration.default.modelCharacteristic
    
    public func performRead(on executor: CommandExecutor) -> Observable<Data> {
        executor.read(command: self).compactMap { $0 }
    }
}
