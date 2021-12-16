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
import CoreLocation

public typealias Peripheral = ScannedPeripheral
public typealias BluetoothState = RxBluetoothKit.BluetoothState

public protocol ChelseabandType {
    
    var connectionObservable: Observable<Device.State> { get }

    var batteryLevelObservable: Observable<UInt8> { get }
    
    var firmwareVersionObservable: Observable<String?> { get }

    var bluetoothHasConnected: Observable<Void> { get }

    var isSearching: Observable<Bool> { get }
    
    var bluetoothState: Observable<BluetoothState> { get }

    var lastConnectedPeripheralUUID: String? { get set }
    
    var locationManager: LocationManager { get }
    
    var isAuthorize: Observable<Bool> { get }

    init(device: DeviceType, apiBaseEndpoint: String, apiKey: String)
    
    func connect(peripheral: Peripheral)

    func isConnected(peripheral: Peripheral) -> Bool

    func isLastConnected(peripheral: Peripheral) -> Bool

    func disconnect(forgotLastPeripheral: Bool)
    
    func updateBandSettings(bandOrientation: BandOrientation) -> Observable<Void>
    
    func fetchSurveyResponses(forNotificationId id: String) -> Observable<[(answer: String, count: Int)]>

    func forceSendConnectStatusOnServer()
    
    func performSafeAndObservNotify(command: CommandPerformer, timeOut: DispatchTimeInterval) -> Observable<Data>

    func performAndObservNotify(command: CommandPerformer) -> Observable<Data>
        
    func perform(command: CommandPerformer) -> Observable<Void>

    func performSafe(command: CommandPerformer, timeOut: DispatchTimeInterval) -> Observable<Void>
    
    func performRead(command: PerformReadCommandProtocol) -> Observable<Void>
    
    func performSafeRead(command: PerformReadCommandProtocol, timeOut: DispatchTimeInterval) -> Observable<Void>

    func setFCMToken(_ token: String)
    
    func register(phoneNumber: String) -> Observable<Void>
    
    func verify(phoneNumber: String, withOTPCode: String, andFCM: String) -> Observable<Bool>
    
    func uploadImage(_ binImage: Data, imageType: ImageControlCommand.AlertImage) -> Observable<Void>
    
    func fetchFreshTicketAndUploadOnBand() -> Observable<TicketType>
    
    func fetchTicket() -> Observable<TicketType?>
    
    func sendMessageCommand(_ message: String, withType type: MessageType, id: String) -> Observable<Void>
    
    func sendGoalCommandNew(data: Data, decoder: JSONDecoder) -> Observable<Void>
    
    func sendVibrationCommand(data: Data, decoder: JSONDecoder) -> Observable<Void>
    
    func sendLedCommand(data: Data, decoder: JSONDecoder) -> Observable<Void>
    
    func sendPollCommand(id: String, question: String, answers: [String]) -> Observable<(String, Int?)>
    
    func sendEndPollCommand() -> Observable<Void>
    
    func sendPoll(response: Int?, id: String) -> Observable<Void>
    
    func sendReaction(id: String)

    func startScanForPeripherals() -> Observable<[Peripheral]>

    func stopScanForPeripherals()
    
    func updateFirmware() -> Observable<Double>
    
    func appWillBeClose(callback: (() -> Void)?)
}

public enum ChelseabandError: LocalizedError {
    case destroyed
    case userHaventTicket
    case bandDisconnected
    
    public var errorDescription: String? {
        switch self {
        case .destroyed:
            return "Chelseaband SDK was destroyed"
        case .userHaventTicket:
            return "Looks like user still haven't ticket on server"
        case .bandDisconnected:
            return "Looks like band is disconnected, connect band to phone and try again"
        }
    }
}

public final class Chelseaband: ChelseabandType {

    public var batteryLevelObservable: Observable<UInt8> {
        return batteryLevelSubject
    }
    
    public var firmwareVersionObservable: Observable<String?> {
        device.firmwareVersionSubject
    }
    
