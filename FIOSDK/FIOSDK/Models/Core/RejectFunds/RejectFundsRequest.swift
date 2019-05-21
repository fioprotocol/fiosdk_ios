//
//  RejectFundsRequest.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-04-04.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

internal struct RejectFundsRequest: Codable {
    
    var fioReqID: String
    var actor: String
    let maxFee: Int
    
    enum CodingKeys: String, CodingKey {
        case fioReqID = "fio_request_id"
        case actor
        case maxFee = "max_fee"
    }
    
}
