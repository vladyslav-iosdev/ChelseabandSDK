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

public protocol UpdateDeviceViaSuotaType {
    var suotaMtuCharSizeSubject: BehaviorSubject<UInt16> { get }
    
    var suotaPatchDataSizeSubject: BehaviorSubject<UInt16> { get }
    
    var suotaServStatusCharacteristicObservable: Observable<Characteristic> { get }
    
    func writeInMemDev(data: Data, timeout: DispatchTimeInterval) -> Observable<Void>
    
    func writeInGpioMap(data: Data, timeout: DispatchTimeInterval) -> Observable<Void>
    
    func writeInPatchLen(data: Data, timeout: DispatchTimeInterval) -> Observable<Void>
    
    func writeInPatchData(data: Data, timeout: DispatchTimeInterval) -> Observable<Void>
}

public protocol DeviceType: UpdateDeviceViaSuotaType {

    var bluetoothState: Observable<BluetoothState> { get }

    /// Fire only when bluetooth get turned on
    var bluetoothHasConnected: Observable<Void> { get }
    
    var bluetoothIsSearching: Observable<Bool> { get }

    var connectionObservable: Observable<Device.State> { get }
    
    var batteryCharacteristicObservable: Observable<Characteristic> { get }
    
    var firmwareVersionCharacteristicObservable: Observable<Characteristic> { get }
    
    var firmwareVersionSubject: BehaviorSubject<String?> { get }

    var peripheralObservable: Observable<ScannedPeripheral> { get }

    var scanningRetry: DispatchTimeInterval { get set }
    
    func updateDeviceInfo(timeOut: RxSwift.RxTimeInterval)
    
    func connect(peripheral: Peripheral) -> Observable<Void>

    func startScanForPeripherals() -> Observable<[ScannedPeripheral]>

    func stopScanForPeripherals()
    
    func write(command: WritableCommand, timeout: DispatchTimeInterval) -> Observable<Void>
    
    func writeAndObservNotify(command: WritableCommand, timeout: DispatchTimeInterval) -> Observable<Data>
    
    func read(command: ReadableCommand, timeout: DispatchTimeInterval) -> Observable<Data?>
}

private enum DeviceError: LocalizedError {
    case maxRetryAttempts
    case writeCharacteristicMissing
    case mandatoryCharacteristicsMissing


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
    
