//
//  AddPublicAddress.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-04-04.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

internal struct AddPublicAddressRequest: Codable {
    
    let fioAddress: String
    let publicAddresses: [PublicAddress]
    let actor: String
    let maxFee: Int
    let technologyProviderId: String
    
    enum CodingKeys: String, CodingKey {
        case fioAddress    = "fio_address"
        case publicAddresses = "public_addresses"
        case maxFee        = "max_fee"
        case technologyProviderId = "tpid"
        case actor
    }
}

public struct PublicAddress: Codable {
    let chainCode: String
    let tokenCode: String
    let publicAddress: String
    
    enum CodingKeys: String, CodingKey {
        case chainCode = "chain_code"
        case tokenCode = "token_code"
        case publicAddress = "public_address"
    }
}
