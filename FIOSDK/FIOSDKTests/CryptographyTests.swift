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
    // shawn arney - this has correct encryption.
    func testEncryptFixedValueForAndroidShawnM() {
        
           let privateKey = "5JbcPK6qTpYxMXtfpGXagYbo3KFE3qqxv2tLXLMPR8dTWWeYCp9"
           let publicKey = "FIO8LKt4DBzXKzDGjFcZo5x82Nv5ahmbZ8AUNXBv2vMfm6smiHst3"
           
           guard let myKey = try! PrivateKey(keyString: privateKey) else {
               return
           }
           let sharedSecret = myKey.getSharedSecret(publicKey: publicKey)
          //  let sharedSecret = "88F10119B11958F6CA389372AA168330DDDABCE58F4BEE68B9B52381FC662E288E965E451F4F43C2463660C0E7C06529149D6018AB583E9EBF6D97DA9F2DA904"
           
           
           let message = "3546494F356B4A4B4E487763746366554D35585A796957537153544D3548547A7A6E4A503946335A646268615141484556713537356F03392E300346494F000000"
        let IV = "a55627b9e12ac16fb82fff1d514eb40b".toHexData()
        guard let encrypted = Cryptography().encrypt(secret: sharedSecret!, message: message, iv: IV) else {
              XCTFail("Encryption failed")
              return
           }
              
           let asciEncrypted = String(data: encrypted, encoding: .ascii)
           print (String(data: encrypted, encoding: .ascii))
          // print (encrypted.hexEncodedString())
        let myEncrypted = encrypted.hexEncodedString().uppercased()
            print ("***")
            print (myEncrypted)
            print ("***")
    }
    
    
    func testDecryptFixedValueForAndroidShawnM() {
        
        let privateKey = "5JbcPK6qTpYxMXtfpGXagYbo3KFE3qqxv2tLXLMPR8dTWWeYCp9"
        let publicKey = "FIO8LKt4DBzXKzDGjFcZo5x82Nv5ahmbZ8AUNXBv2vMfm6smiHst3"
        let encrypted = "[B@79bdac7"
        
        
        guard let myKey = try! PrivateKey(keyString: privateKey) else {
            return
        }
        let sharedSecret = myKey.getSharedSecret(publicKey: publicKey)
        
        
        // encrypted.data(using: .utf8) ?? "".data(using: .utf8)!
        var possibleDecrypted: Data?
        do {
           // possibleDecrypted = try Cryptography().decrypt(secret: sharedSecret!, message: encrypted.toHexData())
            possibleDecrypted = try Cryptography().decrypt(secret: sharedSecret!, message: encrypted.data(using: .utf8) ?? "".data(using: .utf8)!)
        }
        catch {
           XCTFail("Encryption failed")
        }
        guard let decrypted = possibleDecrypted  else {
           XCTFail("Encryption failed")
           return
        }
        print(String(data: decrypted, encoding: .utf8))
        XCTAssert("message" == String(data: decrypted, encoding: .utf8), "Should be the same")
    }
    
    
    
    
    // GOOD encrypted: 09758E9C48AAAEE4B7F389C993CC354A48AE6A5B7A6B585C048D4E5C644B360BA9CDD15CAD8C066CE0B8380DB4B74A0EBF27C2084AD2FEB1EC2573BACDBCB2AF5B388D7CB240E168CE9B20AA066F5CA0174F66304C3DF359EF1F6BEB70E531C7
    func testEncryptDecryptForServerAndroid() {
        
        let privateKey = "5JbcPK6qTpYxMXtfpGXagYbo3KFE3qqxv2tLXLMPR8dTWWeYCp9"
        let publicKey = "FIO8LKt4DBzXKzDGjFcZo5x82Nv5ahmbZ8AUNXBv2vMfm6smiHst3"
        
        guard let myKey = try! PrivateKey(keyString: privateKey) else {
            return
        }
        let sharedSecret = myKey.getSharedSecret(publicKey: publicKey)
        
        
        let message = "3546494F356B4A4B4E487763746366554D35585A796957537153544D3548547A7A6E4A503946335A646268615141484556713537356F03392E300346494F000000"
     //   let secret = "02332627b9325cb70510a70f0f6be4bcb008fbbc7893ca51dedf5bf46aa740c0fc9d3fbd737d09a3c4046d221f4f1a323f515332c3fef46e7f075db561b1a2c9"
        let IV = "f300888ca4f512cebdc0020ff0f7224c".toHexData()
        guard let encrypted = Cryptography().encrypt(secret: sharedSecret!, message: message, iv: IV) else {
           XCTFail("Encryption failed")
           return
        }
           
        let asciEncrypted = String(data: encrypted, encoding: .ascii)
        print (String(data: encrypted, encoding: .ascii))
       // print (encrypted.hexEncodedString())
        let myEncrypted = encrypted.hexEncodedString()
        
        let dEncrypted = asciEncrypted?.data(using:.ascii, allowLossyConversion: true)
        
        var possibleDecrypted: Data?
        do {
            possibleDecrypted = try Cryptography().decrypt(secret: sharedSecret!, message: dEncrypted!)
        }
        catch {
           XCTFail("Encryption failed")
        }
        guard let decrypted = possibleDecrypted  else {
           XCTFail("Encryption failed")
           return
        }
        print( String(data: decrypted, encoding: .utf8))
        XCTAssert(message == String(data: decrypted, encoding: .utf8), "Should be the same")
    }
    
    
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
        let message = "secret messagesecret messagesecret messagesecret messagesecret messagesecret messagesecret message"
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
