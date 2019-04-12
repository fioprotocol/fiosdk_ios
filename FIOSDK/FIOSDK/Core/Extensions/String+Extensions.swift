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
    
}
