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
        public let feeCollected: Int
        private let _expiration: String
        
        public var expiration: Date{
            return _expiration.toLocalDate
        }
        
        enum CodingKeys: String, CodingKey {
            case status
            case _expiration = "expiration"
            case feeCollected = "fee_collected"
        }
        
    }
    
}
