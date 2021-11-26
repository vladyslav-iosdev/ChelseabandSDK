//
//  Ticket.swift
//  ChelseabandSDK
//
//  Created by Sergey Pohrebnuak on 26.11.2021.
//

import Foundation

public protocol TicketType {
    var section: String { get }
    var row: Int { get }
    var seat: String { get }
    var nfcString: String { get }
}

public struct Ticket: TicketType, Decodable {
    public var section: String
    public var row: Int
    public var seat: String
    public var nfcString: String
}
