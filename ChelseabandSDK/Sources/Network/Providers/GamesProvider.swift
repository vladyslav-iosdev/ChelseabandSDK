//
//  GamesProvider.swift
//  ChelseabandSDK
//
//  Created by Sergey Pohrebnuak on 24.12.2021.
//

import Alamofire

enum GamesProvider: String, URLRequestBuilder {
    case location = "games/location"
    case score = "games/score"
    
    var path: String { self.rawValue }
    
    var method: HTTPMethod {
        switch self {
        case .location:
            return .get
        case .score:
            return .get
        }
    }
}
