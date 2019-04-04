//
//  GetFIOBalanceRequest.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-04-02.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

internal struct GetFIOBalanceRequest: Codable {
    
    let fioPubAddress: String
    
    enum CodingKeys: String, CodingKey {
        case fioPubAddress = "fio_pub_address"
    }
    
}

