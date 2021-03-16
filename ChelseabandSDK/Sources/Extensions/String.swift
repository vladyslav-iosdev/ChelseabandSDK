//
//  String.swift
//  ChelseabandSDK
//
//  Created by Vladyslav Shepitko on 17.12.2020.
//

import UIKit

public extension String {

    func toHexEncodedString(uppercase: Bool = true, prefix: String = "", separator: String = "") -> String {
        return unicodeScalars.map { prefix + .init($0.value, radix: 16, uppercase: uppercase) }.joined(separator: separator)
    }

    var valueFromHex: UInt64 {
        let scanner = Scanner(string: self)
        var result: UInt64 = 0

        if scanner.scanHexInt64(&result) {
            //no op
        }

        return result
    }

    subscript(_ range: CountableRange<Int>) -> String {
        let start = index(startIndex, offsetBy: max(0, range.lowerBound))
        let end = index(start, offsetBy: min(self.count - range.lowerBound, range.upperBound - range.lowerBound))

        return String(self[start..<end])
    }

    subscript(_ range: CountablePartialRangeFrom<Int>) -> String {
        let start = index(startIndex, offsetBy: max(0, range.lowerBound))
         return String(self[start...])
    }

    /// Create `Data` from hexadecimal string representation
    ///
    /// This creates a `Data` object from hex string. Note, if the string has any spaces or non-hex characters (e.g. starts with '<' and with a '>'), those are ignored and only hex characters are processed.
    ///
    /// - returns: Data represented by this hexadecimal string.
    var hexadecimal: Data? {
        var data = Data(capacity: count / 2)

        let regex = try! NSRegularExpression(pattern: "[0-9a-f]{1,2}", options: .caseInsensitive)
        regex.enumerateMatches(in: self, range: NSRange(startIndex..., in: self)) { match, _, _ in
            let byteString = (self as NSString).substring(with: match!.range)
            let num = UInt8(byteString, radix: 16)!
            data.append(num)
        }

        guard data.count > 0 else { return nil }

        return data
    }

    var xor: String {
        guard count % 2 == 0 else {
            return String()
        }

        let xor = components(length: 2).compactMap {
            Int($0, radix: 16)
        }.reduce(0, { $0 ^ $1 })

        return String(format: "%02X", xor)
    }

    func components(length: Int) -> [String] {
        return stride(from: 0, to: count, by: length).map {
            let start = self.index(self.startIndex, offsetBy: $0)
            let end = self.index(start, offsetBy: length, limitedBy: self.endIndex) ?? self.endIndex

            return String(self[start..<end])
        }
    }

    var hex: String {
        return Data(utf8).hex
    }

    var hexaData: Data {
        .init(hexa)
    }

    var hexaBytes: [UInt8] {
        .init(hexa)
    }

    private var hexa: UnfoldSequence<UInt8, Index> {
        sequence(state: startIndex) { startIndex in
            guard startIndex < self.endIndex else { return nil }

            let endIndex = self.index(startIndex, offsetBy: 2, limitedBy: self.endIndex) ?? self.endIndex
            defer {
                startIndex = endIndex
            }

            return UInt8(self[startIndex..<endIndex], radix: 16)
        }
    }
}

