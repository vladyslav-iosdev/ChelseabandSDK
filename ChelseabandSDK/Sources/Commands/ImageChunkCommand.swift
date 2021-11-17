//
//  ImageChunkCommand.swift
//  ChelseabandSDK
//
//  Created by Sergey Pohrebnuak on 03.11.2021.
//

import RxSwift
import CoreBluetooth

public final class ImageChunkCommand: CommandNew {
    public let uuidForWrite = ChelseabandConfiguration.default.imageChunkCharacteristic
    
    public var dataForSend: Data = Data()
    
    public var writeType: CBCharacteristicWriteType {
        .withoutResponse
    }
    
    private var imageChunkedArray: [Data]
    
    private static let maxChunkSize = 200
    
    init(_ binImage: Data) {
        imageChunkedArray = binImage.createChunks(chunkSize: ImageChunkCommand.maxChunkSize)
    }
    
    public func perform(on executor: CommandExecutor) -> Observable<Void> {
        return .deferred { [weak self] in
            return Observable<Void>.create { [weak self] seal in
                guard let strongSelf = self else { return Disposables.create() }
                
                let writeDisposable = Observable.from(strongSelf.imageChunkedArray)
                    .concatMap ({ [weak self] nextChunk -> Observable<Void> in
                        guard let strongSelf = self else { return .just(())}
                        strongSelf.dataForSend = nextChunk
                        return executor.write(command: strongSelf)
                    })
                    .materialize()
                    .subscribe(
                        onNext: { result in
                            switch result {
                            case .next(_):
                                break
                            case .error(let error):
                                seal.onError(error)
                            case .completed:
                                break
                            }
                        }, onCompleted: {
                            seal.onNext(())
                            seal.onCompleted()
                        }
                    )
                
                return Disposables.create {
                    writeDisposable.dispose()
                }
            }
        }
    }
}
