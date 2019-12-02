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
    let tokenCode: String
    let publicAddress: String
    let actor: String
    let maxFee: Int
    let walletFioAddress: String
    
    enum CodingKeys: String, CodingKey {
        case fioAddress    = "fio_address"
        case tokenCode     = "token_code"
        case publicAddress = "public_address"
        case maxFee        = "max_fee"
        case walletFioAddress = "tpid"
        case actor
    }
    
}
