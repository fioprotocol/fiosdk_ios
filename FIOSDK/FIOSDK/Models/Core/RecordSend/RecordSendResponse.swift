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
        
        public let fioObtID: String
        public let fromFIOAdd: String
        public let toFIOAdd: String
        public let fromPubAdd: String
        public let toPubAdd: String
        public let amount: String
        public let tokenCode: String
        public let chainCode: String
        public let status: String
        public let obtID: String
        public let metadata: MetaData
        public let fioReqID: String?
        
        enum CodingKeys: String, CodingKey {
            case fioObtID = "fioobtid"
            case fromFIOAdd = "fromfioadd"
            case toFIOAdd = "tofioadd"
            case fromPubAdd = "frompubadd"
            case toPubAdd = "topubadd"
            case amount = "amount"
            case tokenCode = "tokencode"
            case chainCode = "chaincode"
            case status = "status"
            case obtID = "obtid"
            case metadata = "metadata"
            case fioReqID = "fioreqid"
        }
        
        public struct MetaData: Codable {
            
            public let memo: String
            
        }
        
        init(fioObtID: String,
             fromFIOAdd: String,
             toFIOAdd: String,
             fromPubAdd: String,
             toPubAdd: String,
             amount: String,
             tokenCode: String,
             chainCode: String,
             status: String,
             obtID: String,
             metadata: MetaData,
             fioReqID: String?) {
            self.fioObtID = fioObtID
            self.fromFIOAdd = fromFIOAdd
            self.toFIOAdd = toFIOAdd
            self.fromPubAdd = fromPubAdd
            self.toPubAdd = toPubAdd
            self.amount = amount
            self.tokenCode = tokenCode
            self.chainCode = chainCode
            self.status = status
            self.obtID = obtID
            self.metadata = metadata
            self.fioReqID  = fioReqID
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            let fioObtID = try container.decodeIfPresent(String.self, forKey: .fioObtID) ?? ""
            let fioReqID = try container.decodeIfPresent(String.self, forKey: .fioReqID)
            let fromFIOAdd = try container.decodeIfPresent(String.self, forKey: .fromFIOAdd) ?? ""
            let toFIOAdd = try container.decodeIfPresent(String.self, forKey: .toFIOAdd) ?? ""
            let fromPubAdd = try container.decodeIfPresent(String.self, forKey: .fromPubAdd) ?? ""
            let toPubAdd = try container.decodeIfPresent(String.self, forKey: .toPubAdd) ?? ""
            let amount = try container.decodeIfPresent(String.self, forKey: .amount) ?? ""
            let tokenCode = try container.decodeIfPresent(String.self, forKey: .tokenCode) ?? ""
            let chainCode = try container.decodeIfPresent(String.self, forKey: .chainCode) ?? ""
            let obtID = try container.decodeIfPresent(String.self, forKey: .obtID) ?? ""
            let status = try container.decodeIfPresent(String.self, forKey: .status) ?? ""
            var metadata = RecordSendResponse.MetaData(memo: "")
            let metadataString = try container.decodeIfPresent(String.self, forKey: .metadata)
            if let metadataData = metadataString?.data(using: .utf8) {
                metadata = try JSONDecoder().decode(RecordSendResponse.MetaData.self, from: metadataData)
            }
            
            self.init(fioObtID: fioObtID,
                      fromFIOAdd: fromFIOAdd,
                      toFIOAdd: toFIOAdd,
                      fromPubAdd: fromPubAdd,
                      toPubAdd: toPubAdd,
                      amount: amount,
                      tokenCode: tokenCode,
                      chainCode: chainCode,
                      status: status,
                      obtID: obtID,
                      metadata: metadata,
                      fioReqID: fioReqID)
        }
        
    }
    
}