    var errorDescription: String? {
        switch self {
        case .maxRetryAttempts:
            return "Maximum retry attempts"
        case .writeCharacteristicMissing:
            return "Write characteristic missing"
        case .mandatoryCharacteristicsMissing:
            return "Mandatory characteristics missing"
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
    
    public var batteryCharacteristicObservable: Observable<Characteristic> {
        batteryCharacteristic.compactMap { $0 }
    }
    
    public var firmwareVersionCharacteristicObservable: Observable<Characteristic> {
        firmwareVersionCharacteristic.compactMap { $0 }
    }
    
    public var firmwareVersionSubject: BehaviorSubject<String?> = .init(value: UserDefaults.standard.firmwareVersion)
    
    public var suotaMtuCharSizeSubject: BehaviorSubject<UInt16> = .init(value: 23) //NOTE: 23 it's default value from dialog tutorial
    
    public var suotaPatchDataSizeSubject: BehaviorSubject<UInt16> = .init(value: 20) //NOTE: 20 it's default value from dialog tutorial
    
    public var suotaServStatusCharacteristicObservable: Observable<Characteristic> {
        suotaServStatusCharacteristic.compactMap { $0 }
    }

    public var peripheralObservable: Observable<ScannedPeripheral> {
        peripheral.compactMap { $0 }
    }

    public var scanningRetry: DispatchTimeInterval = .seconds(5)

    private let configuration: Configuration
    private var disposeBag = DisposeBag()
    private let connectionBehaviourSubject = BehaviorSubject<Device.State>(value: .disconnected)
    private let bluetoothIsSearchingSubject: PublishSubject<Bool> = .init()
    private var batteryCharacteristic: BehaviorSubject<Characteristic?> = .init(value: nil)
    private var firmwareVersionCharacteristic: BehaviorSubject<Characteristic?> = .init(value: nil)
    private var suotaPatchDataCharSizeCharacteristic: BehaviorSubject<Characteristic?> = .init(value: nil)
    private var suotaMtuCharSizeCharacteristic: BehaviorSubject<Characteristic?> = .init(value: nil)
    private var suotaMemDevCharacteristic: BehaviorSubject<Characteristic?> = .init(value: nil)
    private var suotaGpioMapCharacteristic: BehaviorSubject<Characteristic?> = .init(value: nil)
    private var suotaPatchLenCharacteristic: BehaviorSubject<Characteristic?> = .init(value: nil)
    private var suotaPatchDataCharacteristic: BehaviorSubject<Characteristic?> = .init(value: nil)
    private var suotaServStatusCharacteristic: BehaviorSubject<Characteristic?> = .init(value: nil)
    private var peripheral: BehaviorSubject<ScannedPeripheral?> = .init(value: nil)
    private var fanbandCharacteristics = [Observable<Characteristic>]()

    public init(configuration: Configuration) {
        self.configuration = configuration
    }
    
    public func updateDeviceInfo(timeOut: RxSwift.RxTimeInterval = .seconds(5)) {
        firmwareVersionCharacteristic
            .compactMap{ $0 }
            .timeout(timeOut, scheduler: MainScheduler.instance)
            .take(1)
            .subscribe(onNext: { [weak self] characteristic in
                guard let strongSelf = self else { return }
                characteristic.readValue()
                    .asObservable()
                    .map { $0.value != nil ? String(decoding: $0.value!, as: UTF8.self) : nil }
                    .subscribe(onNext: {
                        strongSelf.firmwareVersionSubject.on(.next($0))
                        UserDefaults.standard.firmwareVersion = $0
                    })
                    .disposed(by: strongSelf.disposeBag)
            })
            .disposed(by: disposeBag)
    }
    
    private func updateSuotaParameters(timeOut: RxSwift.RxTimeInterval = .seconds(5)) {
        suotaPatchDataCharSizeCharacteristic
            .compactMap{ $0 }
            .timeout(timeOut, scheduler: MainScheduler.instance)
            .take(1)
            .subscribe(onNext: { [weak self] characteristic in
                guard let strongSelf = self else { return }
                characteristic.readValue()
                    .asObservable()
                    .compactMap { $0.value }
                    .map { data -> UInt16? in
                        if data.indices.contains(1) {
                            let higherBit = UInt16(data[1])
                            let lowerBit = UInt16(data[0])
                            return (higherBit << 8) | lowerBit
                        } else if data.indices.contains(0) {
                            return UInt16(data[0])
                        } else {
                            return nil
                        }
                    }
                    .compactMap { $0 }
                    .bind(to: strongSelf.suotaPatchDataSizeSubject)
                    .disposed(by: strongSelf.disposeBag)
            })
            .disposed(by: disposeBag)
       
        suotaMtuCharSizeCharacteristic
            .compactMap{ $0 }
            .timeout(timeOut, scheduler: MainScheduler.instance)
            .take(1)
            .subscribe(onNext: { [weak self] characteristic in
                guard let strongSelf = self else { return }
                characteristic.readValue()
                    .asObservable()
                    .compactMap { $0.value }
                    .map { data -> UInt16? in
                        if data.indices.contains(1) {
                            let higherBit = UInt16(data[1])
                            let lowerBit = UInt16(data[0])
                            return (higherBit << 8) | lowerBit
                        } else if data.indices.contains(0) {
                            return UInt16(data[0])
                        } else {
                            return nil
                        }
                    }
                    .compactMap { $0 }
                    .bind(to: strongSelf.suotaMtuCharSizeSubject)
                    .disposed(by: strongSelf.disposeBag)
            })
            .disposed(by: disposeBag)
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
                var countDownTimer: Disposable?

                connectionDisposable = strongSelf.connect(peripheral: peripheral, services: configuration.servicesForDiscovering)
                    .retryWithDelay(timeInterval: .seconds(5), maxAttempts: 3, onError: { error in
                        strongSelf.connectionBehaviourSubject.onNext(Device.State.disconnected)
                        strongSelf.connectionBehaviourSubject.onNext(Device.State.connecting)
                    })
                    .materialize()
                    .subscribe(onNext: { event in
                        strongSelf.peripheral.onNext(peripheral)
                        if countDownTimer == nil {
                            countDownTimer = Observable<Int>.timer(.seconds(0), period: .seconds(15), scheduler: MainScheduler.instance)
                                .skip(1)
                                .take(1)
                                .subscribe(onNext: { timePassed in
                                    seal.onError(DeviceError.mandatoryCharacteristicsMissing)
                                })
                        }

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
                                characteristicsDictionary[configuration.firmwareVersionCharacteristic.uuidString] = strongSelf.discoverCharacteristics(service, id: configuration.firmwareVersionCharacteristic)
                                characteristicsDictionary[configuration.hardwareCharacteristic.uuidString] = strongSelf.discoverCharacteristics(service, id: configuration.hardwareCharacteristic)
                                characteristicsDictionary[configuration.serialCharacteristic.uuidString] = strongSelf.discoverCharacteristics(service, id: configuration.serialCharacteristic)
                                characteristicsDictionary[configuration.modelCharacteristic.uuidString] = strongSelf.discoverCharacteristics(service, id: configuration.modelCharacteristic)
                                characteristicsDictionary[configuration.manufacturerCharacteristic.uuidString] = strongSelf.discoverCharacteristics(service, id: configuration.manufacturerCharacteristic)
                                characteristicsDictionary[configuration.softwareCharacteristic.uuidString] = strongSelf.discoverCharacteristics(service, id: configuration.softwareCharacteristic)
                            case configuration.suotaService:
                                characteristicsDictionary[configuration.suotaPatchDataCharSizeCharacteristic.uuidString] = strongSelf.discoverCharacteristics(service, id: configuration.suotaPatchDataCharSizeCharacteristic)
                                characteristicsDictionary[configuration.suotaMtuCharSizeCharacteristic.uuidString] = strongSelf.discoverCharacteristics(service, id: configuration.suotaMtuCharSizeCharacteristic)
                                characteristicsDictionary[configuration.suotaMemDevCharacteristic.uuidString] = strongSelf.discoverCharacteristics(service, id: configuration.suotaMemDevCharacteristic)
                                characteristicsDictionary[configuration.suotaGpioMapCharacteristic.uuidString] = strongSelf.discoverCharacteristics(service, id: configuration.suotaGpioMapCharacteristic)
                                characteristicsDictionary[configuration.suotaPatchLenCharacteristic.uuidString] = strongSelf.discoverCharacteristics(service, id: configuration.suotaPatchLenCharacteristic)
                                characteristicsDictionary[configuration.suotaPatchDataCharacteristic.uuidString] = strongSelf.discoverCharacteristics(service, id: configuration.suotaPatchDataCharacteristic)
                                characteristicsDictionary[configuration.suotaServStatusCharacteristic.uuidString] = strongSelf.discoverCharacteristics(service, id: configuration.suotaServStatusCharacteristic)
                            case configuration.fanbandService:
                                characteristicsDictionary[configuration.seatingPositionCharacteristic.uuidString] = strongSelf.discoverCharacteristics(service, id: configuration.seatingPositionCharacteristic)
                                characteristicsDictionary[configuration.nfcTicketCharacteristic.uuidString] = strongSelf.discoverCharacteristics(service, id: configuration.nfcTicketCharacteristic)
                                characteristicsDictionary[configuration.deviceSettingsCharacteristic.uuidString] = strongSelf.discoverCharacteristics(service, id: configuration.deviceSettingsCharacteristic)
                                characteristicsDictionary[configuration.ledCharacteristic.uuidString] = strongSelf.discoverCharacteristics(service, id: configuration.ledCharacteristic)
                                characteristicsDictionary[configuration.vibrationCharacteristic.uuidString] = strongSelf.discoverCharacteristics(service, id: configuration.vibrationCharacteristic)
                                characteristicsDictionary[configuration.imageControlCharacteristic.uuidString] = strongSelf.discoverCharacteristics(service, id: configuration.imageControlCharacteristic)
                                characteristicsDictionary[configuration.imageChunkCharacteristic.uuidString] = strongSelf.discoverCharacteristics(service, id: configuration.imageChunkCharacteristic)
                                characteristicsDictionary[configuration.alertCharacteristic.uuidString] = strongSelf.discoverCharacteristics(service, id: configuration.alertCharacteristic)
                                characteristicsDictionary[configuration.scoreCharacteristic.uuidString] = strongSelf.discoverCharacteristics(service, id: configuration.scoreCharacteristic)
                                characteristicsDictionary[configuration.pollCharacteristic.uuidString] = strongSelf.discoverCharacteristics(service, id: configuration.pollCharacteristic)
                            default:
                                break
                            }
                            
                            let allSatisfy = configuration.mandatoryCharacteristicIDForWork.allSatisfy({ mandatoryKey in
                                characteristicsDictionary.contains { $0.key == mandatoryKey }
                            })
                            
                            if allSatisfy {
                                strongSelf.fanbandCharacteristics.removeAll()
                                let characteristicsObservable = characteristicsDictionary.map { $0.value }
                                let characteristicsDisposable = Observable.combineLatest(characteristicsObservable)
                                    .subscribe(onNext: { characteristics in
                                        characteristics.forEach { characteristic in
                                            switch characteristic.uuid {
                                            case configuration.batteryCharacteristic:
                                                strongSelf.batteryCharacteristic.on(.next(characteristic))
                                            case configuration.firmwareVersionCharacteristic:
                                                strongSelf.firmwareVersionCharacteristic.on(.next(characteristic))
                                            case configuration.manufacturerCharacteristic:
                                                strongSelf.fanbandCharacteristics.append(Observable.just(characteristic))
                                            case configuration.hardwareCharacteristic:
                                                strongSelf.fanbandCharacteristics.append(Observable.just(characteristic))
                                            case configuration.modelCharacteristic:
                                                strongSelf.fanbandCharacteristics.append(Observable.just(characteristic))
                                            case configuration.serialCharacteristic:
                                                strongSelf.fanbandCharacteristics.append(Observable.just(characteristic))
                                            case configuration.softwareCharacteristic:
                                                strongSelf.fanbandCharacteristics.append(Observable.just(characteristic))
                                            case configuration.suotaPatchDataCharSizeCharacteristic:
                                                strongSelf.suotaPatchDataCharSizeCharacteristic.on(.next(characteristic))
                                            case configuration.suotaMtuCharSizeCharacteristic:
                                                strongSelf.suotaMtuCharSizeCharacteristic.on(.next(characteristic))
                                            case configuration.suotaMemDevCharacteristic:
                                                strongSelf.suotaMemDevCharacteristic.on(.next(characteristic))
                                            case configuration.suotaGpioMapCharacteristic:
                                                strongSelf.suotaGpioMapCharacteristic.on(.next(characteristic))
                                            case configuration.suotaPatchLenCharacteristic:
                                                strongSelf.suotaPatchLenCharacteristic.on(.next(characteristic))
                                            case configuration.suotaPatchDataCharacteristic:
                                                strongSelf.suotaPatchDataCharacteristic.on(.next(characteristic))
                                            case configuration.suotaServStatusCharacteristic:
                                                strongSelf.suotaServStatusCharacteristic.on(.next(characteristic))
                                            case configuration.vibrationCharacteristic:
                                                strongSelf.fanbandCharacteristics.append(Observable.just(characteristic))
                                            case configuration.seatingPositionCharacteristic:
                                                strongSelf.fanbandCharacteristics.append(Observable.just(characteristic))
                                            case configuration.nfcTicketCharacteristic:
                                                strongSelf.fanbandCharacteristics.append(Observable.just(characteristic))
                                            case configuration.deviceSettingsCharacteristic:
                                                strongSelf.fanbandCharacteristics.append(Observable.just(characteristic))
                                            case configuration.ledCharacteristic:
                                                strongSelf.fanbandCharacteristics.append(Observable.just(characteristic))
                                            case configuration.imageControlCharacteristic:
                                                strongSelf.fanbandCharacteristics.append(Observable.just(characteristic))
                                            case configuration.imageChunkCharacteristic:
                                                strongSelf.fanbandCharacteristics.append(Observable.just(characteristic))
                                            case configuration.alertCharacteristic:
                                                strongSelf.fanbandCharacteristics.append(Observable.just(characteristic))
                                            case configuration.scoreCharacteristic:
                                                strongSelf.fanbandCharacteristics.append(Observable.just(characteristic))
                                            case configuration.pollCharacteristic:
                                                strongSelf.fanbandCharacteristics.append(Observable.just(characteristic))
                                            default:
                                                break
                                            }
                                        }
                                        strongSelf.updateDeviceInfo()
                                        strongSelf.updateSuotaParameters()
                                        seal.onNext(())
                                        countDownTimer?.dispose()

                                        strongSelf.connectionBehaviourSubject.onNext(Device.State.connected)
                                    }, onError: { error in
                                        strongSelf.batteryCharacteristic.on(.next(nil))
                                        strongSelf.firmwareVersionCharacteristic.on(.next(nil))
                                        strongSelf.suotaPatchDataCharSizeCharacteristic.on(.next(nil))
                                        strongSelf.suotaMtuCharSizeCharacteristic.on(.next(nil))
                                        strongSelf.suotaMemDevCharacteristic.on(.next(nil))
                                        strongSelf.suotaGpioMapCharacteristic.on(.next(nil))
                                        strongSelf.suotaPatchLenCharacteristic.on(.next(nil))
                                        strongSelf.suotaPatchDataCharacteristic.on(.next(nil))
                                        strongSelf.suotaServStatusCharacteristic.on(.next(nil))
                                        strongSelf.fanbandCharacteristics.removeAll()

                                        seal.onError(error)
                                    })
                            }
                        }
                    }, onError: { error in
                        seal.onError(error)
                    })

                return Disposables.create {
                    strongSelf.connectionBehaviourSubject.onNext(Device.State.disconnected)

                    connectionDisposable?.dispose()
                    characteristicsDisposable?.dispose()
                    countDownTimer?.dispose()
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
                }
                .scan(set, accumulator: { set, peripheral -> NSMutableSet in
                    set.add(peripheral)
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
    
    public func write(command: WritableCommand, timeout: DispatchTimeInterval) -> Observable<Void> {
        return .deferred { [weak self] in
            guard let strongSelf = self else {
                return .error(BluetoothError.destroyed)
            }

            return strongSelf.findCharacteristic(forCommand: command)
                .flatMap { characteristic -> Observable<Characteristic> in
                    if let value = characteristic {
                        return value.writeValue(command.dataForSend,
                                                type: command.writeType).asObservable()
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
    
    public func writeAndObservNotify(command: WritableCommand, timeout: DispatchTimeInterval) -> Observable<Data> {
        return .deferred { [weak self] in
            guard let strongSelf = self else {
                return .error(BluetoothError.destroyed)
            }

            return strongSelf.findCharacteristic(forCommand: command)
                .flatMap { characteristic -> Observable<Characteristic> in
                    if let value = characteristic {
                        return value.writeValue(command.dataForSend,
                                                type: command.writeType).asObservable()
                    } else {
                        throw DeviceError.writeCharacteristicMissing
                    }
            }
            .timeout(timeout, scheduler: MainScheduler.instance)
            .take(1)
            .flatMap { $0.observeValueUpdateAndSetNotification() }
            .compactMap { $0.value }
            .debug("\(strongSelf).write")
        }
    }
    
    public func read(command: ReadableCommand, timeout: DispatchTimeInterval) -> Observable<Data?> {
        return .deferred { [weak self] in
            guard let strongSelf = self else {
                return .error(BluetoothError.destroyed)
            }

            return strongSelf.findCharacteristic(forCommand: command)
                .flatMap { characteristic -> Observable<Data?> in
                    if let value = characteristic {
                        return value.readValue()
                            .map { $0.value }
                            .asObservable()
                        
                    } else {
                        throw DeviceError.writeCharacteristicMissing
                    }
            }
            .timeout(timeout, scheduler: MainScheduler.instance)
            .take(1)
            .debug("\(strongSelf).write")
        }
    }
    
    private func findCharacteristic(forCommand command: Command) -> Observable<Characteristic?> {
        Observable.combineLatest(fanbandCharacteristics)
            .map { $0.first { $0.uuid == command.commandUUID } }
            .take(1)
    }
    
    public func writeInMemDev(data: Data, timeout: DispatchTimeInterval) -> Observable<Void> {
        return write(in: suotaMemDevCharacteristic, data: data, withTimeOut: timeout)
    }
    
    public func writeInGpioMap(data: Data, timeout: DispatchTimeInterval) -> Observable<Void> {
        return write(in: suotaGpioMapCharacteristic, data: data, withTimeOut: timeout)
    }
    
    public func writeInPatchLen(data: Data, timeout: DispatchTimeInterval) -> Observable<Void> {
        return write(in: suotaPatchLenCharacteristic, data: data, withTimeOut: timeout)
    }
    
    public func writeInPatchData(data: Data, timeout: DispatchTimeInterval) -> Observable<Void> {
        return .deferred { [weak self] in
            guard let strongSelf = self else {
                return .error(BluetoothError.destroyed)
            }

            return strongSelf.suotaPatchDataCharacteristic
                .flatMap { characteristic -> Observable<Characteristic> in
                    if let value = characteristic {
                        return value.writeValue(data, type: .withoutResponse).asObservable()
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
    
    private func write(in characteristic: BehaviorSubject<Characteristic?>, data: Data, withTimeOut timeout: DispatchTimeInterval) -> Observable<Void> {
        return .deferred { [weak self] in
            guard let strongSelf = self else {
                return .error(BluetoothError.destroyed)
            }

            return characteristic
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
