//
//  MockCommandsExecutor.swift
//  ChelseabandSDKTests
//
//  Created by Sergey Pohrebnuak on 22.09.2021.
//

import RxSwift
import ChelseabandSDK

struct MockCommandsExecutor: CommandExecutor {
    
    private var device: DeviceType
    
    var isConnected: Observable<Bool> = .just(true)
    
    init(device: DeviceType) {
        self.device = device
    }
        
    func write(command: WritableCommand) -> Observable<Void> {
        device.write(command: command, timeout: .seconds(5))
    }
    
    func writeAndObservNotify(command: WritableCommand) -> Observable<Data> {
        .just(Data())
    }
    
    func read(command: ReadableCommand) -> Observable<Data?> {
        .just(Data())
    }
}