    public var connectionObservable: Observable<Device.State> {
        return device.connectionObservable
    }

    public var bluetoothHasConnected: Observable<Void> {
        return device.bluetoothHasConnected
    }

    public var isSearching: Observable<Bool> {
        return device.bluetoothIsSearching
    }
    
    public var bluetoothState: Observable<BluetoothState> {
        return device.bluetoothState
    }

    public var lastConnectedPeripheralUUID: String? {
        get {
            UserDefaults.standard.lastConnectedPeripheralUUID
        }
        set {
            UserDefaults.standard.lastConnectedPeripheralUUID = newValue
        }
    }
    
    public var locationManager: LocationManager {
        locationTracker
    }
    
    public var isAuthorize: Observable<Bool> { UserDefaults.standard.isAuthorizeObservable }

    private var batteryLevelSubject: BehaviorSubject<UInt8> = .init(value: 0)
    private let device: DeviceType
    private let statistic: Statistics
    private var connectionDisposable: Disposable? = .none
    private var disposeBag = DisposeBag()
    private var longLifeDisposeBag = DisposeBag()
    private let locationTracker: LocationTracker
    private let tokenBehaviourSubject = BehaviorSubject<String?>(value: nil)
    private var suotaUpdate: SUOTAUpdateType? = nil

    required public init(device: DeviceType, apiBaseEndpoint: String, apiKey: String) {
        self.device = device
        self.statistic = API()
        UserDefaults.standard.apiBaseEndpoint = apiBaseEndpoint
        UserDefaults.standard.apiKey = apiKey
        
        locationTracker = LocationManagerTracker()
        observeForFCMTokenChange()
        observeLocationChange()
    }
    private var connectedPeripheral: Peripheral?

    public func isConnected(peripheral: Peripheral) -> Bool {
        return connectedPeripheral?.peripheral.identifier == peripheral.peripheral.identifier
    }

    public func connect(peripheral: Peripheral) {
        disposeBag = DisposeBag()
        connectionDisposable = device
            .connect(peripheral: peripheral)
            .subscribe(onNext: { [weak self] _ in
                guard let strongSelf = self else { return }
                strongSelf.connectedPeripheral = peripheral
                strongSelf.lastConnectedPeripheralUUID = peripheral.UUID

                strongSelf.synchronizeBattery()
                strongSelf.observeForConnectionStatusChange()
                strongSelf.sendBandUUIDOnServer(peripheral)
                strongSelf.synchronizeScore()
                
            }, onError: { [weak self] error in
                guard let strongSelf = self else { return }
                strongSelf.disconnect(forgotLastPeripheral: false)
            })
    }
    
    public func appWillBeClose(callback: (() -> Void)?) {
        statistic.sendBand(status: false, callback: callback)
    }

    public func isLastConnected(peripheral: Peripheral) -> Bool {
        lastConnectedPeripheralUUID == peripheral.UUID
    }
    
    public func fetchSurveyResponses(forNotificationId id: String) -> Observable<[(answer: String, count: Int)]> {
        statistic.fetchSurveyResponses(forNotificationId: id)
    }

    private var fcmTokenObservable: Observable<String> {
        tokenBehaviourSubject
            .compactMap{ $0 }
    }

    private var connectedOrDisconnectedObservable: Observable<Device.State> {
        connectionObservable
            .skip(1)
            .filter { $0 == .connected || $0 == .disconnected }
    }

    private func observeForConnectionStatusChange() {
        Observable.combineLatest(fcmTokenObservable, connectedOrDisconnectedObservable)
            .map { $0.1 }
            .subscribe(onNext: {
                self.statistic.sendBand(status: $0.isConnected)
            }).disposed(by: disposeBag)
    }

    private func observeForFCMTokenChange() {
        fcmTokenObservable
            .subscribe(onNext: { token in
                self.statistic.register(fcmToken: token)
            }).disposed(by: longLifeDisposeBag)
    }

    private func observeLocationChange() {
        locationTracker.isInAreaObservable
            .subscribe(onNext: { [weak self] in
                self?.statistic.sendLocation(isInArea: $0)
            })
            .disposed(by: longLifeDisposeBag)
    }
    
