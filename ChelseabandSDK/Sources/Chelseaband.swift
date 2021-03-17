//
//  ChelseaBand.swift
//  ChelseabandSDK
//
//  Created by Vladyslav Shepitko on 24.11.2020.
//

import Foundation
import RxSwift 
import RxBluetoothKit
import CoreBluetooth

public protocol ChelseabandType {
    
    var connectionObservable: Observable<Device.State> { get }

    var batteryLevelObservable: Observable<UInt64> { get }

    var bluetoothHasConnected: Observable<Void> { get }

    var bluetoothState: Observable<BluetoothState> { get }

    init(device: DeviceType)
    
    func connect()

    func disconnect()

    func perform(command: Command) -> Observable<Void>

    func performSafe(command: Command, timeOut: DispatchTimeInterval) -> Observable<Void>
    
    func setFMCToken(_ token: String)
}

public final class Chelseaband: ChelseabandType {

    public var batteryLevelObservable: Observable<UInt64> {
        return batteryLevelSubject
    }
    
    public var connectionObservable: Observable<Device.State> {
        return device.connectionObservable
    }

    public var bluetoothHasConnected: Observable<Void> {
        return device.bluetoothHasConnected
    }

    public var bluetoothState: Observable<BluetoothState> {
        return device.bluetoothState
    }

    private var readCharacteristicSubject: PublishSubject<Data> = .init()
    private var batteryLevelSubject: BehaviorSubject<UInt64> = .init(value: 0)
    private let device: DeviceType
    private var connectionDisposable: Disposable? = .none
    private var disposeBag = DisposeBag()
    private var fmcToken = PublishSubject<String>()
    private let locationTracker: LocationTracker

    required public init(device: DeviceType) {
        self.device = device
        
        locationTracker = LocationManagerTracker()
        locationTracker.startObserving()
        locationTracker.location
            .subscribe(onNext: {
                API().sendLocation(latitude: $0.latitude, longitude: $0.longitude)
            })
            .disposed(by: disposeBag)
        
        fmcToken
            .subscribe(onNext: {
                API().register(fmcToken: $0)
            })
            .disposed(by: disposeBag)
        
        connectionObservable
            .filter { $0 == .connected || $0 == .disconnected}
            .subscribe(onNext: {
                API().sendBand(status: $0.isConnected)
            })
            .disposed(by: disposeBag)
    }

    public func connect() {
        connectionDisposable = device
            .connect()
            .debug("\(self).main")
            .subscribe(onNext: { [weak self] _ in
                guard let strongSelf = self else { return }

                strongSelf.setupChelseaband(device: strongSelf.device)
            }, onError: { [weak self] error in
                guard let strongSelf = self else { return }

                strongSelf.disconnect()
            })
    }

    private func setupChelseaband(device: DeviceType) {
        disposeBag = DisposeBag()

        device
            .readCharacteristicObservable
            .flatMap { $0.observeValueUpdateAndSetNotification() }
            .compactMap { $0.characteristic.value }
            .catchError { _ in .never() } //NOTE: update this to avoid sending never when error
            .subscribe(readCharacteristicSubject)
            .disposed(by: disposeBag)

        let batteryCommand = BatteryCommand()
        batteryCommand.batteryLevel
            .debug("\(self).read-BatteryCommand")
            .subscribe(batteryLevelSubject)
            .disposed(by: disposeBag)

        perform(command: batteryCommand)
            .subscribe()
            .disposed(by: disposeBag)

        let timeCommand = TimeCommand()

        perform(command: timeCommand)
            .subscribe()
            .disposed(by: disposeBag)

        let accelerometerCommand = AccelerometerCommand()
        accelerometerCommand.axisObservable.subscribe (onNext: { axis in
            //no-op
        }).disposed(by: disposeBag)

        perform(command: accelerometerCommand)
            .subscribe()
            .disposed(by: disposeBag)

        let macAddressCommand = MACAddressCommand()
        macAddressCommand.MACAddressObservable.subscribe (onNext: { MACAddress in
            print(MACAddress)
        }).disposed(by: disposeBag)

        perform(command: macAddressCommand)
            .subscribe()
            .disposed(by: disposeBag)
    }

    public func perform(command: Command) -> Observable<Void> {
        command
            .perform(on: self, notifyWith: self)
            .observeOn(MainScheduler.instance)
            .subscribeOn(SerialDispatchQueueScheduler(qos: .default))
    }

    public func performSafe(command: Command, timeOut: DispatchTimeInterval = .seconds(3)) -> Observable<Void> {
        connectionObservable
            .skipWhile { !$0.isConnected }
            .take(1)
            .timeout(timeOut, scheduler: MainScheduler.instance)
            .debug("\(self).performSafe.trigger")
            .flatMap { _ -> Observable<Void> in
                self.perform(command: command)
            }
            .debug("\(self).performSafe.perform")
    }

    public func disconnect() {
        connectionDisposable?.dispose()
        connectionDisposable = .none
    }
    
    public func setFMCToken(_ token: String) {
        fmcToken.onNext(token)
    }
}

extension Chelseaband: CommandNotifier {

    public var notifyObservable: Observable<Data> {
        readCharacteristicSubject
    }
}

extension Chelseaband: CommandExecutor {

    public var isConnected: Observable<Bool> {
        connectionObservable
            .startWith(.disconnected)
            .map { $0.isConnected }
    }

    public func write(data: Data) -> Observable<Void> {
        device.write(data: data, timeout: .seconds(5)).debug("\(self).write")
    }
}

