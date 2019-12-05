//
//  RequestFundsResponse.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-04-04.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

public struct RequestFundsResponse: Codable {

    #warning("what should fiorequestId be?  A string or Int? -- seems it is supposed to be an INT - change the spec if required")
    public let fioRequestId: Int
    public let status: String
    public let feeCollected: Int
    
    enum CodingKeys: String, CodingKey {
        case fioRequestId = "fio_request_id"
        case status
        case feeCollected = "fee_collected"
    }
    
}
