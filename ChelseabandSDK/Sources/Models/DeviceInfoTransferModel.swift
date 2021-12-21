//
//  DeviceInfoTransferModel.swift
//  ChelseabandSDK
//
//  Created by Sergey Pohrebnuak on 20.12.2021.
//

import Foundation

struct DeviceInfoTransferModel: DeviceInfoTransferModelType {
    private let serial: String
    private let hardwareVersion: String
    private let manufacturer: String
    private let model: String
    private let software: String
    private let firmwareVersion: String
    
    init?(serialData: Data, hardwareData: Data, manufacturerData: Data, modelData: Data, softwareData: Data, firmwareVersion: String?) {
        guard let serial = String(data: serialData, encoding: .utf8),
              let hardwareVersion = String(data: hardwareData, encoding: .utf8),
              let manufacturer = String(data: manufacturerData, encoding: .utf8),
              let model = String(data: modelData, encoding: .utf8),
              let software = String(data: softwareData, encoding: .utf8),
              let firmwareVersion = firmwareVersion else { return nil }
        
        self.serial = serial
        self.hardwareVersion = hardwareVersion
        self.manufacturer = manufacturer
        self.model = model
        self.software = software
        self.firmwareVersion = firmwareVersion
    }
    
    func getLikeDict() -> [String: Any] {
        [
            "fanbandUUID": serial,
            "manufacturer": manufacturer,
            "model": model,
            "firmwareVersion": firmwareVersion,
            "hardwareVersion": hardwareVersion,
            "software": software
        ]
    }
}
