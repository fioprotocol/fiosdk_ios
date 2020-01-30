//
//  RenewFIODomainResponse.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-05-23.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

extension FIOSDK.Responses {
    
    public struct RenewFIODomainResponse: Codable {
        
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
