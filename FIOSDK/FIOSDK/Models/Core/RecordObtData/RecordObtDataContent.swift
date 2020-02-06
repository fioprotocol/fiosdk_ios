//
//  RecordSendContent.swift
//  FIOSDK
//
//  Created by shawn arney on 12/3/19.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

public struct RecordObtDataContent: Codable {
    
    public let payerPublicAddress: String
    public let payeePublicAddress: String
    public let amount: String
    public let chainCode: String
    public let tokenCode: String
    public let status: String
    public let obtId: String
    public let memo: String
    public let hash: String
    public let offlineUrl: String

    enum CodingKeys: String, CodingKey{
        case payerPublicAddress = "payer_public_address"
        case payeePublicAddress = "payee_public_address"
        case amount
        case chainCode = "chain_code"
        case tokenCode = "token_code"
        case status
        case obtId = "obt_id"
        case memo
        case hash
        case offlineUrl = "offline_url"
    }
    
    func toJSONString() -> String {
        guard let json = try? JSONEncoder().encode(self) else {
            return ""
        }
        return String(data: json, encoding: .utf8) ?? ""
    }
}

