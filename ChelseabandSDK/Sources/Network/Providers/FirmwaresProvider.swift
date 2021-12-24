//
//  FirmwaresProvider.swift
//  ChelseabandSDK
//
//  Created by Sergey Pohrebnuak on 24.12.2021.
//

import Alamofire

enum FirmwaresProvider: String, URLRequestBuilder {
    case latest = "firmwares/latest"
    
    var path: String { self.rawValue }
    
    var method: HTTPMethod {
        switch self {
        case .latest:
            return .get
        }
    }
}
