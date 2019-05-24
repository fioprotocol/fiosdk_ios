//
//  RegisterFIODomainResponse.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-05-23.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

extension FIOSDK.Responses {
    
    public struct RegisterFIODomainResponse: Codable {
        
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
