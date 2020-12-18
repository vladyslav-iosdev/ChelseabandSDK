//
//  Device.swift
//  ChelseabandSDK
//
//  Created by Vladyslav Shepitko on 29.11.2020.
//

import UIKit
import CoreBluetooth
import RxBluetoothKit
import RxSwift

public extension Device {
    enum State {
        case scanning
        case connecting
        case connected
        case disconnected

        public var isConnected: Bool {
            switch self {
            case .connected:
                return true
            case .connecting, .scanning, .disconnected:
                return false
            }
        }

        public var title: String? {
            switch self {
            case .disconnected, .connected:
                return nil
            case .connecting:
                return "Connecting"
            case .scanning:
                return "Scanning"
            }
        }
    }
} 

public extension ObservableType {

    func retryWithDelay(timeInterval: RxTimeInterval, maxAttempts: Int, onError: @escaping (Error) -> Void = { _ in }) -> Observable<Element> {
        return retryWhen { error in
            error
                .do(onNext: { error in
                    onError(error)
                    print("❌ An error occured subscribing to notification for the scanning for device: \(error) (will retry in 2s)")
                })
                .scan(0) { attempts, error in
                    guard attempts < maxAttempts else { throw DeviceError.maxRetryAttempts }
                    guard DeviceError.isRetryable(error: error) else { throw error }

                    return attempts + 1
            }.delay(timeInterval, scheduler: MainScheduler.instance)
        }
    }

    func mapToVoid() -> Observable<Void> {
        map { _ in }
    }
}

public typealias ID = CBUUID
public typealias ConnectedPeripheral = Peripheral

public protocol DeviceType {

    var bluetoothState: Observable<BluetoothState> { get }

    /// Fire only when bluetooth get turned on
    var bluetoothHasConnected: Observable<Void> { get }

    var connectionObservable: Observable<Device.State> { get }

    var disconnectObservable: Observable<(Peripheral, DisconnectionReason?)> { get }

    var readCharacteristicObservable: Observable<Characteristic> { get }

    var scanningTimeout: DispatchTimeInterval { get set }

    var scanningRetry: DispatchTimeInterval { get set }

    func connect() -> Observable<Void>

    func write(data: Data, readTimeout timeout: DispatchTimeInterval) -> Observable<Void>
}

private enum DeviceError: Error {
    case maxRetryAttempts
    case writeCharacteristicMissing

    static func isRetryable(error: Error) -> Bool {
        if let value = error as? BluetoothError {
            switch value {
            case .peripheralConnectionFailed, .peripheralDisconnected:
                return true
            default:
                return false
            }
        } else {
            return true
        }
    }
}

public final class Device: DeviceType {

    private let manager = CentralManager()

    public var bluetoothState: Observable<BluetoothState> {
        manager.observeStateWithInitialValue()
    }

    /// Fire only when bluetooth get turned on
    public var bluetoothHasConnected: Observable<Void> {
        bluetoothState
            .map { $0 == .poweredOn }
            .filter { $0 }
            .mapToVoid()
    }

    public var connectionObservable: Observable<Device.State> {
        connectionBehaviourSubject
    }

    public var disconnectObservable: Observable<(Peripheral, DisconnectionReason?)> {
        disconnectPublishSubject
    }

    public var readCharacteristicObservable: Observable<Characteristic> {
        readCharacteristic.compactMap{ $0 }
    }

    public var scanningTimeout: DispatchTimeInterval = .seconds(5)
    public var scanningRetry: DispatchTimeInterval = .seconds(5)

    private let configuration: Configuration
    private var disposeBag = DisposeBag()
    private let connectionBehaviourSubject = BehaviorSubject<Device.State>(value: .disconnected)
    private let disconnectPublishSubject = PublishSubject<(Peripheral, DisconnectionReason?)>()
    private var writeCharacteristic: BehaviorSubject<Characteristic?> = .init(value: nil)
    private var readCharacteristic: BehaviorSubject<Characteristic?> = .init(value: nil)

    public init(configuration: Configuration) {
        self.configuration = configuration
    }

    public func connect() -> Observable<Void> {
        return connect(manager: manager, configuration: configuration)
    }

