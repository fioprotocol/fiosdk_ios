//
//  PublicAddressRequest.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-04-04.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

internal struct PublicAddressRequest: Codable {
    
    public let fioAddress: String
    public let chainCode: String
    public let tokenCode: String
    
    enum CodingKeys: String, CodingKey{
        case fioAddress = "fio_address"
        case chainCode = "chain_code"
        case tokenCode = "token_code"
    }
    
}
