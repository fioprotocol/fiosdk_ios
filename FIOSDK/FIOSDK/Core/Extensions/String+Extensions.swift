//
//  Extensions.swift
//  FIOSDK
//
//  Created by shawn arney on 11/7/18.
//  Copyright © 2018 Dapix, Inc. All rights reserved.
//
internal extension String {
    
    var ascii: [UInt8] {
        return unicodeScalars.compactMap { $0.isASCII ? UInt8($0.value) : nil }
    }
    
    /// Convert string with hex value to hex bytes Data object
    /// - Return: The Data containing the random bytes or nil if any problem happened.
    func toHexData() -> Data {
        var data: Data = Data(capacity: self.count/2)
        let characters = Array(self)
        for i in stride(from: 0, to: characters.count, by: 2) {
            let byteString = String(characters[i]) + String(characters[i+1])
            let hexNum = UInt8(byteString, radix: 16)!
            data.append(hexNum)
        }
        return data
    }
    
}
