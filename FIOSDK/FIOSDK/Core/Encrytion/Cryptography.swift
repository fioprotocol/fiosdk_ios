//
//  Cryptography.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-06-19.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation
import CommonCrypto

enum CryptographyError: Error {
    case runtimeError(String)
}

enum HMACMode: String {
    
    case sha1 = "SHA1"
    case md5 = "MD5"
    case sha224 = "SHA224"
    case sha256 = "SHA256"
    case sha384 = "SHA384"
    case sha512 = "SHA512"
    
}

struct Cryptography {
    
    /// Generate random bytes Data object according to the given size.
    /// - Parameters:
    ///     - size: The number of random bytes being added to a Data object.
    /// - Return: The Data containing the random bytes or nil if any problem happened.
    private func extract(from data: Data, index: Int, length: Int) -> Data? {
        guard data.count > 0 else {
            return nil
        }
        // Get a new copy of data
        let subData = data.subdata(in: (index..<length))
        // Return the new copy of data
        return subData
    }
    
    /// Generate SHA512 digest in hex format with given hex string.
    /// - Parameters:
    ///     - string: The string to be hashed with SHA512.
    /// - Return: Digest from given string as String with hex value.
    private func sha512Hex(string: String) -> String {
        return sha512Hex(string.toHexData())
    }
    
