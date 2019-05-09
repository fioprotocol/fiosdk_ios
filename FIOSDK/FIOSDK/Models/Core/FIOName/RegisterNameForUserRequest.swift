//
//  RegisterNameForUserRequest.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-05-03.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

internal struct RegisterNameForUserRequest: Codable {
    
    let fioName:String
    let publicKey:String
    
    enum CodingKeys: String, CodingKey {
        case fioName = "fio_name"
        case publicKey = "owner_fio_public_key"
    }
    
}
