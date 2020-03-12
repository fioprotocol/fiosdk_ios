//
//  RejectFundsRequest.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-04-04.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

internal struct RejectFundsRequest: Codable {
    
    let fioRequestId: Int
    let maxFee: Int
    let technologyProviderId: String
    var actor: String
    
    enum CodingKeys: String, CodingKey {
        case fioRequestId = "fio_request_id"
        case maxFee = "max_fee"
        case technologyProviderId = "tpid"
        case actor
    }
    
}
