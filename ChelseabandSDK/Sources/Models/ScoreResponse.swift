//
//  ScoreResponse.swift
//  ChelseabandSDK
//
//  Created by Sergey Pohrebnuak on 24.12.2021.
//

import Foundation

public enum ScoreResponseError: LocalizedError {
    case oppositeTeamLogoNotLoaded
    case noScoreModelJSONStringInScoreResponse
    
    public var errorDescription: String? {
        switch self {
        case .oppositeTeamLogoNotLoaded:
            return "Opposite team logo not loaded"
        case .noScoreModelJSONStringInScoreResponse:
            return "Score model JSON String not found in score response"
        }
    }
}

struct ScoreResponse: Decodable {
    let imageData: Data
    let scoreModelData: Data
    
    enum CodingKeys: String, CodingKey {
        case binImage
        case scoreJsonString
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let imageStringURL = try values.decode(String.self, forKey: .binImage)
        if let imageURL = URL(string: imageStringURL),
           let imageData = try? Data(contentsOf: imageURL) {
            self.imageData = imageData
        } else {
            throw ScoreResponseError.oppositeTeamLogoNotLoaded
        }
        
        let scoreModelJSONString = try values.decode(String.self, forKey: .scoreJsonString)
        if let scoreModelData = scoreModelJSONString.data(using: .utf8) {
            self.scoreModelData = scoreModelData
        } else {
            throw ScoreResponseError.noScoreModelJSONStringInScoreResponse
        }
    }
}
