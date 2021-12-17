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
    case missedUserId
    case missedSurveyResponses
    case missedSomeDataInSurveyResponses
    case noPayloadDataInGameScoreResponse
    case oppositeTeamLogoNotLoaded
    case noScoreModelJSONStringInScoreResponse
    case missedFirmwareResponse
    case noSomeDataInFirmwareResponse
    case customServerError(String)
    
    public var errorDescription: String? {
        switch self {
        case .missingRequiredData:
            return "Missing required data in response"
        case .cantConvertDataToJSON:
            return "Can't convert data to JSON dictionary"
        case .incorrectVerificationCode:
            return "Incorrect verification code"
        case .missedUserId:
            return "User id not found in verification response"
        case .missedSurveyResponses:
            return "Survey responses not found"
        case .missedSomeDataInSurveyResponses:
            return "In survey responses not found answer or count"
        case .noPayloadDataInGameScoreResponse:
            return "No payload data in game score api call"
        case .oppositeTeamLogoNotLoaded:
            return "Opposite team logo not loaded"
        case .noScoreModelJSONStringInScoreResponse:
            return "Score model JSON String not found in score response"
        case .missedFirmwareResponse:
            return "No payload data in firmware response"
        case .noSomeDataInFirmwareResponse:
            return "No some data in firmware response or data incorrect"
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
        case get = "GET"
        case post = "POST"
        case patch = "PATCH"
    }
    
    private enum Modules {
        private var baseURL: String { UserDefaults.standard.apiBaseEndpoint }
        
        case auth(_ endpoint: AuthEndpoint)
        case games(_ endpoint: GamesEndpoint)
        case users(_ endpoint: UsersEndpoint)
        case notifications(_ endpoint: NotificationsEndpoint)
        case tickets(_ endpoint: TicketsEndpoint)
        case firmwares(_ endpoint: FirmwaresEndpoint)
        
        enum AuthEndpoint: String {
            case sendOTP = "phone/send-code"
            case verifyOTP = "phone/verify"
        }
        
        enum GamesEndpoint: String {
            case score
        }
        
        enum UsersEndpoint: String {
            case fcm
            case connectFanband = "connect-fanband"
            case status
            case inArea = "in-area"
        }
        
        enum NotificationsEndpoint {
            case react(String)
            case answer(String)
            case surveyResponse(String)
            
            var rawValue: String {
                switch self {
                case .react(let id):
                    return "\(id)/react"
                case .answer(let id):
                    return "\(id)/answer"
                case .surveyResponse(let id):
                    return "\(id)/survey-responses"
                }
            }
        }
        
        enum TicketsEndpoint: String {
            case bandTicket = "band-ticket"
        }
        
        enum FirmwaresEndpoint: String {
            case latest
        }
        
        var path: String {
            var endpointURL: String!
            
            switch self {
            case .auth(let endpoint):
                endpointURL = endpoint.rawValue
            case .games(let endpoint):
                endpointURL = endpoint.rawValue
            case .users(let endpoint):
                endpointURL = endpoint.rawValue
            case .notifications(let endpoint):
                endpointURL = endpoint.rawValue
            case .tickets(let endpoint):
                endpointURL = endpoint.rawValue
            case .firmwares(let endpoint):
                endpointURL = endpoint.rawValue
            }
            
            return baseURL + self.getModuleRawValue() + endpointURL
        }
        
        private func getModuleRawValue() -> String {
            switch self {
            case .auth(_):
                return "auth/"
            case .games(_):
                return "games/"
            case .users(_):
                return "users/"
            case .notifications(_):
                return "notifications/"
            case .tickets(_):
                return "tickets/"
            case .firmwares(_):
                return "firmwares/"
            }
        }
    }
    
    // MARK: - Public functions
    func register(fcmToken token: String) {
        sendRequest(Modules.users(.fcm).path,
                    method: .patch,
                    jsonParams: ["fcm": token])
    }
    
    func connectFanband(bandUUID: String) {
        sendRequest(Modules.users(.connectFanband).path,
                               method: .patch,
                               jsonParams: ["fanbandUUID": bandUUID])
        { result in
            switch result {
            case .success(let dictionary):
                break
            case .failure(let error):
                break
            }
        }
    }
    
    func register(phoneNumber: String) -> Observable<Void> {
        Observable<Void>.create { [weak self] observer in
            guard let strongSelf = self else { return Disposables.create() }
            
            strongSelf.sendRequest(Modules.auth(.sendOTP).path,
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
    
    func verify(phoneNumber: String, withOTPCode OTPCode: String, andFCM fcm: String) -> Observable<Bool>
    {
        Observable<Bool>.create { [weak self] observer in
            guard let strongSelf = self else { return Disposables.create() }
            
            let jsonData = [
                "phone": phoneNumber,
                "code": OTPCode,
                "fcm": fcm
            ]
            strongSelf.sendRequest(Modules.auth(.verifyOTP).path,
                                   method: .post,
                                   jsonParams: jsonData)
            { result in
                switch result {
                case .success(let dictionary):
                    if let userId = (dictionary["data"] as? [String: Any])?["userId"] as? String {
                        UserDefaults.standard.userId = userId
                        observer.onNext(true)
                    } else {
                        observer.onError(APIError.missedUserId)
                    }
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
    
    func getCurrentScore() -> Observable<(image: Data, scoreModel: Data)> {
        Observable<(image: Data, scoreModel: Data)>.create { [weak self] observer in
            guard let strongSelf = self else { return Disposables.create() }
            
            strongSelf.sendRequest(Modules.games(.score).path, method: .get) { result in
                switch result {
                case .success(let dictionary):
                    guard let scoreJSON = dictionary["data"] as? [String: Any]
                    else {
                        observer.onError(APIError.noPayloadDataInGameScoreResponse)
                        return
                    }
                    
                    guard let binImageURL = scoreJSON["binImage"] as? String,
                          let imageURL = URL(string: binImageURL),
                          let imageData = try? Data(contentsOf: imageURL)
                    else {
                        observer.onError(APIError.oppositeTeamLogoNotLoaded)
                        return
                    }
                    
                    guard let scoreModelJSONString = scoreJSON["scoreJsonString"] as? String,
                          let scoreModelData = scoreModelJSONString.data(using: .utf8)
                    else {
                        observer.onError(APIError.noScoreModelJSONStringInScoreResponse)
                        return
                    }

                    observer.onNext((image: imageData, scoreModel: scoreModelData))
                case .failure(let error):
                    observer.onError(error)
                }
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }
    
    func sendBand(status: Bool, callback: (() -> Void)?) {
        sendRequest(Modules.users(.status).path,
                    method: .patch,
                    jsonParams: ["status": status]) { _ in callback?() }
    }
    
    func sendLocation(isInArea: Bool) {
        sendRequest(Modules.users(.inArea).path,
                    method: .patch,
                    jsonParams: ["isInArea": isInArea])
    }
    
    func sendVotingResponse(_ response: Int?, _ id: String) -> Observable<Void> {
        Observable<Void>.create { [weak self] observer in
            guard let strongSelf = self else { return Disposables.create() }
            strongSelf.sendRequest(Modules.notifications(.answer(id)).path,
                                   method: .patch,
                                   jsonParams: ["answer": "\(response ?? -1)"])
            { result in
                switch result {
                case .success(let json):
                    observer.onNext(())
                case .failure(let error):
                    observer.onError(error)
                }
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }
    
    func sendReaction(_ id: String) {
        sendRequest(Modules.notifications(.react(id)).path,
                    method: .patch)
    }
    
    func fetchTicket() -> Observable<TicketType?> {
        Observable<TicketType?>.create { [weak self] observer in
            guard let strongSelf = self else { return Disposables.create() }
            
            strongSelf.sendRequest(Modules.tickets(.bandTicket).path,
                                   method: .get)
            { result in
                switch result {
                case .success(let json):
                    let decoder = JSONDecoder()
                    if let jsonTicket = json["data"] as? [String: Any],
                       let ticketData = try? JSONSerialization.data(withJSONObject: jsonTicket),
                       let ticket = try? decoder.decode(Ticket.self, from: ticketData)
                    {
                        observer.onNext(ticket)
                    } else {
                        observer.onNext(nil)
                    }
                case .failure(let error):
                    observer.onError(error)
                }
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }
    
    func fetchSurveyResponses(forNotificationId id: String) -> Observable<[(answer: String, count: Int)]> {
        Observable<[(answer: String, count: Int)]>.create { [weak self] observer in
            guard let strongSelf = self else { return Disposables.create() }
            
            strongSelf.sendRequest(Modules.notifications(.surveyResponse(id)).path, method: .get) { result in
                switch result {
                case .success(let json):
                    guard let surveyResponses = (json["data"] as? [String: Any])?["responses"] as? [[String: Any]]
                    else {
                        observer.onError(APIError.missedSurveyResponses)
                        return
                    }
                    
                    var result = [(answer: String, count: Int)]()
                    do {
                        try surveyResponses.forEach {
                            guard let answer = $0["response"] as? String,
                                  let count = $0["count"] as? Int
                            else { throw APIError.missedSomeDataInSurveyResponses }
                            
                            result.append((answer, count))
                        }
                        observer.onNext(result)
                    } catch let error {
                        observer.onError(error)
                    }
                case .failure(let error):
                    observer.onError(error)
                }
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }
    
    func fetchFirmware() -> Observable<(version: String, firmwareURL: URL)> {
        Observable<(version: String, firmwareURL: URL)>.create { [weak self] observer in
            guard let strongSelf = self else { return Disposables.create() }
            
            strongSelf.sendRequest(Modules.firmwares(.latest).path,
                                   method: .get)
            { result in
                switch result {
                case .success(let json):
                    guard let firmwareResponses = json["data"] as? [String: Any] else {
                        observer.onError(APIError.missedFirmwareResponse)
                        return
                    }
                    
                    if let firmwareVersion = firmwareResponses["version"] as? String,
                       let firmwarePath = firmwareResponses["fileUrl"] as? String,
                       let firmwareURL = URL(string: firmwarePath)
                    {
                        observer.onNext((version: firmwareVersion, firmwareURL: firmwareURL))
                    } else {
                        observer.onError(APIError.noSomeDataInFirmwareResponse)
                    }
                case .failure(let error):
                    observer.onError(error)
                }
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
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
                    print("✅", url, dictionary)
                    callback?(.success(dictionary))
                } else if dictionary["statusCode"] as? Int == 60022 {
                    print("❌", url, dictionary)
                    callback?(.failure(APIError.incorrectVerificationCode))
                } else {
                    print("❌", url, dictionary)
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
        private let userId = UserDefaults.standard.userId
    
        func generateURLRequest(path: URL) -> URLRequest {
            var request = URLRequest(url: path)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(appKey, forHTTPHeaderField: "experiwear-key")
            request.setValue(userId, forHTTPHeaderField: "user-id")
            
            return request
        }
    }
}
