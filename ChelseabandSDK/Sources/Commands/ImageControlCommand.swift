//
//  ImageControlCommand.swift
//  ChelseabandSDK
//
//  Created by Sergey Pohrebnuak on 01.11.2021.
//

import RxSwift
import Foundation
import var CommonCrypto.CC_MD5_DIGEST_LENGTH
import func CommonCrypto.CC_MD5
import typealias CommonCrypto.CC_LONG

public enum ImageControlCommandError: LocalizedError {
    case wrongImageSize
    
    public var errorDescription: String? {
        switch self {
        case .wrongImageSize:
            return "Image size which should upload to band not equal to expected"
        }
    }
}

public struct ImageControlCommand: CommandNew {
    public let uuidForWrite = ChelseabandConfiguration.default.imageControlCharacteristic
    
    public var dataForSend: Data {
        alertImage.imageType.data + alertImage.imageLength.data + md5ImageHashData
    }
    
    private let alertImage: AlertImage
    private let md5ImageHashData: Data
    
    init(_ image: AlertImage, imageData: Data) {
        alertImage = image
        md5ImageHashData = ImageControlCommand.MD5(fromData: imageData)
    }
    
    public func perform(on executor: CommandExecutor) -> Observable<Void> {
        executor.write(command: self)
    }
    
    private static func MD5(fromData data: Data) -> Data {
        let length = Int(CC_MD5_DIGEST_LENGTH)
        var digestData = Data(count: length)

        _ = digestData.withUnsafeMutableBytes { digestBytes -> UInt8 in
            data.withUnsafeBytes { messageBytes -> UInt8 in
                if let messageBytesBaseAddress = messageBytes.baseAddress, let digestBytesBlindMemory = digestBytes.bindMemory(to: UInt8.self).baseAddress {
                    let messageLength = CC_LONG(data.count)
                    CC_MD5(messageBytesBaseAddress, messageLength, digestBytesBlindMemory)
                }
                return 0
            }
        }
        return digestData
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
                return 2240
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
