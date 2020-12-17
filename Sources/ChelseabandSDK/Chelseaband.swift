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

    init(device: DeviceType)
    
    func connect()
    func disconnect()

    func perform(command: Command) -> Observable<Void>
}

public class Chelseaband: ChelseabandType {

    public var batteryLevelObservable: Observable<UInt64> {
        return batteryLevelSubject
    }
    
    public var connectionObservable: Observable<Device.State> {
        return device.connectionObservable
    } 

    private var readCharacteristicSubject: PublishSubject<Data> = .init()
    private var batteryLevelSubject: BehaviorSubject<UInt64> = .init(value: 0)
    private let device: DeviceType
    private var connectionDisposable: Disposable? = .none
    private var disposeBag = DisposeBag()
    private var setupDisposeBag = DisposeBag()

    required public init(device: DeviceType) {
        self.device = device

        device.bluetoothHasConnected.subscribe { [weak self] _ in
            guard let strongSelf = self else { return }

            strongSelf.connect()
        }.disposed(by: disposeBag)
    }

    public func connect() {
        connectionDisposable = device
            .connect()
            .do(afterNext: { device in
                self.setupChelseaband(device: device)
            })
            .subscribe()
    }

    private func setupChelseaband(device: DeviceType) {
        setupDisposeBag = DisposeBag()

        device
            .readCharacteristicObservable
            .flatMap { $0.observeValueUpdateAndSetNotification() }
            .compactMap { $0.characteristic.value }
            .catchError { _ in .never() }
            .subscribe(readCharacteristicSubject)
            .disposed(by: setupDisposeBag)


        let batteryCommand = BatteryCommand()
        batteryCommand.batteryLevel
            .debug("bat-v: ")
            .subscribe(batteryLevelSubject)
            .disposed(by: setupDisposeBag)

        perform(command: batteryCommand)
            .subscribe()
            .disposed(by: setupDisposeBag)

        let timeCommand = TimeCommand()

        perform(command: timeCommand)
            .subscribe()
            .disposed(by: setupDisposeBag)
    }

    public func perform(command: Command) -> Observable<Void> {
        command
            .perform(on: self, notifyWith: self)
            .mapToVoid()
            .observeOn(MainScheduler.instance)
            .subscribeOn(SerialDispatchQueueScheduler.init(qos: .default))
    }

    public func disconnect() {
        connectionDisposable?.dispose()
        connectionDisposable = .none
    }
}

extension Chelseaband: CommandNotifier {

    public var notifyObservable: Observable<Data> {
        readCharacteristicSubject
    }
}

extension Chelseaband: CommandExecutor {

    public var isConnected: Observable<Bool> {
        connectionObservable.map { $0.isConnected }.startWith(false)
    }

    public func write(data: Data) -> Observable<Void> {
        device.write(data: data, readTimeout: .milliseconds(250))
    }
}