    private func connect(manager: CentralManager, configuration: Configuration) -> Observable<Void> {
        return .deferred {
            return Observable<Void>.create { [weak self] seal in
                guard let strongSelf = self else {
                    seal.onError(BluetoothError.destroyed)
                    return Disposables.create()
                }

                var yy: Disposable?
                var ww: Disposable?
                
                let xx = strongSelf.startScanning(manager: manager, service: configuration.service)
                    .subscribe(onNext: { peripheral in
                        yy = strongSelf.connect(periferal: peripheral, service: configuration.service)
                            .retryWithDelay(timeInterval: .seconds(5), maxAttempts: 3, onError: { error in
                                strongSelf.connectionBehaviourSubject.onNext(Device.State.connecting)
                            })
                            .materialize()
                            .subscribe(onNext: { event in
                                switch event {
                                case .completed:
                                    seal.onCompleted()
                                case .error(let error):
                                    seal.onError(error)
                                case .next(let service):
                                    let writeCharacteristic = strongSelf.discoverCharacteristics(service, id: configuration.writeCharacteristic)
                                    let readCharacteristic = strongSelf.discoverCharacteristics(service, id: configuration.readCharacteristic)

                                    ww = Observable.combineLatest(writeCharacteristic, readCharacteristic)
                                        .debug("\(strongSelf).final-setup")
                                        .subscribe(onNext: { pair in
                                            strongSelf.writeCharacteristic.on(.next(pair.0))
                                            strongSelf.readCharacteristic.on(.next(pair.1))
                                        }, onError: { error in
                                            strongSelf.writeCharacteristic.on(.next(nil))
                                            strongSelf.readCharacteristic.on(.next(nil))

                                            seal.onError(error)
                                        }, onCompleted: {
                                            seal.onNext(())

                                            strongSelf.connectionBehaviourSubject.onNext(Device.State.connected)
                                        })
                                }
                            }, onError: { error in
                                seal.onError(error)
                            })
                    }, onError: { error in
                        seal.onError(error)
                    })

                return Disposables.create {
                    strongSelf.connectionBehaviourSubject.onNext(Device.State.disconnected)

                    xx.dispose()
                    yy?.dispose()
                    ww?.dispose()
                }

                //            let peripheralObservable = strongSelf.startScanning(manager: manager, service: configuration.service)
                //
                //            let connectionObservable = peripheralObservable
                //                .flatMap { strongSelf.connect(periferal: $0, service: configuration.service) }
                //                .share()
                //                .debug("device-connection")
                ////                .materialize()
                //
                //            let disconnectDisposable = connectionObservable
                ////            connectionObservable.dematerialize()
                //                .flatMap { strongSelf.manager.observeDisconnect(for: $0.peripheral) }
                //                .map { e in Device.State.disconnected(e.1) }
                //                .share()
                //                .debug("device-disconnect")
                //                .materialize()
                //                .map({ e -> Device.State in
                //                    switch e {
                //                    case .next(let state):
                //                        return state
                //                    case .completed:
                //                        return .disconnected(nil)
                //                    case .error(let error):
                //                        return .disconnected(error)
                //                    }
                //                })
                //                .subscribe(strongSelf.connectionBehaviourSubject)
                //
                //            let subscription = connectionObservable
                //                .flatMap { service -> Observable<Service> in
                //                    let writeCharacteristic = strongSelf.discoverCharacteristics(service, id: configuration.writeCharacteristic)
                //                    let readCharacteristic = strongSelf.discoverCharacteristics(service, id: configuration.readCharacteristic)
                //
                //                    return Observable.combineLatest(writeCharacteristic, readCharacteristic)
                //                        .do(onNext: { characteristics in
                //                            strongSelf.writeCharacteristic.on(.next(characteristics.0))
                //                            strongSelf.readCharacteristic.on(.next(characteristics.1))
                //                        })
                //                        .map { _ in service }
                //                        .do(onNext: { _ in
                //                            strongSelf.connectionBehaviourSubject.onNext(Device.State.connected)
                //                        })
                //                }
                //                .map { _ in strongSelf }
                //                .subscribe(seal)
                //
                //            return Disposables.create {
                //                strongSelf.connectionBehaviourSubject.onNext(Device.State.disconnected(nil))
                //
                //                disconnectDisposable.dispose()
                //                subscription.dispose()
                //            }

            }
        }
    }

    private func discoverCharacteristics(_ service: Service, id: ID) -> Observable<Characteristic> {
        Observable.just(service)
            .compactMap { $0.discoverCharacteristics([id]) }
            .flatMap { $0 }
            .flatMap { Observable.from($0) }
            .debug("\(self).discoverCharacteristics: \(id)")
    }

    private func startScanning(manager: CentralManager, service: ID) -> Observable<ScannedPeripheral> {
        let scanningRetry = self.scanningRetry

        return Observable.just(manager)
            .filter { !$0.manager.isScanning }
            .do(onNext: { [weak self] _ in
                self?.connectionBehaviourSubject.onNext(.scanning)
            })
            .flatMap { $0.scanForPeripherals(withServices: [service]) }
            .take(1)
            .timeout(scanningTimeout, scheduler: MainScheduler.instance)
            .retryWithDelay(timeInterval: scanningRetry, maxAttempts: 3)
            .debug("\(self).scanning")
    }


    private func connect(periferal: ScannedPeripheral, service: ID, retry: DispatchTimeInterval = .seconds(5)) -> Observable<Service> {
        return Observable.of(periferal)
            .do(onNext: { [weak self] _ in
                self?.connectionBehaviourSubject.onNext(.connecting)
            })
            .flatMap { $0.peripheral.establishConnection() }
            .flatMap { $0.discoverServices([service]) }
            .flatMap { Observable.from($0) }
            .debug("\(self).connect")
    }

    public func write(data: Data, readTimeout timeout: DispatchTimeInterval) -> Observable<Void> {
        return .deferred { [weak self] in
            guard let strongSelf = self else {
                return .error(BluetoothError.destroyed)
            }

            return strongSelf.writeCharacteristic
                .flatMap { characteristic -> Observable<Characteristic> in
                    if let value = characteristic {
                        return value.writeValue(data, type: .withResponse).asObservable()
                    } else {
                        throw DeviceError.writeCharacteristicMissing
                    }
            }
            .mapToVoid()
            .take(1)
            .debug("\(strongSelf).write")
        }
    }
}
