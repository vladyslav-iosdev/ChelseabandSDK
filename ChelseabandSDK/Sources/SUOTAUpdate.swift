//
//  SUOTAUpdate.swift
//  ChelseabandSDK
//
//  Created by Sergey Pohrebnuak on 20.08.2021.
//

import Foundation
import RxSwift

protocol SUOTAUpdateType {
    var percentOfUploadingObservable: Observable<Double> { get }
    init(updateDevice device: UpdateDeviceViaSuotaType, withData: Data)
}

public enum SUOTAUpdateError: Error {
    case noValueForPatchOrMtuSize
    case wrongExpectedValue
    case writeError
}
// TODO: refactoring suota on comand new model
final class SUOTAUpdate: SUOTAUpdateType {
    public var percentOfUploadingObservable: Observable<Double> {
        percentOfUploadingSubject
    }
    
    private var percentOfUploadingSubject: BehaviorSubject<Double> = .init(value: 0)
    private var data: Data
    private var expectedValue: UInt8 = 0x0
    private var expectedData: Data {
        Data([expectedValue])
    }
    private var chunkSize: Int = 20
    private var blockSize: Int = 20
    private var blockStartByte: Int = 0
    
    private enum Steps {
        case zero
        case first
        case second
        case third
        case fourth
        case fifth
        case sixth
        case seventh
        case eight
    }
    
    private var step: Steps = .first
    private var nextStep: Steps = .zero
    private var shouldHandleError = true
    
    private let disposeBag = DisposeBag()
    private let timeout: DispatchTimeInterval = .seconds(5)
    private let device: UpdateDeviceViaSuotaType
    
    init(updateDevice device: UpdateDeviceViaSuotaType, withData: Data) {
        self.device = device
        data = withData
        subscribeOnUpdates()
        doStep()
    }
    
    private func doStep() {
        switch step {
        case .zero:
            break
        case .first:
            firstStep()
        case .second:
            secondStep()
        case .third:
            thirdStep()
        case .fourth:
            fourthStep()
        case .fifth:
            fifthStep()
        case .sixth:
            sixthStep()
        case .seventh:
            seventhStep()
        case .eight:
            percentOfUploadingSubject.on(.completed)
        }
    }
    
