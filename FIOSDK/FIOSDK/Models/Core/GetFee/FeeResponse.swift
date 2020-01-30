//
//  FeeResponse.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-05-23.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

extension FIOSDK.Responses {
    
    public struct FeeResponse: Codable {
        
        public let fee: Int
        
        enum CodingKeys: String, CodingKey {
            case fee
        }
    }
}
