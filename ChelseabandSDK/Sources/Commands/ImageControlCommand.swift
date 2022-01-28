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
    case noHashData
    case wrongHashDataSize
    case imageHashNotEqual
    case tooManyAttempts
    
    public var errorDescription: String? {
        switch self {
        case .wrongImageSize:
            return "Image size which should upload to band not equal to expected"
        case .noHashData:
            return "Read from characteristic, but hash data is empty"
        case .wrongHashDataSize:
            return "Data which received from the band is not equal to expected"
        case .imageHashNotEqual:
            return "Hash from prototype didn't equal to expected"
        case .tooManyAttempts:
            return "Too many attempts for uploading image to the band"
        }
    }
}

public struct ImageControlCommand: PerformableWriteCommand {
    public let commandUUID = ChelseabandConfiguration.default.imageControlCharacteristic
    
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

extension ImageControlCommand: PerformReadCommandProtocol {
    public func performRead(on executor: CommandExecutor) -> Observable<Data> {
        executor.read(command: self)
            .do(onNext: {
                guard let data = $0 else { throw ImageControlCommandError.noHashData }
                guard data.count == 48 else { throw ImageControlCommandError.wrongHashDataSize }
                
                let hashArrays = ([UInt8](data)).chunked(by: 16)
                let imageHashFromPrototype = Data(hashArrays[Int(alertImage.imageType)])
                
                if imageHashFromPrototype != md5ImageHashData {
                    throw ImageControlCommandError.imageHashNotEqual
                }
            })
            .map { _ in Data() }
    }
}

extension ImageControlCommand {
    public enum AlertImage {
        case opposingTeamsLogos
        case alertIcon
        case gamedayTheme
        
        var imageType: UInt8 {
            switch self {
            case .opposingTeamsLogos:
                return 0
            case .alertIcon:
                return 1
            case .gamedayTheme:
                return 2
            }
        }
        
        var imageLength: UInt32 {
            switch self {
            case .opposingTeamsLogos:
                return 64960
            case .alertIcon:
                return 2738
            case .gamedayTheme:
                return 25600
            }
        }
    }
}
