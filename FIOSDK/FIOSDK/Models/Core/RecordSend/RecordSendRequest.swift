//
//  RecordSendRequest.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-04-03.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

internal struct RecordSendRequest: Codable {
    
    let fioReqID: String
    let payerFIOAddress: String
    let payeeFIOAddress: String
    let payerPublicAddress: String
    let payeePublicAddress: String
    let amount: String
    let tokenCode: String
    let status: String
    let obtID: String
    let metadata: String
    let actor: String
    let maxFee: Int
    
    enum CodingKeys: String, CodingKey {
        case payerFIOAddress = "payer_fio_address"
        case payeeFIOAddress = "payee_fio_address"
        case payerPublicAddress = "payer_public_address"
        case payeePublicAddress = "payee_public_address"
        case amount = "amount"
        case tokenCode = "token_code"
        case status = "status"
        case obtID = "obt_id"
        case metadata = "metadata"
        case fioReqID = "fio_request_id"
        case actor
        case maxFee = "max_fee"
    }
    
    public init(fioReqID: String? = nil,
                payerFIOAddress: String,
                payeeFIOAddress: String,
                payerPublicAddress: String,
                payeePublicAddress: String,
                amount: Float,
                tokenCode: String,
                status: String,
                obtID: String,
                memo: String,
                actor: String,
                maxFee: Int) {
        self.fioReqID = fioReqID ?? ""
        self.payerFIOAddress = payerFIOAddress
        self.payeeFIOAddress = payeeFIOAddress
        self.payerPublicAddress = payerPublicAddress
        self.payeePublicAddress = payeePublicAddress
        self.amount = String(amount)
        self.tokenCode = tokenCode
        self.status = status
        self.obtID = obtID
        self.metadata = MetaData(memo: memo).toJSONString()
        self.actor = actor
        self.maxFee = maxFee
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
