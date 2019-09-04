//
//  PrivateKey.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-04-12.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation
import Security

internal extension Data {
    
    func wifStringPureSwift(enclave: SecureEnclave) -> String {
        let size_of_data_to_hash = count + 1
        let size_of_hash_bytes = 4
        var data: Array<UInt8> = Array(repeating: UInt8(0), count: size_of_data_to_hash+size_of_hash_bytes)
        data[0] = UInt8(0x80)
        let bytes = [UInt8](self)
        for i in 1..<size_of_data_to_hash {
            data[i] = bytes[i-1]
        }
        var digest = Data(bytes: data, count: size_of_data_to_hash)
        digest = digest.sha256().sha256()
        for i in 0..<size_of_hash_bytes {
            data[size_of_data_to_hash+i] = ([UInt8](digest))[i]
        }
        let base58 = Data(bytes: data, count: size_of_data_to_hash+size_of_hash_bytes).base58EncodedData()
        return "PVT_\(enclave.rawValue)_\(String(data: base58, encoding: .ascii)!)"
    }
    
    func wifString(enclave: SecureEnclave) -> String {
        return "PVT_\(enclave.rawValue)_\(String(data: base58CheckEncodedData(version: 0x80), encoding: .ascii)!)"
    }
    
}

internal extension String {
    
    func parseWif() throws -> Data? {
        guard let data = decodeChecked(version: 0x80) else {
            throw NSError(domain: "com.swiftyeos.error", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid base58: \(self)"])
        }
        return data
    }
    
}

enum PrivateKeyError: Error {
    case runtimeError(String)
}

internal struct PrivateKey {
    
    static let prefix = "PVT"
    static let delimiter = "_"
    var enclave: SecureEnclave
    var data: Data
    
    init?(keyString: String) throws {
        if keyString.range(of: PrivateKey.delimiter) == nil {
            enclave = .Secp256k1
            data = try keyString.parseWif()!
        } else {
            let dataParts = keyString.components(separatedBy: PrivateKey.delimiter)
            guard dataParts[0] == PrivateKey.prefix else {
                throw NSError(domain: "com.swiftyeos.error", code: 0, userInfo: [NSLocalizedDescriptionKey: "Private Key \(keyString) has invalid prefix: \(PrivateKey.delimiter)"])
            }
            
            guard dataParts.count != 2 else {
                throw NSError(domain: "com.swiftyeos.error", code: 0, userInfo: [NSLocalizedDescriptionKey: "Private Key has data format is not right: \(keyString)"])
            }
            
            enclave = SecureEnclave(rawValue: dataParts[1])!
            let dataString = dataParts[2]
            data = try dataString.parseWif()!
        }
    }
    
    init(enclave: SecureEnclave, data: Data) {
        self.enclave = enclave
        self.data = data
    }
    
    init?(enclave: SecureEnclave, mnemonicString: String) throws {
        self.enclave = enclave
        
        let phraseStr = mnemonicString.cString(using: .utf8)
        if mnemonic_check(phraseStr) == 0 {
            throw NSError(domain: "com.swiftyeos.error", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid Mnemonic"])
        }
        
        var seed = Data(count: 512/8)
        seed.withUnsafeMutableBytes { bytes in
            mnemonic_to_seed(phraseStr, "", bytes, nil)
        }
        
        var node = seed.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) -> HDNode in
            var node = HDNode()
            hdnode_from_seed(bytes, Int32(seed.count), UnsafePointer<Int8>("secp256k1"), &node)
            return node
        }
        
        hdnode_private_ckd(&node, (0x80000000 | (44)));   // 44' - BIP 44 (purpose field)
        hdnode_private_ckd(&node, (0x80000000 | (194)));  // 194'- EOS (see SLIP 44)
        hdnode_private_ckd(&node, (0x80000000 | (0)));    // 0'  - Account 0
        hdnode_private_ckd(&node, 0);                     // 0   - External
        hdnode_private_ckd(&node, 0);                     // 0   - Slot #0
        
        let data =  withUnsafeBytes(of: &node.private_key) { (rawPtr) -> Data in
            let ptr = rawPtr.baseAddress!.assumingMemoryBound(to: UInt8.self)
            return Data(bytes: ptr, count: 32)
        }
        
        self.data = data
    }
    
    func wif() -> String {
        return self.data.wifString(enclave: enclave)
    }
    
