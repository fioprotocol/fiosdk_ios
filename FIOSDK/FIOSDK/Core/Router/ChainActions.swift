//
//  ChainActions.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-04-02.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

internal enum ChainActions: String {
    
    case newFundsRequest        = "newfundsreq"
    case rejectFundsRequest     = "rejectfndreq"
    case addPublicAddress       = "addaddress"
    case recordSend             = "recordsend"
    case transferTokens         = "trnsfiopubky"
    case registerFIODomain      = "regdomain"
    case registerFIOAddress     = "regaddress"
    case renewFIODomain         = "renewdomain"
    
}
