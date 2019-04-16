//
//  TransferFIOTokensResponse.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-04-03.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

public struct TransferFIOTokensResponse: Codable {
    
    public let status: String
    
    enum CodingKeys: String, CodingKey {
        case status = "status"
    }
    
}
