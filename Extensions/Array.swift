//
//  Array.swift
//  ChelseabandSDK
//
//  Created by Vladyslav Shepitko on 17.12.2020.
//

import UIKit

public extension FixedWidthInteger {
    var data: Data {
        let data = withUnsafeBytes(of: self) { Data($0) }
        return data
    }
}

public extension Double {
    var data: Data {
        let data = withUnsafeBytes(of: self) { Data($0) }
        return data
    }
}

public extension Array {
    func chunked(by chunkSize: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: chunkSize).map {
            Array(self[$0..<Swift.min($0 + chunkSize, self.count)])
        }
    }
}

public extension Data {

    var bytes: [UInt8] {
        .init(self)
    }

    var hex: String {
        return map { String(format: "%02x", $0) }.joined()
    }
}

public extension Int {
    var hex: String {
        return String(format:"%02X", self)
    }
}
