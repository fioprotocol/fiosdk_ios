//
//  TxResultProcessed.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-04-04.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

extension FIOSDK.Responses {
    public struct TxResultProcessed: Codable {
        var actionTraces: [TxResultActionTrace]
        
        enum CodingKeys: String, CodingKey {
            case actionTraces = "action_traces"
        }
    }
}
