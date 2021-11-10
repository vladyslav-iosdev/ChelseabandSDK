//
//  API.swift
//  ChelseabandSDK
//
//  Created by Sergey Pohrebnuak on 16.03.2021.
//

import Foundation
import RxSwift

public enum APIError: LocalizedError {
    case missingRequiredData
    case cantConvertDataToJSON
    case incorrectVerificationCode
    case customServerError(String)
    
    public var errorDescription: String? {
        switch self {
        case .missingRequiredData:
            return "Missing required data in response"
        case .cantConvertDataToJSON:
            return "Can't convert data to JSON dictionary"
        case .incorrectVerificationCode:
            return "Incorrect verification code"
        case .customServerError(let description):
            return description
        }
    }
}

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
            case fcm
            case mac
            case status
            case name
            case sendOTP = "phone/send-code"
            case verifyOTP = "phone/verify"
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
    func register(fcmToken token: String) {
        UserDefaults.standard.pushToken = token
        sendRequest(Modules.fanbands(.fcm).path,
                    method: .post,
                    jsonParams: ["fcm": token])
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
    
    func register(phoneNumber: String) -> Observable<Void> {
        Observable<Void>.create { [weak self] observer in
            guard let strongSelf = self else { return Disposables.create() }
            
            strongSelf.sendRequest(Modules.fanbands(.sendOTP).path,
                                   method: .post,
                                   jsonParams: ["phone": phoneNumber])
            { result in
                switch result {
                case .success(let dictionary):
                    observer.onNext(())
                case .failure(let error):
                    observer.onError(error)
                }
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }
    
    func verify(phoneNumber: String, withOTPCode OTPCode: String) -> Observable<Bool> {
        Observable<Bool>.create { [weak self] observer in
            guard let strongSelf = self else { return Disposables.create() }
            
            let jsonData = [
                "phone": phoneNumber,
                "code": OTPCode
            ]
            strongSelf.sendRequest(Modules.fanbands(.verifyOTP).path,
                                   method: .post,
                                   jsonParams: jsonData)
            { result in
                switch result {
                case .success(let dictionary):
                    observer.onNext(true)
                case .failure(let error):
                    if case APIError.incorrectVerificationCode = error {
                        observer.onNext(false)
                    } else {
                        observer.onError(error)
                    }
                }
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
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
    private func sendRequest(_ url: String, method: Method,
                             jsonParams: [String : Any]? = nil,
                             callback: ((Result<[String: Any], Error>) -> ())? = nil) {
            
        guard let url = URL(string: url) else { return }
        let session = urlSession
        var request = HeaderHelper().generateURLRequest(path: url)
        request.httpMethod = method.rawValue
        request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringCacheData
        if let jsonParams = jsonParams {
            request.httpBody = try? JSONSerialization.data(withJSONObject: jsonParams, options: .prettyPrinted)
        }
        
        let task = session.dataTask(with: request, completionHandler: {(data, response, error) in
            session.finishTasksAndInvalidate()
            if let error = error {
                print("❌", url, response)
                callback?(.failure(error))
                return
            }
            
            guard let jsonData = data else {
                print("❌", url, response)
                callback?(.failure(APIError.missingRequiredData))
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: jsonData, options: [])
                
                guard let dictionary = json as? [String: Any] else {
                    print("❌", url, response)
                    callback?(.failure(APIError.cantConvertDataToJSON))
                    return
                }
                
                if dictionary["statusCode"] as? Int == 0 {
                    print("✅", url, json)
                    callback?(.success(dictionary))
                } else if dictionary["statusCode"] as? Int == 60022 {
                    print("❌", url, response)
                    callback?(.failure(APIError.incorrectVerificationCode))
                } else {
                    print("❌", url, response)
                    let errorDescription = dictionary["message"] as? String ?? "Unknown server error"
                    let error = APIError.customServerError(errorDescription)
                    callback?(.failure(error))
                }
            } catch let error {
                print("❌", url, response)
                callback?(.failure(error))
            }
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
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(appKey, forHTTPHeaderField: "experiwear-key")
            request.setValue(token, forHTTPHeaderField: "experiwear-fcm")
            return request
        }
    }
}
