//
//  DisplayBrightnessCommand.swift
//  ChelseabandSDK
//
//  Created by Sergey Pohrebnuak on 11.02.2022.
//

import RxSwift

public enum DisplayBrightness: UInt8, CaseIterable {
    case brightnessEqualTo_0 = 50 //NOTE: equal to in name it's percent of brightness
    case brightnessEqualTo_25 = 100
    case brightnessEqualTo_50 = 150
    case brightnessEqualTo_75 = 200
    case brightnessEqualTo_100 = 250
}

public struct DisplayBrightnessCommand: PerformableWriteCommand {
    public let commandUUID = ChelseabandConfiguration.default.displayBrightness

    public var dataForSend: Data { Data([displayBrightness.rawValue]) }
    
    private let displayBrightness: DisplayBrightness
    
    public init(displayBrightness: DisplayBrightness) {
        self.displayBrightness = displayBrightness
    }
    
    public func perform(on executor: CommandExecutor) -> Observable<Void> {
        executor.write(command: self)
    }
}
