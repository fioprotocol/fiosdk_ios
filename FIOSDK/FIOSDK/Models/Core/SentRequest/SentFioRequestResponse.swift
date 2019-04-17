//
//  SentFIORequestRespose.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-04-03.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

extension FIOSDK.Responses {

    public struct SentFioRequestResponse: Codable {
        
        public let requests: [SentFioRequest]
        
        enum CodingKeys: String, CodingKey {
            case requests
        }
        
        /// PendingFioRequestsResponse.request DTO
        public struct SentFioRequest: Codable {
            
            public var fundsRequestId: String {
                return String(fioreqid)
            }
            private let fioreqid: Int
            public let payerFIOAddress: String
            public let payeeFIOAddress: String
            public let payeePublicAddress: String
            public let amount: String
            public let tokenCode: String
            public let metadata: MetaData
            public let timeStamp: TimeInterval
            public let status: String
            
            enum CodingKeys: String, CodingKey {
                case fioreqid = "fio_request_id"
                case payerFIOAddress = "payer_fio_address"
                case payeeFIOAddress = "payee_fio_address"
                case payeePublicAddress = "payee_public_address"
                case amount
                case tokenCode = "token_code"
                case metadata
                case timeStamp = "time_stamp"
                case status
            }
            
            public struct MetaData: Codable {
                
                public let memo: String
                
            }
            
            init(fioreqid: Int,
                 payerFIOAddress: String,
                 payeeFIOAddress: String,
                 payeePublicAddress: String,
                 amount: String,
                 tokenCode: String,
                 metadata: MetaData,
                 timeStamp: TimeInterval,
                 status: String) {
                self.fioreqid = fioreqid
                self.payerFIOAddress = payerFIOAddress
                self.payeeFIOAddress = payeeFIOAddress
                self.payeePublicAddress = payeePublicAddress
                self.amount = amount
                self.tokenCode = tokenCode
                self.metadata = metadata
                self.timeStamp = timeStamp
                self.status = status
            }
            
            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                
                let fioreqid = try container.decodeIfPresent(Int.self, forKey: .fioreqid) ?? 0
                let payerFIOAddress = try container.decodeIfPresent(String.self, forKey: .payerFIOAddress) ?? ""
                let payeeFIOAddress = try container.decodeIfPresent(String.self, forKey: .payeeFIOAddress) ?? ""
                let payeePublicAddress = try container.decodeIfPresent(String.self, forKey: .payeePublicAddress) ?? ""
                let amount = try container.decodeIfPresent(String.self, forKey: .amount) ?? ""
                let tokenCode = try container.decodeIfPresent(String.self, forKey: .tokenCode) ?? ""
                let timeStamp = try container.decodeIfPresent(TimeInterval.self, forKey: .timeStamp) ?? Date().timeIntervalSince1970
                var metadata = SentFioRequest.MetaData(memo: "")
                let metadataString = try container.decodeIfPresent(String.self, forKey: .metadata)
                if let metadataData = metadataString?.data(using: .utf8) {
                    metadata = try JSONDecoder().decode(SentFioRequest.MetaData.self, from: metadataData)
                }
                let status = try container.decodeIfPresent(String.self, forKey: .status) ?? ""
                
                self.init(fioreqid: fioreqid,
                          payerFIOAddress: payerFIOAddress,
                          payeeFIOAddress: payeeFIOAddress,
                          payeePublicAddress: payeePublicAddress,
                          amount: amount,
                          tokenCode: tokenCode,
                          metadata: metadata,
                          timeStamp: timeStamp,
                          status: status)
            }
            
        }
        
    }
    
}
