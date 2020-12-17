//
//  ChelseabandTests.swift
//  ChelseabandSDK_Tests
//
//  Created by Vladyslav Shepitko on 24.11.2020.
//  Copyright © 2020 CocoaPods. All rights reserved.
//
import RxSwift
import XCTest
import RxTest

@testable import ChelseabandSDK

class ChelseabandTests: XCTestCase {
    let bag = DisposeBag()

    func testDataChunked() {
        let string: String = "Hello world! hello bluetooth device!".hex
        let chunks = string.hexaBytes.chunked(by: 16)

        XCTAssertEqual(chunks.count, 3)
    }

//    func testImport() {
//        let keystore = FakeEtherKeystore()
//        let expectation = self.expectation(description: "completion block called")
//        keystore.importWallet(type: .keystore(string: TestKeyStore.keystore, password: TestKeyStore.password)) { result in
//            expectation.fulfill()
//            let wallet = try! result.dematerialize()
//            XCTAssertEqual("0x5E9c27156a612a2D516C74c7a80af107856F8539", wallet.address.eip55String)
//            XCTAssertEqual(1, keystore.wallets.count)
//        }
//        wait(for: [expectation], timeout: 0.01)
//    }

    func testConvertHexToDataByChunks() {

//        let v1 = "0000000000000000"
//        let v2 = "00000000"
//        let chunkSize: Int = 16
//        let expected = [v1.hex, v2.hex]
//
//        let command = FakeCommand(value: v1 + v2)
//
//        let trigger = PublishSubject<Void>()
//        var chunks: [String] = []
//
////        trigger.flatMap { _ in
//////            CommandConveter().convertToData(command: command, chunk: chunkSize)
////        }.subscribe(onNext: { e in
////            XCTAssertLessThanOrEqual(e.count, chunkSize)
////
////            chunks.append(e.hex)
////        }).disposed(by: bag)
////
////        trigger.onNext(())
//
//        XCTAssertEqual(chunks, expected)
    }

    func testConnect() {
//        let service = Chelseaband.fake()
//
//        service.connect()
    }

//    let service = Chelseaband.fake()
//    let command = FakeCommand(value: "Hello world! hello bluetooth device!")

    func testWrite() {
//        service.write_s(command: command).debug("a=>").subscribe(onNext: { v in
//            print("asasd")
//        }, onError: { e in
//            print("asasd")
//        }, onCompleted: {
//            print("asasd")
//        }, onDisposed: {
//            print("asasd")
//        }).disposed(by: bag)
    }
}


//struct FakeCommand: Command {
//    let value: String
//
//    var hex: String {
//        return value.hex
//    }
//}
//
//extension Chelseaband {
//    static func fake() -> Chelseaband {
//        return Chelseaband.init(configuration: FakeConfiguration.initial)
//    }
//}
