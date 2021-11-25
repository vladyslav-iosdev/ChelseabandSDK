//
//  DeviceSettingsCommand.swift
//  ChelseabandSDK
//
//  Created by Sergey Pohrebnuak on 25.11.2021.
//

import RxSwift

public enum BandOrientation: UInt8 {
    case buttonOnLeftSide
    case buttonOnRightSide
}

public struct DeviceSettingsCommand: CommandNew {
    public let uuidForWrite = ChelseabandConfiguration.default.deviceSettingsCharacteristic

    public var dataForSend: Data { Data([bandOrientation.rawValue]) }
    
    private let bandOrientation: BandOrientation
    
    init(bandOrientation: BandOrientation) {
        self.bandOrientation = bandOrientation
    }
    
    public func perform(on executor: CommandExecutor) -> Observable<Void> {
        executor.write(command: self)
    }
}
