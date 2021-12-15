//
//  String.swift
//  ChelseabandSDK
//
//  Created by Vladyslav Shepitko on 17.12.2020.
//

import UIKit

public extension String {
    func removeNullTerminated() -> String {
        self.replacingOccurrences(of: "\0", with: "", options: .literal, range: nil)
    }
}

