//
//  TicketsProvider.swift
//  ChelseabandSDK
//
//  Created by Sergey Pohrebnuak on 24.12.2021.
//

import Alamofire

enum TicketsProvider: String, URLRequestBuilder {
    case bandTicket = "tickets/band-ticket"
    
    var path: String { self.rawValue }
    
    var method: HTTPMethod {
        switch self {
        case .bandTicket:
            return .get
        }
    }
}
