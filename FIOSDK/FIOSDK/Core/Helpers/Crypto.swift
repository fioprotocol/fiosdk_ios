//
//  Crypto.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-04-12.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation
import Security

/*
 let message     = "base58 or base64"
 let messageData = message.data(using:String.Encoding.utf8)!
 let keyData     = "16BytesLengthKey".data(using:String.Encoding.utf8)!
 let ivData      = "A-16-Byte-String".data(using:String.Encoding.utf8)!
 
 let decryptedData = testCrypt(inData:messageData, keyData:keyData, ivData:ivData, operation:kCCEncrypt)
 var decrypted     = String(data:decryptedData, encoding:String.Encoding.utf8)
 print(decrypted)
 */

internal enum SecureEnclave: String {
    case Secp256k1 = "K1"
    case Secp256r1 = "R1"
}

internal func curve(enclave: SecureEnclave) -> uECC_Curve {
    if enclave == .Secp256k1 {
        return uECC_secp256k1()
    } else {
        return uECC_secp256r1()
    }
}

internal func ccSha256(_ digest: UnsafeMutableRawPointer?, _ data: UnsafeRawPointer?, _ size: Int) -> Bool {
    let opaquePtr = OpaquePointer(digest)
    return CC_SHA256(data, CC_LONG(size), UnsafeMutablePointer<UInt8>(opaquePtr)).pointee != 0
}

internal let setSHA256Implementation: Void = {
    b58_sha256_impl = ccSha256
}()

internal extension String {
    
    func decodeChecked(version: UInt8) -> Data? {
        _ = setSHA256Implementation
        let source = self.data(using: .utf8)!
        
        var bin = [UInt8](repeating: 0, count: source.count)
        
        var size = bin.count
        let success = source.withUnsafeBytes { (sourceBytes: UnsafePointer<CChar>) -> Bool in
            if se_b58tobin(&bin, &size, sourceBytes, source.count) {
                bin = Array(bin[(bin.count - size)..<bin.count])
                return se_b58check(bin, size, sourceBytes, source.count) == Int32(version)
            }
            return false
        }
        
        if success {
            return Data(bytes: bin[1..<(bin.count-4)])
        }
        return nil
    }
    
}

internal extension Data {
    
    func sha256() -> Data {
        var hash = [UInt8](repeating: 0,  count: Int(CC_SHA256_DIGEST_LENGTH))
        withUnsafeBytes {
            _ = CC_SHA256($0, CC_LONG(count), &hash)
        }
        
        return Data(bytes: hash)
    }
    
    func base58EncodedData() -> Data {
        var mult = 2
        while true {
            var enc = Data(repeating: 0, count: self.count * mult)
            let s = self.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) -> Data? in
                var size = enc.count
                let success = enc.withUnsafeMutableBytes { ptr -> Bool in
                    return se_b58enc(ptr, &size, bytes, self.count)
                }
                if success {
                    return enc.subdata(in: 0..<(size-1))
                } else {
                    return nil
                }
            }
            
            if let s = s {
                return s
            }
            
            mult += 1
        }
    }
    
    func base58CheckEncodedData(version: UInt8) -> Data {
        _ = setSHA256Implementation
        var enc = Data(repeating: 0, count: self.count * 3)
        let s = self.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) -> Data? in
            var size = enc.count
            let success = enc.withUnsafeMutableBytes { ptr -> Bool in
                return se_b58check_enc(ptr, &size, version, bytes, self.count)
            }
            if success {
                return enc.subdata(in: 0..<(size-1))
            } else {
                fatalError()
            }
        }
        return s!
    }
    
    static func decode(base58: String) -> Data? {
        let source = base58.data(using: .utf8)!
        
        var bin = [UInt8](repeating: 0, count: source.count)
        
        var size = bin.count
        let success = source.withUnsafeBytes { (sourceBytes: UnsafePointer<CChar>) -> Bool in
            if se_b58tobin(&bin, &size, sourceBytes, source.count) {
                return true
            }
            return false
        }
        
        if success {
            return Data(bytes: bin[(bin.count - size)..<bin.count])
        }
        return nil
    }
    
}
