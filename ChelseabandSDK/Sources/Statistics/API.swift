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
        private var baseURL: String { UserDefaults.standard.apiBaseEndpoint }
        
        case fanbands(_ endpoint: FanbandsEndpoint)
        case notifications(_ endpoint: NotificationsEndpoint)
        case accelerometer(_ endpoint: AccelerometerEndpoint)
        
        enum FanbandsEndpoint: String {
            case fmc
            case mac
            case status
            case name
            case phone
            case pin
            case inArea = "in-area"
        }
        
        enum NotificationsEndpoint {
            case react(String)
            case answer(String)
            
            var rawValue: String {
                switch self {
                case .react(let id):
                    return "\(id)/react"
                case .answer(let id):
                    return "\(id)/answer"
                }
            }
        }
        
        enum AccelerometerEndpoint: String {
            case none = ""
        }
        
        var path: String {
            var endpointURL: String!
            
            switch self {
            case .fanbands(let endpoint):
                endpointURL = endpoint.rawValue
            case .notifications(let endpoint):
                endpointURL = endpoint.rawValue
            case .accelerometer(let endpoint):
                endpointURL = endpoint.rawValue
            }
            
            return baseURL + self.getModuleRawValue() + endpointURL
        }
        
        private func getModuleRawValue() -> String {
            switch self {
            case .fanbands(_):
                return "fanbands/"
            case .notifications(_):
                return "notifications/"
            case .accelerometer(_):
                return "accelerometer/"
            }
        }
    }
    
    // MARK: - Public functions
    func register(fmcToken token: String) {
        UserDefaults.standard.pushToken = token
        sendRequest(Modules.fanbands(.fmc).path,
                    method: .post,
                    jsonParams: ["fmc": token])
    }
    
    func register(bandMacAddress mac: String) {
        sendRequest(Modules.fanbands(.mac).path,
                    method: .patch,
                    jsonParams: ["mac": mac])
    }
    
    func register(bandName name: String) {
        sendRequest(Modules.fanbands(.name).path,
                    method: .patch,
                    jsonParams: ["name": name])
    }
    
    func register(bandPin pin: String) {
        sendRequest(Modules.fanbands(.pin).path,
                    method: .patch,
                    jsonParams: ["pin": pin])
    }
    
    func register(phoneNumber: String) {
        sendRequest(Modules.fanbands(.phone).path,
                    method: .patch,
                    jsonParams: ["phone": phoneNumber])
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

    func sendAccelerometer(_ data: [[Double]], forId id: String) {
        let json: [String: Any] = [
            "date": "\(Date())",
            "notificationId": id,
            "frame": ["data": data]
        ]
        sendRequest(Modules.accelerometer(.none).path,
                    method: .post,
                    jsonParams: json)
    }
    
    func sendVotingResponse(_ response: VotingResult, _ id: String) {
        sendRequest(Modules.notifications(.answer(id)).path,
                    method: .patch,
                    jsonParams: ["answer": "\(response.rawValue)"])
    }
    
    func sendReaction(_ id: String) {
        sendRequest(Modules.notifications(.react(id)).path,
                    method: .patch)
    }
    
    // MARK: - Private functions
    @discardableResult
    private func sendRequest(_ url: String, method: Method,
                             jsonParams: [String : Any]? = nil) {
            
        guard let url = URL(string: url) else { return }
        let session = urlSession
        var request = HeaderHelper().generateURLRequest(path: url)
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
                print("❌", url, response)
                return
            }
            print("✅", url, json)
        })
        task.resume()
    }
}

extension API {
    struct HeaderHelper {
        private let appKey = UserDefaults.standard.apiKey
        private let token = UserDefaults.standard.pushToken
    
        func generateURLRequest(path: URL) -> URLRequest {
            var request = URLRequest(url: path)
            request.setValue(appKey, forHTTPHeaderField: "experiwear-key")
            request.setValue(token, forHTTPHeaderField: "experiwear-fmc")
            return request
        }
    }
}
