//
//  SeatPositionCommand.swift
//  ChelseabandSDK
//
//  Created by Sergey Pohrebnuak on 26.11.2021.
//

import RxSwift

public enum SeatPositionCommandError: LocalizedError {
    case cantConvertToSeatData
    
    public var errorDescription: String? {
        switch self {
        case .cantConvertToSeatData:
            return "Can't convert ticket to seat data which will be send to the band"
        }
    }
}

public struct SeatPositionCommand: CommandNew {
    
    public var uuidForWrite = ChelseabandConfiguration.default.seatingPositionCharacteristic
    
    public var dataForSend: Data
    
    public func perform(on executor: CommandExecutor) -> Observable<Void> {
        executor.write(command: self)
    }
    
    init(fromTicket ticket: TicketType) throws {
        let resultString = "section \(ticket.section)\nrow \(ticket.row)\nseat \(ticket.seat)\0"
        if let data = resultString.data(using: .utf8) {
            dataForSend = data
        } else {
            throw SeatPositionCommandError.cantConvertToSeatData
        }
    }
}
