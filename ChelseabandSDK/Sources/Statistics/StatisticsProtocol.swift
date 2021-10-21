//
//  StatisticsProtocol.swift
//  ChelseabandSDK
//
//  Created by Sergey Pohrebnuak on 16.03.2021.
//

import Foundation

protocol Statistics {
    func register(fmcToken: String)
    func register(bandMacAddress: String)
    func register(bandName: String)
    func register(bandPin: String)
    func register(phoneNumber: String)
    func sendBand(status: Bool)
    func sendLocation(latitude: Double, longitude: Double)
    func sendAccelerometer(_ data: [[Double]], forId id: String)
    func sendVotingResponse(_: VotingResult, _: String)
    func sendReaction(_: String)
}
