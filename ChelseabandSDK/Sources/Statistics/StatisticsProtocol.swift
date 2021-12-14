//
//  StatisticsProtocol.swift
//  ChelseabandSDK
//
//  Created by Sergey Pohrebnuak on 16.03.2021.
//

import RxSwift

protocol Statistics {
    func connectFanband(bandUUID: String)
    func getCurrentScore() -> Observable<(image: Data, scoreModel: Data)>
    func register(fcmToken: String)
    func register(phoneNumber: String) -> Observable<Void>
    func verify(phoneNumber: String, withOTPCode OTPCode: String, andFCM: String) -> Observable<Bool>
    func sendBand(status: Bool)
    func sendLocation(isInArea: Bool)
    func sendVotingResponse(_: Int?, _: String) -> Observable<Void>
    func sendReaction(_: String)
    func fetchTicket() -> Observable<TicketType?>
    func fetchSurveyResponses(forNotificationId id: String) -> Observable<[String: Int]>
}
