//
//  SetFIODomainVisibilityRequest.swift
//  FIOSDK
//
//  Created by shawn arney on 12/3/19.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

internal struct SetFIODomainVisibilityRequest: Codable {
    
    let fioDomain: String
    let isPublic: Int
    let maxFee: Int
    let walletFioAddress:String
    let actor: String
    
    enum CodingKeys: String, CodingKey {
        case fioDomain = "fio_domain"
        case isPublic = "is_public"
        case maxFee = "max_fee"
        case walletFioAddress = "tpid"
        case actor
    }
}
