//
//  ImageChunkCommand.swift
//  ChelseabandSDK
//
//  Created by Sergey Pohrebnuak on 03.11.2021.
//

import RxSwift
import CoreBluetooth

public struct ImagePerformCommand: CommandPerformer {
    private var imageChunkedArray: [Data]
    
    private static let maxChunkSize = 200
    
    init(_ binImage: Data) {
        imageChunkedArray = binImage.createChunks(chunkSize: ImagePerformCommand.maxChunkSize)
    }
    
    public func perform(on executor: CommandExecutor) -> Observable<Void> {
        Observable.from(self.imageChunkedArray)
            .concatMap ({ nextChunk -> Observable<Void> in
                let command = ImageChunkCommand(dataForSend: nextChunk)
                return executor.write(command: command)
            })
            .takeLast(1)
    }
}

public struct ImageChunkCommand: WritableCommand {
    public let commandUUID = ChelseabandConfiguration.default.imageChunkCharacteristic
    
    public var dataForSend: Data
    
    public var writeType: CBCharacteristicWriteType {
        .withoutResponse
    }
}
