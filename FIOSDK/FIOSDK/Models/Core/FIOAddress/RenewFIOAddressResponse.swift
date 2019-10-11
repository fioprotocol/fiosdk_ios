//
//  RenewFIOAddressResponse.swift
//  FIOSDK
//
//  Created by Kenneth Rangel on 2019-10-11.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

extension FIOSDK.Responses {
    
    public struct RenewFIOAddressResponse: Codable {
        
        public let status: String
        public let expiration: Date
        public let feeCollected: Int
        
        enum CodingKeys: String, CodingKey {
            case status
            case expiration
            case feeCollected = "fee_collected"
        }
        
    }
    
}
