//
//  RegisterFIOAddressRequest.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-05-23.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

internal struct RegisterFIOAddressRequest: Codable {
    
    let FIOAddress: String
    let FIOPublicKey: String
    let maxFee: Int
    let actor: String
    
    enum CodingKeys: String, CodingKey {
        case FIOAddress = "fio_address"
        case FIOPublicKey = "owner_fio_public_key"
        case maxFee = "max_fee"
        case actor
    }
    
}
