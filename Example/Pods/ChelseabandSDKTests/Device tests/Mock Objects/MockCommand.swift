//
//  MockCommand.swift
//  ChelseabandSDKTests
//
//  Created by Sergey Pohrebnuak on 13.09.2021.
//

import Foundation
import ChelseabandSDK

final class MockCommand: WritableCommand {
    
    enum TypeOfUUID {
        case existed
        case notExisted
    }
    
    let uuidForWrite: ID
    
    var dataForSend: Data {
        Data([1])
    }
    
    init(typeOfUUID: TypeOfUUID) {
        switch typeOfUUID {
        case .existed:
            uuidForWrite = ChelseabandConfiguration.default.ledCharacteristic
        case .notExisted:
            uuidForWrite = .init(string: "00000000-0000-0000-0000-000000000000")
        }
    }
}
