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
    
    func testAbiNewFundsContentEncryption (){
        let alicefioPrivateKey = "5JLxoeRoMDGBbkLdXJjxuh3zHsSS7Lg6Ak9Ft8v8sSdYPkFuABF"
        let bobfioPublicKeyAlternative  = "FIO7uRvrLVrZCbCM2DtCgUMospqUMnP3JUC1sKHA8zNoF835kJBvN"
        let bobfioPrivateKeyAlternative = "5JCpqkvsrCzrAC3YWhx7pnLodr3Wr9dNMULYU8yoUrPRzu269Xz"
        let alicefioPublicKey  = "FIO5oBUYbtGTxMS66pPkjC2p8pbA3zCtc8XD4dq9fMut867GRdh82"
        
        let encryptedAnswer = "11VJ1mUV8CM/WIJ9D7HO2KM2T4QzwFBSXq68kvtDFm6XQ2wXFegxMffmzx2mtTr8oBOg9YmdaEZz57pYICoHRBOCkxkjHoxhGAfNy+hF71sBxRZ2tO4vi/LpsRAZ0ybtEbhPBWmfpaIeRM3PXGEFan42CSS4ZmTxensy1JWSg8s="
        
        let payeePublicAddress = "0xc39b2845E3CFAdE5f5b2864fe73f5960B8dB483B"
        let amount = 3.58
        let tokenCode = "ETH"
        let metadata = RequestFundsRequest.MetaData(memo: "testing this for eth", hash: "", offlineUrl: "")
        

        let contentJson = RequestFundsContent(payeePublicAddress: payeePublicAddress, amount: String(amount), chainCode: tokenCode, tokenCode: tokenCode, memo:metadata.memo ?? "", hash: metadata.hash ?? "", offlineUrl: metadata.offlineUrl ?? "")
        
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
            
        return encrypted.base64EncodedString()
    }
    
    func testAbiNewFundsContentDecryption (){
        let bobfioPrivateKeyAlternative = "5JCpqkvsrCzrAC3YWhx7pnLodr3Wr9dNMULYU8yoUrPRzu269Xz"
        let alicefioPublicKey  = "FIO5oBUYbtGTxMS66pPkjC2p8pbA3zCtc8XD4dq9fMut867GRdh82"
        
        let rawJsonItemDecrypted = "0xc39b2845E3CFAdE5f5b2864fe73f5960B8dB483B"
        let encryptedAnswer = "uaB7gApTgf/Uwj3pbDi1vy7yb1xh1qjI2s+fahdy3kCrX2kZOWXpa8lUAdIYBTzUuk2IuSAP72BR49wJy+i1YiMNeMdQ+at0kQ1nDrDE+89Ra24bkIMzj8fCh23Yj8hxhn+Et6hgqpE2DhiWeGxVYAwTYlUiKzq3j18CspKKJPVJiqOh6UvwHX+sRcL+ZY8P"

        let decryptedContent = self.decrypt(privateKey: bobfioPrivateKeyAlternative, publicKey: alicefioPublicKey, contentType: FIOAbiContentType.newFundsContent, encrypted: encryptedAnswer)
        
        print ("--decrypted--")
        print (decryptedContent)
        
        
        XCTAssert(decryptedContent.contains(rawJsonItemDecrypted), "Decypption failed, unable to find value that should be decrypted")
    }
    
    ///TODO: this is broken
    func testAbiNewFundsKotlinBase64Decryption() {
        
        let encryptedAnswer = "eiZj0JKbi0z5yf6jH/k46o04zc/srywnTMgxNxeQADvq8v9xWJVbFyWTrCSi9XpoK08gNBO/wencFW1hm3bnzr+SmNoDYpzZjdmtjggAl2f8Bw+BRv/+X6e1ei6upa9zVLzym7+p/kgaAyEQv5ghtg=="
        let bobfioPrivateKeyAlternative = "5JCpqkvsrCzrAC3YWhx7pnLodr3Wr9dNMULYU8yoUrPRzu269Xz"
        let alicefioPublicKey  = "FIO5oBUYbtGTxMS66pPkjC2p8pbA3zCtc8XD4dq9fMut867GRdh82"

        let rawJsonItemDecrypted = "1PzCN3cBkTL72GPeJmpcueU4wQi9guiLa6"

        let decryptedContent = self.decrypt(privateKey: bobfioPrivateKeyAlternative, publicKey: alicefioPublicKey, contentType: FIOAbiContentType.newFundsContent, encrypted: encryptedAnswer)

        print ("--decrypted--")
        print (decryptedContent)

        XCTAssert(decryptedContent.contains(rawJsonItemDecrypted), "Decypption failed, unable to find value that should be decrypted")
        
    }
    
    internal func decrypt(privateKey: String, publicKey: String, contentType: FIOAbiContentType, encrypted: String) -> String{
        guard let myKey = try! PrivateKey(keyString: privateKey) else {
            return ""
        }
        let sharedSecret = myKey.getSharedSecret(publicKey: publicKey)
        
        var possibleDecrypted: Data?
        do {
           //possibleDecrypted = try Cryptography().decrypt(secret: sharedSecret!, message: encrypted.toHexData())
            
            possibleDecrypted = try Cryptography().decrypt(secret: sharedSecret!, message: Data(base64Encoded: encrypted) ?? "".data(using: .utf8)!)
            
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
        var possibleDecrypted: Data?
        do {
            possibleDecrypted = try Cryptography().decrypt(secret: sharedSecret!, message: encrypted.toHexData())
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
        let alicePrivateKey = "5JLxoeRoMDGBbkLdXJjxuh3zHsSS7Lg6Ak9Ft8v8sSdYPkFuABF"
        let bobPublicKey  = "FIO7uRvrLVrZCbCM2DtCgUMospqUMnP3JUC1sKHA8zNoF835kJBvN"
        
        let encryptedAnswer = "5E4EB97B11B96E1728FAAE903B17DABBB36270529F8C7A7DAD4F9E017A49786FAB657F1FA117B83840DF6C5B6518D7097DCFAA22B34013315174AD36FCEEC68E760A2F3E1794FEFC5054667D2D1930AD"
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
        let alicePublicKey = "FIO5oBUYbtGTxMS66pPkjC2p8pbA3zCtc8XD4dq9fMut867GRdh82"
        let bobPrivateKey = "5JCpqkvsrCzrAC3YWhx7pnLodr3Wr9dNMULYU8yoUrPRzu269Xz"
        
        let encrypted = "5E4EB97B11B96E1728FAAE903B17DABBB36270529F8C7A7DAD4F9E017A49786FAB657F1FA117B83840DF6C5B6518D7097DCFAA22B34013315174AD36FCEEC68E760A2F3E1794FEFC5054667D2D1930AD"
        
        let decryptedAnswer = "5468697320697320612074657374206D657373616765"
        
        guard let myKey = try! PrivateKey(keyString: bobPrivateKey) else {
            return
        }
        let sharedSecret = myKey.getSharedSecret(publicKey: alicePublicKey)
        var possibleDecrypted: Data?
        do {
            possibleDecrypted = try Cryptography().decrypt(secret: sharedSecret!, message: encrypted.toHexData())        }
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
    
    // this is broken
    func testMainEncryptDecrypt(){
        
        let fioPrivateKey = "5JLxoeRoMDGBbkLdXJjxuh3zHsSS7Lg6Ak9Ft8v8sSdYPkFuABF"
        let fioPublicKey  = "FIO5oBUYbtGTxMS66pPkjC2p8pbA3zCtc8XD4dq9fMut867GRdh82"

        let fioPrivateKeyAlternative = "5JCpqkvsrCzrAC3YWhx7pnLodr3Wr9dNMULYU8yoUrPRzu269Xz"
        let fioPublicKeyAlternative  = "FIO7uRvrLVrZCbCM2DtCgUMospqUMnP3JUC1sKHA8zNoF835kJBvN"
        
        let fiosdk = FIOSDK.sharedInstance(privateKey: fioPrivateKey, publicKey: fioPrivateKey, url: "a", mockUrl: "b")
        
        let contentJson = "{\"amount\":\"9.0\",\"chain_code\":\"FIO\",\"token_code\":\"FIO\",\"memo\":\"\",\"hash\":\"\",\"offline_url\":\"\",\"payee_public_address\":\"FIO5kJKNHwctcfUM5XZyiWSqSTM5HTzznJP9F3ZdbhaQAHEVq575o\"}"
        let encrypted = fiosdk.encrypt(publicKey: fioPublicKeyAlternative, contentType: FIOAbiContentType.newFundsContent, contentJson: contentJson)
        print (encrypted)
        
        guard let privateKey = try! PrivateKey(keyString: fioPrivateKey) else {
            XCTFail("Encryption failed")
            return
        }
        let sharedSecret = privateKey.getSharedSecret(publicKey: fioPublicKeyAlternative) ?? ""
        var possibleDecrypted: Data?
        do {
            possibleDecrypted = try Cryptography().decrypt(secret: sharedSecret, message: Data(base64Encoded: encrypted) ?? "".data(using: .utf8)!)
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
    
    /* results from typescrypt sdk encryption */
    func testDecryptFixedValueFromTypeScriptSDK() {
        let alicePrivateKey = "5J35xdLtcPvDASxpyWhNrR2MfjSZ1xjViH5cvv15VVjqyNhiPfa"
        let alicePublicKey = "FIO6NxZ7FLjjJuHGByJtNJQ1uN1P5X9JJnUmFW3q6Q7LE7YJD4GZs"
        let bobPrivateKey = "5J37cXw5xRJgE869B5LxC3FQ8ZJECiYnsjuontcHz5cJsz5jhb7"
        let bobPublicKey = "FIO4zUFC29aq8uA4CnfNSyRZCnBPya2uQk42jwevc3UZ2jCRtepVZ"
           
        let encrypted = "UKPHFo0xs3GwGAXMc44QqkDtj7dcbGHjU3cJmN1qiYWADvzyd9pen2WwKn0VZtk0ZTGFXpap7Id8nZxlCMK7TjkabO85XNbhausE4ZZzx3hm25bqV2GDRHpRomsRDGAzLbFEumsm+4UNBtnOqUK3Kuo91vKjlLIV3NoF83qOSbhL8QDqV2N/yJxSu4PsiDeqhhSypZx8McaubVoUueioWA=="

        let decryptedContent = self.decrypt(privateKey: alicePrivateKey, publicKey: bobPublicKey, contentType: FIOAbiContentType.newFundsContent, encrypted: encrypted)
               
        print ("--decrypted--")
        print (decryptedContent)
        
        XCTAssert(decryptedContent.contains(bobPublicKey), "Was not decrypted")

    }
    
    /* results from kotlin sdk encryption */
    func testDecryptFixedValueFromKotlinSDK() {
        let alicePrivateKey = "5J35xdLtcPvDASxpyWhNrR2MfjSZ1xjViH5cvv15VVjqyNhiPfa"
        let alicePublicKey = "FIO6NxZ7FLjjJuHGByJtNJQ1uN1P5X9JJnUmFW3q6Q7LE7YJD4GZs"
        let bobPrivateKey = "5J37cXw5xRJgE869B5LxC3FQ8ZJECiYnsjuontcHz5cJsz5jhb7"
        let bobPublicKey = "FIO4zUFC29aq8uA4CnfNSyRZCnBPya2uQk42jwevc3UZ2jCRtepVZ"
           
        let encrypted = "j5+2Map9cfl7KUNjTwiWw191CzDIRJtGkQD3AJIvbvybRp1D7ewnBXs4yyho6opY2xVi7GkzzGGDXmk7d7Bkk50CYtSfQTsxc0ZqcJZ0Cse0OZSjWhmFwmR0U5VrwY3Q6ZcOiLGJIkpUxWD2c+LOCoGjSSjfxRYlFHM42H5UdS+XwjP4Lq4FvXz91kio/p9hLRY/JuzxHL/JNHdT8woq3w=="

        let decryptedContent = self.decrypt(privateKey: bobPrivateKey, publicKey: alicePublicKey, contentType: FIOAbiContentType.newFundsContent, encrypted: encrypted)
               
        print ("--decrypted--")
        print (decryptedContent)
        
        XCTAssert(decryptedContent.contains(bobPublicKey), "Was not decrypted")
    }
    
    func testSharedSDKsNewFundsContentEncryption (){
        let alicePrivateKey = "5J35xdLtcPvDASxpyWhNrR2MfjSZ1xjViH5cvv15VVjqyNhiPfa"
        let alicePublicKey = "FIO6NxZ7FLjjJuHGByJtNJQ1uN1P5X9JJnUmFW3q6Q7LE7YJD4GZs"
        let bobPrivateKey = "5J37cXw5xRJgE869B5LxC3FQ8ZJECiYnsjuontcHz5cJsz5jhb7"
        let bobPublicKey = "FIO4zUFC29aq8uA4CnfNSyRZCnBPya2uQk42jwevc3UZ2jCRtepVZ"

        let payeePublicAddress = bobPublicKey
        let amount = 1.57
        let tokenCode = "FIO"
        let metadata = RequestFundsRequest.MetaData(memo: "testing this for fio", hash: "", offlineUrl: "")

        let contentJson = RequestFundsContent(payeePublicAddress: payeePublicAddress, amount: String(amount), chainCode: tokenCode, tokenCode: tokenCode, memo:metadata.memo ?? "", hash: metadata.hash ?? "", offlineUrl: metadata.offlineUrl ?? "")

        print (contentJson.toJSONString())
        let encryptedContent = self.encrypt(privateKey: bobPrivateKey, publicKey: alicePublicKey, contentType: FIOAbiContentType.newFundsContent, contentJson: contentJson.toJSONString())

        print ("--encrypted--")
        print (encryptedContent)

    }
    
}
