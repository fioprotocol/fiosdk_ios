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
    
    
    func testAbiNewFundsContentEncryption (){
        let alicefioPrivateKey = "5JLxoeRoMDGBbkLdXJjxuh3zHsSS7Lg6Ak9Ft8v8sSdYPkFuABF"
        let bobfioPublicKeyAlternative  = "FIO7uRvrLVrZCbCM2DtCgUMospqUMnP3JUC1sKHA8zNoF835kJBvN"
    let bobfioPrivateKeyAlternative = "5JCpqkvsrCzrAC3YWhx7pnLodr3Wr9dNMULYU8yoUrPRzu269Xz"
    let alicefioPublicKey  = "FIO5oBUYbtGTxMS66pPkjC2p8pbA3zCtc8XD4dq9fMut867GRdh82"
        
        let payeePublicAddress = "0xc39b2845E3CFAdE5f5b2864fe73f5960B8dB483B"
        let amount = 3.58
        let tokenCode = "ETH"
        let metadata = RequestFundsRequest.MetaData(memo: "testing this for eth", hash: "", offlineUrl: "")
        

        let contentJson = RequestFundsContent(payeePublicAddress: payeePublicAddress, amount: String(amount), tokenCode: tokenCode, memo:metadata.memo ?? "", hash: metadata.hash ?? "", offlineUrl: metadata.offlineUrl ?? "")
        
        print (contentJson.toJSONString())
        let encryptedContent = self.encrypt(privateKey: alicefioPrivateKey, publicKey: bobfioPublicKeyAlternative, contentType: FIOAbiContentType.newFundsContent, contentJson: contentJson.toJSONString())
        
        print ("--encrypted--")
        print (encryptedContent)
    }
    
    func encrypt (privateKey: String, publicKey: String, contentType: FIOAbiContentType, contentJson: String) -> String {
        
        guard let myKey = try! PrivateKey(keyString: privateKey) else {
            return ""
        }
        let sharedSecret = myKey.getSharedSecret(publicKey: publicKey)
                
        //  2. With the content field, map each field to it's json value.
        //    --> this is the json coming into this.

        // 3. With the content json, pass it to the ABI packer.
        let serializer = abiSerializer()
        let packed = try? serializer.serializeContent(contentType: contentType, json: contentJson)
        print ("--packed--")
        print(packed?.uppercased())
        // 4. Encrypt the resultant ABI packer data.  Using the sharedSecret
        guard let encrypted = Cryptography().encrypt(secret: sharedSecret ?? "", message: packed ?? "", iv: nil) else {
            return ""
        }
                
        return encrypted.hexEncodedString().uppercased()
    }
    
    func testAbiNewFundsContentDecryption (){
        let privateKey = "5JbcPK6qTpYxMXtfpGXagYbo3KFE3qqxv2tLXLMPR8dTWWeYCp9"
        let publicKey = "FIO8LKt4DBzXKzDGjFcZo5x82Nv5ahmbZ8AUNXBv2vMfm6smiHst3"
        let packedAnswer = "2A30786333396232383435453343464164453566356232383634666537336635393630423864423438334204332E3538034554480C74657374696E6720746869730000"
        let encryptedAnswer = "189EB032C20E35E001AF9A030B7D40B3E882441D2476ED3101A2E614F18A6974D06C4CC0913EFE52143D3207123794A0A1DF88501774BD2CAD4968EB8DC757080B0922B7F1CC29875662753B1D3874B4565C646CE7CF722B5E3F26B3481A5F7BC8C7430F8177BC42C08DF0E9D3F677F1AE56FBA03D3220E7E5B4980D8B65A6EC"

        let decryptedContent = self.decrypt(privateKey: privateKey, publicKey: publicKey, contentType: FIOAbiContentType.newFundsContent, encrypted: encryptedAnswer)
        
        print ("--decrypted--")
        print (decryptedContent)
    }
    
    internal func decrypt(privateKey: String, publicKey: String, contentType: FIOAbiContentType, encrypted: String) -> String{
        guard let myKey = try! PrivateKey(keyString: privateKey) else {
            return ""
        }
        let sharedSecret = myKey.getSharedSecret(publicKey: publicKey)
        
        var possibleDecrypted: Data?
        do {
           possibleDecrypted = try Cryptography().decrypt(secret: sharedSecret!, message: encrypted.toHexData())
           //possibleDecrypted = try Cryptography().decrypt(secret: sharedSecret!, message:
          // possibleDecrypted = try Cryptography().decrypt(secret: sharedSecret!, message: encrypted.data(using: .utf8) ?? "".data(using: .utf8)!)
        }
        catch {
          XCTFail("decryption failed")
        }
        guard let decrypted = possibleDecrypted  else {
          XCTFail("decryption failed")
          return ""
        }
        print ("--decrypted--")
        print(String(data: decrypted, encoding: .utf8))
        print ("--hex value--")
        print ( decrypted.hexEncodedString().uppercased())
        
        //  2. With the content field, map each field to it's json value.
        //    --> this is the json coming into this.
        
        // 3. With the content json, pass it to the ABI packer.
        let serializer = abiSerializer()
        let contentJSON = try? serializer.deserializeContent(contentType: contentType, hexString: decrypted.hexEncodedString().uppercased() ?? "")
        
        print (contentJSON)
        return contentJSON ?? ""
        
               /*
        
                the content needs to be encrypted.
                
                These are the steps:
                1. With the private key and the payee public key (fio public address), create the sharedSecret
                
                
                2. With the content field, map each field to it's json value.
                3. With the content json, pass it to the ABI packer.
                4. Encrypt the resultant ABI packer data.  Using the sharedSecret
                
         ok, somehow do the json mapping now.
                payee_public_address,
                amount,
                token_code,
                memo,
                hash,
                offline_url
        
        */
    }
    
    // shawn arney - this has correct encryption.
    //answer A55627B9E12AC16FB82FFF1D514EB40B62F418BCB863357086B0C79D623FA62B99BCF97D83611FDF814842D46FBD118A4C0571521F4A1BE5E442A1E7457D2C7A00DE2AA4553743AEA58C0E5759F5CF5583172815F914824BE10F8CD408D4B0B073D003F647616F6A6E0F040DD219A266E60D39742681974FDCE9EC2A57779442
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
    
    /* the results of a decryption, should be the hexencoded string, uppercased.  For use by the ABI process */
    func testDecryptFixedValueForAndroidShawnM() {
        
        let privateKey = "5JbcPK6qTpYxMXtfpGXagYbo3KFE3qqxv2tLXLMPR8dTWWeYCp9"
        let publicKey = "FIO8LKt4DBzXKzDGjFcZo5x82Nv5ahmbZ8AUNXBv2vMfm6smiHst3"
        let encrypted = "A55627B9E12AC16FB82FFF1D514EB40B62F418BCB863357086B0C79D623FA62B99BCF97D83611FDF814842D46FBD118A4C0571521F4A1BE5E442A1E7457D2C7A00DE2AA4553743AEA58C0E5759F5CF5583172815F914824BE10F8CD408D4B0B073D003F647616F6A6E0F040DD219A266E60D39742681974FDCE9EC2A57779442"
        
        let decryptedAnswer = "3546494F356B4A4B4E487763746366554D35585A796957537153544D3548547A7A6E4A503946335A646268615141484556713537356F03392E300346494F000000"
        
        guard let myKey = try! PrivateKey(keyString: privateKey) else {
            return
        }
        let sharedSecret = myKey.getSharedSecret(publicKey: publicKey)
        
        
        // encrypted.data(using: .utf8) ?? "".data(using: .utf8)!
        var possibleDecrypted: Data?
        do {
            possibleDecrypted = try Cryptography().decrypt(secret: sharedSecret!, message: encrypted.toHexData())
            //possibleDecrypted = try Cryptography().decrypt(secret: sharedSecret!, message:
           // possibleDecrypted = try Cryptography().decrypt(secret: sharedSecret!, message: encrypted.data(using: .utf8) ?? "".data(using: .utf8)!)
        }
        catch {
           XCTFail("Encryption failed")
        }
        guard let decrypted = possibleDecrypted  else {
           XCTFail("Encryption failed")
           return
        }
        print ("--decrypted--")
        print(String(data: decrypted, encoding: .utf8))
        print ("--hex value--")
        print ( decrypted.hexEncodedString().uppercased())
        XCTAssert(decryptedAnswer == decrypted.hexEncodedString().uppercased(), "Should be the same")
    }
    
     func testEncryptFixedValueForAndroidShawnMsecondone() {
        
        // encrypt with private + publicAlternate
        let alicePrivateKey = "5JbcPK6qTpYxMXtfpGXagYbo3KFE3qqxv2tLXLMPR8dTWWeYCp9"
        let bobPublicKey  = "FIO7uRvrLVrZCbCM2DtCgUMospqUMnP3JUC1sKHA8zNoF835kJBvN"
        
           let encryptedAnswer = "5E4EB97B11B96E1728FAAE903B17DABB411D25E0E263783F906D58A30F070411A7F271DD3A77619414FBE0276EA57B2C8D8993C14403C8F1395EB3ABC822B12B1E59D1339D5BB32F07C08D8EAC8EE949"
           guard let myKey = try! PrivateKey(keyString: alicePrivateKey) else {
               return
           }
           let sharedSecret = myKey.getSharedSecret(publicKey: bobPublicKey)
          //  let sharedSecret = "88F10119B11958F6CA389372AA168330DDDABCE58F4BEE68B9B52381FC662E288E965E451F4F43C2463660C0E7C06529149D6018AB583E9EBF6D97DA9F2DA904"
           
           
           let message = "5468697320697320612074657374206D657373616765"
        let IV = "5E4EB97B11B96E1728FAAE903B17DABB".toHexData()
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
        
        XCTAssert(encryptedAnswer == myEncrypted, "Should be the same")
    }
    
    func testDecryptFixedValueForAndroidShawnMsecondone() {
        
        // decrypt with privateAlternate + public
        let alicePublicKey = "FIO8LKt4DBzXKzDGjFcZo5x82Nv5ahmbZ8AUNXBv2vMfm6smiHst3"
        let bobPrivateKey = "5JCpqkvsrCzrAC3YWhx7pnLodr3Wr9dNMULYU8yoUrPRzu269Xz"
        
        let encrypted = "5E4EB97B11B96E1728FAAE903B17DABB411D25E0E263783F906D58A30F070411A7F271DD3A77619414FBE0276EA57B2C8D8993C14403C8F1395EB3ABC822B12B1E59D1339D5BB32F07C08D8EAC8EE949"
        
        let decryptedAnswer = "5468697320697320612074657374206D657373616765"
        
        guard let myKey = try! PrivateKey(keyString: bobPrivateKey) else {
            return
        }
        let sharedSecret = myKey.getSharedSecret(publicKey: alicePublicKey)
        
        
        // encrypted.data(using: .utf8) ?? "".data(using: .utf8)!
        var possibleDecrypted: Data?
        do {
            possibleDecrypted = try Cryptography().decrypt(secret: sharedSecret!, message: encrypted.toHexData())
            //possibleDecrypted = try Cryptography().decrypt(secret: sharedSecret!, message:
           // possibleDecrypted = try Cryptography().decrypt(secret: sharedSecret!, message: encrypted.data(using: .utf8) ?? "".data(using: .utf8)!)
        }
        catch {
           XCTFail("Encryption failed")
        }
        guard let decrypted = possibleDecrypted  else {
           XCTFail("Encryption failed")
           return
        }
        print ("--decrypted--")
        print(String(data: decrypted, encoding: .utf8))
        print ("--hex value--")
        print ( decrypted.hexEncodedString().uppercased())
        XCTAssert(decryptedAnswer == decrypted.hexEncodedString().uppercased(), "Should be the same")
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
    
    
    
    func testEncryptFixedValueForAndroidShawnMDiffKeys() {
           
        let alicefioPrivateKey = "5JLxoeRoMDGBbkLdXJjxuh3zHsSS7Lg6Ak9Ft8v8sSdYPkFuABF"
        let bobfioPublicKeyAlternative  = "FIO7uRvrLVrZCbCM2DtCgUMospqUMnP3JUC1sKHA8zNoF835kJBvN"

        guard let myKey = try! PrivateKey(keyString: alicefioPrivateKey) else {
          return
        }
        let sharedSecret = myKey.getSharedSecret(publicKey: bobfioPublicKeyAlternative)
        //  let sharedSecret = "88F10119B11958F6CA389372AA168330DDDABCE58F4BEE68B9B52381FC662E288E965E451F4F43C2463660C0E7C06529149D6018AB583E9EBF6D97DA9F2DA904"


        let message = "2A30786333396232383435453343464164453566356232383634666537336635393630423864423438334204332E3538034554480C74657374696E6720746869730000"
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
       
   /* the results of a decryption, should be the hexencoded string, uppercased.  For use by the ABI process */
    //
   func testDecryptFixedValueForAndroidShawnMDiffKeys() {
       
          let alicefioPublicKey  = "FIO5oBUYbtGTxMS66pPkjC2p8pbA3zCtc8XD4dq9fMut867GRdh82"
          let bobfioPrivateKeyAlternative = "5JCpqkvsrCzrAC3YWhx7pnLodr3Wr9dNMULYU8yoUrPRzu269Xz"
    
    
       let encrypted = "A55627B9E12AC16FB82FFF1D514EB40B847399E055FD2CBC57D4295B8745DD46E7A165E99D988CB65455B24ED52E4E241429DEFE9C883984E23255C2D1E3C1706A2483C1AA964B2B485C9487FC919DE9B3DEC2136E387942FFAA7F007501B0D54973B5F3C91F7A1FE6630DC61FFBA9A4148DE16176513A8E23A0243EF02AA0F0"
       
       let decryptedAnswer = "2A30786333396232383435453343464164453566356232383634666537336635393630423864423438334204332E3538034554480C74657374696E6720746869730000"
       
       guard let myKey = try! PrivateKey(keyString: bobfioPrivateKeyAlternative) else {
           return
       }
       let sharedSecret = myKey.getSharedSecret(publicKey: alicefioPublicKey)
       
       
       // encrypted.data(using: .utf8) ?? "".data(using: .utf8)!
       var possibleDecrypted: Data?
       do {
           possibleDecrypted = try Cryptography().decrypt(secret: sharedSecret!, message: encrypted.toHexData())
           //possibleDecrypted = try Cryptography().decrypt(secret: sharedSecret!, message:
          // possibleDecrypted = try Cryptography().decrypt(secret: sharedSecret!, message: encrypted.data(using: .utf8) ?? "".data(using: .utf8)!)
       }
       catch {
          XCTFail("Encryption failed")
       }
       guard let decrypted = possibleDecrypted  else {
          XCTFail("Encryption failed")
          return
       }
       print ("--decrypted--")
       print(String(data: decrypted, encoding: .utf8))
       print ("--hex value--")
       print ( decrypted.hexEncodedString().uppercased())
       XCTAssert(decryptedAnswer == decrypted.hexEncodedString().uppercased(), "Should be the same")
   }
    
    
    /* the results of an android decryption, should be the hexencoded string, uppercased.  For use by the ABI process */
     // this is the android request_funds... does it decrypt correctly?
    func testDecryptFixedValueForAndroidShawnMDiffKeys_fromAndroid() {
        let bobfioPrivateKeyAlternative = "5JCpqkvsrCzrAC3YWhx7pnLodr3Wr9dNMULYU8yoUrPRzu269Xz"
        let alicefioPublicKey  = "FIO5oBUYbtGTxMS66pPkjC2p8pbA3zCtc8XD4dq9fMut867GRdh82"
           
        let encrypted = "A754EB5349FB8DABC25DCE3E477FE244F319E0EAB8549CA9BF5B8F445B99FCBC068BBCD06CA9498A1E7DD9824E75ADB26A6C99DCB6F51B6BE1BA2CB1BD430DFB4D1CA2280C5F17485FC8F2F7C77E9E32"
        
        
        let decryptedContent = self.decrypt(privateKey: bobfioPrivateKeyAlternative, publicKey: alicefioPublicKey, contentType: FIOAbiContentType.newFundsContent, encrypted: encrypted)
               
       print ("--decrypted--")
       print (decryptedContent)
        
    }
    
}
