//
//  RecordSendRequest.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-04-03.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

internal struct RecordSendRequest: Codable {
    
    let recordSend: String
    let actor: String
    
    enum CodingKeys: String, CodingKey {
        case recordSend = "recordsend"
        case actor
    }
    
}
