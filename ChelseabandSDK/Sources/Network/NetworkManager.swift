//
//  NetworkManager.swift
//  ChelseabandSDK
//
//  Created by Sergey Pohrebnuak on 16.03.2021.
//

import RxSwift

protocol NetworkManagerType {
    func register(fcmToken: String)
    func connectFanband(bandTransferModel: DeviceInfoTransferModelType)
    func sendBand(status: Bool, callback: (() -> Void)?)
    func sendLocation(isInArea: Bool)
    
    func getCurrentScore() -> Observable<(image: Data, scoreModel: Data)>
    func getPointForObserve() -> Observable<GameLocationType?>
    
    func fetchTicket() -> Observable<TicketType?>
    
    func fetchFirmware() -> Observable<LatestFirmwareInfoType>
    
    func register(phoneNumber: String) -> Single<Void>
    func verify(phoneNumber: String, withOTPCode OTPCode: String, andFCM: String) -> Single<Bool>
    
    func sendReaction(_: String)
    func sendVotingResponse(_: Int?, _: String) -> Single<Void>
    func fetchSurveyResponses(forNotificationId id: String) -> Single<[SurveyResponseType]>
}

extension NetworkManagerType {
    func sendBand(status: Bool, callback: (() -> Void)? = nil) {
        sendBand(status: status, callback: callback)
    }
}

final class NetworkManager: NetworkManagerType {
    // MARK: Users
    func register(fcmToken token: String) {
        ProviderManager().send(service: UsersProvider.fcm(token))
    }
    
    func connectFanband(bandTransferModel: DeviceInfoTransferModelType) {
        ProviderManager().send(service: UsersProvider.connectFanband(bandTransferModel))
    }
    
    func sendBand(status: Bool, callback: (() -> Void)?) {
        ProviderManager().send(service: UsersProvider.status(status)) { callback?() }
    }
    
    func sendLocation(isInArea: Bool) {
        ProviderManager().send(service: UsersProvider.inArea(isInArea))
    }
    
    // MARK: Games
    func getCurrentScore() -> Observable<(image: Data, scoreModel: Data)> {
        Observable<(image: Data, scoreModel: Data)>.create { [weak self] observer in
            
            ProviderManager().send(service: GamesProvider.score, decodeType: Response<ScoreResponse>.self) { apiResult in
                switch apiResult {
                case .success(let response):
                    observer.onNext((response.data.imageData, response.data.scoreModelData))
                case .failure(let error):
                    observer.onError(error)
                }
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }
    
    func getPointForObserve() -> Observable<GameLocationType?> {
        Observable<GameLocationType?>.create { [weak self] observer in
            
            ProviderManager().send(service: GamesProvider.location, decodeType: ResponseWithOptionalData<GameLocation>.self) { apiResult in
                switch apiResult {
                case .success(let response):
                    observer.onNext(response.data)
                case .failure(let error):
                    observer.onError(error)
                }
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }
    
    // MARK: Tickets
    func fetchTicket() -> Observable<TicketType?> {
        Observable<TicketType?>.create { [weak self] observer in
            
            ProviderManager().send(service: TicketsProvider.bandTicket, decodeType: ResponseWithOptionalData<Ticket>.self) { apiResult in
                switch apiResult {
                case .success(let response):
                    observer.onNext(response.data)
                case .failure(let error):
                    observer.onError(error)
                }
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }
    
    // MARK: Firmwares
    func fetchFirmware() -> Observable<LatestFirmwareInfoType> {
        Observable<LatestFirmwareInfoType>.create { [weak self] observer in
            
            ProviderManager().send(service: FirmwaresProvider.latest, decodeType: Response<LatestFirmwareInfo>.self) { apiResult in
                switch apiResult {
                case .success(let response):
                    observer.onNext(response.data)
                case .failure(let error):
                    observer.onError(error)
                }
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }
    
    // MARK: Auth
    func register(phoneNumber: String) -> Single<Void> {
        .create { single in
            
            ProviderManager().send(service: AuthProvider.sendOTP(phoneNumber), decodeType: ResponseWithoutData.self) { apiResult in
                switch apiResult {
                case .success(let _):
                    single(.success(()))
                case .failure(let error):
                    single(.error(error))
                }
            }
            
            return Disposables.create()
        }
    }
    
    func verify(phoneNumber: String, withOTPCode OTPCode: String, andFCM fcm: String) -> Single<Bool> {
        .create { single in
            
            let verifyProvider = AuthProvider.verify(phone: phoneNumber, code: OTPCode, fcm: fcm)
            ProviderManager().send(service: verifyProvider, decodeType: VerifyPhoneNumberResponse.self) { apiResult in
                switch apiResult {
                case .success(let model):
                    single(.success(model.isCorrectPin))
                case .failure(let error):
                    single(.error(error))
                }
            }
            
            return Disposables.create()
        }
    }
    
    // MARK: Notifications
    func sendReaction(_ id: String) {
        ProviderManager().send(service: NotificationsProvider.react(id))
    }
    
    func sendVotingResponse(_ response: Int?, _ id: String) -> Single<Void> {
        .create { single in
            
            ProviderManager().send(service: NotificationsProvider.answer(id: id, answer: response), decodeType: ResponseWithoutData.self) { apiResult in
                switch apiResult {
                case .success:
                    single(.success(()))
                case .failure(let error):
                    single(.error(error))
                }
            }
            
            return Disposables.create()
        }
    }
    
    func fetchSurveyResponses(forNotificationId id: String) -> Single<[SurveyResponseType]> {
        .create { single in
            
            ProviderManager().send(service: NotificationsProvider.surveyResponse(id), decodeType: Response<SurveyResponses>.self) { apiResult in
                switch apiResult {
                case .success(let response):
                    single(.success(response.data.responses))
                case .failure(let error):
                    single(.error(error))
                }
            }
            
            return Disposables.create()
        }
    }
}
