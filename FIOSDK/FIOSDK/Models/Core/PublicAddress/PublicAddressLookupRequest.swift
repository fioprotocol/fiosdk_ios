//
//  PublicAddressLookupRequest.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-04-04.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

internal struct PublicAddressLookupRequest: Codable {
    
    public let fioAddress: String
    public let tokenCode: String
    
    enum CodingKeys: String, CodingKey{
        case fioAddress = "fio_address"
        case tokenCode = "token_code"
    }
    
}
