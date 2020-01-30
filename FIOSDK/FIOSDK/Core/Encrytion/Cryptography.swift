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
    
    /// Encrypt message with given secret and initialization vector. If IV is not provided, a random one will be generated.
    /// - Parameters:
    ///     - secret: The secret to be used to encrypt message.
    ///     - message: The message to be encrypted.
    ///     - iv: Optional Data object representing the initialization vector.
    /// - Return: Encrypted message as Data or nil if something wrong happened.
    func encrypt(secret: String, message: String, iv: Data?) -> Data? {
        let privateKeyHash = FIOHash.sha512(string: secret)
        let tempSha512Arr = Array(privateKeyHash)
        var sha512Arr: [String] = []
        for i in stride(from: 0, to: tempSha512Arr.count, by: 2) {
            sha512Arr.append(String(tempSha512Arr[i]) + String(tempSha512Arr[i+1]))
        }
        let encryptionKey = sha512Arr[0..<32].joined()
        let hmacKey = sha512Arr[32..<sha512Arr.count].joined()
        guard let ivData = (iv != nil) ? iv! : generateRandomBytes(size: 16) else { return nil }
        guard let cypherIV = try? encryptAES256CBC(data: message.toHexData(), key: encryptionKey.toHexData(), iv: ivData) else { return nil }
        
        let hmacValue = FIOHash.hmac(mode: HMACMode.sha256, message: cypherIV, key: hmacKey.toHexData())
        return (hmacValue != nil) ? cypherIV + hmacValue! : nil
    }
    
    /// Decrypt message with given secret. Assumes that message will carry all necessary information for decryption, IV and hmac hash, as well as encrypted content. May throw an error if hmac hashes doesn't match.
    /// - Parameters:
    ///     - secret: The secret to be used to encrypt message.
    ///     - message: The message to be encrypted.
    /// - Return: Decrypted message as Data or nil if something wrong happened.
    func decrypt(secret: String, message: Data) throws -> Data? {
        let privateKeyHash = FIOHash.sha512(string: secret)
        let tempSha512Arr = Array(privateKeyHash)
        var sha512Arr: [String] = []
        for i in stride(from: 0, to: tempSha512Arr.count, by: 2) {
            sha512Arr.append(String(tempSha512Arr[i]) + String(tempSha512Arr[i+1]))
        }
        let encryptionKey = sha512Arr[0..<32].joined()
        let hmacKey = sha512Arr[32..<sha512Arr.count].joined()
        guard let IV = extract(from: message, index: 0, length: 16) else { return nil }
        guard let cipher = extract(from: message, index: 16, length: message.count-32) else { return nil }
        let hmacContent = extract(from: message, index: 32, length: message.count)
        
        guard let hmacVerifier = FIOHash.hmac(mode: HMACMode.sha256, message: IV + cipher, key: hmacKey.toHexData()) else { return nil }
        
        guard hmacContent != hmacVerifier else {
            throw CryptographyError.runtimeError("Decrypt failed")
        }
        
        return try? decryptAES256CBC(data: IV + cipher, key: encryptionKey.toHexData())
    }
    
}
