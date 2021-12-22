//
//  TimeSynchronizationCommand.swift
//  ChelseabandSDK
//
//  Created by Sergey Pohrebnuak on 06.09.2021.
//

import Foundation
import RxSwift

public struct TimeSynchronizationCommand: PerformableWriteCommand {
    
    private let date: Date
        
    public init(date: Date = .init()) {
        self.date = date
    }
    
    enum AdjustReason: UInt8 {
        case manualTimeUpdate
        case externalReferenceTimeUpdate
        case changeOfTimeZone
        case changeOfDST
        
        var data: Data {
            Data([0b10000000 >> self.rawValue])
        }
    }
    
    public var commandUUID = ChelseabandConfiguration.default.batteryCharacteristic // TODO: Change on time characteristic
    
    public var dataForSend: Data {
        let dateTime: Data = year.data + Data([month, day, hours, minutes, seconds])
        let dayDateTime: Data = dateTime + weekDay.data
        let exactTime256: Data = dayDateTime + fractions256.data
        let currentTime: Data = exactTime256 + AdjustReason.manualTimeUpdate.data
        return currentTime
    }
    
    private var year: UInt16 {
        UInt16(date.get(.year))
    }
    
    private var month: UInt8 {
        UInt8(date.get(.month))
    }
    
    private var day: UInt8 {
        UInt8(date.get(.day))
    }
    
    private var hours: UInt8 {
        UInt8(date.get(.hour))
    }
    
    private var minutes: UInt8 {
        UInt8(date.get(.minute))
    }
    
    private var seconds: UInt8 {
        UInt8(date.get(.second))
    }
    
    private var weekDay: UInt8 {
        var dayOfWeek = UInt8(date.get(.weekday))
        dayOfWeek -= 1
        return dayOfWeek == 0 ? 7 : dayOfWeek
    }
    
    private var fractions256: UInt8 {
        let milliseconds: Int = (date.get(.nanosecond) / 1000000)
        return UInt8(milliseconds * 255 / 1000)
    }
    
    public func perform(on executor: CommandExecutor) -> Observable<Void> {
        executor.write(command: self)
    }
}
