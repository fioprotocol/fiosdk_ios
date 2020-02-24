//
//  RenewFIOAddressRequest.swift
//  FIOSDK
//
//  Created by Kenneth Rangel on 2019-10-11.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

internal struct RenewFIOAddressRequest: Codable {
    
    let fioAddress: String
    let maxFee: Int
    let technologyProviderId: String
    let actor: String
    
    enum CodingKeys: String, CodingKey {
        case fioAddress = "fio_address"
        case maxFee = "max_fee"
        case technologyProviderId = "tpid"
        case actor
    }
    
}
