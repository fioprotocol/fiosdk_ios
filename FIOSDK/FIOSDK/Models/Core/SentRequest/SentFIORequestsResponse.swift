//
//  SentFIORequestsResponse.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-04-03.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

extension FIOSDK.Responses {

    public struct SentFIORequestsResponse: Codable {
        
        public let requests: [SentFIORequestResponse]
        
        enum CodingKeys: String, CodingKey {
            case requests
        }
        
        public struct SentFIORequestResponse: Codable {
            
            public let fioRequestId: String
            public let payerFIOAddress: String
            public let payeeFIOAddress: String
            public let payerFIOPublicKey: String
            public let payeeFIOPublicKey: String
           // public let amount: String
           // public let tokenCode: String
           // public let metadata: MetaData
            public let content:String
            public let timeStamp: TimeInterval
            public let status: String
            
            enum CodingKeys: String, CodingKey {
                case fioRequestId = "fio_request_id"
                case payerFIOAddress = "payer_fio_address"
                case payeeFIOAddress = "payee_fio_address"
                case payerFIOPublicKey = "payer_fio_public_key"
                case payeeFIOPublicKey = "payee_fio_public_key"
                case content
                case timeStamp = "time_stamp"
                case status
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
                 timeStamp: TimeInterval,
                 status: String) {
                self.fioRequestId = fioRequestId
                self.payerFIOAddress = payerFIOAddress
                self.payeeFIOAddress = payeeFIOAddress
                self.payerFIOPublicKey = payerFIOPublicKey
                self.payeeFIOPublicKey = payeeFIOPublicKey
                self.content = content
                self.timeStamp = timeStamp
                self.status = status
            }
            
            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                
                let fioreqid = try container.decodeIfPresent(String.self, forKey: .fioRequestId) ?? ""
                let payerFIOAddress = try container.decodeIfPresent(String.self, forKey: .payerFIOAddress) ?? ""
                let payeeFIOAddress = try container.decodeIfPresent(String.self, forKey: .payeeFIOAddress) ?? ""
                let payerFIOPublicKey = try container.decodeIfPresent(String.self, forKey: .payerFIOPublicKey) ?? ""
                let payeeFIOPublicKey = try container.decodeIfPresent(String.self, forKey: .payeeFIOPublicKey) ?? ""
                let content = try container.decodeIfPresent(String.self, forKey: .content) ?? ""
                let timeStamp = try container.decodeIfPresent(TimeInterval.self, forKey: .timeStamp) ?? Date().timeIntervalSince1970
               // var metadata = SentFIORequestResponse.MetaData(memo: "")
                //let metadataString = try container.decodeIfPresent(String.self, forKey: .metadata)
                //if let metadataData = metadataString?.data(using: .utf8) {
                //    metadata = try JSONDecoder().decode(SentFIORequestResponse.MetaData.self, from: metadataData)
               // }
                let status = try container.decodeIfPresent(String.self, forKey: .status) ?? ""
                
                let json = FIOSDK.sharedInstance().decrypt(publicKey: payerFIOPublicKey, contentType: FIOAbiContentType.newFundsContent, encryptedContent: content)
                print (json)
                
                self.init(fioRequestId: fioreqid,
                    payerFIOAddress: payerFIOAddress,
                    payeeFIOAddress: payeeFIOAddress,
                    payerFIOPublicKey: payerFIOPublicKey,
                    payeeFIOPublicKey: payeeFIOPublicKey,
                    content: content,
                    timeStamp: timeStamp,
                    status: status)
            }
            
            /*
             
             1. With the payee private key and the payer public key (fio public address), create the sharedSecret
             
             
             2. With the content field, map each field to it's json value.
             3. With the content json, pass it to the ABI packer.
             
             1. decrypt the resultant ABI packer data.  Using the sharedSecret
             2. with the payee private key and the payer public key, create the sharedsecret
             
             
             */
            
            private func decryptContent(payerPublicKey: String, content: String){
            
                let json = FIOSDK.sharedInstance().decrypt(publicKey: payerPublicKey, contentType: FIOAbiContentType.newFundsContent, encryptedContent: content)
                print (json)
            }
            
            
            
        }
        
    }
    
}
