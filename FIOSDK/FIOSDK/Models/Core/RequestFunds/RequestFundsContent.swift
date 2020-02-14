//
//  RequestFundsContent.swift
//  FIOSDK
//
//  Created by shawn arney on 10/15/19.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

public struct RequestFundsContent: Codable {
    
    public let payeePublicAddress: String
    public let amount: String
    public let chainCode: String
    public let tokenCode: String
    public let memo: String
    public let hash: String
    public let offlineUrl: String

    enum CodingKeys: String, CodingKey{
        case payeePublicAddress = "payee_public_address"
        case amount
        case chainCode = "chain_code"
        case tokenCode = "token_code"
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
