//
//  RejectFundsRequest.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-04-04.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

extension FIOSDK.Responses {

    public struct RejectFundsRequestResponse: Codable {
        
        public let status: Status
        
        enum CodingKeys: String, CodingKey {
            case status
        }
        
        public enum Status: String, Codable {
            case rejected = "request_rejected", unknown
        }
        
    }
    
}

extension FIOSDK.Responses.RejectFundsRequestResponse.Status {
    
    public init(from decoder: Decoder) throws {
        self = try FIOSDK.Responses.RejectFundsRequestResponse.Status(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .unknown
    }
    
}
