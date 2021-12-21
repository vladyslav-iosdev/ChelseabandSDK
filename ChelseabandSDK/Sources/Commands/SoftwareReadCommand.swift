//
//  SoftwareReadCommand.swift
//  ChelseabandSDK
//
//  Created by Sergey Pohrebnuak on 21.12.2021.
//

import RxSwift

struct SoftwareReadCommand: PerformReadCommandProtocol {
    public let commandUUID = ChelseabandConfiguration.default.softwareCharacteristic
    
    public func performRead(on executor: CommandExecutor) -> Observable<Data> {
        executor.read(command: self).compactMap { $0 }
    }
}
