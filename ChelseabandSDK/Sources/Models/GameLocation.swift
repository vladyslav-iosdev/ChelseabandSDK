//
//  GameLocation.swift
//  ChelseabandSDK
//
//  Created by Sergey Pohrebnuak on 24.12.2021.
//

import Foundation

protocol GameLocationType {
    var latitude: Double { get }
    var longitude: Double { get }
    var radius: Double { get }
}

public enum GameLocationError: LocalizedError {
    case latitudeOrLongitudeNotADouble
    
    public var errorDescription: String? {
        switch self {
        case .latitudeOrLongitudeNotADouble:
            return "Can't convert latitude or longitude to double, please check response"
        }
    }
}

struct GameLocation: Decodable, GameLocationType {
    let latitude: Double
    let longitude: Double
    let radius: Double
    
    enum CodingKeys: String, CodingKey {
        case latitude = "lat"
        case longitude = "lng"
        case radius = "inAreaRange"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let latitudeString = try values.decode(String.self, forKey: .latitude)
        let longitudeString = try values.decode(String.self, forKey: .longitude)
        if let latitude = Double(latitudeString),
           let longitude = Double(longitudeString) {
            self.latitude = latitude
            self.longitude = longitude
        } else {
            throw GameLocationError.latitudeOrLongitudeNotADouble
        }
        radius = try values.decode(Double.self, forKey: .radius)
    }
}
