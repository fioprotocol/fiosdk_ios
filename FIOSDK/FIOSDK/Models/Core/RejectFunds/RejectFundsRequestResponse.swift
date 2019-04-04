//
//  RejectFundsRequest.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-04-04.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

public struct RejectFundsRequestResponse: Codable {
    
    public let fioReqID: String
    public let status: Status
    
    enum CodingKeys: String, CodingKey {
        case fioReqID = "fioreqid"
        case status
    }
    
    public enum Status: String, Codable {
        case rejected = "request_rejected", unknown
    }
    
}

extension RejectFundsRequestResponse.Status {
    
    public init(from decoder: Decoder) throws {
        self = try RejectFundsRequestResponse.Status(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .unknown
    }
    
}
