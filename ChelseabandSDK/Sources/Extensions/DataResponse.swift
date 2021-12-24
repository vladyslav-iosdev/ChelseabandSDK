//
//  DataResponse.swift
//  ChelseabandSDK
//
//  Created by Sergey Pohrebnuak on 24.12.2021.
//

import Alamofire

extension DataResponse {
    var debugInfo: String {
        switch self.result {
        case .success(let json):
            return """
            ✅ URL: \(request)

            📤Request:
            📤Headers:
            \((request?.headers ?? [:]).dictionary.map{ "\($0):\($1)" }.joined(separator: "\n"))
            📤Body:
            \(String(data: request?.httpBody ?? Data(), encoding: .utf8) ?? "")
                     
            📥Response:
            📥JSON:
            \(json)
            """
        case .failure(let error):
            return """
            ❌ URL: \(request)

            📤Request:
            📤Headers:
            \((request?.headers ?? [:]).dictionary.map{ "\($0):\($1)" }.joined(separator: "\n"))
            📤Body:
            \(String(data: request?.httpBody ?? Data(), encoding: .utf8) ?? "")
                     
            📥Response:
            📥Error:
            \(error)
            """
        }
    }
    
    var shortDebugInfo: String {
        switch self.result {
        case .success(let json):
            return """
            ✅ URL: \(request)
            \(json)
            """
        case .failure(let error):
            return """
            ❌ URL: \(request)
            \(error)
            """
        }
    }
}