    func rawPrivateKey() -> String {
        return self.wif().components(separatedBy: "_").last!
    }
    
    static func randomPrivateKey(enclave: SecureEnclave = .Secp256k1) -> PrivateKey? {
        var keyData = Data(count: 32)
        let result = keyData.withUnsafeMutableBytes { (mutableBytes: UnsafeMutablePointer<UInt8>) -> Int32 in
            SecRandomCopyBytes(kSecRandomDefault, 32, mutableBytes)
        }
        if result == errSecSuccess {
            return PrivateKey(enclave: enclave, data: keyData)
        } else {
            print("Problem generating random bytes")
            return nil
        }
    }
    
    static func literalValid(keyString: String) -> Bool {
        if keyString.range(of: PrivateKey.delimiter) == nil {
            return keyString.count == 51
        } else {
            let dataParts = keyString.components(separatedBy: PrivateKey.delimiter)
            guard dataParts.count != 2 else {
                return false
            }
            guard dataParts[0] == PrivateKey.prefix else {
                return false
            }
            guard dataParts[1].count == 51 else {
                return false
            }
            return true
        }
    }
    
    /*
 
     var publicBytes: Array<UInt8> = Array(repeating: UInt8(0), count: 64)
     var compressedPublicBytes: Array<UInt8> = Array(repeating: UInt8(0), count: 33)
     
     var curve: uECC_Curve
     
     switch privateKey.enclave {
     case .Secp256r1:
     curve = uECC_secp256r1()
     default:
     curve = uECC_secp256k1()
     }
     uECC_compute_public_key([UInt8](privateKey.data), &publicBytes, curve)
     uECC_compress(&publicBytes, &compressedPublicBytes, curve)
     
     data = Data(bytes: compressedPublicBytes, count: 33)
     uncompressed = Data(bytes:publicBytes, count:64)
 
 void uECC_compress(const uint8_t *public_key, uint8_t *compressed, uECC_Curve curve);
 */
    
    func getUncompressedPublicKey(pubKey: String) -> String? {
        let pub = try? PublicKey(keyString: pubKey)
        print(pub?.rawPublicKey())
        
        var publicBytes: Array<UInt8> = Array(repeating: UInt8(0), count: 64)
        
        uECC_decompress([UInt8](pub!.data), &publicBytes, uECC_secp256k1())
        
        let pubkey_data = Data(bytes: publicBytes, count: 64)
        print ("DECOMPRESS:")
        print ( pubkey_data.publicKeyEncodeString(enclave: .Secp256k1))
        let pbtest = try? PublicKey(keyString: pubkey_data.publicKeyEncodeString(enclave: .Secp256k1))
        print ("****")
        print (pbtest?.rawPublicKey())
        print ("done")
        
        return pubkey_data.publicKeyEncodeString(enclave: .Secp256k1)
    }
    
    func getUncompressedPublicKeyData(pubKey: String) -> Data {
        let pub = try? PublicKey(keyString: pubKey)
        print(pub?.rawPublicKey())
        
        var publicBytes: Array<UInt8> = Array(repeating: UInt8(0), count: 64)
        
        uECC_decompress([UInt8](pub!.data), &publicBytes, uECC_secp256k1())
        
        let pubkey_data = Data(bytes: publicBytes, count: 64)
        
        return pubkey_data
    }
    
    func getSharedSecretFinal(pubKey: String) -> String? {
        // USE SwiftyEOS uECC_shared_secret (seems to give different results)
        print("**START")
        
        var secret_two = UnsafeMutablePointer<UInt8>.allocate(capacity: 32)
        var result: Int32 = 0
        result = uECC_shared_secret([UInt8](self.getUncompressedPublicKeyData(pubKey: pubKey)), [UInt8](self.data), secret_two, uECC_secp256k1())
        
        if result == 1 {
            let decodedString = Data(bytes: secret_two, count: 32)
            print ("***DOES IT MATCH****")
            print (FIOHash.sha512(decodedString).uppercased())
            return FIOHash.sha512(decodedString)
        }
        else {
            print("Problem generating shared secret")
            return nil
        }
        
        return ""
    }

