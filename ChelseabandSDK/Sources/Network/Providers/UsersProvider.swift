//
//  UsersProvider.swift
//  ChelseabandSDK
//
//  Created by Sergey Pohrebnuak on 24.12.2021.
//

import Alamofire

enum UsersProvider: URLRequestBuilder {
    case fcm(String)
    case connectFanband(DeviceInfoTransferModelType)
    case status(Bool)
    case inArea(Bool)
    
    var path: String {
        switch self {
        case .fcm:
            return "users/fcm"
        case .connectFanband:
            return "users/connect-fanband"
        case .status:
            return "users/status"
        case .inArea:
            return "users/in-area"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .fcm:
            return .patch
        case .connectFanband:
            return .patch
        case .status:
            return .patch
        case .inArea:
            return .patch
        }
    }
    
    var parameters: Parameters? {
        switch self {
        case .fcm(let token):
            return ["fcm": token,
                    "platform": "ios"]
        case .connectFanband(let bandTransferModel):
            return bandTransferModel.getLikeDict()
        case .status(let status):
            return ["status": status]
        case .inArea(let isInArea):
            return ["isInArea": isInArea]
        }
    }
}
