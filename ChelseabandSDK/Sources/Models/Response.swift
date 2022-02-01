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

fileprivate enum ResponseCodingKeys: String, CodingKey {
    case message
}

extension ResponseType {
    static func getResponseMessage(from decoder: Decoder) -> String {
        let defaultMessage = "Message description not found"
        
        guard let values = try? decoder.container(keyedBy: ResponseCodingKeys.self) else {
            return defaultMessage
        }
        
        if let message = try? values.decode(String.self, forKey: .message) {
            return message
        } else if let messages = try? values.decode([String].self, forKey: .message) {
            return messages.joined(separator: "\n")
        } else {
            return defaultMessage
        }
    }
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
        message = Self.getResponseMessage(from: decoder)
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
        message = Self.getResponseMessage(from: decoder)
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
        
        switch statusCode {
        case 60022:
            isCorrectPin = false
            self.statusCode = 0 //NOTE: mark status code like all success because manager provider will mark response like failure
        case 0:
            let data = try values.decode(UserIdModel.self, forKey: .data)
            UserDefaults.standard.userId =  data.userId
            isCorrectPin = true
            self.statusCode = statusCode
        default:
            isCorrectPin = false
            self.statusCode = statusCode
        }
        
        self.message = Self.getResponseMessage(from: decoder)
    }
    
    private struct UserIdModel: Decodable {
        let userId: String
    }
}
