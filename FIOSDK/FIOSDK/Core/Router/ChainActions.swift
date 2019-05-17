//
//  ChainActions.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-04-02.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

internal enum ChainActions: String {
    
    case registerFIOName    = "regaddress"
    case newFundsRequest    = "newfundsreq"
    case rejectFundsRequest = "rejectfndreq"
    case addPublicAddress   = "addaddress"
    case recordSend         = "recordsend"
    case transferTokens     = "trnsfiopubky"
    
}
