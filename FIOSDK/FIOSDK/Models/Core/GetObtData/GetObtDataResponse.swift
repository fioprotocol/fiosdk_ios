//
//  GetObtDataResponse.swift
//  FIOSDK
//
//  Created by shawn arney on 12/30/19.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

extension FIOSDK.Responses {
    
    public struct GetObtDataResponse: Codable {
        
        public var obtData: [ObtDataResponse]
        public let more: Int
        
        enum CodingKeys: String, CodingKey {
            case obtData = "obt_data_records"
            case more
        }
        
        public struct ObtDataResponse: Codable {
            
            public let fioRequestId: Int?
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
                public let payerPublicAddress: String
                public let payeePublicAddress: String
                public let amount: String
                public let tokenCode: String
                public let obtId: String
                public let status: String
                public let memo: String
                public let hash: String
                public let offlineUrl: String
                
                enum CodingKeys: String, CodingKey {
                    case payerPublicAddress = "payer_public_address"
                    case payeePublicAddress = "payee_public_address"
                    case amount
                    case tokenCode = "token_code"
                    case obtId = "obt_id"
                    case status
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
                let fioreqid = try container.decodeIfPresent(Int.self, forKey: .fioRequestId) ?? -1
                let content = try container.decodeIfPresent(String.self, forKey: .content) ?? ""
                
                let timeStampString = try (container.decodeIfPresent(String.self, forKey: .timeStamp) ?? "1970-01-01T12:00:00")
                                            .replacingOccurrences(of: "Z", with: "") + "Z"

                let timeStamp = timeStampString.toLocalDate
                
                let status = try container.decodeIfPresent(String.self, forKey: .status) ?? ""

                var metadataString = FIOSDK.sharedInstance().decrypt(publicKey: payeeFIOPublicKey, contentType: FIOAbiContentType.recordObtDataContent, encryptedContent: content)
                
                if (metadataString.count < 1){
                    metadataString = FIOSDK.sharedInstance().decrypt(publicKey: payerFIOPublicKey, contentType: FIOAbiContentType.recordObtDataContent, encryptedContent: content)
                }
                
                var deadRecord = false
                var metadata = ObtDataResponse.MetaData(payerPublicAddress: "", payeePublicAddress: "", amount: "", tokenCode: "", obtId: "", status: "", memo: "", hash: "", offlineUrl: "")
                if let metadataData = metadataString.data(using: .utf8) {
                    do {
                        metadata = try JSONDecoder().decode(ObtDataResponse.MetaData.self, from: metadataData)
                    }
                    catch {
                         deadRecord = true
                    }
                }
                
                if (deadRecord){
                    self.init(fioRequestId: -1,
                        payerFIOAddress: "",
                        payeeFIOAddress: "",
                        payerFIOPublicKey: "",
                        payeeFIOPublicKey: "",
                        timeStamp: Date(timeIntervalSince1970: 1),
                        status: "",
                        content: metadata)
                    
                }
                else {
                    self.init(fioRequestId: fioreqid,
                        payerFIOAddress: payerFIOAddress,
                        payeeFIOAddress: payeeFIOAddress,
                        payerFIOPublicKey: payerFIOPublicKey,
                        payeeFIOPublicKey: payeeFIOPublicKey,
                        timeStamp: timeStamp,
                        status: status,
                        content: metadata)
                }

            }
            
        }
        
    }
    
}
