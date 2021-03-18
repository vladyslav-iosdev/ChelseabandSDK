//
//  API.swift
//  ChelseabandSDK
//
//  Created by Sergey Pohrebnuak on 16.03.2021.
//

import Foundation

final class API: Statistics {

    // MARK: - Variables
    private var urlSession: URLSession {
        get {
            let configuration = URLSessionConfiguration.default
            configuration.urlCache = nil
            return URLSession(configuration: configuration)
        }
    }
    
    // MARK: - Enums
    private enum Method: String {
        case post = "POST"
        case patch = "PATCH"
    }
    
    private enum Modules {
        private var baseURL: String {return "https://hawks-dev.api.experiwear.com/"}
        
        case fanbands(_ endpoint: FanbandsEndpoint)
        
        enum FanbandsEndpoint: String {
            case fmc
            case mac
            case status
            case inArea = "in-area"
        }
        
        var path: String {
            var endpointURL: String!
            
            switch self {
            case .fanbands(let endpoint):
                endpointURL = endpoint.rawValue
            }
            
            return baseURL + self.getModuleRawValue() + endpointURL
        }
        
        private func getModuleRawValue() -> String {
            switch self {
            case .fanbands(_):
                return "fanbands/"
            }
        }
    }
    
    // MARK: - Public functions
    func register(fmcToken token: String) {
        UserDefaults.standard.save(token: token)
        sendRequest(Modules.fanbands(.fmc).path,
                    method: .post,
                    jsonParams: ["fmc": token])
    }
    
    func register(bandMacAddress mac: String) {
        sendRequest(Modules.fanbands(.mac).path,
                    method: .patch,
                    jsonParams: ["mac": mac])
    }
    
    func sendBand(status: Bool) {
        sendRequest(Modules.fanbands(.status).path,
                    method: .patch,
                    jsonParams: ["status": status])
    }
    
    func sendLocation(latitude: Double, longitude: Double) {
        sendRequest(Modules.fanbands(.inArea).path,
                    method: .patch,
                    jsonParams: ["lat": latitude,
                                 "lng": longitude])
    }
    
    // MARK: - Private functions
    @discardableResult
    private func sendRequest(_ url: String, method: Method,
                             jsonParams: [String : Any]? = nil) -> URLSessionDataTask {
            
        let url = URL(string: url)!
        let session = urlSession
        var request = HeaderHelper.generateURLRequest(path: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringCacheData
        if let jsonParams = jsonParams {
            request.httpBody = try? JSONSerialization.data(withJSONObject: jsonParams, options: .prettyPrinted)
        }
        
        let task = session.dataTask(with: request, completionHandler: {(data, response, error) in
            session.finishTasksAndInvalidate()
            guard   error == nil,
                    let jsonData = data,
                    let json = try? JSONSerialization.jsonObject(with: jsonData, options: [])
            else {
                print("❌ ERROR send api call \(String(describing: response))")
                return
            }
            print(json)
        })
        task.resume()
        return task
    }
}

extension API {
    struct HeaderHelper {
        private static let appKey = "ypIgNGcq203LYa1I4bnxXHV8Iz2lZf113uNag9QX56A9C07aEVWNsazmHVG3"
        private static let token = UserDefaults.standard.getToken()
    
        static func generateURLRequest(path: URL) -> URLRequest {
            var request = URLRequest(url: path)
            request.setValue(appKey, forHTTPHeaderField: "experiwear-key")
            request.setValue(token, forHTTPHeaderField: "experiwear-fmc")
            return request
        }
    }
}
