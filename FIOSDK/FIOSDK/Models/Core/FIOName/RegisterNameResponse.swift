//
//  RegisterNameResponse.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-05-14.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

public struct RegisterNameResponse: Codable {
    
    public let status: String
    public let expiration: Date
    
    enum CodingKeys: String, CodingKey {
        case status
        case expiration
    }
    
}
