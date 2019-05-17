//
//  RegisterName.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-04-04.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

internal struct RegisterName: Codable {
    
    let fioName:String
    let actor:String
    let ownerFIOPublicKey: String
    let maxFee: Int
    
    enum CodingKeys: String, CodingKey {
        case fioName = "fio_address"
        case actor = "actor"
        case ownerFIOPublicKey = "owner_fio_public_key"
        case maxFee = "max_fee"
    }
    
}
