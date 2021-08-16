//
//  Device.swift
//  ChelseabandSDK
//
//  Created by Vladyslav Shepitko on 29.11.2020.
//

import Foundation
import CoreBluetooth
import RxBluetoothKit
import RxSwift
import RxCocoa

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
    }
} 

public extension ObservableType {

    func retryWithDelay(timeInterval: RxTimeInterval, maxAttempts: Int, onError: @escaping (Error) -> Void = { _ in }) -> Observable<Element> {
        return retryWhen { error in
            error
                .do(onNext: { error in
                    onError(error)
                    print("❌ An error occured: \(error) (will retry in `n`s)")
                })
                .scan(0) { attempts, error in
                    guard attempts < maxAttempts else { throw DeviceError.maxRetryAttempts }
                    guard DeviceError.isRetryable(error: error) else { throw error }

                    return attempts + 1
            }.delay(timeInterval, scheduler: MainScheduler.instance)
        }
    }
    
    func retryWithDelay(timeInterval: RxTimeInterval, onError: @escaping () -> Void = { }) -> Observable<Element> {
        return retryWhen { error in
            error
                .do(onNext: { error in
                    onError()
                })
                .scan(0) { attempts, error in
                    if let value = error as? RxError {
                        switch value {
                        case .timeout:
                            attempts + 1
                        default:
                            throw error
                        }
                    }
                    
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
    
    var bluetoothIsSearching: Observable<Bool> { get }

    var connectionObservable: Observable<Device.State> { get }

    var readCharacteristicObservable: Observable<Characteristic> { get }
    
    var batteryCharacteristicObservable: Observable<Characteristic> { get }

    var peripheralObservable: Observable<ScannedPeripheral> { get }

    var scanningRetry: DispatchTimeInterval { get set }

    func connect(peripheral: Peripheral) -> Observable<Void>

    func startScanForPeripherals() -> Observable<[ScannedPeripheral]>

    func stopScanForPeripherals()

    func write(data: Data, timeout: DispatchTimeInterval) -> Observable<Void>
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
    
    public var bluetoothIsSearching: Observable<Bool> {
        bluetoothIsSearchingSubject
    }

    public var connectionObservable: Observable<Device.State> {
        connectionBehaviourSubject
    }

    public var readCharacteristicObservable: Observable<Characteristic> {
        readCharacteristic.compactMap { $0 }
    }
    
    public var batteryCharacteristicObservable: Observable<Characteristic> {
        batteryCharacteristic.compactMap { $0 }
    }

    public var peripheralObservable: Observable<ScannedPeripheral> {
        peripheral.compactMap { $0 }
    }

    public var scanningRetry: DispatchTimeInterval = .seconds(5)

    private let configuration: Configuration
    private var disposeBag = DisposeBag()
    private let connectionBehaviourSubject = BehaviorSubject<Device.State>(value: .disconnected)
    private let bluetoothIsSearchingSubject: PublishSubject<Bool> = .init()
    private var writeCharacteristic: BehaviorSubject<Characteristic?> = .init(value: nil)
    private var readCharacteristic: BehaviorSubject<Characteristic?> = .init(value: nil)
    private var batteryCharacteristic: BehaviorSubject<Characteristic?> = .init(value: nil)
    private var peripheral: BehaviorSubject<ScannedPeripheral?> = .init(value: nil)

    public init(configuration: Configuration) {
        self.configuration = configuration
    }

    public func connect(peripheral: Peripheral) -> Observable<Void> {
        let configuration = self.configuration

        return .deferred {
            return Observable<Void>.create { [weak self] seal in
                guard let strongSelf = self else {
                    seal.onError(BluetoothError.destroyed)
                    return Disposables.create()
                }

                var connectionDisposable: Disposable?
                var characteristicsDisposable: Disposable?
                var characteristicsDictionary: [String: Observable<Characteristic>] = [:]

                connectionDisposable = strongSelf.connect(peripheral: peripheral, services: configuration.servicesForDiscovering)
                    .retryWithDelay(timeInterval: .seconds(5), maxAttempts: 3, onError: { error in
                        strongSelf.connectionBehaviourSubject.onNext(Device.State.disconnected)
                        strongSelf.connectionBehaviourSubject.onNext(Device.State.connecting)
                    })
                    .materialize()
                    .subscribe(onNext: { event in
                        strongSelf.peripheral.onNext(peripheral)

                        switch event {
                        case .completed:
                            seal.onCompleted()
                        case .error(let error):
                            seal.onError(error)
                        case .next(let service):
                            switch service.uuid {
                            case configuration.batteryService:
                                characteristicsDictionary[configuration.batteryCharacteristic.uuidString] = strongSelf.discoverCharacteristics(service, id: configuration.batteryCharacteristic)
                            case configuration.deviceInfoService:
                                characteristicsDictionary[configuration.deviceInfoCharacteristic.uuidString] = strongSelf.discoverCharacteristics(service, id: configuration.deviceInfoCharacteristic)
                            default:
                                break
                            }
                            
                            let allSatisfy = configuration.mandatoryCharacteristicIDForWork.allSatisfy({ mandatoryKey in
                                characteristicsDictionary.contains { $0.key == mandatoryKey }
                            })
                            
                            if allSatisfy {
                                let characteristicsObservable = characteristicsDictionary.map { $0.value }
                                let characteristicsDisposable = Observable.combineLatest(characteristicsObservable)
                                    .subscribe(onNext: { characteristics in
                                        characteristics.forEach { characteristic in
                                            switch characteristic.uuid {
                                            case configuration.batteryCharacteristic:
                                                strongSelf.batteryCharacteristic.on(.next(characteristic))
                                            case configuration.deviceInfoCharacteristic:
                                                break
                                            default:
                                                break
                                            }
                                        }
                                    }, onError: { error in
                                        strongSelf.batteryCharacteristic.on(.next(nil))

                                        seal.onError(error)
                                    }, onCompleted: {
                                        seal.onNext(())

                                        strongSelf.connectionBehaviourSubject.onNext(Device.State.connected)
                                    })
                            } else {
                                // TODO: here start timer if after some time allSatisfy will not fire send error and broke connection
                            }
                        }
                    }, onError: { error in
                        seal.onError(error)
                    })

                return Disposables.create {
                    strongSelf.connectionBehaviourSubject.onNext(Device.State.disconnected)

                    connectionDisposable?.dispose()
                    characteristicsDisposable?.dispose()
                }
            }
        }
    }

    public func startScanForPeripherals() -> Observable<[ScannedPeripheral]> {
        return .deferred {
            let set = NSMutableSet()
            return self.manager.scanForPeripherals(withServices: self.configuration.advertisementServices)
                .do(onSubscribed: { self.bluetoothIsSearchingSubject.onNext(true) },
                    onDispose: { self.bluetoothIsSearchingSubject.onNext(false) })
                .timeout(self.scanningRetry, scheduler: MainScheduler.instance)
                .retryWithDelay(timeInterval: self.scanningRetry) {
                    set.removeAllObjects()
                    //NOTE: if you make reconnect to device in delay time peripheral wouln't added to set
                    if  let value = try? self.peripheral.value(),
                        value.peripheral.isConnected {
                        set.add(value)
                    }
                }
                .scan(set, accumulator: { set, peripheral -> NSMutableSet in
                    if !set.contains(where: {
                        ($0 as? Peripheral)?.peripheral.identifier == peripheral.peripheral.identifier
                    })
                    {
                        set.add(peripheral)
                    }

                    return set
                })
                .compactMap { $0.allObjects as? [Peripheral] }
                .asObservable()
        }
    }

    public func stopScanForPeripherals() {
        manager.manager.stopScan()
    }

    private func discoverCharacteristics(_ service: Service, id: ID) -> Observable<Characteristic> {
        Observable.just(service)
            .compactMap { $0.discoverCharacteristics([id]) }
            .flatMap { $0 }
            .flatMap { Observable.from($0) }
            .debug("\(self).discoverCharacteristics: \(id)")
    }

    private func discoverCharacteristics(_ service: Service) -> Observable<[Characteristic]> {
        Observable.just(service)
            .compactMap { $0.discoverCharacteristics(nil) }
            .flatMap { $0 }
            .flatMap { Observable.from($0) }
            .toArray()
            .asObservable()
            .debug("\(self).discoverCharacteristics")
    }

    private func connect(peripheral: ScannedPeripheral, services: [ID], retry: DispatchTimeInterval = .seconds(5)) -> Observable<Service> {
        return Observable.of(peripheral)
            .do(onNext: { [weak self] _ in
                self?.connectionBehaviourSubject.onNext(.connecting)
            })
            .flatMap { $0.peripheral.establishConnection() }
            .flatMap { $0.discoverServices(services) }
            .flatMap { Observable.from($0) }
            .debug("\(self).connect")
    }

    public func write(data: Data, timeout: DispatchTimeInterval = .seconds(5)) -> Observable<Void> {
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
            .timeout(timeout, scheduler: MainScheduler.instance)
            .mapToVoid()
            .take(1)
            .debug("\(strongSelf).write")
        }
    }
}
