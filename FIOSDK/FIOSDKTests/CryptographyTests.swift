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
    // encryption piece
    // step 1 - serialize the content
    // after encryption - it returns a hex string
    
    /*
     
     fun decryptSharedMessage(encryptedMessageAsHexString: String, sharedKey: ByteArray): String
     {
         val hashedSecretKey = HashUtils.sha512(sharedKey)

         val decryptionKey = hashedSecretKey.copyOf(32)
         val hmacKey = hashedSecretKey.copyOfRange(32,hashedSecretKey.size)

         val messageBytes = encryptedMessageAsHexString.hexStringToByteArray()
         val hmacContent = messageBytes.copyOfRange(0,messageBytes.size-32)
         val messageHmacData = messageBytes.copyOfRange(hmacContent.size,messageBytes.size)

         val iv = hmacContent.copyOf(16)
         val encryptedMessage = hmacContent.copyOfRange(iv.size,hmacContent.size)

         val hmacData = Cryptography.createHmac(hmacContent,hmacKey)
         if(hmacData.equals(messageHmacData))
             throw FIOError("Hmac does not match.")
         else
         {
             val decrypter = Cryptography(decryptionKey, iv)
             val decryptedMessage = decrypter.decrypt(encryptedMessage)

             return decryptedMessage.toHexString()
         }
     }
     
     
     */
    
    func testEncryptDecryptForServer(){
        let message = "3546494F356B4A4B4E487763746366554D35585A796957537153544D3548547A7A6E4A503946335A646268615141484556713537356F03392E300346494F000000"
        let secret = "02332627b9325cb70510a70f0f6be4bcb008fbbc7893ca51dedf5bf46aa740c0fc9d3fbd737d09a3c4046d221f4f1a323f515332c3fef46e7f075db561b1a2c9"
        let IV = "f300888ca4f512cebdc0020ff0f7224c".toHexData()
        guard let encrypted = Cryptography().encrypt(secret: secret, message: message, iv: IV) else {
           XCTFail("Encryption failed")
           return
        }
           
        
        
        print (encrypted.hexEncodedString())
        let myEncrypted = encrypted.hexEncodedString()
        
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
    
    
    func testEncryptDecryptWithFixedIVShouldSucceed(){
        let message = "secret message"
        let secret = "02332627b9325cb70510a70f0f6be4bcb008fbbc7893ca51dedf5bf46aa740c0fc9d3fbd737d09a3c4046d221f4f1a323f515332c3fef46e7f075db561b1a2c9"
        let IV = "f300888ca4f512cebdc0020ff0f7224c".toHexData()
        guard let encrypted = Cryptography().encrypt(secret: secret, message: message, iv: IV) else {
            XCTFail("Encryption failed")
            return
        }
        
       // print (encrypted.)
        
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
    
    func testValidateEncryptionShouldSucceed(){
        let message = "secret message"
        let secret = "02332627b9325cb70510a70f0f6be4bcb008fbbc7893ca51dedf5bf46aa740c0fc9d3fbd737d09a3c4046d221f4f1a323f515332c3fef46e7f075db561b1a2c9"
        let IV = "f300888ca4f512cebdc0020ff0f7224c".toHexData()
        
        let encryptedExpectedResult = "f300888ca4f512cebdc0020ff0f7224c7f896315e90e172bed65d005138f224da7301d5563614e3955750e4480aabf7753f44b4975308aeb8e23c31e114962ab"
        
        guard let encrypted = Cryptography().encrypt(secret: secret, message: message, iv: IV) else {
            XCTFail("Encryption failed")
            return
        }
        
        print (encrypted.hexEncodedString())
        
        XCTAssert(encrypted.hexEncodedString() == encryptedExpectedResult, "Should be the same")
    }
    
    func testMainEncryptDecrypt(){
        
        let fioPrivateKey = "5JLxoeRoMDGBbkLdXJjxuh3zHsSS7Lg6Ak9Ft8v8sSdYPkFuABF"
        let fioPublicKey  = "FIO5oBUYbtGTxMS66pPkjC2p8pbA3zCtc8XD4dq9fMut867GRdh82"

        let fioPrivateKeyAlternative = "5JCpqkvsrCzrAC3YWhx7pnLodr3Wr9dNMULYU8yoUrPRzu269Xz"
        let fioPublicKeyAlternative  = "FIO7uRvrLVrZCbCM2DtCgUMospqUMnP3JUC1sKHA8zNoF835kJBvN"
        
        let fiosdk = FIOSDK.sharedInstance(accountName: "a", privateKey: fioPrivateKey, publicKey: fioPrivateKey, systemPrivateKey: fioPrivateKey, systemPublicKey: fioPublicKey, url: "a", mockUrl: "b")
        
        let contentJson = "{\"amount\":\"9.0\",\"token_code\":\"FIO\",\"memo\":\"\",\"hash\":\"\",\"offline_url\":\"\",\"payee_public_address\":\"FIO5kJKNHwctcfUM5XZyiWSqSTM5HTzznJP9F3ZdbhaQAHEVq575o\"}"
        let encrypted = fiosdk.encrypt(publicKey: fioPublicKeyAlternative, contentType: FIOAbiContentType.newFundsContent, contentJson: contentJson)
        print (encrypted)
        
        guard let privateKey = try! PrivateKey(keyString: fioPrivateKey) else {
            XCTFail("Encryption failed")
            return
        }
        let sharedSecret = privateKey.getSharedSecret(publicKey: fioPublicKeyAlternative) ?? ""
        var possibleDecrypted: Data?
        do {
            possibleDecrypted = try Cryptography().decrypt(secret: sharedSecret, message: encrypted.uppercased().toHexData())
        }
        catch {
            XCTFail("Decryption failed")
        }

        // the hex value needs to be put back into a non-hex state.
        
        let decrypted = fiosdk.decrypt(publicKey: fioPublicKeyAlternative, contentType: FIOAbiContentType.newFundsContent, encryptedContent: encrypted)
        print (decrypted)
        
    }
    
}
