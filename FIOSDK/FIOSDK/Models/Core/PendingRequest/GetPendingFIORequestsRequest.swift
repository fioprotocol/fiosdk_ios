//
//  GetPendingFIORequestsRequest.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-04-04.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

internal struct GetPendingFIORequestsRequest: Codable {
    
    public let address: String
    
    enum CodingKeys: String, CodingKey{
        case address = "fio_public_address"
    }
    
}
