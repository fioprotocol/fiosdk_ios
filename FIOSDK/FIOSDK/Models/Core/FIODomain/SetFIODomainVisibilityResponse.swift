//
//  SetFIODomainVisibilityResponse.swift
//  FIOSDK
//
//  Created by shawn arney on 12/3/19.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

extension FIOSDK.Responses {
    public struct SetFIODomainVisibilityResponse: Codable {
        
        public let status: String
        public let feeCollected: Int
        
        enum CodingKeys: String, CodingKey{
            case status
            case feeCollected = "fee_collected"
        }
    }
}
