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
    var suotaServStatusCharacteristic: ID { get }
    
    var fanbandService: ID { get }
    var ledCharacteristic: ID { get }
    var vibrationCharacteristic: ID { get }
    
    var advertisementServices: [ID] { get }
    var servicesForDiscovering: [ID] { get }
    /**
        If one of this characteristic will not found device will be immediately disconnected
     */
    var mandatoryCharacteristicIDForWork: [String] { get }
}

public enum ChelseabandConfiguration: Configuration {
    case `default`
    
    public var batteryService: ID {
        switch self {
        case .default:
            return ID(string: "180F")
        }
    }
    
    public var batteryCharacteristic: ID {
        switch self {
        case .default:
            return ID(string: "2A19")
        }
    }
    
    public var deviceInfoService: ID {
        switch self {
        case .default:
            return ID(string: "180A")
        }
    }
    
    public var firmwareVersionCharacteristic: ID {
        switch self {
        case .default:
            return ID(string: "2A28")
        }
    }
    
    public var fanbandService: ID {
        switch self {
        case .default:
            return ID(string: "00000000-1111-2222-2222-333333333333")
        }
    }
    
    public var ledCharacteristic: ID {
        switch self {
        case .default:
            return ID(string: "11111111-0000-0000-0000-111111111114")
        }
    }
    
    public var vibrationCharacteristic: ID {
        switch self {
        case .default:
            return ID(string: "11111111-0000-0000-0000-111111111113")
        }
    }
    
    public var suotaService: ID {
        switch self {
        case .default:
            return ID(string: "FEF5")
        }
    }
    
    public var suotaPatchDataCharSizeCharacteristic: ID {
        switch self {
        case .default:
            return ID(string: "42C3DFDD-77BE-4D9C-8454-8F875267FB3B")
        }
    }
    
    public var suotaMtuCharSizeCharacteristic: ID {
        switch self {
        case .default:
            return ID(string: "B7DE1EEA-823D-43BB-A3AF-C4903DFCE23C")
        }
    }
    
    public var suotaMemDevCharacteristic: ID {
        switch self {
        case .default:
            return ID(string: "8082CAA8-41A6-4021-91C6-56F9B954CC34")
        }
    }
    
    public var suotaGpioMapCharacteristic: ID {
        switch self {
        case .default:
            return ID(string: "724249F0-5EC3-4B5F-8804-42345AF08651")
        }
    }
    
    public var suotaPatchLenCharacteristic: ID {
        switch self {
        case .default:
            return ID(string: "9D84B9A3-000C-49D8-9183-855B673FDA31")
        }
    }
    
    public var suotaPatchDataCharacteristic: ID {
        switch self {
        case .default:
            return ID(string: "457871E8-D516-4CA1-9116-57D0B17B9CB2")
        }
    }
    
    public var suotaServStatusCharacteristic: ID {
        switch self {
        case .default:
            return ID(string: "5F78DF94-798C-46F5-990A-B3EB6A065C88")
        }
    }
    
    public var advertisementServices: [ID] {
        [suotaService]
    }
    public var servicesForDiscovering: [ID] {
        [batteryService, deviceInfoService, suotaService, fanbandService]
    }
    public var mandatoryCharacteristicIDForWork: [String] {
        [
            batteryCharacteristic.uuidString,
            firmwareVersionCharacteristic.uuidString,
            suotaPatchDataCharSizeCharacteristic.uuidString,
            suotaMtuCharSizeCharacteristic.uuidString,
            suotaMemDevCharacteristic.uuidString,
            suotaGpioMapCharacteristic.uuidString,
            suotaPatchLenCharacteristic.uuidString,
            suotaPatchDataCharacteristic.uuidString,
            suotaServStatusCharacteristic.uuidString,
            ledCharacteristic.uuidString,
            vibrationCharacteristic.uuidString
        ]
    }
}
