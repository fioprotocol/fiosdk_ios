//
//  FIOHash.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-06-20.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation
import CommonCrypto

struct FIOHash {
    
    /// Generate SHA512 digest in hex format with given hex string.
    /// - Parameters:
    ///     - string: The string to be hashed with SHA512.
    /// - Return: Digest from given string as String with hex value.
    static func sha512(string: String) -> String {
        return sha512(string.toHexData())
    }
    
    /// Generate SHA512 digest in hex format with given Data.
    /// - Parameters:
    ///     - data: The Data to be hashed with SHA512.
    /// - Return: Digest from given string as String with hex value.
    static func sha512(_ data: Data) -> String {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA512_DIGEST_LENGTH))
        data.withUnsafeBytes { bytes in
            CC_SHA512(bytes, CC_LONG(data.count), &digest)
        }
        
        var digestHex = ""
        for index in 0..<Int(CC_SHA512_DIGEST_LENGTH) {
            digestHex += String(format: "%02x", digest[index])
        }
        
        return digestHex
    }

    
    static func sha1(_ data: Data) -> String {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        data.withUnsafeBytes { bytes in
            CC_SHA1(bytes, CC_LONG(data.count), &digest)
        }
        
        return arrayToHexString(digest, count: Int(CC_SHA1_DIGEST_LENGTH))
    }
    
    static func sha256(with data: Data) -> String {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes { bytes in
            CC_SHA256(bytes, CC_LONG(data.count), &digest)
        }
    
        return arrayToHexString(digest, count: Int(CC_SHA256_DIGEST_LENGTH))
    }
    
    static func sha256(with string: String) -> String {
        let data = string.data(using: .utf8)!
        return sha256(with: data)
    }

//    static func ripemd160(_ data: Data) {
//
//    }
    
    /// Apply hmac hashing with especified mode to the given message and key.
    /// - Parameters:
    ///     - mode: The type of hmac algorithm.
    ///     - message: The message to be hashed.
    ///     - key: key to be used during hashing.
    /// - Return: Hashed message as Data.
    static func hmac(mode:HMACMode, message:Data, key:Data) -> Data? {
        let algos = [HMACMode.sha1:   (kCCHmacAlgSHA1,   CC_SHA1_DIGEST_LENGTH),
                     HMACMode.md5:    (kCCHmacAlgMD5,    CC_MD5_DIGEST_LENGTH),
                     HMACMode.sha224: (kCCHmacAlgSHA224, CC_SHA224_DIGEST_LENGTH),
                     HMACMode.sha256: (kCCHmacAlgSHA256, CC_SHA256_DIGEST_LENGTH),
                     HMACMode.sha384: (kCCHmacAlgSHA384, CC_SHA384_DIGEST_LENGTH),
                     HMACMode.sha512: (kCCHmacAlgSHA512, CC_SHA512_DIGEST_LENGTH)]
        guard let (hashAlgorithm, length) = algos[mode]  else { return nil }
        var macData = Data(count: Int(length))
        
        macData.withUnsafeMutableBytes {macBytes in
            message.withUnsafeBytes {messageBytes in
                key.withUnsafeBytes {keyBytes in
                    CCHmac(CCHmacAlgorithm(hashAlgorithm),
                           keyBytes,     key.count,
                           messageBytes, message.count,
                           macBytes)
                }
            }
        }
        return macData
    }

    static func arrayToHexString(_ array: [UInt8], count: Int) -> String {
        var hex = ""
        for index in 0..<count {
            hex += String(format: "%02x", array[index])
        }
        return hex
    }

}
