//
//  ScoreModelType.swift
//  ChelseabandSDK
//
//  Created by Sergey Pohrebnuak on 01.12.2021.
//

import Foundation

protocol ScoreModelType {
    var wakeUpScreen: UInt8 { get }
    var titleType: UInt8 { get }
    var opposingTeamID: UInt8 { get }
    var time: UInt16 { get }
    var title: String { get }
    var body: String? { get }
    func encodeToData() -> Data
}
