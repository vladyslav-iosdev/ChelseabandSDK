//
//  NFCCommand.swift
//  ChelseabandSDK
//
//  Created by Sergey Pohrebnuak on 26.11.2021.
//

import RxSwift

public enum NFCCommandError: LocalizedError {
    case cantConvertToNFCData
    
    public var errorDescription: String? {
        switch self {
        case .cantConvertToNFCData:
            return "Can't convert ticket to NFC data which will be send to the band"
        }
    }
}

public struct NFCCommand: PerformableWriteCommand {
    
    public var commandUUID = ChelseabandConfiguration.default.nfcTicketCharacteristic
    
    public var dataForSend: Data
    
    public func perform(on executor: CommandExecutor) -> Observable<Void> {
        executor.write(command: self)
    }
    
    init(fromTicket ticket: TicketType) throws {
        if let data = ticket.nfcString.data(using: .utf8) {
            dataForSend = data
        } else {
            throw NFCCommandError.cantConvertToNFCData
        }
    }
}
