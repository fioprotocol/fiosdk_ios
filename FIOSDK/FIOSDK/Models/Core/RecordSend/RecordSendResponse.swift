//
//  RecordSendResponse.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-04-03.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

extension FIOSDK.Responses {

    public struct RecordSendResponse: Codable {

        public let status: Status
            public let feeCollected: Int
            
            enum CodingKeys: String, CodingKey {
                case status
                case feeCollected = "fee_collected"
            }
            
            public enum Status: String, Codable {
                case sentToBlockchain = "sent_to_blockchain", unknown
            }
        }
}

extension FIOSDK.Responses.RecordSendResponse.Status {
    
    public init(from decoder: Decoder) throws {
        self = try FIOSDK.Responses.RecordSendResponse.Status(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .unknown
    }
    
}