    private func synchronizeScore() {
        statistic.getCurrentScore()
            .flatMap { [weak self] resultTuple -> Observable<Data> in
                guard let strongSelf = self else { throw ChelseabandError.destroyed }
                return strongSelf.uploadImage(resultTuple.image,
                                  imageType: .opposingTeamImage)
                    .map { resultTuple.scoreModel }
            }
            .take(1)
            .flatMap { [weak self] scoreModelData -> Observable<Void> in
                guard let strongSelf  = self else { throw ChelseabandError.destroyed }
                return strongSelf.sendGoalCommandNew(data: scoreModelData, decoder: .init())
            }
            .take(1)
            .timeout(.seconds(60), scheduler: MainScheduler.instance)
            .subscribe()
            .disposed(by: disposeBag)
    }

    private func synchronizeBattery() {
        Observable.combineLatest(device.batteryCharacteristicObservable, device.connectionObservable)
            .do(onNext: {
                //NOTE: if device will disconnect set battery level to zero
                if $0.1 != .connected {
                    self.batteryLevelSubject.onNext(0)
                }
            })
            .flatMap {
                //NOTE: when subscribe on value update it didn't return current state that's why need read value for fetch current state
                Observable<Observable<Event<Characteristic>>>.of(
                    $0.0.observeValueUpdateAndSetNotification().materialize(),
                    $0.0.readValue().asObservable().materialize()
                ).merge()
            }
            .compactMap{ $0.element }
            .compactMap{ $0.characteristic.value }
            .compactMap{ $0.uint8 }
            .bind(to: batteryLevelSubject)
            .disposed(by: disposeBag)
    }
    
    public func uploadImage(_ binImage: Data, imageType: ImageControlCommand.AlertImage) -> Observable<Void> {
        guard imageType.imageLength == binImage.count else {
            return Observable<Void>.error(ImageControlCommandError.wrongImageSize)
        }
        
        let imageControl = ImageControlCommand(imageType, imageData: binImage)
        let imageChunk = ImagePerformCommand(binImage)
        let commands = [
            performSafe(command: imageControl, timeOut: .seconds(5)),
            performSafe(command: imageChunk, timeOut: .seconds(5)),
            performSafeRead(command: imageControl, timeOut: .seconds(5))
        ]
        
        return Observable<Void>.create { [weak self] seal in
            let commandsDisposable = Observable.from(commands)
                .concatMap { $0 }
                .retryWhen { error in
                    error
                        .scan(0) { attempts, error in
                            let max = 3
                            guard attempts < max else { throw ImageControlCommandError.tooManyAttempts }
                            guard case ImageControlCommandError.imageHashNotEqual = error else { throw error }
                            return attempts + 1
                        }
                }
                .materialize()
                .subscribe(
                    onNext: { result in
                        switch result {
                        case .error(let error):
                            seal.onError(error)
                        default:
                            break
                        }
                    }, onCompleted: {
                        seal.onNext(())
                        seal.onCompleted()
                    })
            
            return Disposables.create {
                commandsDisposable.dispose()
            }
        }
    }
    
    public func fetchFreshTicketAndUploadOnBand() -> Observable<TicketType> {
        Observable.combineLatest(statistic.fetchTicket(), connectionObservable)
            .skipWhile { !$0.1.isConnected }
            .timeout(.seconds(15), scheduler: MainScheduler.instance)
            .take(1)
            .catchError { error in
                if case RxSwift.RxError.timeout = error {
                    throw ChelseabandError.bandDisconnected
                } else {
                    throw error
                }
            }
            .map{ $0.0 }
            .map { serverTicket -> TicketType in
                if let ticket = serverTicket {
                    return ticket
                } else {
                    throw ChelseabandError.userHaventTicket
                }
            }
            .flatMap { [weak self] ticket -> Observable<Observable<TicketType>> in
                guard let strongSelf = self else { throw ChelseabandError.destroyed }
                do {
                    let seatCommand = try SeatPositionCommand(fromTicket: ticket)
                    let nfcCommand = try NFCCommand(fromTicket: ticket)
                    return Observable.from([nfcCommand.perform(on: strongSelf).map { ticket },
                                            seatCommand.perform(on: strongSelf).map { ticket }])
                } catch let error {
                    throw error
                }
            }
            .concatMap { $0 }
            .takeLast(1)
    }
    
