//
//  Data.swift
//  ChelseabandSDK
//
//  Created by Sergey Pohrebnuak on 16.08.2021.
//

import UIKit

extension Data {    
    var uint8: UInt8 {
        var number: UInt8 = 0
        self.copyBytes(to:&number, count: MemoryLayout<UInt8>.size)
        return number
    }
}
