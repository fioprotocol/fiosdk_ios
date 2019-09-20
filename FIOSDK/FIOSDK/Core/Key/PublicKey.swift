//
//  PublicKey.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-04-12.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

internal extension Data {

    func publicKeyEncodeString(enclave: SecureEnclave) -> String {
        let size_of_data_to_hash = count
        let size_of_hash_bytes = 4
        var data: Array<UInt8> = Array(repeating: UInt8(0), count: size_of_data_to_hash+size_of_hash_bytes)
        var bytes = [UInt8](self)
        for i in 0..<size_of_data_to_hash {
            data[i] = bytes[i]
        }
        let hash = RMD(&bytes, 33)
        for i in 0..<size_of_hash_bytes {
            data[size_of_data_to_hash+i] = hash![i]
        }
        let base58 = Data(bytes: data, count: size_of_data_to_hash+size_of_hash_bytes).base58EncodedData()
        return "PUB_\(enclave.rawValue)_\(String(data: base58, encoding: .ascii)!)"
    }
    
}

internal extension String {
    
    func publicKeyParseWif() -> Data? {
        guard let base58 = Data.decode(base58: self) else { return nil }
        let bytes = [UInt8](base58)
        var data: Array<UInt8> = Array(repeating: UInt8(0), count: base58.count-4)
        for i in 0..<base58.count-4 {
            data[i] = bytes[i]
        }
        return Data(bytes: data, count: base58.count-4)
    }
    
}

internal struct PublicKey {
    
    var data: Data
    var enclave: SecureEnclave
    static let delimiter = "_"
    static let prefix = "PUB"
    
    init(privateKey: PrivateKey) {
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
        enclave = privateKey.enclave
    }
    
    init?(keyString: String) throws {
        var nonEOSKey = keyString
        if nonEOSKey.range(of: "EOS") != nil {
            nonEOSKey = nonEOSKey.replacingOccurrences(of: "EOS", with: "").replacingOccurrences(of: "FIO", with: "")
        }
        if nonEOSKey.range(of: "FIO") != nil {
            nonEOSKey = nonEOSKey.replacingOccurrences(of: "FIO", with: "")
        }
        if nonEOSKey.range(of: PublicKey.delimiter) == nil {
            enclave = .Secp256k1
            data = try nonEOSKey.publicKeyParseWif()!
        } else {
            let dataParts = nonEOSKey.components(separatedBy: PublicKey.delimiter)
            guard dataParts[0] == PublicKey.prefix else {
                throw NSError(domain: "com.swiftyeos.error", code: 0, userInfo: [NSLocalizedDescriptionKey: "Private Key \(nonEOSKey) has invalid prefix: \(PrivateKey.delimiter)"])
            }
            
            guard dataParts.count != 2 else {
                throw NSError(domain: "com.swiftyeos.error", code: 0, userInfo: [NSLocalizedDescriptionKey: "Private Key has data format is not right: \(nonEOSKey)"])
            }
            
            enclave = SecureEnclave(rawValue: dataParts[1])!
            let dataString = dataParts[2]
            data = try dataString.publicKeyParseWif()!
        }
    }
    
    
    func wif() -> String {
        return self.data.publicKeyEncodeString(enclave: enclave)
    }
    
    func rawPublicKey() -> String {
        let withoutDelimiter = self.wif().components(separatedBy: "_").last
        guard withoutDelimiter!.hasPrefix("EOS") else {
            return "FIO\(withoutDelimiter!)"
        }
        return withoutDelimiter!
    }
    
}
