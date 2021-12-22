//
//  Peripheral.swift
//  ChelseabandSDK
//
//  Created by Sergey Pohrebnuak on 09.12.2021.
//

import Foundation

extension Peripheral {
    var UUID: String? {
        guard let manufacturerData = advertisementData.advertisementData["kCBAdvDataManufacturerData"] as? Data else { return nil }
                            
        var manufacturerBytes = [UInt8](manufacturerData)
        manufacturerBytes.removeFirst()
        manufacturerBytes.removeFirst()
        return Data(manufacturerBytes).hexEncodedString()
    }
}
