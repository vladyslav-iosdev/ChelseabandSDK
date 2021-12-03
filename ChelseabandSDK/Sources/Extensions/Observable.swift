//
//  Observable.swift
//  ChelseabandSDK
//
//  Created by Vladyslav Shepitko on 11.03.2021.
//

import RxSwift

extension Observable where Element == Data {

    ///Filters hex value of data, filter if command starts with `hex` performs guard check for `byteIndex`
    /// - Parameter hex: Hex value to check if data starts with this `hex`
    /// - Parameter byteIndex: index of byte to determin wether chain could be completed
    /// - Parameter mininumBytes: guard check
    /// - Returns: completed observable`Observable<Void> `.
    public func completeWhenByteEqualsToOne(hexStartWith hex: String, byteIndex: Int = 3) -> Observable<Element> {
        filter {
            $0.hex.starts(with: hex) && $0.bytes.count >= byteIndex + 1
        }.map { data -> Data in
            guard data.bytes[byteIndex] == 1 else {
                throw CommandError.invalid
            }

            return data
        }.take(1)//NOTE: Wee need to complete observable sequence
    }
}

extension ObservableType {
    func mapTimeoutError(to error: Error) -> Observable<Element> {
        catchError {
            if case RxSwift.RxError.timeout = $0 {
                throw error
            } else {
                throw $0
            }
        }
    }
}
