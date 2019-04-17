//
//  TransferFIOTokensRequest.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-04-03.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

internal struct TransferFIOTokensRequest: Codable {
    
    let amount: String
    let actor: String
    let payeePublicAddress: String
    
    enum CodingKeys: String, CodingKey {
        case amount = "amount"
        case actor = "actor"
        case payeePublicAddress = "payee_public_address"
    }
    
}
