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

extension Collection {
    func chunked(by n: Int) -> [SubSequence] {
        var startIndex = self.startIndex
        let count = self.count

        return (0..<count/n).map { _ in
            var endIndex = index(startIndex, offsetBy: n, limitedBy: self.endIndex) ?? self.endIndex
            if count % n > 0, distance(from: self.startIndex, to: startIndex) > (count / n) {
                endIndex = self.endIndex
            }

            defer { startIndex = endIndex }
            return self[startIndex..<endIndex]
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
        return String(format:"%02x", self)
    }
}
