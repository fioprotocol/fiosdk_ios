//
//  SentFIORequestsResponse.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-04-03.
//  Modified by Shawn Arney on 2019-11-04. Adding encryption/decryption
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

extension FIOSDK.Responses {
    
    public struct SentFIORequestsResponse: Codable {
        
        public let requests: [SentFIORequestResponse]
        public let more: Int
        
        enum CodingKeys: String, CodingKey {
            case requests
            case more
        }
        
        public struct SentFIORequestResponse: Codable {
            
            public let fioRequestId: Int
            public let payerFIOAddress: String
            public let payeeFIOAddress: String
            public let payerFIOPublicKey: String
            public let payeeFIOPublicKey: String
            public let content:MetaData
            public let timeStamp: Date
            public let status: String
            
            enum CodingKeys: String, CodingKey {
                case fioRequestId = "fio_request_id"
                case payerFIOAddress = "payer_fio_address"
                case payeeFIOAddress = "payee_fio_address"
                case payerFIOPublicKey = "payer_fio_public_key"
                case payeeFIOPublicKey = "payee_fio_public_key"
                case timeStamp = "time_stamp"
                case status
                case content
            }
            
            public struct MetaData: Codable {
                public let payeePublicAddress: String
                public let amount: String
                public let tokenCode: String
                public let memo: String
                public let hash: String
                public let offlineUrl: String
                
                enum CodingKeys: String, CodingKey {
                    case payeePublicAddress = "payee_public_address"
                    case amount
                    case tokenCode = "token_code"
                    case memo
                    case hash
                    case offlineUrl = "offline_url"
               }
            }
            
            init(fioRequestId: Int,
                 payerFIOAddress: String,
                 payeeFIOAddress: String,
                 payerFIOPublicKey: String,
                 payeeFIOPublicKey: String,
                 timeStamp: Date,
                 status: String,
                 content:MetaData) {
                self.fioRequestId = fioRequestId
                self.payerFIOAddress = payerFIOAddress
                self.payeeFIOAddress = payeeFIOAddress
                self.payerFIOPublicKey = payerFIOPublicKey
                self.payeeFIOPublicKey = payeeFIOPublicKey
                self.timeStamp = timeStamp
                self.status = status
                self.content = content
            }
            
            public init(from decoder: Decoder) throws {
                
                let container = try decoder.container(keyedBy: CodingKeys.self)
                let payerFIOAddress = try container.decodeIfPresent(String.self, forKey: .payerFIOAddress) ?? ""
                let payeeFIOAddress = try container.decodeIfPresent(String.self, forKey: .payeeFIOAddress) ?? ""
                let payerFIOPublicKey = try container.decodeIfPresent(String.self, forKey: .payerFIOPublicKey) ?? ""
                let payeeFIOPublicKey = try container.decodeIfPresent(String.self, forKey: .payeeFIOPublicKey) ?? ""
                let fioreqid = try container.decodeIfPresent(Int.self, forKey: .fioRequestId) ?? 0
                let content = try container.decodeIfPresent(String.self, forKey: .content) ?? ""
                
                let timeStampString = try (container.decodeIfPresent(String.self, forKey: .timeStamp) ?? "1970-01-01T12:00:00")
                                            .replacingOccurrences(of: "Z", with: "") + "Z"

                let formatter = ISO8601DateFormatter()
                let timeStamp = formatter.date(from: timeStampString)
                
                let status = try container.decodeIfPresent(String.self, forKey: .status) ?? ""
                
                let metadataString = FIOSDK.sharedInstance().decrypt(publicKey: payerFIOPublicKey, contentType: FIOAbiContentType.newFundsContent, encryptedContent: content)
                
                var metadata = SentFIORequestResponse.MetaData(payeePublicAddress: "", amount: "", tokenCode: "", memo: "", hash: "", offlineUrl: "")
                if let metadataData = metadataString.data(using: .utf8) {
                    metadata = try JSONDecoder().decode(SentFIORequestResponse.MetaData.self, from: metadataData)
                }
                
                self.init(fioRequestId: fioreqid,
                    payerFIOAddress: payerFIOAddress,
                    payeeFIOAddress: payeeFIOAddress,
                    payerFIOPublicKey: payerFIOPublicKey,
                    payeeFIOPublicKey: payeeFIOPublicKey,
                    timeStamp: timeStamp ?? Date(timeIntervalSince1970: 1),
                    status: status,
                    content: metadata)
            }
            
        }
        
    }
    
}
