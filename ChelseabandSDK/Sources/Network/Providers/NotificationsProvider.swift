//
//  NotificationsProvider.swift
//  ChelseabandSDK
//
//  Created by Sergey Pohrebnuak on 24.12.2021.
//

import Alamofire

enum NotificationsProvider: URLRequestBuilder {
    case react(String)
    case answer(id: String, answer: Int?)
    case surveyResponse(String)
    
    var path: String {
        switch self {
        case .react(let id):
            return "notifications/\(id)/react"
        case .answer(let params):
            return "notifications/\(params.id)/answer"
        case .surveyResponse(let id):
            return "notifications/\(id)/survey-responses"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .react:
            return .patch
        case .answer:
            return .patch
        case .surveyResponse:
            return .get
        }
    }
    
    var parameters: Parameters? {
        switch self {
        case .react:
            return nil
        case .answer(let params):
            return ["answer": "\(params.answer ?? -1)"]
        case .surveyResponse:
            return nil
        }
    }
}
