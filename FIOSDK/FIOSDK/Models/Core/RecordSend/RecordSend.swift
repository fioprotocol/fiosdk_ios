//
//  RecordSend.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-04-03.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

internal struct RecordSend: Codable {
    
    let fioReqID: String?
    let fromFIOAdd: String
    let toFIOAdd: String
    let fromPubAdd: String
    let toPubAdd: String
    let amount: String
    let tokenCode: String
    let chainCode: String
    let status: String
    let obtID: String
    let metadata: String
    
    enum CodingKeys: String, CodingKey {
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
    
    public init(fioReqID: String? = nil,
                fromFIOAdd: String,
                toFIOAdd: String,
                fromPubAdd: String,
                toPubAdd: String,
                amount: Float,
                tokenCode: String,
                chainCode: String,
                status: String,
                obtID: String,
                memo: String) {
        self.fioReqID = fioReqID
        self.fromFIOAdd = fromFIOAdd
        self.toFIOAdd = toFIOAdd
        self.fromPubAdd = fromPubAdd
        self.toPubAdd = toPubAdd
        self.amount = String(amount)
        self.tokenCode = tokenCode
        self.chainCode = chainCode
        self.status = status
        self.obtID = obtID
        self.metadata = MetaData(memo: memo).toJSONString()
    }
    
    public struct MetaData: Codable {
        
        public var memo: String
        
        public init(memo: String){
            self.memo = memo
        }
        
        enum CodingKeys: String, CodingKey {
            case memo
        }
        
        func toJSONString() -> String {
            guard let json = try? JSONEncoder().encode(self) else {
                return ""
            }
            return String(data: json, encoding: .utf8) ?? ""
        }
        
    }
    
    func toJSONString() -> String {
        guard let json = try? JSONEncoder().encode(self) else {
            return ""
        }
        return String(data: json, encoding: .utf8) ?? ""
    }
    
}
