//
//  TransferFIOTokensRequest.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-04-03.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

internal struct TransferFIOTokensRequest: Codable {
    
    let payeePublicKey: String
    let amount: Int
    let maxFee: Int
    let technologyProviderId: String
    let actor: String
    
    enum CodingKeys: String, CodingKey {
        case payeePublicKey = "payee_public_key"
        case amount = "amount"
        case maxFee = "max_fee"
        case technologyProviderId = "tpid"
        case actor = "actor"
    }
    
}
