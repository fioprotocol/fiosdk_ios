//
//  RequestFundsRequest.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-04-04.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

public struct RequestFundsRequest: Codable {
    
    public let payerFIOAddress: String
    public let payeeFIOAddress: String
    public let payeePublicAddress: String
    public let amount: String
    public let tokenCode: String
    public let metadata: String
    public let actor: String
    public let maxFee: Int
    
    enum CodingKeys: String, CodingKey{
        case payerFIOAddress = "payer_fio_address"
        case payeeFIOAddress = "payee_fio_address"
        case payeePublicAddress = "payee_public_address"
        case amount
        case tokenCode = "token_code"
        case metadata
        case actor
        case maxFee = "max_fee"
    }
    
    public struct MetaData: Codable{
        public var memo: String?
        public var hash: String?
        public var offlineUrl: String?
        
        public init(memo: String?, hash: String?, offlineUrl: String?){
            self.memo = memo
            self.hash = hash
            self.offlineUrl = offlineUrl
        }
        
        enum CodingKeys: String, CodingKey {
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
    
}
