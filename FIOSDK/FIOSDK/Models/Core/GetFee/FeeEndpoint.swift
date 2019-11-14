//
//  FeeEndpoint.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-05-27.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

extension FIOSDK.Params {

    public enum FeeEndpoint: String {
        
        case registerFIODomain = "register_fio_domain"
        case registerFIOAddress = "register_fio_address"
        case transferTokensPubKey = "transfer_tokens_pub_key"
        case transferTokensFIOAddress = "transfer_tokens_fio_address"
        
    }

}
