//
//  SentFIORequestRespose.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-04-03.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

public struct SentFioRequestResponse: Codable {
    
    public let fioPublicAddress: String
    public let requests: [SentFioRequest]
    
    enum CodingKeys: String, CodingKey{
        case fioPublicAddress = "fiopubadd"
        case requests
    }
    
    /// PendingFioRequestsResponse.request DTO
    public struct SentFioRequest: Codable {
        
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
        public let status: String
        
        enum CodingKeys: String, CodingKey {
            case fioreqid = "fioreqid"
            case fromFioAddress = "fromfioadd"
            case toFioAddress = "tofioadd"
            case toPublicAddress = "topubadd"
            case amount
            case tokenCode = "tokencode"
            case metadata
            case timeStamp = "timestamp"
            case status
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
             timeStamp: TimeInterval,
             status: String) {
            self.fioreqid = fioreqid
            self.fromFioAddress = fromFioAddress
            self.toFioAddress = toFioAddress
            self.toPublicAddress = toPublicAddress
            self.amount = amount
            self.tokenCode = tokenCode
            self.metadata = metadata
            self.timeStamp = timeStamp
            self.status = status
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            let fioreqid = try container.decodeIfPresent(Int.self, forKey: .fioreqid) ?? 0
            let fromFioAddress = try container.decodeIfPresent(String.self, forKey: .fromFioAddress) ?? ""
            let toFioAddress = try container.decodeIfPresent(String.self, forKey: .toFioAddress) ?? ""
            let toPublicAddress = try container.decodeIfPresent(String.self, forKey: .toPublicAddress) ?? ""
            let amount = try container.decodeIfPresent(String.self, forKey: .amount) ?? ""
            let tokenCode = try container.decodeIfPresent(String.self, forKey: .tokenCode) ?? ""
            let timeStamp = try container.decodeIfPresent(TimeInterval.self, forKey: .timeStamp) ?? Date().timeIntervalSince1970
            //                var timeStamp: TimeInterval = Date().timeIntervalSince1970
            //                if let unwrappedTimeStamp = timeStampValue, let timeStampDouble = Double(unwrappedTimeStamp) {
            //                    timeStamp = TimeInterval(timeStampDouble)
            //                }
            var metadata = SentFioRequest.MetaData(memo: "")
            let metadataString = try container.decodeIfPresent(String.self, forKey: .metadata)
            if let metadataData = metadataString?.data(using: .utf8) {
                metadata = try JSONDecoder().decode(SentFioRequest.MetaData.self, from: metadataData)
            }
            let status = try container.decodeIfPresent(String.self, forKey: .status) ?? ""
            
            self.init(fioreqid: fioreqid,
                      fromFioAddress: fromFioAddress,
                      toFioAddress: toFioAddress,
                      toPublicAddress: toPublicAddress,
                      amount: amount,
                      tokenCode: tokenCode,
                      metadata: metadata,
                      timeStamp: timeStamp,
                      status: status)
        }
        
    }
    
}
