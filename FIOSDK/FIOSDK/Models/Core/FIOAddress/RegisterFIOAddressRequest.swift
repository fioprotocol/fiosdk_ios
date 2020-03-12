//
//  RegisterFIOAddressRequest.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-05-23.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

internal struct RegisterFIOAddressRequest: Codable {
    
    let fioAddress: String
    let fioPublicKey: String
    let maxFee: Int
    let technologyProviderId:String
    let actor: String
    
    enum CodingKeys: String, CodingKey {
        case fioAddress = "fio_address"
        case fioPublicKey = "owner_fio_public_key"
        case maxFee = "max_fee"
        case technologyProviderId = "tpid"
        case actor
    }
}
