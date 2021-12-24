//
//  LatestFirmwareInfo.swift
//  ChelseabandSDK
//
//  Created by Sergey Pohrebnuak on 24.12.2021.
//

import Foundation

protocol LatestFirmwareInfoType {
    var firmwareVersion: String { get }
    var firmwareURL: URL { get }
}

public enum LatestFirmwareInfoError: LocalizedError {
    case incorrectFirmwareURL
    
    public var errorDescription: String? {
        switch self {
        case .incorrectFirmwareURL:
            return "Can't convert firmware file path to URL"
        }
    }
}

struct LatestFirmwareInfo: Decodable, LatestFirmwareInfoType {
    let firmwareVersion: String
    let firmwareURL: URL
       
    enum CodingKeys: String, CodingKey {
        case firmwareVersion = "version"
        case firmwareURL = "fileUrl"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        firmwareVersion = try values.decode(String.self, forKey: .firmwareVersion)
        let firmwareStringURL = try values.decode(String.self, forKey: .firmwareURL)
        if let firmwareURL = URL(string: firmwareStringURL){
            self.firmwareURL = firmwareURL
        } else {
            throw LatestFirmwareInfoError.incorrectFirmwareURL
        }
    }
}
