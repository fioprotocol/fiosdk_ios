//
//  HMACMode.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-06-20.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

internal enum HMACMode: String {
    
    case sha1 = "SHA1"
    case md5 = "MD5"
    case sha224 = "SHA224"
    case sha256 = "SHA256"
    case sha384 = "SHA384"
    case sha512 = "SHA512"
    
}
