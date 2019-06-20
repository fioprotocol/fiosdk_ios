//
//  CryptographyTests.swift
//  FIOSDKTests
//
//  Created by Vitor Navarro on 2019-06-19.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import XCTest
@testable import FIOSDK

class CryptographyTests: XCTestCase {
    
    func testEncryptDecryptWithFixedIVShouldSucceed(){
        let message = "secret message"
        let secret = "02332627b9325cb70510a70f0f6be4bcb008fbbc7893ca51dedf5bf46aa740c0fc9d3fbd737d09a3c4046d221f4f1a323f515332c3fef46e7f075db561b1a2c9"
        let IV = "f300888ca4f512cebdc0020ff0f7224c".toHexData()
        guard let encrypted = Cryptography().encrypt(secret: secret, message: message, iv: IV) else {
            XCTFail("Encryption failed")
            return
        }
        var possibleDecrypted: Data?
        do {
            possibleDecrypted = try Cryptography().decrypt(secret: secret, message: encrypted)
        }
        catch {
            XCTFail("Encryption failed")
        }
        guard let decrypted = possibleDecrypted  else {
            XCTFail("Encryption failed")
            return
        }
        XCTAssert(message == String(data: decrypted, encoding: .utf8), "Should be the same")
    }
    
    func testEncryptDecryptWithRandomIVShouldSucceed(){
        let message = "secret message"
        let secret = "02332627b9325cb70510a70f0f6be4bcb008fbbc7893ca51dedf5bf46aa740c0fc9d3fbd737d09a3c4046d221f4f1a323f515332c3fef46e7f075db561b1a2c9"
        guard let encrypted = Cryptography().encrypt(secret: secret, message: message, iv: nil) else {
            XCTFail("Encryption failed")
            return
        }
        var possibleDecrypted: Data?
        do {
             possibleDecrypted = try Cryptography().decrypt(secret: secret, message: encrypted)
        }
        catch {
            XCTFail("Encryption failed")
        }
        guard let decrypted = possibleDecrypted  else {
            XCTFail("Encryption failed")
            return
        }
        XCTAssert(message == String(data: decrypted, encoding: .utf8), "Should be the same")
    }
    
}
