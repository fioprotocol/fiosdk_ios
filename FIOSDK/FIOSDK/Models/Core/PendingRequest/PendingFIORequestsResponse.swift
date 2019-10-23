//
//  PendingFIORequestsResponse.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-04-04.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

extension FIOSDK.Responses {

    /// getPendingFioRequest DTO response
    public struct PendingFIORequestsResponse: Codable {
        
        public let requests: [PendingFIORequestResponse]
        
        enum CodingKeys: String, CodingKey{
            case requests
        }
        
        /// PendingFioRequestsResponse.request DTO
        public struct PendingFIORequestResponse: Codable {
            private let fioRequestId: String
            public let payerFIOAddress: String
            public let payeeFIOAddress: String
           // public let payeePublicAddress: String

            public let payerFIOPublicKey: String
            public let payeeFIOPublicKey: String
           // public let amount: String
           // public let tokenCode: String
           // public let metadata: MetaData
            public let timeStamp: TimeInterval
            public let content: String
            
            enum CodingKeys: String, CodingKey {
                case fioRequestId = "fio_request_id"
                case payerFIOAddress = "payer_fio_address"
                case payeeFIOAddress = "payee_fio_address"
                case payerFIOPublicKey = "payer_fio_public_key"
                case payeeFIOPublicKey = "payee_fio_public_key"
                case content = "content"
                case timeStamp = "time_stamp"
            }
            
            public struct MetaData: Codable {
                
                public let memo: String
                
            }
            
            init(fioRequestId: String,
                 payerFIOAddress: String,
                 payeeFIOAddress: String,
                 payerFIOPublicKey: String,
                 payeeFIOPublicKey: String,
                 content: String,
                 timeStamp: TimeInterval) {
                self.fioRequestId = fioRequestId
                self.payerFIOAddress = payerFIOAddress
                self.payeeFIOAddress = payeeFIOAddress
                self.payerFIOPublicKey = payerFIOPublicKey
                self.payeeFIOPublicKey = payeeFIOPublicKey
                self.content = content

                self.timeStamp = timeStamp
            }
            
            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                
                let fioreqid = try container.decodeIfPresent(String.self, forKey: .fioRequestId) ?? ""
                let payerFIOAddress = try container.decodeIfPresent(String.self, forKey: .payerFIOAddress) ?? ""
                let payeeFIOAddress = try container.decodeIfPresent(String.self, forKey: .payeeFIOAddress) ?? ""
                let payerFIOPublicKey = try container.decodeIfPresent(String.self, forKey: .payerFIOPublicKey) ?? ""
                let payeeFIOPublicKey = try container.decodeIfPresent(String.self, forKey: .payeeFIOPublicKey) ?? ""
               // let amount = try container.decodeIfPresent(String.self, forKey: .amount) ?? ""
               // let tokenCode = try container.decodeIfPresent(String.self, forKey: .tokenCode) ?? ""
                let timeStampValue = try container.decodeIfPresent(Double.self, forKey: .timeStamp)
                var timeStamp: TimeInterval = Date().timeIntervalSince1970
                if let timeStampDouble = timeStampValue {
                    timeStamp = TimeInterval(timeStampDouble)
                }
                /*
                var metadata = PendingFIORequestResponse.MetaData(memo: "")
                let metadataString = try container.decodeIfPresent(String.self, forKey: .metadata)?.replacingOccurrences(of: "[object Object]", with: "")
                
                if (metadataString != nil && metadataString!.count > 3){
                    if let metadataData = metadataString?.data(using: .utf8) {
                        metadata = try JSONDecoder().decode(PendingFIORequestResponse.MetaData.self, from: metadataData)
                    }
                }
 */

                self.init(fioRequestId: fioreqid,
                    payerFIOAddress: payerFIOAddress,
                    payeeFIOAddress: payeeFIOAddress,
                    payerFIOPublicKey: payerFIOPublicKey,
                    payeeFIOPublicKey: payeeFIOPublicKey,
                    content: "",
                    timeStamp: timeStamp)
                
            }
            
        }
        
    }
    
}