    private func firstStep() {
        step = .zero
        nextStep = .second
        expectedValue = 0x10
        let memoryType: UInt32 = 0x13 //SPI
        let memoryBank: UInt32 = 0x0

        let memDev: UInt32 = (memoryType << 24) | memoryBank
        
        device.writeInMemDev(data: memDev.data, timeout: timeout)
            .subscribe(
                onNext: {},
                onError: { [weak self] _ in
                    self?.percentOfUploadingSubject.on(.error(SUOTAUpdateError.writeError))
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func secondStep() {
        let spiMISOGPIO: UInt32 = 0x05
        let spiMOSIGPIO: UInt32 = 0x06
        let spiCSGPIO: UInt32 = 0x03
        let spiSCKGPIO: UInt32 = 0x0

        let memInfo = (spiMISOGPIO << 24) | (spiMOSIGPIO << 16) | (spiCSGPIO << 8) | spiSCKGPIO
        step = .third
        device.writeInGpioMap(data: memInfo.data, timeout: timeout)
            .subscribe(
                onNext: { [weak self] in self?.doStep() },
                onError: { [weak self] _ in
                    self?.percentOfUploadingSubject.on(.error(SUOTAUpdateError.writeError))
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func thirdStep() {
        guard let managerSuotaPatchDataSize = try? device.suotaPatchDataSizeSubject.value(),
              let managerSuotaMtu = try? device.suotaMtuCharSizeSubject.value() else
        {
            percentOfUploadingSubject.on(.error(SUOTAUpdateError.noValueForPatchOrMtuSize))
            return
        }

        chunkSize = Int(min(managerSuotaPatchDataSize, managerSuotaMtu - 3))
        blockSize = max(blockSize, chunkSize)
        appendChecksum(fileData: &data)
        
        if blockSize > data.count {
            blockSize = data.count
            if chunkSize > blockSize {
                chunkSize = blockSize
            }
        }
        
        step = .fourth
        doStep()
    }
    
    private func fourthStep() {
        step = .fifth
        let blockSize = UInt16(self.blockSize)
        device.writeInPatchLen(data: blockSize.data, timeout: timeout)
            .subscribe(
                onNext: { [weak self] in self?.doStep() },
                onError: { [weak self] _ in
                    self?.percentOfUploadingSubject.on(.error(SUOTAUpdateError.writeError))
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func fifthStep() {
        step = .zero
        nextStep = .fifth
        expectedValue = 0x02

        let dataLength = data.count
        var chunkStartByte: Int = 0

        while (chunkStartByte < blockSize) {
            let bytesRemaining = blockSize - chunkStartByte
            let currChunkSize = bytesRemaining >= chunkSize ? chunkSize : bytesRemaining
            
            let progress = Double(blockStartByte + chunkStartByte + currChunkSize) / Double(dataLength)
            percentOfUploadingSubject.on(.next(progress * 100))
            print("SUOTA Update progress: \(progress)")

            var bytes = [UInt8](repeating: 0, count: currChunkSize)
            let range = NSMakeRange(blockStartByte + chunkStartByte, currChunkSize)
            (data as NSData).getBytes(&bytes, range: range)
            chunkStartByte += currChunkSize
            
            if chunkStartByte >= blockSize {
                // Prepare for next block
                blockStartByte += blockSize

                let bytesRemaining = dataLength - blockStartByte
                if bytesRemaining == 0 {
                    nextStep = .sixth
                    
                } else if bytesRemaining < blockSize {
                    blockSize = bytesRemaining
                    nextStep = .fourth // Back to step 4, setting the patch length
                }
            }
            
            device.writeInPatchData(data: Data(bytes), timeout: timeout)
                .subscribe(
                    onNext: {},
                    onError: { [weak self] _ in
                        self?.percentOfUploadingSubject.on(.error(SUOTAUpdateError.writeError))
                    }
                )
                .disposed(by: disposeBag)
        }
    }
    
    private func sixthStep() {
        step = .zero
        nextStep = .seventh
        expectedValue = 0x02
        let suotaEnd: UInt32 = 0xFE000000
        device.writeInMemDev(data: suotaEnd.data, timeout: timeout)
            .subscribe(
                onNext: {},
                onError: { [weak self] _ in
                    self?.percentOfUploadingSubject.on(.error(SUOTAUpdateError.writeError))
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func seventhStep() {
        step = .eight
        let suotaReboot: UInt32 = 0xFD000000
        shouldHandleError = false
        device.writeInMemDev(data: suotaReboot.data, timeout: timeout)
            .subscribe { [weak self] in self?.doStep() }
            .disposed(by: disposeBag)
    }
    
    private func subscribeOnUpdates() {
        device.suotaServStatusCharacteristicObservable
            .subscribe(onNext: { [weak self] characteristic in
                guard let strongSelf = self else { return }
                characteristic
                    .observeValueUpdateAndSetNotification()
                    .compactMap { $0.value }
                    .subscribe(onNext: { [weak self] in
                        guard let strongSelf = self else { return }
                        if strongSelf.expectedValue != 0 {
                            if $0 == strongSelf.expectedData {
                                strongSelf.step = strongSelf.nextStep
                                strongSelf.expectedValue = 0
                                strongSelf.doStep()
                            } else {
                                strongSelf.percentOfUploadingSubject.on(.error(SUOTAUpdateError.wrongExpectedValue))
                            }
                        }
                    }, onError: { [weak self] error in
                        guard let strongSelf = self else { return }
                        if strongSelf.shouldHandleError {
                            strongSelf.percentOfUploadingSubject.on(.error(error))
                        }
                    })
                    .disposed(by: strongSelf.disposeBag)
            })
            .disposed(by: disposeBag)
    }
    
    private func appendChecksum(fileData: inout Data) {
        var crc_code: UInt8 = 0
        
        let bytes = fileData.bytes
        var i = 0
        while i < fileData.count {
            crc_code ^= bytes[i]
            i += 1
        }
        
        fileData.append(crc_code)
    }
    
    deinit {
        print("deinit \(self)")
    }
}
