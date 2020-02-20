//
//  TxResultActionTrace.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-04-04.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

extension FIOSDK.Responses {
    public struct TxResultActionTrace: Codable {
        var receipt: TxResultReceipt
    }
}
