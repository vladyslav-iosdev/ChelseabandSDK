//
//  Configuration.swift
//  ChelseabandSDK
//
//  Created by Vladyslav Shepitko on 24.11.2020.
//

import Foundation

public protocol Configuration {
    var batteryService: ID { get }
    var batteryCharacteristic: ID { get }
    
    var deviceInfoService: ID { get }
    var firmwareVersionCharacteristic: ID { get }
    
    var suotaService: ID { get }
    var suotaPatchDataCharSizeCharacteristic: ID { get }
    var suotaMtuCharSizeCharacteristic: ID { get }
    var suotaMemDevCharacteristic: ID { get }
    var suotaGpioMapCharacteristic: ID { get }
    var suotaPatchLenCharacteristic: ID { get }
    var suotaPatchDataCharacteristic: ID { get }
    var suotaMemInfoCharacteristic: ID { get }
    var suotaServStatusCharacteristic: ID { get }
    
    var advertisementServices: [ID] { get }
    var servicesForDiscovering: [ID] { get }
    /**
        If one of this characteristic will not found device will be immediately disconnected
     */
    var mandatoryCharacteristicIDForWork: [String] { get }
}

