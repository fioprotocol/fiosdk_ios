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
    public let content: String
    public let maxFee: Int
    public let technologyProviderId: String
    public let actor: String
    
    enum CodingKeys: String, CodingKey{
        case payerFIOAddress = "payer_fio_address"
        case payeeFIOAddress = "payee_fio_address"
        case content
        case maxFee = "max_fee"
        case technologyProviderId = "tpid"
        case actor
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
