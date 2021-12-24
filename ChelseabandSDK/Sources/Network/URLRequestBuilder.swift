//
//  URLRequestBuilder.swift
//  ChelseabandSDK
//
//  Created by Sergey Pohrebnuak on 24.12.2021.
//

import Alamofire

protocol URLRequestBuilder: URLRequestConvertible {
    var baseURL: String { get }
    var path: String { get }
    var headers: HTTPHeaders? { get }
    var parameters: Parameters? { get }
    var method: HTTPMethod { get }
}

extension URLRequestBuilder {
    var baseURL: String { UserDefaults.standard.apiBaseEndpoint }

    var headers: HTTPHeaders? {
        HTTPHeaders([
            .init(name: "Content-Type", value: "application/json"),
            .init(name: "experiwear-key", value: UserDefaults.standard.apiKey),
            .init(name: "user-id", value: UserDefaults.standard.userId ?? "")
        ])
    }
    
    var parameters: Parameters? { return nil }
    
    func asURLRequest() throws -> URLRequest {
        let url = try baseURL.asURL()
        
        var request = URLRequest(url: url.appendingPathComponent(path))
        request.method = method
        request.allHTTPHeaderFields = headers?.dictionary
        let encoding = JSONEncoding.default
        return try encoding.encode(request, with: parameters)
    }
}