    public func fetchTicket() -> Observable<TicketType?> {
        statistic.fetchTicket()
            .take(1)
    }
    
    public func sendMessageCommand(_ message: String, withType type: MessageType, id: String) -> Observable<Void> {
        do {
            let messageCommand = try MessageCommand(message, type: type)
            return performSafe(command: messageCommand, timeOut: .seconds(5))
        } catch {
            return .error(error)
        }
    }
    
    public func sendGoalCommandNew(data: Data, decoder: JSONDecoder) -> Observable<Void> {
        do {
            let scoreCommand = try ScoreCommand(fromData: data, withDecoder: decoder)
            return performSafe(command: scoreCommand, timeOut: .seconds(5))
        } catch {
            return Observable<Void>.error(error)
        }
    }
    
    public func sendPollCommand(id: String, question: String, answers: [String]) -> Observable<(String, Int?)> {
        do {
            let pollCommand = try PollCommand(pollText: question, pollAnswers: answers)
            return performSafeAndObservNotify(command: pollCommand, timeOut: .seconds(5))
                .map { data in
                    let stringInt = String.init(data: data, encoding: .utf8)
                    return (id, Int(stringInt ?? ""))
                }
        } catch {
            return .error(error)
        }
    }
    
    public func sendEndPollCommand() -> Observable<Void> {
        do {
            let endPollCommand = try PollCommand()
            return performSafe(command: endPollCommand, timeOut: .seconds(5))
        } catch {
            return .error(error)
        }
    }

    public func sendPoll(response: Int?, id: String) -> Observable<Void> {
        statistic.sendVotingResponse(response, id)
    }
    
    public func sendVibrationCommand(data: Data, decoder: JSONDecoder) -> Observable<Void> {
        do {
            let vibrationCommand = try VibrationCommand(fromData: data, withDecoder: decoder)
            return performSafe(command: vibrationCommand, timeOut: .seconds(5))
        } catch {
            return Observable<Void>.error(error)
        }
    }
    
    public func sendLedCommand(data: Data, decoder: JSONDecoder) -> Observable<Void> {
        do {
            let ledCommand = try LEDCommand(fromData: data, withDecoder: decoder)
            return performSafe(command: ledCommand, timeOut: .seconds(5))
        } catch {
            return Observable<Void>.error(error)
        }
    }
    
    public func updateFirmware() -> Observable<Double> {
        if let suota = suotaUpdate {
            return suota.percentOfUploadingObservable
        }
        
        //TODO: remove contentsOfFile logic
        let suota = SUOTAUpdate(updateDevice: device,
                                withData: NSData(contentsOfFile: Bundle.main.path(forResource: "fanband.1.11.1.0", ofType: "img")!)! as Data)
        
        suota.percentOfUploadingObservable
            .subscribe(onError: { [weak self] _ in
                self?.suotaUpdate = nil
            }, onCompleted: { [weak self] in
                self?.suotaUpdate = nil
            })
            .disposed(by: disposeBag)
        
        suotaUpdate = suota
        return suota.percentOfUploadingObservable
    }
    
    public func updateBandSettings(bandOrientation: BandOrientation) -> Observable<Void> {
        let deviceSettingsCommand = DeviceSettingsCommand(bandOrientation: bandOrientation)
        return performSafe(command: deviceSettingsCommand, timeOut: .seconds(5))
    }
    
