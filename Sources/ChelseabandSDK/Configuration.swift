//
//  Configuration.swift
//  ChelseabandSDK
//
//  Created by Vladyslav Shepitko on 24.11.2020.
//

import Foundation

public protocol Configuration {
    var service: ID { get }
    var writeCharacteristic: ID { get }
    var readCharacteristic: ID { get }
}

