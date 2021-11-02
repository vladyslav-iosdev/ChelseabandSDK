//
//  ImageControlCommand.swift
//  ChelseabandSDK
//
//  Created by Sergey Pohrebnuak on 01.11.2021.
//

import RxSwift

public struct ImageControlCommand: CommandNew {
    public let uuidForWrite = ChelseabandConfiguration.default.imageControlCharacteristic
    
    public var dataForSend: Data {
        alertImage.imageType.data + alertImage.imageLength.data
    }
    
    private let alertImage: AlertImage
    
    init(_ image: AlertImage) {
        alertImage = image
    }
    
    public func perform(on executor: CommandExecutor) -> Observable<Void> {
        executor.write(command: self)
    }
}

extension ImageControlCommand {
    public enum AlertImage {
        case opposingTeamImage
        case alertIcon
        case opposingTeamWinningLogo
        case gamedayTheme
        
        var imageType: UInt8 {
            switch self {
            case .opposingTeamImage:
                return 0
            case .alertIcon:
                return 1
            case .opposingTeamWinningLogo:
                return 2
            case .gamedayTheme:
                return 3
            }
        }
        
        var imageLength: UInt32 {
            switch self {
            case .opposingTeamImage:
                return 3200
            case .alertIcon:
                return 7200
            case .opposingTeamWinningLogo:
                return 3200
            case .gamedayTheme:
                return 25600
            }
        }
    }
}
