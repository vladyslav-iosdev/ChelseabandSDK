//
//  Data.swift
//  ChelseabandSDK
//
//  Created by Sergey Pohrebnuak on 16.08.2021.
//

import UIKit

extension Data {
    var uint64: UInt64 {
        withUnsafeBytes { $0.load(as: UInt64.self) }
    }
}
