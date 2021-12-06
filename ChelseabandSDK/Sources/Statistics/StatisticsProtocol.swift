//
//  StatisticsProtocol.swift
//  ChelseabandSDK
//
//  Created by Sergey Pohrebnuak on 16.03.2021.
//

import RxSwift

protocol Statistics {
    func register(fcmToken: String)
    func register(bandMacAddress: String)
    func register(bandName: String)
    func register(bandPin: String)
    func register(phoneNumber: String) -> Observable<Void>
    func verify(phoneNumber: String, withOTPCode OTPCode: String, andFCM: String) -> Observable<Bool>
    func sendBand(status: Bool)
    func sendLocation(latitude: Double, longitude: Double)
    func sendAccelerometer(_ data: [[Double]], forId id: String)// TODO: remove in future
    func sendVotingResponse(_: VotingResult, _: String)
    func sendReaction(_: String)
    func fetchTicket() -> Observable<TicketType?>
    func fetchSurveyResponses(forNotificationId id: String) -> Observable<[String: Int]>
}
