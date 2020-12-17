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
        case disconnected(DisconnectionReason?)

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

    func retryWithDelay(_ timeInterval: RxTimeInterval, maxAttempts: Int? = nil) -> Observable<Element> {
        return retryWhen { (errors: Observable<Error>) in
            return errors.enumerated().flatMap() { ( attempt, error) -> Observable<Int64> in
                if let maxAttempts = maxAttempts, attempt >= maxAttempts - 1 {
                    return Observable.error(error)
                }

                return Observable<Int64>.timer(timeInterval, scheduler: MainScheduler.instance)
            }
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

    func connect() -> Observable<DeviceType>

    func write(data: Data, readTimeout timeout: DispatchTimeInterval) -> Observable<Void>
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

    private let configuration: Configuration
    private var disposeBag = DisposeBag()
    private let connectionBehaviourSubject = BehaviorSubject<Device.State>(value: .disconnected(nil))
    private let disconnectPublishSubject = PublishSubject<(Peripheral, DisconnectionReason?)>()
    private var writeCharacteristic: BehaviorSubject<Characteristic?> = .init(value: nil)
    private var readCharacteristic: BehaviorSubject<Characteristic?> = .init(value: nil)

    public init(configuration: Configuration) {
        self.configuration = configuration
    }

    public func connect() -> Observable<DeviceType> {
        return connect(manager: manager, configuration: configuration).debug("device-connect")
    }

    private func connect(manager: CentralManager, configuration: Configuration) -> Observable<DeviceType> {
        return Observable<DeviceType>.create { [weak self] observer in
            guard let strongSelf = self else {
                observer.onError(BluetoothError.destroyed)
                return Disposables.create()
            }

            let peripheralObservable = strongSelf.startScanning(manager: manager, service: configuration.service)

            let connectionObservable = peripheralObservable
                .flatMap { strongSelf.connect(periferal: $0, service: configuration.service) }
                .share()
                .debug("device-connection")

            let disconnectDisposable = connectionObservable
                .flatMap { strongSelf.manager.observeDisconnect(for: $0.peripheral) }
                .map { e in Device.State.disconnected(e.1) }
                .catchErrorJustReturn(.disconnected(nil))
                .share()
                .debug("device-disconnect")
                .subscribe(strongSelf.connectionBehaviourSubject)

            let subscription = connectionObservable
                .flatMap { service -> Observable<Service> in
                    let writeCharacteristic = strongSelf.discoverWriteCharacteristics(service, id: configuration.writeCharacteristic)
                    let readCharacteristic = strongSelf.discoverReadCharacteristics(service, id: configuration.readCharacteristic)

                    return Observable.combineLatest(writeCharacteristic, readCharacteristic)
                        .do(onNext: { characteristics in
                            strongSelf.writeCharacteristic.on(.next(characteristics.0))
                            strongSelf.readCharacteristic.on(.next(characteristics.1))
                        })
                        .map { _ in service }
                        .do(onNext: { _ in
                            strongSelf.connectionBehaviourSubject.onNext(Device.State.connected)
                        })
                }
                .map { _ in strongSelf }
                .subscribe(observer)

            return Disposables.create {
                strongSelf.connectionBehaviourSubject.onNext(Device.State.disconnected(nil))

                disconnectDisposable.dispose()
                subscription.dispose()
            }
        }
    }

    private func discoverWriteCharacteristics(_ service: Service, id: ID) -> Observable<Characteristic> {
        Observable.just(service)
        .compactMap { $0.discoverCharacteristics([id]) }
        .flatMap { $0 }
        .flatMap { Observable.from($0) } 
        .debug("device-w")
    }

    private func discoverReadCharacteristics(_ service: Service, id: ID) -> Observable<Characteristic> {
        Observable.just(service)
            .compactMap { $0.discoverCharacteristics([id]) }
            .flatMap { $0 }
            .flatMap { Observable.from($0) }
            .debug("device-r")
    }

    private func startScanning(manager: CentralManager, service: ID, timeout: DispatchTimeInterval = .seconds(5), retry: DispatchTimeInterval = .seconds(5)) -> Observable<ScannedPeripheral> {
        return Observable.just(manager).filter {
                !$0.manager.isScanning && $0.retrieveConnectedPeripherals(withServices: [service]).isEmpty
            }.do(onNext: { [weak self] _ in
                self?.connectionBehaviourSubject.onNext(.scanning)
            })
            .flatMap { $0.scanForPeripherals(withServices: [service]) }
            .take(1)
            .flatMap { Observable.just($0) }
            .timeout(timeout, scheduler: MainScheduler.instance)
            .retryWhen { error in
                error.do(onNext: { error in
                    print("❌ An error occured subscribing to notification for the scanning for device: \(error) (will retry in 2s)")
                }).delay(retry, scheduler: MainScheduler.instance)
            }
            .debug("device-scanning")
    }

    private func connect(periferal: ScannedPeripheral, service: ID, retry: DispatchTimeInterval = .seconds(5)) -> Observable<Service> {
        return Observable.of(periferal)
            .do(onNext: { [weak self] _ in
                self?.connectionBehaviourSubject.onNext(.connecting)
            })
            .flatMap { $0.peripheral.establishConnection() }
            .retryWhen { error in
                error.do(onNext: { error in //NOTE: retry to connect to disconnected device
                    print("❌ An error occured subscribing to notification for the connection to service: \(error) (will retry in 2s)")
                })
                .delay(retry, scheduler: MainScheduler.instance)
            }
            .flatMap { $0.discoverServices([service]) }
            .flatMap { Observable.from($0) }
            .debug("device-service")
    }

    public func write(data: Data, readTimeout timeout: DispatchTimeInterval) -> Observable<Void> {
        writeCharacteristic
            .compactMap { $0 }
            .flatMap { $0.writeValue(data, type: .withResponse) }
            .take(1)
            .debug("kkk-w_w")
            .mapToVoid()
    }
}
