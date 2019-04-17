//
//  AddPublicAddress.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-04-04.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

/// Struct to use as DTO for the addpublic address method
internal struct AddPublicAddress: Codable {
    
    let fioAddress: String
    let tokenCode: String
    let publicAddress: String
    let actor: String
    
    enum CodingKeys: String, CodingKey {
        case fioAddress    = "fio_address"
        case tokenCode     = "token_code"
        case publicAddress = "public_address"
        case actor
    }
    
}
