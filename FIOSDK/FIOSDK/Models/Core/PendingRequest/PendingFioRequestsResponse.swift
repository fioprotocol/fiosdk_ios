//
//  PendingFioRequestsResponse.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-04-04.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

/// getPendingFioRequest DTO response
public struct PendingFioRequestsResponse: Codable {
    
    public let fioPubAdd: String
    public let requests: [PendingFioRequest]
    
    enum CodingKeys: String, CodingKey{
        case fioPubAdd = "fiopubadd"
        case requests
    }
    
    /// PendingFioRequestsResponse.request DTO
    public struct PendingFioRequest: Codable {
        
        public var fundsRequestId: String {
            return String(fioreqid)
        }
        private let fioreqid: Int
        public let fromFioAddress: String
        public let toFioAddress: String
        public let toPublicAddress: String
        public let amount: String
        public let tokenCode: String
        public let metadata: MetaData
        public let timeStamp: TimeInterval
        
        enum CodingKeys: String, CodingKey {
            case fioreqid = "fioreqid"
            case fromFioAddress = "fromfioadd"
            case toFioAddress = "tofioadd"
            case toPublicAddress = "topubadd"
            case amount
            case tokenCode = "tokencode"
            case metadata
            case timeStamp = "fiotime"
        }
        
        public struct MetaData: Codable {
            
            public let memo: String
            
        }
        
        init(fioreqid: Int,
             fromFioAddress: String,
             toFioAddress: String,
             toPublicAddress: String,
             amount: String,
             tokenCode: String,
             metadata: MetaData,
             timeStamp: TimeInterval) {
            self.fioreqid = fioreqid
            self.fromFioAddress = fromFioAddress
            self.toFioAddress = toFioAddress
            self.toPublicAddress = toPublicAddress
            self.amount = amount
            self.tokenCode = tokenCode
            self.metadata = metadata
            self.timeStamp = timeStamp
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            let fioreqid = try container.decodeIfPresent(Int.self, forKey: .fioreqid) ?? 0
            let fromFioAddress = try container.decodeIfPresent(String.self, forKey: .fromFioAddress) ?? ""
            let toFioAddress = try container.decodeIfPresent(String.self, forKey: .toFioAddress) ?? ""
            let toPublicAddress = try container.decodeIfPresent(String.self, forKey: .toPublicAddress) ?? ""
            let amount = try container.decodeIfPresent(String.self, forKey: .amount) ?? ""
            let tokenCode = try container.decodeIfPresent(String.self, forKey: .tokenCode) ?? ""
            let timeStampValue = try container.decodeIfPresent(String.self, forKey: .timeStamp)
            var timeStamp: TimeInterval = Date().timeIntervalSince1970
            if let unwrappedTimeStamp = timeStampValue, let timeStampDouble = Double(unwrappedTimeStamp) {
                timeStamp = TimeInterval(timeStampDouble)
            }
            var metadata = PendingFioRequest.MetaData(memo: "")
            let metadataString = try container.decodeIfPresent(String.self, forKey: .metadata)
            if let metadataData = metadataString?.data(using: .utf8) {
                metadata = try JSONDecoder().decode(PendingFioRequest.MetaData.self, from: metadataData)
            }
            
            self.init(fioreqid: fioreqid,
                      fromFioAddress: fromFioAddress,
                      toFioAddress: toFioAddress,
                      toPublicAddress: toPublicAddress,
                      amount: amount,
                      tokenCode: tokenCode,
                      metadata: metadata,
                      timeStamp: timeStamp)
        }
        
    }
    
}
