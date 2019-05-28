//
//  FeeRequest.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-05-23.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

internal struct FeeRequest: Codable {
    
    let fioAddress: String
    let endPoint: String
    
    enum CodingKeys: String, CodingKey {
        case fioAddress = "fio_address"
        case endPoint = "end_point"
    }
    
}

