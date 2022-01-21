//
//  AuthProvider.swift
//  ChelseabandSDK
//
//  Created by Sergey Pohrebnuak on 24.12.2021.
//

import Alamofire

enum AuthProvider: URLRequestBuilder {
    case sendOTP(String)
    case verify(phone: String, code: String, fcm: String)
    
    var path: String {
        switch self {
        case .sendOTP:
            return "auth/phone/send-code"
        case .verify:
            return "auth/phone/verify"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .sendOTP:
            return .post
        case .verify:
            return .post
        }
    }
    
    var parameters: Parameters? {
        switch self {
        case .sendOTP(let phoneNumber):
            return ["phone": phoneNumber]
        case .verify(let data):
            return ["phone": data.phone,
                    "code": data.code,
                    "fcm": data.fcm,
                    "platform": "ios"]
        }
    }
}
