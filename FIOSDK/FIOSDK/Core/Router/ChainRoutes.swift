//
//  ChainRoutes.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-04-02.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

internal enum ChainRoutes: String {
    
    case serializeJSON          = "/chain/serialize_json"
    case registerFIOName        = "/chain/register_fio_name"
    case newFundsRequest        = "/chain/new_funds_request"
    case rejectFundsRequest     = "/chain/reject_funds_request"
    case addPublicAddress       = "/chain/add_pub_address"
    case pubAddressLookup       = "/chain/pub_address_lookup"
    case getFIONames            = "/chain/get_fio_names"
    case getPendingFIORequests  = "/chain/get_pending_fio_requests"
    case getSentFIORequests     = "/chain/get_sent_fio_requests"
    case recordSend             = "/chain/record_send"
    case getFIOBalance          = "/chain/get_fio_balance"
    case transferTokens         = "/chain/transfer_tokens"
    case getInfo                = "/chain/get_info"
    case getBlock               = "/chain/get_block"
    
}
