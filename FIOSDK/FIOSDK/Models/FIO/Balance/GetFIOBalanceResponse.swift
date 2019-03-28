//
//  GetFIOBalanceResponse.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-04-02.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

public struct GetFIOBalanceResponse: Codable {
    
    public let balance: String
    
    enum CodingKeys: String, CodingKey {
        case balance = "balance"
    }
    
}
