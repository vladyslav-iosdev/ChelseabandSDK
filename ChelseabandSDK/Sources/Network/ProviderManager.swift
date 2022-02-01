//
//  ProviderManager.swift
//  ChelseabandSDK
//
//  Created by Sergey Pohrebnuak on 24.12.2021.
//

import Alamofire

enum Result<T: Decodable> {
    case success(T)
    case failure(Error)
}

public enum ProviderManagerError: LocalizedError {
    case unknownError(String)
    
    public var errorDescription: String? {
        switch self {
        case .unknownError(let error):
            return error
        }
    }
}

final class ProviderManager<T: URLRequestBuilder> {
    func send<U: ResponseType>(service: T, decodeType: U.Type, callback: @escaping (Result<U>) -> Void) {
        guard let urlRequest = service.urlRequest else { return }
        
        AF.request(urlRequest).responseDecodable(of: U.self) { response in
            print(response.shortDebugInfo)
            switch response.result {
            case .success(let model):
                if model.statusCode == 0 {
                    callback(.success(model))
                } else {
                    callback(.failure(ProviderManagerError.unknownError(model.message)))
                }
            case .failure(let error):
                callback(.failure(error))
            }
        }
    }
    
    func send(service: T, callback: (() -> Void)? = nil) {
        guard let urlRequest = service.urlRequest else { return }
        AF.request(urlRequest).responseJSON { response in
            print(response.shortDebugInfo)
            callback?()
        }
    }
}
