//
//  RegisterNameForUserResponse.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-05-03.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

public struct RegisterNameForUserResponse: Codable {
    
    let status: String
    let expiration: Date
    
    enum CodingKeys: String, CodingKey {
        case status
        case expiration
    }
    
}
