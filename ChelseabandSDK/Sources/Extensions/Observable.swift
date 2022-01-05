//
//  Observable.swift
//  ChelseabandSDK
//
//  Created by Vladyslav Shepitko on 11.03.2021.
//

import RxSwift

public extension ObservableType {
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
