//
//  ChainRoutes.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-04-02.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

internal enum ChainRoutes: String {
    
    case availCheck               = "/chain/avail_check"
    case serializeJSON            = "/chain/serialize_json"
    case newFundsRequest          = "/chain/new_funds_request"
    case rejectFundsRequest       = "/chain/reject_funds_request"
    case addPublicAddress         = "/chain/add_pub_address"
    case publicAddressLookup         = "/chain/pub_address_lookup"
    case getFIONames              = "/chain/get_fio_names"
    case getPendingFIORequests    = "/chain/get_pending_fio_requests"
    case getSentFIORequests       = "/chain/get_sent_fio_requests"
    case recordSend               = "/chain/record_send"
    case getFIOBalance            = "/chain/get_fio_balance"
    case transferTokens           = "/chain/transfer_tokens_pub_key"
    case getInfo                  = "/chain/get_info"
    case getBlock                 = "/chain/get_block"
    case registerFIODomain        = "/chain/register_fio_domain"
    case registerFIOAddress       = "/chain/register_fio_address"
    case renewFIODomain           = "/chain/renew_fio_domain"
    case renewFIOAddress          = "/chain/renew_fio_address"
    case getFee                   = "/chain/get_fee"
    case getABI                   = "/chain/get_raw_abi"
}
