//
//  Response.swift
//  ChelseabandSDK
//
//  Created by Sergey Pohrebnuak on 24.12.2021.
//

import Foundation

protocol ResponseType: Decodable {
    var statusCode: Int { get }
    var message: String { get }
}

struct ResponseWithoutData: ResponseType {
    let statusCode: Int
    let message: String
}

struct Response<T: Decodable>: ResponseType {
    let statusCode: Int
    let message: String
    let data: T
    
    enum CodingKeys: String, CodingKey {
        case statusCode
        case message
        case data
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        statusCode = try values.decode(Int.self, forKey: .statusCode)
        message = try values.decode(String.self, forKey: .message)
        data = try values.decode(T.self, forKey: .data)
    }
}

struct ResponseWithOptionalData<T: Decodable>: ResponseType {
    let statusCode: Int
    let message: String
    let data: T?
    
    enum CodingKeys: String, CodingKey {
        case statusCode
        case message
        case data
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        statusCode = try values.decode(Int.self, forKey: .statusCode)
        message = try values.decode(String.self, forKey: .message)
        data = try? values.decode(T.self, forKey: .data)
    }
}

struct VerifyPhoneNumberResponse: ResponseType {
    let statusCode: Int
    let message: String
    let isCorrectPin: Bool
    
    enum CodingKeys: String, CodingKey {
        case statusCode
        case message
        case data
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let statusCode = try values.decode(Int.self, forKey: .statusCode)
        
        if statusCode == 60022 {
            isCorrectPin = false
            self.statusCode = 0 //NOTE: mark status code like all success because manager provider will mark response like failure
        } else {
            let data = try values.decode(UserIdModel.self, forKey: .data)
            UserDefaults.standard.userId =  data.userId
            isCorrectPin = true
            self.statusCode = statusCode
        }
        
        message = try values.decode(String.self, forKey: .message)
    }
    
    private struct UserIdModel: Decodable {
        let userId: String
    }
}