    /// this uncompresses the key
    func getSharedSecret3(pubKey: String) -> String? {
        
        let pub = try? PublicKey(keyString: "6LPpixYR2td9WHFJXHALoZh5MhrU5ky8zeFynvzNacPBuP6jU6")
        print(pub?.rawPublicKey())
        
        var publicBytes: Array<UInt8> = Array(repeating: UInt8(0), count: 64)
        
        uECC_decompress([UInt8](pub!.data), &publicBytes, uECC_secp256k1())
        

            let pubkey_data = Data(bytes: publicBytes, count: 64)
        print ("DECOMPRESS:")
        print ( pubkey_data.publicKeyEncodeString(enclave: .Secp256k1))
            let pbtest = try? PublicKey(keyString: pubkey_data.publicKeyEncodeString(enclave: .Secp256k1).replacingOccurrences(of: "EOS", with: ""))
            print ("****")
            print (pbtest?.rawPublicKey())
            print ("done")
        
        return ""
    }
    
    func getSharedSecret2(pubKey: String) -> String? {
        // USE SwiftyEOS uECC_shared_secret (seems to give different results)
        
        var v_pKey = UnsafeMutablePointer<UInt8>.allocate(capacity: 32)
        var v_pubKey = UnsafeMutablePointer<UInt8>.allocate(capacity: 64)
        
        var v_result: Int32 = 0
        v_result = uECC_make_key(v_pKey, v_pubKey, uECC_secp256k1())
        
        if (v_result == 1) {
            let pkey_data = Data(bytes: v_pKey, count: 32)
            print(String(data: pkey_data, encoding: String.Encoding.utf8))
            
            let pubkey_data = Data(bytes: v_pubKey, count: 64)
            let p = PrivateKey(enclave: .Secp256k1, data: pkey_data)
            print(p.rawPrivateKey())
            
            print (Data(bytes: v_pubKey, count: 64))
            
            let pub = try? PublicKey(keyString: "PUB_K1_TMX7mfnzkrPmeX5nNVGW4ghQXxxrXsCuXVvSKERLbuGYfkexxvQ5MTeSF6C6YdKViQm1jzu4KHXP9TaUiteyqk9dUoRys")
            print(pub?.rawPublicKey())
            
            let pbtest = try? PublicKey(keyString: pubkey_data.publicKeyEncodeString(enclave: .Secp256k1))
            print (pbtest?.rawPublicKey())
            
            print ("***RAW FROM MAKE KEY GEN****")
            
            print(Data(bytes: v_pubKey, count: 64).publicKeyEncodeString(enclave: .Secp256k1))
            
            var secret = UnsafeMutablePointer<UInt8>.allocate(capacity: 32)
            var t_result: Int32 = 0
            t_result = uECC_shared_secret(v_pubKey,v_pKey , secret, uECC_secp256k1())
            if (t_result == 1){
                let decodedString = Data(bytes: secret, count: 32)
                print ("*****")
                print( FIOHash.sha512(decodedString))
            }
            
            var z_result: Int32 = 0
            z_result = uECC_shared_secret(v_pubKey , v_pKey, secret, uECC_secp256k1())
            if (z_result == 1){
                let decodedString = Data(bytes: secret, count: 32)
                print ("*2ND****")
                print( FIOHash.sha512(decodedString))
            }
            
            var secret_two = UnsafeMutablePointer<UInt8>.allocate(capacity: 32)
            guard let publicKey = try? PublicKey(keyString: pub!.rawPublicKey().replacingOccurrences(of: "EOS", with: "")) else { return "" }
            var result: Int32 = 0
            
            // this works - doing it directly.
     //       pkey_data.withUnsafeBytes({ (privKeyPointer: UnsafePointer<UInt8>) -> Void in
      //          pubkey_data.withUnsafeBytes({ (pubKeyPointer: UnsafePointer<UInt8>) -> Void in
        //            result = uECC_shared_secret(pubKeyPointer, privKeyPointer, secret_two, uECC_secp256k1())
         //       })
         //   })
            
         //   p.data.withUnsafeBytes({ (privKeyPointer: UnsafePointer<UInt8>) -> Void in
         ///       pbtest?.uncompressed.withUnsafeBytes({ (pubKeyPointer: UnsafePointer<UInt8>) -> Void in
         //           result = uECC_shared_secret(pubKeyPointer, privKeyPointer, secret_two, uECC_secp256k1())
          //      })
           // })
            
            //ok, so it is the format here that is screwed up
            // start with private key - make sure that is coming across correctly. PRIVATE KEY is correct. Then, fix the public key
            // public key needs to be in this format:  pubkey_data.publicKeyEncodeString(enclave: .Secp256k1)
            // PUB_K1_FkwjHRSj4xVaWR8QLic7idBJFYcxqADXV31XAAbemDwfRV4ZFgkBapnYjnKZNRcxMCNbVXHXT3WGZeCb6cAWRGUjov3A9
            result = uECC_shared_secret([UInt8](pbtest!.data), [UInt8](p.data), secret_two, uECC_secp256k1())
            
          //  [UInt8](pk.data)
       //  i think i just need to uncompress it.
            print (pbtest?.rawPublicKey())
            
            if result == 1 {
                let decodedString = Data(bytes: secret_two, count: 32)
                print ("***DOES IT MATCH****")
                print (FIOHash.sha512(decodedString))
                return FIOHash.sha512(decodedString)
            }
            else {
                print("Problem generating shared secret")
                return nil
            }
            
       
            
        }
        
        return ""
      
    }
    