    /// Generate SHA512 digest in hex format with given Data.
    /// - Parameters:
    ///     - data: The Data to be hashed with SHA512.
    /// - Return: Digest from given string as String with hex value.
    private func sha512Hex(_ data: Data) -> String {
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
    
    /// Generate random bytes Data object according to the given size.
    /// - Parameters:
    ///     - size: The number of random bytes being added to a Data object.
    /// - Return: The Data containing the random bytes or nil if any problem happened.
    private func generateRandomBytes(size: Int) -> Data? {
        
        var keyData = Data(count: size)
        let result = keyData.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, size, $0.baseAddress!)
        }
        if result == errSecSuccess {
            return keyData
        } else {
            print("Problem generating random bytes")
            return nil
        }
    }
    
    /// Encrypt data with AES256-CBC with given key and initialization vector.
    /// - Parameters:
    ///     - data: Data object to be encrypted.
    ///     - key: key to be used during encryption.
    ///     - iv: initialization vector for encrytion.
    /// - Return: Digest from given string as String with hex value.
    private func encryptAES256CBC(data: Data, key: Data, iv: Data) throws -> Data {
        // Output buffer (with padding)
        let outputLength = data.count + kCCBlockSizeAES128
        var outputBuffer = Array<UInt8>(repeating: 0,
                                        count: outputLength)
        var numBytesEncrypted = 0
        
        let status = CCCrypt(CCOperation(kCCEncrypt),
                             CCAlgorithm(kCCAlgorithmAES),
                             CCOptions(kCCOptionPKCS7Padding),
                             Array(key),
                             kCCKeySizeAES256,
                             Array(iv),
                             Array(data),
                             data.count,
                             &outputBuffer,
                             outputLength,
                             &numBytesEncrypted)
        
        guard status == kCCSuccess else {
            throw CryptographyError.runtimeError(String(status))
        }
        let outputBytes = iv + outputBuffer.prefix(numBytesEncrypted)
        return Data(bytes: outputBytes)
    }
    
    /// Decrypt data with AES256-CBC with given key, it considers that data has the initialization vector in the beginning of the Data value.
    /// - Parameters:
    ///     - data: Data object to be decrypted. Containing iv + encrypted data.
    ///     - key: key to be used during encryption.
    /// - Return: Digest from given string as String with hex value.
    private func decryptAES256CBC(data cipherData: Data, key: Data) throws -> Data {
        // Split IV and cipher text
        let iv = cipherData.prefix(kCCBlockSizeAES128)
        let cipherTextBytes = cipherData
            .suffix(from: kCCBlockSizeAES128)
        let cipherTextLength = cipherTextBytes.count
        
        // Output buffer
        var outputBuffer = Array<UInt8>(repeating: 0,
                                        count: cipherTextLength)
        var numBytesDecrypted = 0
        
        let status = CCCrypt(CCOperation(kCCDecrypt),
                             CCAlgorithm(kCCAlgorithmAES),
                             CCOptions(kCCOptionPKCS7Padding),
                             Array(key),
                             kCCKeySizeAES256,
                             Array(iv),
                             Array(cipherTextBytes),
                             cipherTextLength,
                             &outputBuffer,
                             cipherTextLength,
                             &numBytesDecrypted)
        
        guard status == kCCSuccess else {
            throw CryptographyError.runtimeError(String(status))
        }
        
        // Discard padding
        let outputBytes = outputBuffer.prefix(numBytesDecrypted)
        return Data(outputBytes)
    }
    
    /// Apply hmac hashing with especified mode to the given message and key.
    /// - Parameters:
    ///     - mode: The type of hmac algorithm.
    ///     - message: The message to be hashed.
    ///     - key: key to be used during hashing.
    /// - Return: Hashed message as Data.
    private func hmac(mode:HMACMode, message:Data, key:Data) -> Data? {
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
    
    /// Encrypt message with given secret and initialization vector. If IV is not provided, a random one will be generated.
    /// - Parameters:
    ///     - secret: The secret to be used to encrypt message.
    ///     - message: The message to be encrypted.
    ///     - iv: Optional Data object representing the initialization vector.
    /// - Return: Encrypted message as Data or nil if something wrong happened.
    func encrypt(secret: String, message: String, iv: Data?) -> Data? {
        let privateKeyHash = sha512Hex(string: secret)
        let tempSha512Arr = Array(privateKeyHash)
        var sha512Arr: [String] = []
        for i in stride(from: 0, to: tempSha512Arr.count, by: 2) {
            sha512Arr.append(String(tempSha512Arr[i]) + String(tempSha512Arr[i+1]))
        }
        let encryptionKey = sha512Arr[0..<32].joined()
        let hmacKey = sha512Arr[32..<sha512Arr.count].joined()
        guard let ivData = (iv != nil) ? iv! : generateRandomBytes(size: 16) else { return nil }
        guard let cypherIV = try? encryptAES256CBC(data: message.data(using: String.Encoding.utf8)!, key: encryptionKey.toHexData(), iv: ivData) else { return nil }
        let hmacValue = hmac(mode: HMACMode.sha256, message: cypherIV, key: hmacKey.toHexData())
        return (hmacValue != nil) ? cypherIV + hmacValue! : nil
    }
    
    /// Decrypt message with given secret. Assumes that message will carry all necessary information for decryption, IV and hmac hash, as well as encrypted content. May throw an error if hmac hashes doesn't match.
    /// - Parameters:
    ///     - secret: The secret to be used to encrypt message.
    ///     - message: The message to be encrypted.
    /// - Return: Decrypted message as Data or nil if something wrong happened.
    func decrypt(secret: String, message: Data) throws -> Data? {
        let privateKeyHash = sha512Hex(string: secret)
        let tempSha512Arr = Array(privateKeyHash)
        var sha512Arr: [String] = []
        for i in stride(from: 0, to: tempSha512Arr.count, by: 2) {
            sha512Arr.append(String(tempSha512Arr[i]) + String(tempSha512Arr[i+1]))
        }
        let encryptionKey = sha512Arr[0..<32].joined()
        let hmacKey = sha512Arr[32..<sha512Arr.count].joined()
        guard let IV = extract(from: message, index: 0, length: 16) else { return nil }
        guard let cipher = extract(from: message, index: 16, length: 32) else { return nil }
        let hmacContent = extract(from: message, index: 32, length: message.count)
        
        guard let hmacVerifier = hmac(mode: HMACMode.sha256, message: IV + cipher, key: hmacKey.toHexData()) else { return nil }
        
        guard hmacContent == hmacVerifier else {
            throw CryptographyError.runtimeError("Decrypt failed")
        }
        
        return try? decryptAES256CBC(data: IV + cipher, key: encryptionKey.toHexData())
    }
    
}
