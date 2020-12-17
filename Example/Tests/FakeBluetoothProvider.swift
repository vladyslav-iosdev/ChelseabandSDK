////
////  FakeBluetoothProvider.swift
////  ChelseabandSDK_Tests
////
////  Created by Vladyslav Shepitko on 24.11.2020.
////  Copyright © 2020 CocoaPods. All rights reserved.
////
//
//import Foundation
//import RxBluetoothKit
//import CoreBluetooth
//import RxSwift
//
//@testable import ChelseabandSDK
//
////extension BluetoothProvider {
////    static func fake() -> FakeBluetoothProvider {
////        FakeBluetoothProvider()
////    }
////}
//
//class FakeBluetoothProvider: BluetoothProviderType {
//    func startScanning_s(services: [ID]?, timeout: DispatchTimeInterval) -> Observable<Void> {
//        return .just(())
//    }
//
//    var scanning: Observable<Bool> {
//        return .just(false)
//    }
//
//    var bluetoothState: Observable<BluetoothState> {
//        return .just(.poweredOff)
//    }
//
//
//    func getValueUpdates(for characteristic: Characteristic) -> Observable<Data> {
//        return .just(.init())
//    }
//
//    func readValue(for characteristic: Characteristic) -> Observable<Data> {
//        return .just(.init())
//    }
//
//    func dissconnect() {
//
//    }
//
//    func startScanning(services: [ID]?, timeout: DispatchTimeInterval) -> Observable<ScannedPeripheral> {
//        return Observable<ScannedPeripheral>.create { seal -> Disposable in
//            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//                seal.onCompleted()
//            }
//
//            return Disposables.create {
//
//            }
//        }
//    }
//
//    func connect(to peripheral: Peripheral) -> Observable<ConnectedPeripheral> {
//        return Observable<ConnectedPeripheral>.create { seal -> Disposable in
//
//            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//                seal.onCompleted()
//            }
//
//            return Disposables.create {
//
//            }
//        }
//    }
//
//    func discoveredServices(for peripheral: ConnectedPeripheral) -> Observable<[Service]> {
//        return .just([])
//    }
//
//    func characteristics(for service: Service) -> Observable<[Characteristic]> {
//        return .just([])
//    }
//
//    func write(value data: Data, for characteristic: Characteristic, type: CBCharacteristicWriteType) -> Single<Characteristic> {
//        return Observable<Characteristic>.create { seal -> Disposable in
//            seal.onCompleted()
//
//            return Disposables.create {
//
//            }
//        }.asSingle()
//    }
//
//}
