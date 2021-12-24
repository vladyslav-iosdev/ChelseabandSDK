//
//  SurveyResponses.swift
//  ChelseabandSDK
//
//  Created by Sergey Pohrebnuak on 24.12.2021.
//

import Foundation

public protocol SurveyResponseType {
    var response: String { get }
    var count: Int { get }
}

public struct SurveyResponse: Decodable, SurveyResponseType {
    public let response: String
    public let count: Int
}

struct SurveyResponses: Decodable {
    let responses: [SurveyResponseType]
    
    enum CodingKeys: String, CodingKey {
        case responses
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        responses = try values.decode([SurveyResponse].self, forKey: .responses)
    }
}