    public func forceSendConnectStatusOnServer() {
        connectionObservable
            .take(1)
            .timeout(.seconds(2), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.statistic.sendBand(status: $0.isConnected)
            })
            .disposed(by: disposeBag)
    }
    
    public func perform(command: CommandPerformer) -> Observable<Void> {
        command
            .perform(on: self)
            .observeOn(MainScheduler.instance)
            .subscribeOn(SerialDispatchQueueScheduler(qos: .default))
    }
    
    public func performAndObservNotify(command: CommandPerformer) -> Observable<Data> {
        command
            .performAndObserveNotify(on: self)
            .observeOn(MainScheduler.instance)
            .subscribeOn(SerialDispatchQueueScheduler(qos: .default))
    }
    
    public func performSafe(command: CommandPerformer, timeOut: DispatchTimeInterval = .seconds(3)) -> Observable<Void> {
        connectionObservable
            .skipWhile { !$0.isConnected }
            .skipWhile { _ in self.suotaUpdate != nil }
            .take(1)
            .timeout(timeOut, scheduler: MainScheduler.instance)
            .flatMap { _ -> Observable<Void> in
                self.perform(command: command)
            }
    }
    
    public func performSafeAndObservNotify(command: CommandPerformer, timeOut: DispatchTimeInterval) -> Observable<Data> {
        connectionObservable
            .skipWhile { !$0.isConnected }
            .skipWhile { _ in self.suotaUpdate != nil }
            .take(1)
            .timeout(timeOut, scheduler: MainScheduler.instance)
            .flatMap { _ -> Observable<Data> in
                self.performAndObservNotify(command: command)
            }
    }
    
    public func performSafeRead(command: PerformReadCommandProtocol, timeOut: DispatchTimeInterval = .seconds(3)) -> Observable<Void> {
        connectionObservable
            .skipWhile { !$0.isConnected }
            .skipWhile { _ in self.suotaUpdate != nil }
            .take(1)
            .timeout(timeOut, scheduler: MainScheduler.instance)
            .flatMap { _ -> Observable<Void> in
                self.performRead(command: command)
            }
    }
    
    public func performRead(command: PerformReadCommandProtocol) -> Observable<Void> {
        command
            .performRead(on: self)
            .observeOn(MainScheduler.instance)
            .subscribeOn(SerialDispatchQueueScheduler(qos: .default))
    }

    public func disconnect(forgotLastPeripheral: Bool) {
        connectionDisposable?.dispose()
        connectionDisposable = .none
        connectedPeripheral = .none
        if forgotLastPeripheral {
            lastConnectedPeripheralUUID = .none
        }
    }

    public func setFCMToken(_ token: String) {
        tokenBehaviourSubject.onNext(token)
    }
    
    public func register(phoneNumber: String) -> Observable<Void> {
        statistic.register(phoneNumber: phoneNumber)
    }
    
    public func verify(phoneNumber: String, withOTPCode OTPCode: String, andFCM fcm: String) -> Observable<Bool> {
        statistic.verify(phoneNumber: phoneNumber, withOTPCode: OTPCode, andFCM: fcm)
    }
    
    private func sendBandUUIDOnServer(_ peripheral: Peripheral) {
        guard let bandUUID = peripheral.UUID else { return }
        
        statistic.connectFanband(bandUUID: bandUUID)
    }
    
    public func sendReaction(id: String) {
        statistic.sendReaction(id)
    }

    public func startScanForPeripherals() -> Observable<[Peripheral]> {
        device
            .startScanForPeripherals()
            .share(replay: 1)
    }

    public func stopScanForPeripherals() {
        device.stopScanForPeripherals()
    }
}

extension Chelseaband: CommandExecutor {

    public var isConnected: Observable<Bool> {
        connectionObservable
            .startWith(.disconnected)
            .map { $0.isConnected }
    }
    
    public func write(command: WritableCommand) -> Observable<Void> {
        device.write(command: command, timeout: .seconds(5))
    }
    
    public func writeAndObservNotify(command: WritableCommand) -> Observable<Data> {
        device.writeAndObservNotify(command: command, timeout: .seconds(5))
    }
    
    public func read(command: ReadableCommand) -> Observable<Data?> {
        device.read(command: command, timeout: .seconds(5))
    }
}
