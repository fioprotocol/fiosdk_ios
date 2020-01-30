//
//  GetABIRequest.swift
//  FIOSDK
//
//  Created by shawn arney on 6/20/19.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

internal struct GetABIRequest: Codable {
    
    let accountName: String
    
    enum CodingKeys: String, CodingKey {
        case accountName = "account_name"
    }
    
}
