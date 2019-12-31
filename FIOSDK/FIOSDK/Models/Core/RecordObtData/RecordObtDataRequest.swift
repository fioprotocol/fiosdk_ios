//
//  RecordSendRequest.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-04-03.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

public struct RecordObtDataRequest: Codable {
    
    let payerFIOAddress: String
    let payeeFIOAddress: String
    let content: String
    let fioRequestId: Int?
    let maxFee: Int
    let walletFioAddress: String
    let actor: String
    
    enum CodingKeys: String, CodingKey {
        case payerFIOAddress = "payer_fio_address"
        case payeeFIOAddress = "payee_fio_address"
        case content
        case fioRequestId = "fio_request_id"
        case maxFee = "max_fee"
        case walletFioAddress = "tpid"
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