    func getSharedSecret(pubKey: String) -> String? {
        // USE SwiftyEOS uECC_shared_secret (seems to give different results)
//        var secret = UnsafeMutablePointer<UInt8>.allocate(capacity: 0)
        guard let publicKey = try? PublicKey(keyString: pubKey.replacingOccurrences(of: "EOS", with: "")) else { return "" }
//        var result: Int32 = 0
//        data.withUnsafeBytes({ (privKeyPointer: UnsafePointer<UInt8>) -> Void in
//            publicKey.data.withUnsafeBytes({ (pubKeyPointer: UnsafePointer<UInt8>) -> Void in
//                result = uECC_shared_secret(pubKeyPointer, privKeyPointer, secret, uECC_secp256k1())
//            })
//        })
//
//        if result == 1 {
//            let decodedString = Data(bytes: secret, count: 32)
//            return FIOHash.sha512(decodedString)
//        }
//        else {
//            print("Problem generating shared secret")
//            return nil
//        }
        
    //OR TRY TO Immitate JS code (not sure how to match that code, its using external libs)
        var compressed:Array<UInt8> = Array(repeating: UInt8(0), count: 33)
        var KBPointer = UnsafeMutablePointer<UInt8>.allocate(capacity: 0)
        publicKey.data.withUnsafeBytes({ (pubKeyPointer: UnsafePointer<UInt8>) -> Void in
            let buffer = UnsafeBufferPointer(start: pubKeyPointer,
                                             count: publicKey.data.count)
            compressed = Array<UInt8>(buffer)
        })
        uECC_decompress(compressed, KBPointer, uECC_secp256k1())
        let buffer = UnsafeBufferPointer(start: KBPointer,
                                         count: 130)
        let KB = Array<UInt8>(buffer)
        let firstSlice = KB[1..<33].map { item in
            String(item)
        }.joined()
        let secondSlice = Array(KB[33..<65]).map { item in
            String(item)
            }.joined()
        // THIS is not going to work as it is cause KB[1..<33] is to big to fit a number, not sure how to do BigInteger.fromBuffer( KB.slice( 1,33 ))
        let x = CGFloat(Int(firstSlice)!)
        let y = CGFloat(Int(secondSlice)!)
        let KBP = CGPoint(x: x, y: y)
//        point_multiply(<#T##curve: UnsafePointer<ecdsa_curve>!##UnsafePointer<ecdsa_curve>!#>, <#T##k: UnsafePointer<bignum256>!##UnsafePointer<bignum256>!#>, <#T##p: UnsafePointer<curve_point>!##UnsafePointer<curve_point>!#>, <#T##res: UnsafeMutablePointer<curve_point>!##UnsafeMutablePointer<curve_point>!#>)
//        let KB = uECC_decompress()
//        let KB = public_key.toUncompressed().toBuffer()
//        let KBP = Point.fromAffine(
//        secp256k1,
//        BigInteger.fromBuffer( KB.slice( 1,33 )), // x
//        BigInteger.fromBuffer( KB.slice( 33,65 )) // y
//        )
//        let r = toBuffer()
//        let P = KBP.multiply(BigInteger.fromBuffer(r))
//        let S = P.affineX.toBuffer({size: 32})
        // SHA512 used in ECIES
        
        return nil
    }
    
}
