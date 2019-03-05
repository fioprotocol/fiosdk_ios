//
//  FIOPublicAddressGenerator.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-03-01.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

/**
 * This class is responsible for account name API parameter https://stealth.atlassian.net/wiki/spaces/DEV/pages/53280776/API#API-Generatingactor, which is a generated hash following this https://stealth.atlassian.net/wiki/spaces/DEV/pages/130482236/Hash+function+definition specs
 * Account name is also called actor or FIO public address
 */
struct AccountNameGenerator {
    
    /**
     * Generate account name with given public key based on a hash function.
     * If the public key has less than 4 chars its considered invalid and an empty value will be returned.
     * This function will also return an empty string in the case of an invalid base58 generation from the public key.
     * - Parameter withPublicKey: A valid public key to derive the account name from.
     * - Return: account name value.
     */
    public static func run(withPublicKey publicKey: String) -> String {
        guard publicKey.count > 4 else { return "" }
        //STEP 1 AND STEP 2 are not needed we receive the public key
        var pubKey = publicKey
        //STEP 3 remove 4 chars
        pubKey.removeSubrange(pubKey.startIndex..<pubKey.index(pubKey.startIndex, offsetBy: 4))
        //STEP 4 Base58 the pubkey
        guard let base58 = pubKey.data(using: .ascii)?.base58EncodedData() else { return "" }
        let hash = String(data: base58, encoding: .ascii) ?? ""
        //STEP 5 Get a long
        let long = stringToUInt64T(value: hash)
        //STEP 6 Generate the name from long
        return longToString(long)
    }
    
    private static func stringToUInt64T(value: String) -> UInt64 {
        let characters = value.ascii
        let length = value.count
        
        var number: UInt64 = 0
        
        for i in 0...12 {
            var c: UInt64 = 0
            if (i < length && i <= 12) {
                c = UInt64(characters[i])
            }
            if (i < 12) {
                c &= 0x1f
                let toShift = 64 - 5 * (i+1)
                c = c << toShift
            } else {
                c &= 0x0f
            }
            number |= c
        }
        
        return number
    }
    
    private static func longToString(_ value: UInt64) -> String {
        var charMap: [UInt8] = ".12345abcdefghijklmnopqrstuvwxyz".ascii
        var temp = value
        
        var characters: [UInt8] = [UInt8](repeating: 0, count: 13)
        
        characters[12] = charMap[Int(temp & 0x0f)]
        temp = temp >> 4
        
        for i in 1...12 {
            let c = charMap[Int(temp & 0x1f)]
            characters[12-i] = c
            temp = temp >> 5
        }
        
        var result = String(bytes: characters, encoding: .ascii)!
        if result.count > 12 {
            result = String(result[..<result.index(result.startIndex, offsetBy: 12)])
        }
        return result
    }
    
}
