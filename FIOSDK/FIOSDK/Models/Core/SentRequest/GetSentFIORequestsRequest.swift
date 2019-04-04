//
//  GetSentFIORequestsRequest.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-04-03.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

internal struct GetSentFIORequestsRequest: Codable {
    
    public let address: String
    
    enum CodingKeys: String, CodingKey{
        case address = "fiopubadd"
    }
    
}
