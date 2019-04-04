//
//  RequestFundsResponse.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-04-04.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

public struct RequestFundsResponse: Codable {
    
    public var fundsRequestId: String {
        return String(fioreqid)
    }
    public let fioreqid: Int //TODO: Change it back to String if Ed confirm it should be String
    
    enum CodingKeys: String, CodingKey {
        case fioreqid
    }
    
    init(fioreqid: Int) {
        self.fioreqid = fioreqid
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let fioreqid: Int = try container.decodeIfPresent(Int.self, forKey: .fioreqid) ?? 0
        
        self.init(fioreqid: fioreqid)
    }
    
}
